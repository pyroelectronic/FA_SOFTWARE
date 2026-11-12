#!/usr/bin/python3 -IB
"""C1: vorhandene Ethernetprofile automatisch per permanenter MAC binden."""
import ast
import contextlib
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import uuid
try:
    import fcntl
except ImportError:  # Tests unter Windows; Installation nur unter Linux.
    fcntl = None

ROOT = Path("/var/lib/friedrich/c1")
BACKUP = ROOT / "profile-backup"
OLD_CONF = Path("/etc/NetworkManager/conf.d/90-friedrich-ethercat.conf")
NM = "org.freedesktop.NetworkManager"
NM_PATH = "/org/freedesktop/NetworkManager"
FIELDS = ("connection.uuid", "connection.interface-name", "connection.autoconnect",
          "802-3-ethernet.mac-address", "match.interface-name")


class Incomplete(Exception):
    pass


def run(*args):
    try:
        return subprocess.run(args, check=True, capture_output=True, text=True, timeout=30,
                              env={"PATH": "/usr/sbin:/usr/bin:/sbin:/bin", "LC_ALL": "C"}).stdout
    except (OSError, subprocess.SubprocessError):
        raise Incomplete("Aufruf fehlgeschlagen/Programm fehlt: " + args[0]) from None


def mac(value):
    if not isinstance(value, str) or not re.fullmatch(r"(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}", value):
        raise Incomplete("Permanente Hardware-MAC fehlt oder ist ungültig")
    raw = bytes.fromhex(value.replace(":", ""))
    if not any(raw) or raw[0] & 1:
        raise Incomplete("Unbrauchbare Hardware-MAC")
    return value.lower()


def hardware():
    found = {"r8168": [], "lan743x": []}
    for device in json.loads(run("ip", "-j", "link", "show")):
        name = device["ifname"]
        if device.get("link_type") != "ether" or not (Path("/sys/class/net") / name / "device").exists():
            continue
        info = run("ethtool", "-i", name)
        driver = next((s.partition(":")[2].strip() for s in info.splitlines() if s.startswith("driver:")), "")
        if driver in found:
            identity = mac(run("ethtool", "-P", name).strip().partition(": ")[2])
            found[driver].append({"name": name, "mac": identity})
    if any(len(devices) != 1 for devices in found.values()):
        raise Incomplete("LAN1/r8168 und LAN2/lan743x müssen jeweils eindeutig physisch erkannt werden")
    ports = {role: found[driver][0] for role, driver in (("LAN1", "r8168"), ("LAN2", "lan743x"))}
    if ports["LAN1"]["mac"] == ports["LAN2"]["mac"]:
        raise Incomplete("Beide Ethernetcontroller melden dieselbe permanente MAC")
    return ports


def profiles():
    rows = {}
    for line in run("nmcli", "-t", "--escape", "no", "-f", "UUID,TYPE", "connection", "show").splitlines():
        key, kind = line.split(":", 1)
        key = str(uuid.UUID(key))
        if kind not in ("ethernet", "802-3-ethernet"):
            continue
        fields = {}
        for row in run("nmcli", "-t", "--escape", "no", "-f", ",".join(FIELDS), "connection", "show", "uuid", key).splitlines():
            field, value = row.split(":", 1)
            if field not in FIELDS or field in fields:
                raise Incomplete("Profilfelder widersprüchlich")
            fields[field] = value
        fields.setdefault("match.interface-name", "")
        if set(fields) != set(FIELDS) or fields["connection.uuid"] != key or key in rows:
            raise Incomplete("Ethernetprofil unvollständig oder UUID widersprüchlich")
        if fields["802-3-ethernet.mac-address"]:
            fields["802-3-ethernet.mac-address"] = mac(fields["802-3-ethernet.mac-address"])
        rows[key] = fields
    active = {}
    for line in run("nmcli", "-t", "--escape", "no", "-f", "UUID,DEVICE", "connection", "show", "--active").splitlines():
        key, name = line.split(":", 1)
        key = str(uuid.UUID(key))
        if key in active:
            raise Incomplete("Aktive Profilzuordnung nicht eindeutig")
        active[key] = name
    return rows, active


