#!/usr/bin/env bash
# B1-Diagnose: nur Leseabfragen; geschrieben wird ausschließlich ein neues Benutzerprotokoll.
set -u

usage() {
    printf 'Aufruf ohne sudo: bash %s AI7020-8|AI7100-3\n' "$0"
}
if [[ $# == 1 && ( $1 == --help || $1 == -h ) ]]; then usage; exit 0; fi
if [[ $# != 1 || ( $1 != AI7020-8 && $1 != AI7100-3 ) ]]; then usage >&2; exit 2; fi
if (( EUID == 0 )); then
    printf 'Bitte als normaler Projektbenutzer ohne vorangestelltes sudo starten.\n' >&2
    exit 2
fi
if [[ ! -x /usr/bin/uname || $(/usr/bin/uname -s) != Linux ]]; then
    printf 'B1 benötigt Linux; es wurden keine Abfragen ausgeführt.\n' >&2
    exit 2
fi
if [[ ! -x /usr/bin/python3 ]]; then
    printf 'Erforderliches /usr/bin/python3 fehlt; nichts installiert.\n' >&2
    exit 2
fi

exec /usr/bin/python3 -I -B - "$1" "${BASH_SOURCE[0]}" <<'PYTHON'
import datetime
import hashlib
import os
import pwd
import secrets
import stat
import subprocess
import sys

# Dieser Teil läuft als lesender Unterprozess. Kein Dateischreibzugriff, keine Shell.
COLLECTOR = r'''
import datetime
import fnmatch
import hashlib
import os
from pathlib import Path
import re
import shlex
import shutil
import stat
import subprocess
import sys
from urllib.parse import urlsplit
import zlib

ENV = {"PATH": "/usr/sbin:/usr/bin:/sbin:/bin", "LC_ALL": "C", "LANG": "C", "TZ": "UTC"}
APT = ["-o", "Dir::Cache::pkgcache=", "-o", "Dir::Cache::srcpkgcache="]
problems = set()
missing = set()
package_re = re.compile(r"[a-z0-9][a-z0-9+.-]*(?::[a-z0-9-]+)?")
version_re = re.compile(r"[A-Za-z0-9.+:~_-]+")
path_re = re.compile(r"/[A-Za-z0-9_./+@=-]+")

def emit(*fields):
    # Keine Terminalsteuerzeichen, URLs oder mehrzeiligen Fremdausgaben durchreichen.
    values = []
    for value in fields:
        value = str(value)
        if "://" in value or any(ord(c) < 32 or ord(c) == 127 for c in value):
            value = "<nicht protokolliert>"
        values.append(value)
    print("\t".join(values), flush=True)

def problem(message):
    if message not in problems:
        problems.add(message)
        emit("OFFEN", message)

def run(program, *args, allowed=(0,)):
    executable = shutil.which(program, path=ENV["PATH"])
    if not executable:
        if program not in missing:
            missing.add(program)
            problem("Programm fehlt: " + program)
        return None
    try:
        result = subprocess.run([executable, *args], env=ENV, stdin=subprocess.DEVNULL,
                                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                timeout=30, check=False)
    except subprocess.TimeoutExpired:
        problem("Zeitlimit bei Leseabfrage: " + program)
        return None
    except OSError:
        problem("Leseabfrage nicht ausführbar: " + program)
        return None
    if result.returncode not in allowed:
        problem("Leseabfrage fehlgeschlagen: " + program + " (Exit " + str(result.returncode) + ")")
        return None
    return result.stdout

def text(data):
    return data.decode("utf-8", errors="replace") if data is not None else ""

def read(path, optional=False):
    try:
        target = Path(path).resolve(strict=True)
        if not stat.S_ISREG(os.lstat(target).st_mode):
            problem("Eingabe ist keine reguläre Datei; nicht gelesen")
            return None
        descriptor = os.open(target, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(descriptor, "rb") as stream:
            if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):
                problem("Dateityp änderte sich; nicht gelesen")
                return None
            data = stream.read(32 * 1024 * 1024 + 1)
            if len(data) > 32 * 1024 * 1024:
                problem("Eingabedatei zu groß für die kompakte Erfassung")
                return None
            return data
    except FileNotFoundError:
        if not optional:
            problem("Erforderliche Eingabedatei fehlt")
    except (OSError, RuntimeError):
        problem("Eingabedatei nicht lesbar")
    return None

def public_path(path):
    value = str(path)
    return value if path_re.fullmatch(value) else "<Pfad nicht protokolliert>"

def section(name):
    print("\n" + name, flush=True)

def apt_config(*pairs):
    raw = run("apt-config", "shell", *[item for pair in pairs for item in pair])
    try:
        return dict(item.split("=", 1) for item in shlex.split(text(raw)))
    except ValueError:
        problem("APT-Konfigurationsantwort nicht auswertbar")
        return {}

def cache_stamp(directory):
    try:
        entries = sorted((p.name, p.stat().st_size, p.stat().st_mtime_ns)
                         for p in Path(directory).iterdir() if p.is_file())
        return entries
    except OSError:
        problem("APT-Listenstand nicht lesbar")
        return None

section("1 SYSTEM UND PAKETE")
emit("ABFRAGEMODUS", "privilegiert lesend" if os.geteuid() == 0 else "ohne sudo, möglicherweise unvollständig")
status_before = read("/var/lib/dpkg/status")
os_release = text(read("/etc/os-release"))
for line in os_release.splitlines():
    key, sep, value = line.partition("=")
    if sep and key in ("ID", "VERSION_ID"):
        value = value.strip('"')
        emit(key, value if re.fullmatch(r"[a-z0-9._-]+", value) else "ungeprüftes Format")
kernel = os.uname().release
if not version_re.fullmatch(kernel):
    problem("Kernelrelease hat ungeprüftes Format")
    kernel = "unbekannt"
emit("KERNEL", kernel)
emit("ARCH", os.uname().machine)
release = text(read("/etc/nv_tegra_release"))
match = re.search(r"^# R(\d+).*REVISION:\s*([0-9.]+),", release, re.M)
emit("L4T", match.group(1) + "." + match.group(2) if match else "nicht ermittelt")
if not match:
    problem("L4T-Release nicht auswertbar")

packages = {}
raw = run("dpkg-query", "-W", "-f=${binary:Package}\t${Version}\t${Architecture}\t${db:Status-Status}\n")
for line in text(raw).splitlines():
    fields = line.split("\t")
    if len(fields) == 4 and package_re.fullmatch(fields[0]) and version_re.fullmatch(fields[1]):
        packages[fields[0]] = fields[1:]
    else:
        problem("Paketdatensatz mit ungeprüftem Format ausgelassen")
holds = set()
holds_raw = run("dpkg", "--get-selections")
for line in text(holds_raw).splitlines():
    fields = line.split()
    if len(fields) == 2 and fields[1] == "hold" and package_re.fullmatch(fields[0]):
        holds.add(fields[0])
emit("HOLDS", "nicht auswertbar" if holds_raw is None else ", ".join(sorted(holds)) or "keine")
audit = run("dpkg", "--audit")
emit("DPKG-AUDIT", "OK" if audit == b"" else "auffällig oder nicht auswertbar; Rohtext ausgelassen")
if audit:
    problem("dpkg-Audit meldet Auffälligkeiten")

overview = re.compile(r"^(nvidia-|libnv|cuda-|libcu(?:blas|d|fft|file|pti|rand|solver|sparse)|tensorrt|vpi|linux-(?:image|modules|headers|generic|firmware)|initramfs-tools|linux-base|flash-kernel|u-boot|grub|shim|apt$|dpkg$|unattended-upgrades|packagekit|snapd|fwupd|cron$|anacron$)")
selected = {p for p in packages if overview.search(p.split(":")[0])}
emit("PAKETE-GESAMT", len(packages) if raw is not None else "nicht auswertbar", "im Bericht nur BSP/NVIDIA/Updater und Artefaktbesitzer")

section("2 APT-QUELLEN (OHNE URI/GEHEIMNISSE)")
cfg = apt_config(("SL", "Dir::Etc::sourcelist/f"), ("SP", "Dir::Etc::sourceparts/d"),
                 ("PF", "Dir::Etc::preferences/f"), ("PP", "Dir::Etc::preferencesparts/d"),
                 ("LISTS", "Dir::State::lists/d"))
cache_before = cache_stamp(cfg["LISTS"]) if "LISTS" in cfg else None

def source_class(uri):
    try:
        uri = urlsplit(uri)
        if uri.scheme not in ("http", "https"):
            return "sonstige Quelle, lokal prüfen"
        if uri.hostname == "repo.download.nvidia.com" and uri.path.rstrip("/") in ("/jetson/common", "/jetson/t234"):
            return uri.scheme + ":NVIDIA" + uri.path.rstrip("/")
        if uri.hostname and (uri.hostname == "ubuntu.com" or uri.hostname.endswith(".ubuntu.com")):
            return uri.scheme + ":Ubuntu"
        if uri.hostname == "download.docker.com":
            return uri.scheme + ":Docker"
    except ValueError:
        pass
    return "sonstige Quelle, lokal prüfen"

def source_value(value):
    return value if len(value) <= 300 and re.fullmatch(r"[A-Za-z0-9_./ +,-]*", value) else "ungeprüftes Format"

sources = []
try:
    if "SL" in cfg:
        sources.append(Path(cfg["SL"]))
    if "SP" in cfg:
        sources += sorted(p for p in Path(cfg["SP"]).iterdir() if p.suffix in (".list", ".sources") and p.is_file())
except OSError:
    problem("APT-Quellenverzeichnis nicht lesbar")
source_count = 0
for path in sources:
    data = read(path, optional=True)
    if data is None:
        continue
    records = []
    if path.suffix == ".sources":
        for block in re.split(r"\n\s*\n", text(data)):
            fields, key = {}, None
            for line in block.splitlines():
                if not line.strip() or line.lstrip().startswith("#"):
                    continue
                if line[:1].isspace() and key:
                    fields[key] += " " + line.strip()
                elif ":" in line:
                    key, value = line.split(":", 1)
                    key = key.lower()
                    fields[key] = value.strip()
            if fields:
                records.append(fields)
    else:
        for line in text(data).splitlines():
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            match = re.fullmatch(r"\s*(deb(?:-src)?)\s+(?:\[([^\]]*)\]\s+)?(\S+)\s+(\S+)(.*)", line)
            if not match:
                problem("APT-Quellenzeile nicht erkannt; Rohtext ausgelassen")
                continue
            typ, opts, uri, suite, components = match.groups()
            opts = dict(x.split("=", 1) for x in (opts or "").split() if "=" in x)
            fields = dict(types=typ, uris=uri, suites=suite, components=components.split("#", 1)[0].strip(),
                          architectures=opts.get("arch", "Standard"), trusted=opts.get("trusted", "Standard"),
                          **{"signed-by": opts.get("signed-by", "")})
            if "arch+" in opts or "arch-" in opts:
                fields["architectures"] = "Zusatzregel-lokal-pruefen"
            records.append(fields)
    for fields in records:
        source_count += 1
        if not all(key in fields for key in ("types", "uris", "suites")):
            problem("Unvollständiger APT-Quellendatensatz; Rohtext ausgelassen")
            continue
        if "architectures-add" in fields or "architectures-remove" in fields:
            fields["architectures"] = "Zusatzregel-lokal-pruefen"
        emit("QUELLE", source_count,
             *[key + "=" + source_value(fields.get(key, default)) for key, default in
               (("types", "?"), ("suites", "?"), ("components", ""), ("architectures", "Standard"),
                ("enabled", "yes"), ("trusted", "Standard"))],
             "signed-by=" + ("definiert" if fields.get("signed-by") else "nicht angegeben"),
             "Ursprung=" + ",".join(source_class(uri) for uri in fields["uris"].split()))
try:
    pins = [Path(cfg["PF"])] if "PF" in cfg else []
    pins += list(Path(cfg["PP"]).iterdir()) if "PP" in cfg else []
    emit("PIN-DATEIEN", sum(p.is_file() for p in pins), "Regelinhalte bleiben gezielt lokal zu prüfen")
except OSError:
    problem("APT-Pin-Verzeichnis nicht lesbar")
emit("APT-STAND", "nur vorhandene lokale Listen; kein apt update; Binärcaches deaktiviert")

section("3 BSP-ARTEFAKTE: EIN DATEIKATALOG")
files = {}
module_scan_failed = False
roots = ["/boot", "/lib/modules/" + kernel, "/etc/kernel", "/usr/lib/linux/triggers",
         "/etc/initramfs-tools/hooks", "/etc/initramfs-tools/scripts", "/usr/share/initramfs-tools/hooks",
         "/etc/nv-update-initrd", "/etc/depmod.d", "/usr/lib/depmod.d"]
boot_patterns = ("Image", "Image.gz", "vmlinuz*", "initrd*", "*.dtb", "*.dtbo", "*.efi", "*.cap",
                 "extlinux.conf", "config-*", "System.map*")

def walk_error(error):
    global module_scan_failed
    if str(getattr(error, "filename", "")).startswith("/lib/modules/" + kernel):
        module_scan_failed = True
    problem("Artefaktverzeichnis nicht vollständig lesbar")

for root in roots:
    if not os.path.isdir(root):
        emit("VERZEICHNIS", root, "nicht vorhanden")
        if root in ("/boot", "/lib/modules/" + kernel):
            problem("Erforderlicher Boot-/Modulbaum fehlt")
            if root.startswith("/lib/modules/"):
                module_scan_failed = True
        continue
    role = "BOOT" if root == "/boot" else "MODUL" if root.startswith("/lib/modules/") else "HELFER"
    for parent, directories, names in os.walk(root, followlinks=False, onerror=walk_error):
        for directory in directories:
            if os.path.islink(os.path.join(parent, directory)):
                if role == "MODUL" and directory in ("build", "source"):
                    emit("MODUL-QUELLVERWEIS", directory, "absichtlich nicht verfolgt")
                else:
                    problem("Verzeichnislink im Artefaktbaum nicht verfolgt; Inhalt gesondert zuordnen")
                    if role == "MODUL":
                        module_scan_failed = True
        directories[:] = sorted(d for d in directories if d not in ("build", "source") and not os.path.islink(os.path.join(parent, d)))
        for name in sorted(names):
            if role == "BOOT" and not any(fnmatch.fnmatch(name.lower(), p.lower()) for p in boot_patterns):
                continue
            if role == "MODUL" and not (re.search(r"\.ko(?:\.(?:xz|gz|zst))?$", name) or name.startswith("modules.")):
                continue
            files[os.path.join(parent, name)] = role
for path in ("/etc/nv_boot_control.conf", "/usr/sbin/nvbootctrl", "/usr/sbin/nv-update-initrd",
             "/usr/sbin/nv_update_engine", "/usr/sbin/nv_bootloader_payload_updater",
             "/opt/nvidia/l4t-bootloader-config/nv-l4t-bootloader-config.sh"):
    if os.path.isfile(path):
        files[path] = "HELFER"

def permitted_target(path):
    # Ubuntu usrmerge: /lib/modules wird häufig unter /usr/lib/modules aufgelöst.
    allowed = roots + ["/usr/lib/modules/" + kernel, "/usr/sbin", "/usr/bin", "/opt/nvidia/l4t-bootloader-config"]
    return any(path == root or path.startswith(root + "/") for root in allowed)

resolved = {}
for path in files:
    target = os.path.realpath(path)
    if permitted_target(target) and public_path(path) == path and public_path(target) == target:
        resolved[path] = target
    else:
        problem("Artefakt mit nicht freigegebenem Pfad/Ziel ausgelassen")
        if files[path] == "MODUL":
            module_scan_failed = True

owners = {}
owners_complete = True
queries = sorted(set(resolved) | set(resolved.values()))
for start in range(0, len(queries), 80):
    raw = run("dpkg-query", "-S", "--", *queries[start:start + 80], allowed=(0, 1))
    if raw is None:
        owners_complete = False
    for line in text(raw).splitlines():
        prefix, sep, path = line.partition(": ")
        candidates = prefix.split(", ")
        if sep and path in queries and all(package_re.fullmatch(p) for p in candidates):
            owners.setdefault(path, set()).update(candidates)
        elif line.startswith(("diversion ", "local diversion ")):
            emit("HINWEIS", "dpkg-Diversion vorhanden; Zuordnung gezielt prüfen")
for path in resolved:
    selected.update(owners.get(path, set()) | owners.get(resolved[path], set()))

package_md5 = {}
md5_incomplete = set()
detail = {p for p in selected if p.startswith(("nvidia-l4t-", "linux-image-", "linux-modules-", "initramfs-tools", "linux-base", "flash-kernel", "grub", "shim", "u-boot", "nvidia-jetpack"))}
detail.update(p for values in owners.values() for p in values)
for package in sorted(detail):
    controls_raw = run("dpkg-query", "--control-list", package)
    if controls_raw is None:
        md5_incomplete.add(package)
    controls = text(controls_raw).splitlines()
    if "md5sums" in controls:
        sums = run("dpkg-query", "--control-show", package, "md5sums")
        if sums is None:
            md5_incomplete.add(package)
        for line in text(sums).splitlines():
            match = re.fullmatch(r"([0-9a-fA-F]{32})\s+(.+)", line)
            if match:
                package_md5[(package, "/" + match.group(2).lstrip("/"))] = match.group(1).lower()
    conffiles = run("dpkg-query", "-W", "-f=${Conffiles}\n", package)
    if conffiles is None:
        md5_incomplete.add(package)
    for line in text(conffiles).splitlines():
        match = re.fullmatch(r"\s*(/.*?)\s+([0-9a-fA-F]{32})(?:\s+obsolete)?", line)
        if match:
            package_md5[(package, match.group(1))] = match.group(2).lower()

hash_cache = {}
module_digest = hashlib.sha256()
module_count = module_errors = module_bytes = 0
for path in sorted(resolved):
    target = resolved[path]
    role = files[path]
    sha = md5 = "-"
    size = 0
    state = "ok"
    try:
        if not stat.S_ISREG(os.lstat(target).st_mode):
            raise OSError()
        descriptor = os.open(target, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(descriptor, "rb") as stream:
            before = os.fstat(stream.fileno())
            if not stat.S_ISREG(before.st_mode):
                raise OSError()
            key = (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns)
            if key not in hash_cache:
                h, m = hashlib.sha256(), hashlib.md5()
                for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                    h.update(chunk)
                    m.update(chunk)
                after = os.fstat(stream.fileno())
                if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
                    raise OSError()
                hash_cache[key] = (h.hexdigest(), m.hexdigest())
            sha, md5 = hash_cache[key]
            size = before.st_size
    except OSError:
        state = "unlesbar oder während Lesen geändert"
        problem("Dateikatalog unvollständig")
    assigned = owners.get(path, set()) | owners.get(target, set())
    expected = {package_md5[(p, f)] for p in assigned for f in (path, target) if (p, f) in package_md5}
    comparison = "unowned_in_dpkg" if not assigned else "checksum_not_recorded"
    if not assigned and not owners_complete:
        comparison = "ownership_not_determined"
    elif assigned & md5_incomplete:
        comparison = "checksum_not_determined"
    if expected and state == "ok":
        comparison = "matches_package_metadata" if md5 in expected else "differs_from_package_metadata"
    emit("DATEI", role, public_path(path), "Ziel=" + public_path(target) if target != path else "regulär",
         size, sha, ",".join(sorted(assigned)) or "ohne Paketzuordnung", comparison, state)
    if role == "MODUL":
        relative = os.path.relpath(path, "/lib/modules/" + kernel)
        module_digest.update((relative + "\t" + ("link" if path != target else "file") + "\t" + sha + "\n").encode())
        module_count += 1
        module_bytes += size
        module_errors += state != "ok"
emit("MODULBAUM", module_count, "Bytes=" + str(module_bytes), "SHA256=" + module_digest.hexdigest(),
     "vollständig" if module_errors == 0 and not module_scan_failed else "UNVOLLSTÄNDIG")
emit("DATEI-LEGENDE", "Paketzuordnung/MD5 beweist keine FA-Herkunft; unowned ist nicht automatisch FA-eigen")

for field in ("filename", "vermagic", "srcversion"):
    value = text(run("modinfo", "-k", kernel, "-F", field, "lan743x")).strip()
    if value and re.fullmatch(r"[A-Za-z0-9_./+ =:-]+", value) and "://" not in value:
        emit("LAN743X-" + field.upper(), value)
loaded = read("/sys/module/lan743x/srcversion", optional=True)
if loaded and re.fullmatch(r"[0-9A-Fa-f]+", text(loaded).strip()):
    emit("LAN743X-LAUFZEIT-SRCVERSION", text(loaded).strip(), "kein Bytehash-Nachweis der geladenen Datei")
kernel_config = read("/proc/config.gz", optional=True)
if kernel_config:
    import gzip
    try:
        kernel_config = gzip.decompress(kernel_config)
    except (OSError, EOFError, zlib.error):
        kernel_config = None
        problem("Kernelkonfiguration nicht dekomprimierbar")
if kernel_config is None:
    kernel_config = read("/boot/config-" + kernel, optional=True)
match = re.search(r"^(CONFIG_LAN743X=[ym]|# CONFIG_LAN743X is not set)$", text(kernel_config), re.M)
emit("KERNELCONFIG", match.group(0) if match else "LAN743X-Einstellung nicht verfügbar")

bios = text(read("/sys/class/dmi/id/bios_version", optional=True)).strip()
boot_version_re = re.compile(r"[0-9]+(?:\.[0-9]+){1,3}(?:[-._+][A-Za-z0-9]+)*")
emit("QSPI-VERSION", bios if boot_version_re.fullmatch(bios) else "nicht auswertbar/verfügbar")
slots = text(run("nvbootctrl", "-t", "bootloader", "dump-slots-info"))
for line in slots.splitlines():
    key, separator, value = line.partition(":")
    value = value.strip()
    if key == "Current version" and boot_version_re.fullmatch(value):
        emit("BOOTLOADER", key, value)
    elif key in ("Capsule update status", "num_slots") and re.fullmatch(r"[0-9]{1,3}", value):
        emit("BOOTLOADER", key, value)
    elif key in ("Current bootloader slot", "Active bootloader slot") and value in ("A", "B", "0", "1"):
        emit("BOOTLOADER", key, value)
    elif key == "slot" and re.fullmatch(r"[01],?\s+status:\s*(?:normal|unbootable|invalid)", value):
        emit("BOOTLOADER", key, value)
bootconf = text(read("/boot/extlinux/extlinux.conf", optional=True))
for line in bootconf.splitlines():
    words = line.split("#", 1)[0].split()
    if words and words[0].upper() in ("LINUX", "KERNEL", "INITRD", "FDT", "FDTOVERLAYS", "OVERLAYS"):
        paths = words[1:]
        emit("EXTLINUX-" + words[0].upper(), *[public_path(p) if p.startswith("/boot/") else "lokal prüfen" for p in paths])
emit("BOOT-GRENZE", "Dateihashes/Slotstatus beweisen nicht allein die effektiv gestartete DTB/UEFI-Kombination; keine Bootargs/EFI-Variablen erfasst")
emit("EFI-MOUNTPUNKT", "/boot/efi gemountet" if os.path.ismount("/boot/efi") else "kein Mount an /boot/efi nachgewiesen; Dateistand ist kein ESP-Nachweis")

section("4 PAKETBEZIEHUNGEN, KANDIDATEN UND SKRIPTE")
relation_format = "${binary:Package}\t${Pre-Depends}\t${Depends}\t${Recommends}\t${Breaks}\t${Conflicts}\t${Replaces}\t${Provides}\t${Triggers-Pending}\t${Triggers-Awaited}\n"
for package in sorted(selected):
    record = packages.get(package)
    if record:
        version, arch, state = record
        emit("PAKET", package, version, arch, state, "hold" if package in holds else "kein hold")
    policy = text(run("apt-cache", *APT, "policy", package))
    policy_fields = set()
    for line in policy.splitlines():
        match = re.fullmatch(r"\s*(Installed|Candidate):\s*(\S+)\s*", line)
        if match and (version_re.fullmatch(match.group(2)) or match.group(2) == "(none)"):
            emit("APT-" + match.group(1), package, match.group(2))
            policy_fields.add(match.group(1))
            continue
        match = re.fullmatch(r"\s*(?:\*\*\*\s+)?([0-9][A-Za-z0-9.+:~_-]*)\s+(-?\d+)\s*", line)
        if match:
            emit("APT-VERSION", package, match.group(1), "Priorität=" + match.group(2))
    if policy_fields != {"Installed", "Candidate"}:
        problem("APT-Installed/Candidate nicht vollständig auswertbar")
        emit("APT-OFFEN", package)
    if package not in detail:
        continue
    relations = text(run("dpkg-query", "-W", "-f=" + relation_format, package)).strip("\n").split("\t")
    if len(relations) == 10:
        for name, value in zip(("Paket", "Pre-Depends", "Depends", "Recommends", "Breaks", "Conflicts", "Replaces", "Provides", "Triggers-Pending", "Triggers-Awaited"), relations):
            if value:
                if len(value) <= 8192 and re.fullmatch(r"[A-Za-z0-9_+.:~(),|<>= /\[\]!-]+", value):
                    emit(name, package, value)
                else:
                    problem("Paketbeziehung mit ungeprüftem Format ausgelassen")
    else:
        problem("Paketbeziehungen nicht auswertbar")
    controls = text(run("dpkg-query", "--control-list", package)).splitlines()
    for control in ("preinst", "postinst", "prerm", "postrm", "triggers"):
        if control not in controls:
            continue
        data = run("dpkg-query", "--control-show", package, control)
        if data is not None:
            markers = sorted(set(re.findall(r"depmod|update-initramfs|mkinitramfs|update-grub|flash-kernel|dpkg-trigger|nv_update_engine|nv_bootloader_payload_updater|/boot|/lib/modules|/etc/kernel|/usr/lib/linux/triggers", text(data))))
            emit("CONTROL", package, control, hashlib.sha256(data).hexdigest(), ",".join(markers) or "keine Stichworttreffer")
emit("SKRIPT-GRENZE", "Nur installierte Control-Dateien; kein Volltext, keine Ausführung. Stichwörter können Kommentare sein. Kandidatenskripte und Aufrufketten bleiben gesondert zu prüfen.")

section("5 AUTOMATISCHE AKTUALISIERUNGEN")
units = ("apt-daily.timer", "apt-daily-upgrade.timer", "apt-daily.service", "apt-daily-upgrade.service",
         "unattended-upgrades.service", "cron.service", "anacron.service", "anacron.timer",
         "packagekit.service", "snapd.service", "snapd.socket", "fwupd.service", "fwupd-refresh.timer")
raw = text(run("systemctl", "show", "--no-pager", "-p", "Id", "-p", "LoadState", "-p", "ActiveState",
               "-p", "SubState", "-p", "UnitFileState", *units, allowed=(0, 1)))
unit_count = 0
for block in raw.split("\n\n"):
    values = dict(line.split("=", 1) for line in block.splitlines() if "=" in line)
    if values.get("Id") in units:
        unit_count += 1
        emit("UNIT", values["Id"], *[values.get(k, "?") if re.fullmatch(r"[a-z-]*", values.get(k, "")) else "ungeprüft" for k in ("LoadState", "ActiveState", "SubState", "UnitFileState")])
if unit_count != len(units):
    problem("Nicht alle bekannten Update-Unitzustände erfasst")
flags = apt_config(("PERIODIC", "APT::Periodic::Enable/i"), ("LISTEN", "APT::Periodic::Update-Package-Lists/i"),
                   ("DOWNLOAD", "APT::Periodic::Download-Upgradeable-Packages/i"),
                   ("UNATTENDED", "APT::Periodic::Unattended-Upgrade/i"),
                   ("AUTOREBOOT", "Unattended-Upgrade::Automatic-Reboot/b"))
for key in ("PERIODIC", "LISTEN", "DOWNLOAD", "UNATTENDED", "AUTOREBOOT"):
    value = flags.get(key, "nicht gesetzt")
    emit("APT-SCHALTER", key, value if re.fullmatch(r"\d+|true|false|nicht gesetzt", value) else "ungeprüftes Format")
updater_pattern = re.compile(r"apt-get|unattended|fwupdmgr|nv_update_engine|dpkg\s|apt\s|Pre-Invoke|Post-Invoke")
updater_links = 0
for root in ("/etc/cron.d", "/etc/cron.daily", "/etc/cron.weekly", "/etc/cron.monthly",
             "/var/spool/cron/crontabs", "/etc/apt/apt.conf.d", "/etc/systemd/system"):
    if not os.path.isdir(root):
        continue
    for parent, directories, names in os.walk(root, followlinks=False, onerror=walk_error):
        directories[:] = [d for d in directories if not os.path.islink(os.path.join(parent, d))]
        for name in sorted(names):
            path = os.path.join(parent, name)
            if os.path.islink(path):
                updater_links += 1
                continue
            data = read(path, optional=True)
            if data is not None and updater_pattern.search(text(data)):
                # Nur Systempfad, kein Job-/Hooktext, keine Argumente oder Umgebungswerte.
                emit("UPDATE-HINWEIS", public_path(path), "statisch lokal prüfen")
for path in ("/etc/crontab", "/etc/anacrontab"):
    data = read(path, optional=True)
    if data and updater_pattern.search(text(data)):
        emit("UPDATE-HINWEIS", path, "statisch lokal prüfen")
emit("UPDATE-VERWEISE", updater_links, "Dateisymlinks bewusst nicht verfolgt; eigene Verweise bleiben lokal zu prüfen")
emit("UPDATE-GRENZE", "Timerzustände/Stichwörter sind kein vollständiger Ausschluss anderer Updatewege; Origins, Pins und eigene Hooks bleiben zu prüfen")
status_after = read("/var/lib/dpkg/status")
emit("DPKG-MOMENTAUFNAHME", "unverändert" if status_before is not None and status_before == status_after else "INSTABIL/UNVOLLSTÄNDIG")
if status_before is None or status_before != status_after:
    problem("Paketdatenbank änderte sich während der Erfassung")
if "LISTS" in cfg and cache_before != cache_stamp(cfg["LISTS"]):
    problem("APT-Listen änderten sich während der Erfassung")
emit("ERGEBNIS", "vollständig ausgeführt" if not problems else "unvollständig", "Fehlerarten=" + str(len(problems)))
sys.exit(1 if problems else 0)
'''

def main():
    if os.getuid() == 0 or os.getuid() != os.geteuid():
        print("Normalbenutzer erforderlich.", file=sys.stderr)
        return 2
    label = sys.argv[1]
    if label not in ("AI7020-8", "AI7100-3"):
        return 2
    home = os.path.realpath(pwd.getpwuid(os.getuid()).pw_dir)
    filename = "b1_inventory_" + label + "_" + datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "_" + secrets.token_hex(4) + ".txt"
    old_umask = os.umask(0o077)
    try:
        directory = os.open(home, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        try:
            fd = os.open(filename, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600, dir_fd=directory)
        finally:
            os.close(directory)
    except OSError:
        print("Protokoll im tatsächlichen Benutzer-Home nicht anlegbar; keine Abfragen gestartet.", file=sys.stderr)
        return 2
    finally:
        os.umask(old_umask)
    path = os.path.join(home, filename)
    env = {"PATH": "/usr/sbin:/usr/bin:/sbin:/bin", "LC_ALL": "C", "LANG": "C", "TZ": "UTC"}
    header_problem = False
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as report:
            report.write("B1 INVENTAR – Format 1\nGerätelabel: " + label + " (vom Aufrufer, kein Modellnachweis)\n")
            report.write("UTC: " + datetime.datetime.now(datetime.timezone.utc).isoformat() + "\n")
            try:
                with open(sys.argv[2], "rb") as source:
                    report.write("Skript-SHA256: " + hashlib.sha256(source.read()).hexdigest() + "\n")
            except OSError:
                report.write("OFFEN: Skriptprüfsumme nicht lesbar\n")
                header_problem = True
            report.write("Nur Leseabfragen; geschrieben wird ausschließlich dieses neue Benutzerprotokoll.\n")
            report.flush()
            command = ["/usr/bin/python3", "-I", "-B", "-c", COLLECTOR]
            privileged = False
            if os.path.isfile("/usr/bin/sudo"):
                print("B1: sudo wird ausschließlich für Leseabfragen benötigt.", flush=True)
                try:
                    # sudo liest das Passwort vom TTY; weder Dialogdaten noch rohe Fehler ins Log übernehmen.
                    privileged = subprocess.run(["/usr/bin/sudo", "-p", "B1: sudo-Passwort: ", "-v"],
                                                env=env, stdin=subprocess.DEVNULL,
                                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                                check=False).returncode == 0
                except OSError:
                    privileged = False
            if privileged:
                command = ["/usr/bin/sudo", "-n", "--", *command]
            else:
                report.write("OFFEN: sudo fehlt oder Authentifizierung fehlgeschlagen; Erfassung ohne erhöhte Leserechte.\n")
            print("B1 erfasst den Bestand. Protokoll: " + path, flush=True)
            result = subprocess.run(command, env=env, stdin=subprocess.DEVNULL, stdout=report,
                                    stderr=subprocess.DEVNULL, check=False)
            code = 0 if result.returncode == 0 and privileged and not header_problem else 1
            report.write("\nENDE: " + ("OK" if code == 0 else "UNVOLLSTÄNDIG – OFFEN-Meldungen prüfen") + "\n")
            report.flush()
            os.fsync(report.fileno())
        print("B1 abgeschlossen. Exit " + str(code) + "; Protokoll: " + path)
        return code
    except KeyboardInterrupt:
        print("B1 abgebrochen; vorhandenes Teilprotokoll: " + path, file=sys.stderr)
        return 130
    except (OSError, ValueError):
        print("Protokoll-/Abfragefehler; vorhandenes Teilprotokoll: " + path, file=sys.stderr)
        return 1

try:
    sys.exit(main())
except Exception:
    # Keine möglicherweise sensiblen Exception-Inhalte oder Tracebacks ausgeben.
    print("B1 konnte nicht abgeschlossen werden; keine rohe Fehlerausgabe protokolliert.", file=sys.stderr)
    sys.exit(1)
PYTHON