def plan(ports, rows, active):
    result = []
    for role, port in ports.items():
        candidates = []
        for key, data in rows.items():
            bound, name = data["802-3-ethernet.mac-address"], data["connection.interface-name"]
            if bound == port["mac"] or (not bound and (name == port["name"] or (not name and active.get(key) == port["name"]))):
                candidates.append(key)
        if len(candidates) != 1:
            raise Incomplete(role + ": vorhandenes Ethernetprofil nicht eindeutig; keine Änderung")
        key = candidates[0]
        if (key in active and active[key] != port["name"]) or any(k != key and n == port["name"] for k, n in active.items()):
            raise Incomplete(role + ": aktive Verbindung widerspricht der Hardwarezuordnung")
        result.append(dict(role=role, uuid=key, **port))
    if len({item["uuid"] for item in result}) != 2:
        raise Incomplete("Beide Ports wurden demselben Profil zugeordnet")
    for key, data in rows.items():
        if key not in {item["uuid"] for item in result} and data["connection.autoconnect"] == "yes" and data["802-3-ethernet.mac-address"] in ("", ports["LAN1"]["mac"], ports["LAN2"]["mac"]):
            raise Incomplete("Weiteres Autoconnectprofil könnte LAN1/LAN2 übernehmen; keine Änderung")
    return result


def desired(item):
    return {"802-3-ethernet.mac-address": item["mac"], "connection.interface-name": "", "match.interface-name": ""}


def bound(items, rows):
    return all(item["uuid"] in rows and all(rows[item["uuid"]][k] == v for k, v in desired(item).items()) for item in items)


def private(path, directory=False):
    info = path.lstat()
    if path.is_symlink() or not (stat.S_ISDIR(info.st_mode) if directory else stat.S_ISREG(info.st_mode)) or info.st_uid != 0 or info.st_mode & 0o077:
        raise Incomplete("Kein sicheres root-privates Verzeichnis/Originalprofil: " + str(path))
    return info


def legacy_error(token, reason):
    command = ("sudo /usr/bin/python3 -I -B " + str(ROOT / token / "worker.py") + " rollback-manual " + token) if token else "Altzustand anhand C1_NETZWERK.md prüfen; nichts pauschal löschen"
    raise Incomplete("Altes C1 blockiert: " + reason + ". Manueller Rückfall über USB/Konsole: " + command)


def legacy_guard():
    if ROOT.exists() or ROOT.is_symlink():
        private(ROOT, directory=True)
        marker = ROOT / "pending"
        if marker.exists() or marker.is_symlink():
            token = marker.read_text().strip() if marker.is_file() and not marker.is_symlink() else ""
            legacy_error(token if re.fullmatch(r"[0-9a-f]{16}", token) else None, "pending-Marker vorhanden")
        for directory in ROOT.iterdir():
            if not re.fullmatch(r"[0-9a-f]{16}", directory.name):
                continue
            try:
                private(directory, directory=True)
                private(directory / "state.json")
                state = json.loads((directory / "state.json").read_text())
                closed = state["id"] == directory.name and state["status"] in ("committed", "rolled-back", "aborted")
            except (OSError, ValueError, KeyError, TypeError, Incomplete):
                closed = False
            if not closed:
                legacy_error(directory.name, "Transaktion offen oder Zustandsdatei unvollständig")
    if OLD_CONF.exists() or OLD_CONF.is_symlink():
        legacy_error(None, "alte LAN2-Unmanaged-Datei vorhanden; zugehörige Alttransaktion zuerst zurücknehmen")


def profile_path(key):
    raw = run("gdbus", "call", "--system", "--dest", NM, "--object-path", NM_PATH + "/Settings", "--method", NM + ".Settings.GetConnectionByUuid", key)
    objects = re.findall(r"'(/org/freedesktop/NetworkManager/Settings/[^']+)'", raw)
    if len(objects) != 1:
        raise Incomplete("Profilquelle nicht eindeutig")
    def prop(name):
        value = run("gdbus", "call", "--system", "--dest", NM, "--object-path", objects[0], "--method", "org.freedesktop.DBus.Properties.Get", NM + ".Settings.Connection", name).strip()
        if not value.startswith("(<") or not value.endswith(">,)"):
            raise Incomplete("Profilquellen-Metadaten nicht auswertbar")
        return value[2:-3]
    if prop("Unsaved") != "false" or prop("Flags") != "uint32 0":
        raise Incomplete("Profil hat ungespeicherte/temporäre Änderungen; keine sichere Originaldatei")
    path = Path(ast.literal_eval(prop("Filename")))
    if path.parent != Path("/etc/NetworkManager/system-connections") or path.resolve() != path:
        raise Incomplete("Profilquelle ist kein persistentes Keyfile unter /etc/NetworkManager/system-connections")
    private(path)
    return path


def backup(items, paths):
    expected = [(i["role"], i["uuid"], i["mac"], str(paths[i["uuid"]])) for i in items]
    if not BACKUP.exists() and not BACKUP.is_symlink():
        BACKUP.mkdir(mode=0o700)
        entries = []
        for number, item in enumerate(items, 1):
            path = paths[item["uuid"]]
            info, data = private(path), path.read_bytes()
            filename = "profile-" + str(number) + ".nmconnection"
            with (BACKUP / filename).open("xb") as stream:
                stream.write(data)
            os.chmod(BACKUP / filename, 0o600)
            entries.append(dict(role=item["role"], uuid=item["uuid"], mac=item["mac"], path=str(path), file=filename,
                                sha256=hashlib.sha256(data).hexdigest(), uid=info.st_uid, gid=info.st_gid, mode=format(stat.S_IMODE(info.st_mode), "04o")))
        with (BACKUP / "manifest.json").open("x", encoding="utf-8") as stream:
            json.dump({"profiles": entries}, stream, indent=2)
        os.chmod(BACKUP / "manifest.json", 0o600)
    private(BACKUP, directory=True)
    private(BACKUP / "manifest.json")
    entries = json.loads((BACKUP / "manifest.json").read_text())["profiles"]
    if len(entries) != 2 or [(e["role"], e["uuid"], e["mac"], e["path"]) for e in entries] != expected:
        raise Incomplete("Originalbackup gehört nicht zu diesen beiden Profilen; nichts überschrieben")
    for number, entry in enumerate(entries, 1):
        if entry["file"] != "profile-" + str(number) + ".nmconnection":
            raise Incomplete("Backupmanifest widersprüchlich")
        if (entry.get("uid") != 0 or type(entry.get("gid")) is not int or entry["gid"] < 0 or
                not isinstance(entry.get("mode"), str) or not re.fullmatch(r"[0-7]{4}", entry["mode"]) or int(entry["mode"], 8) & 0o077):
            raise Incomplete("Backupmanifest enthält keine gültigen Originalrechte")
        source = BACKUP / entry["file"]
        private(source)
        if hashlib.sha256(source.read_bytes()).hexdigest() != entry["sha256"]:
            raise Incomplete("Originalbackup unvollständig/beschädigt; keine Profiländerung")


@contextlib.contextmanager
def locked():
    ROOT.mkdir(mode=0o700, parents=True, exist_ok=True)
    private(ROOT, directory=True)
    fd = os.open(ROOT / "lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    try:
        if fcntl is None:
            raise Incomplete("Installation benötigt Linux-flock")
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        os.close(fd)


def inspect():
    legacy_guard()
    rows, active = profiles()
    return plan(hardware(), rows, active), rows


def source_paths(items):
    paths = {i["uuid"]: profile_path(i["uuid"]) for i in items}
    if len(set(paths.values())) != 2:
        raise Incomplete("Beide Profile müssen getrennte Originaldateien haben")
    return paths


def install(check=False):
    items, rows = inspect()
    if bound(items, rows):
        source_paths(items)  # Korrekte In-Memory-Werte allein sind nicht dauerhaft.
        print("C1 OK: beide vorhandenen Profile bereits dauerhaft per MAC gebunden; nichts geändert.")
        return 0
    if check:
        print("C1 OFFEN: MAC-/Namensbindungen noch einzurichten; c1-install ausführen.")
        return 1
    with locked():
        items, rows = inspect()  # Nach Warten auf das Lock erneut lesen.
        paths = source_paths(items)
        if bound(items, rows):
            print("C1 OK: bereits eingerichtet; nichts geändert.")
            return 0
        backup(items, paths)  # Beide Originale vollständig prüfen, bevor etwas geändert wird.
        print("Originalprofile gesichert: " + str(BACKUP))
        try:
            for item in items:
                if not bound([item], rows):
                    args = ["nmcli", "connection", "modify", "uuid", item["uuid"]]
                    for key, value in desired(item).items():
                        args.extend((key, value))
                    run(*args)
            after, _ = profiles()
            if not bound(items, after) or any(profile_path(i["uuid"]) != paths[i["uuid"]] for i in items):
                raise Incomplete("Gespeicherte Profilbindung/Quelldatei weicht ab")
        except (Incomplete, OSError, ValueError, KeyError, TypeError):
            raise Incomplete("Profiländerung unvollständig; kein automatischer Rückfall. Beide Originale aus " + str(BACKUP) + " gemäß C1_NETZWERK.md manuell wiederherstellen") from None
        print("C1 OK: beide vorhandenen Profile dauerhaft gebunden. Fertig; keine Bestätigung erforderlich.")
        return 0


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("install", "status"):
        print("Aufruf über install.sh c1-install oder c1-status", file=sys.stderr)
        return 2
    try:
        if sys.platform != "linux" or os.geteuid() != 0:
            raise Incomplete("Linux/root erforderlich")
        return install(check=sys.argv[1] == "status")
    except (Incomplete, OSError, ValueError, KeyError, TypeError) as error:
        reason = str(error) if isinstance(error, Incomplete) else "Bestand oder Originalbackup nicht vollständig lesbar; keine Sicherung überschreiben"
        print("C1 FEHLER: " + reason, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
