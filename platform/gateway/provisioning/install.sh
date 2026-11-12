#!/usr/bin/env bash
set -u
export LC_ALL=C

usage() {
    printf 'Aufruf: %s labor | bsp-plan PAKET... | bsp-holds | c1-install | c1-status\n' "$0"
    printf 'labor: Bestandsaufnahme, Projektverzeichnisse und Node-RED für den SSH-Tunnel.\n'
    printf 'bsp-plan: nur APT-Simulation, keine Installationsfreigabe. bsp-holds: noch gesperrt.\n'
    printf 'C1: beide Bestandsprofile per MAC binden, Originale sichern; c1-status prüft nur lesend.\n'
}

if [[ $# == 1 && ( $1 == --help || $1 == -h ) ]]; then
    usage
    exit 0
fi
if ! { [[ $# == 1 && ( $1 == labor || $1 == bsp-holds || $1 == c1-install || $1 == c1-status ) ]] ||
       [[ $# -ge 2 && $1 == bsp-plan ]]; }; then
    usage >&2
    exit 2
fi
if [[ $(uname -s) != Linux ]]; then
    printf 'PROBLEM  Die Bestandsaufnahme benötigt Linux.\n' >&2
    exit 1
fi

declare -A count=([OK]=0 [FEHLT]=0 [OFFEN]=0 [PROBLEM]=0)
report() {
    printf '%-8s %s\n' "$1" "$2"
    ((count[$1] += 1))
}

os_field() {
    awk -v key="$1" 'index($0, key "=") == 1 {
        value = substr($0, length(key) + 2)
        gsub(/^"|"$/, "", value)
        print value
        exit
    }' /etc/os-release 2>/dev/null
}

dt_value() {
    if [[ -r $1 ]]; then
        tr '\000' ' ' < "$1"
    fi
}

package_version() {
    local record
    record=$(dpkg-query -W -f='${db:Status-Status} ${Version}' -- "$1" 2>/dev/null) || return "$?"
    [[ $record == installed\ * ]] || return 1
    printf '%s\n' "${record#installed }"
}

# B2: Vorschlag aus B1, keine automatische Aktivierung im Laborprofil.
readonly BSP_HOLDS_APPROVED=yes
readonly -a BSP_PACKAGES=(
    nvidia-l4t-kernel nvidia-l4t-kernel-dtbs nvidia-l4t-kernel-oot-modules
    nvidia-l4t-display-kernel nvidia-l4t-initrd nvidia-l4t-bootloader
    nvidia-l4t-core nvidia-l4t-tools nvidia-l4t-init nvidia-l4t-configs
    nvidia-l4t-firmware nvidia-l4t-xusb-firmware nvidia-l4t-apt-source
    nvidia-l4t-kernel-headers nvidia-l4t-kernel-oot-headers)

bsp_check_baseline() {
    local package expected version audit
    if [[ $EUID != 0 || $(os_field ID) != ubuntu || $(os_field VERSION_ID) != 22.04 ||
          $(uname -m) != aarch64 || $(uname -r) != 5.15.148-tegra ]] ||
       ! grep -qE '^# R36 .*REVISION: 4\.0,' /etc/nv_tegra_release 2>/dev/null; then
        printf 'B2 blockiert: root und die bekannte Ubuntu-/ARM64-/R36.4.0-Basis erforderlich.\n' >&2
        return 1
    fi
    if ! audit=$(dpkg --audit 2>/dev/null) || [[ -n $audit ]]; then
        printf 'B2 blockiert: dpkg-Zustand nicht eindeutig sauber; keine automatische Reparatur.\n' >&2
        return 1
    fi
    for package in "${BSP_PACKAGES[@]}"; do
        expected=36.4.0-20240912212859
        case $package in
            nvidia-l4t-kernel|nvidia-l4t-kernel-*|nvidia-l4t-display-kernel)
                expected=5.15.148-tegra-$expected ;;
        esac
        version=$(package_version "$package") || version=''
        if [[ $version != "$expected" ]]; then
            printf 'B2 blockiert: fehlender oder abweichender Paketstand bei %s.\n' "$package" >&2
            return 1
        fi
    done
}

# Nur lesen. -c wird innerhalb dieses root-Prozesses erzeugt, nicht über sudo-FDs.
bsp_simulate_install() (
    local package policy plan candidate
    (( $# > 0 )) || return 2
    bsp_check_baseline || return 1
    command -v python3 >/dev/null && command -v timeout >/dev/null &&
        command -v apt-get >/dev/null && command -v apt-cache >/dev/null || {
        printf 'B2 blockiert: erforderliches Python-/APT-/timeout-Programm fehlt.\n' >&2; return 1;
    }
    for package in "$@"; do
        # Keine Optionen, lokalen DEBs, Regex-/Globauswahl oder APT-Aktionssuffixe.
        if [[ ! $package =~ ^[a-z0-9][a-z0-9+.-]+$ || $package == *[-+] || $package == *.deb ]]; then
            printf 'B2 blockiert: nur exakte Binärpaketnamen ohne Zusatzsyntax erlaubt.\n' >&2
            return 2
        fi
        case $package in nvidia-l4t*|nvidia-jetpack*)
            printf 'B2 blockiert: NVIDIA-BSP-Paket als Installationsziel.\n' >&2; return 1 ;;
        esac
        if ! policy=$(env -u APT_CONFIG timeout 30s apt-cache -o Dir::Cache::pkgcache= \
                -o Dir::Cache::srcpkgcache= policy -- "$package" 2>/dev/null); then
            printf 'B2 blockiert: lokale APT-Kandidatenabfrage fehlgeschlagen.\n' >&2
            return 1
        fi
        candidate=$(awk '$1 == "Candidate:" {print $2}' <<< "$policy")
        if [[ ${policy%%$'\n'*} != "$package:" ||
              ! $candidate =~ ^[a-zA-Z0-9.+:~_-]+$ ]]; then
            printf 'B2 blockiert: exaktes Paket oder eindeutiger lokaler Kandidat fehlt.\n' >&2
            return 1
        fi
    done
    # #clear statt leerem -o: leere Werte entfernen bestehende Hooklisten nicht.
    # Pins/Quellen bleiben wirksam; keine Netzabfrage, kein persistenter Binärcache.
    if ! plan=$(env -u APT_CONFIG timeout 120s apt-get -c <(printf '%s\n' \
            '#clear APT::Install;' '#clear AptCli::Hooks;' '#clear DPkg::Pre-Invoke;' \
            '#clear DPkg::Post-Invoke;' '#clear DPkg::Pre-Install-Pkgs;') \
            --simulate --no-remove --no-upgrade --no-install-recommends \
            -o APT::Ignore-Hold=false -o APT::Get::allow-change-held-packages=false \
            -o APT::Get::allow-downgrades=false -o APT::Get::force-yes=false \
            -o APT::Get::AutomaticRemove=false -o APT::Get::Fix-Broken=false \
            -o APT::Get::ReInstall=false -o APT::Get::Print-URIs=false \
            -o APT::Install-Suggests=false \
            -o Dir::Cache::pkgcache= -o Dir::Cache::srcpkgcache= \
            install -- "$@" 2>/dev/null); then
        printf 'B2 blockiert: APT-Simulation fehlgeschlagen oder Zeitlimit erreicht.\n' >&2
        return 1
    fi
    # Nur bereinigte Aktionsnamen ausgeben; keine Quellen-/Hook-/Fehlerrohdaten.
    printf '%s\n' "$plan" | python3 -I -B -c '
import re, sys
lines = sys.stdin.read().splitlines()
inst, conf, counts = {}, set(), None
name = r"[a-z0-9][a-z0-9+.-]*(?::[a-z0-9-]+)?"
version = r"[A-Za-z0-9.+:~_-]+"
danger = re.compile(r"^(?:nvidia-l4t|nvidia-jetpack|linux-|initramfs-tools|grub|shim|u-boot|fwupd|dkms|systemd|udev)|^(?:kmod|busybox-initramfs|klibc-utils|flash-kernel|keyboard-configuration|dmsetup|ntfs-3g|plymouth|fuse3|kbd|isc-dhcp-client)$")
def stop(message):
    print("B2 blockiert: " + message, file=sys.stderr)
    sys.exit(1)
for line in lines:
    line = line.strip()
    summary = re.fullmatch(r"(\d+) upgraded, (\d+) newly installed, (\d+) to remove and (\d+) not upgraded\.", line)
    if summary:
        if counts is not None: stop("mehrdeutige APT-Zusammenfassung")
        counts = tuple(map(int, summary.groups()))
        continue
    if re.match(r"\d+ not fully installed or removed", line):
        stop("unvollständiger dpkg-Zustand")
    if not re.match(r"(?:Inst|Conf|Remv|Purg)(?:\s|$)", line):
        continue
    action = re.fullmatch(r"(Inst|Conf|Remv|Purg) (" + name + r") (.+)", line)
    if not action: stop("unbekanntes APT-Aktionsformat")
    op, package, rest = action.groups()
    if danger.search(package.split(":")[0]): stop("BSP-/Boot-/Regenerationspaket " + package)
    if op in ("Remv", "Purg"): stop("Entfernung oder Purge im Plan")
    pattern = r"(?:\[(" + version + r")\] )?\((" + version + r")(?: [^\r\n]*)?\)"
    values = re.fullmatch(pattern, rest)
    if not values: stop("unbekanntes APT-Versionsformat")
    old, new = values.groups()
    if op == "Inst":
        if package in inst: stop("doppelte Installation im Plan")
        inst[package] = (old, new)
    else:
        if package in conf or package not in inst or inst[package][1] != new:
            stop("ungeklärte Konfiguration oder anhängiger Trigger")
        conf.add(package)
if counts is None or counts[2] != 0 or conf != set(inst):
    stop("APT-Plan unvollständig oder nicht auswertbar")
if (sum(old is not None for old, new in inst.values()), sum(old is None for old, new in inst.values())) != counts[:2]:
    stop("APT-Zählung passt nicht zu den Aktionen")
for package, (old, new) in inst.items():
    print("PLAN", package, "Änderung" if old else "Neuinstallation", new)
print("Simulation strukturell geprüft; KEINE Installationsfreigabe.")
print("Kandidatenskripte, Trigger, Quellen/Pins und Paralleländerungen bleiben vor realen Transaktionen zu klären.")
'
)

bsp_activate_holds() (
    local before after package
    local -a missing=()
    # Absichtlich keine Freigabe per Umgebungsvariable oder normalem Laborlauf.
    if [[ $BSP_HOLDS_APPROVED != yes ]]; then
        printf 'B2-Holds nicht freigegeben. Keine Paketmarkierung geändert.\n' >&2
        return 2
    fi
    bsp_check_baseline || return 1
    before=$(env -u APT_CONFIG apt-mark showhold 2>/dev/null) || return 1
    for package in "${BSP_PACKAGES[@]}"; do
        if ! grep -qxF -e "$package" -e "$package:arm64" <<< "$before"; then
            missing+=("$package")
        fi
    done
    if (( ${#missing[@]} )); then
        if ! env -u APT_CONFIG apt-mark hold -- "${missing[@]}" >/dev/null 2>&1; then
            printf 'B2-Hold-Schritt fehlgeschlagen; mögliche Teilmarkierungen prüfen, kein automatisches unhold.\n' >&2
            return 1
        fi
    fi
    after=$(env -u APT_CONFIG apt-mark showhold 2>/dev/null) || return 1
    while IFS= read -r package; do
        [[ -z $package ]] || grep -qxF -- "$package" <<< "$after" || {
            printf 'B2: vorhandener Hold nach Prüfung nicht bestätigt.\n' >&2; return 1;
        }
    done <<< "$before"
    for package in "${BSP_PACKAGES[@]}"; do
        grep -qxF -e "$package" -e "$package:arm64" <<< "$after" || return 1
    done
    printf 'B2: alle 15 vorgeschlagenen Holds bestätigt, frühere Holds erhalten.\n'
)
# Ende B2. Keine dieser Funktionen wird durch labor aufgerufen.

check_project_directory() {
    local path=$1 owner=$2 actual
    if [[ -L $path ]]; then
        printf 'Konflikt: %s ist ein symbolischer Link.\n' "$path" >&2
        return 1
    fi
    if [[ ! -e $path ]]; then
        return 0
    fi
    if [[ ! -d $path ]]; then
        printf 'Konflikt: %s ist kein Verzeichnis.\n' "$path" >&2
        return 1
    fi
    if ! actual=$(stat -c '%u:%g' -- "$path") || [[ $actual != "$owner" ]]; then
        printf 'Konflikt: %s hat UID:GID %s. Erwartet wird %s.\n' \
            "$path" "${actual:-unbekannt}" "$owner" >&2
        return 1
    fi
    if [[ ! -r $path || ! -w $path || ! -x $path ]]; then
        printf 'Konflikt: Dem Projektbenutzer fehlt Lese-, Schreib- oder Suchzugriff auf %s.\n' "$path" >&2
        return 1
    fi
}

create_project_directories() (
    local home=$1 uid=$2 gid=$3 base path parent relative attributes error
    local -a directories=(friedrich-projects friedrich-projects/workspace
        friedrich-projects/workspace/project friedrich-projects/workspace/nodered
        friedrich-projects/workspace/nodered/projects friedrich-projects/nodered_runtime)

    if [[ $EUID != "$uid" || $(id -g) != "$gid" ]]; then
        printf 'Verzeichnisanlage benötigt die UID %s und die primäre GID %s des Projektkontos.\n' "$uid" "$gid" >&2
        return 1
    fi
    if [[ ${home%/} == '' || -L ${home%/} ]] || ! cd -P -- "$home" || [[ $PWD == / ]]; then
        printf 'Projekt-Home ist kein zugängliches reguläres Verzeichnis: %s\n' "$home" >&2
        return 1
    fi
    base=$PWD

    # Den gesamten Baum prüfen, bevor ein Verzeichnis angelegt wird.
    for relative in "${directories[@]}"; do
        path="$base/$relative"
        check_project_directory "$path" "$uid:$gid" || return 1
        parent=${path%/*}
        if [[ ! -e $path && -d $parent && ( -g $parent || ! -w $parent ) ]]; then
            printf 'Anlage von %s blockiert: Elternverzeichnis %s hat setgid oder ist nicht schreibbar.\n' \
                "$path" "$parent" >&2
            return 1
        fi
    done

    for relative in "${directories[@]}"; do
        path="$base/$relative"
        check_project_directory "$path" "$uid:$gid" || return 1
        if [[ -d $path ]]; then
            printf '         Vorhanden %s\n' "$path"
            continue
        fi
        parent=${path%/*}
        # Den physischen Elternpfad prüfen und nur das einzelne Kind anlegen.
        if ! error=$(cd -P -- "$parent" 2>&1 && [[ $PWD == "$parent" && ! -g . ]] &&
            mkdir -m 0750 -- "${path##*/}" 2>&1); then
            printf 'Anlage von %s fehlgeschlagen. %s\n' "$path" "${error:-Elternpfad oder Rechte prüfen.}" >&2
            return 1
        fi
        check_project_directory "$path" "$uid:$gid" || return 1
        if ! attributes=$(stat -c '%u:%g:%a' -- "$path") || [[ $attributes != "$uid:$gid:750" ]]; then
            printf 'Anlage von %s ergab %s. Erwartet wird UID:GID:Modus %s:%s:750.\n' \
                "$path" "${attributes:-unbekannt}" "$uid" "$gid" >&2
            return 1
        fi
        printf '         Angelegt %s\n' "$path"
    done
)

# Ausschließlich den lokalen, bereits gestarteten Docker-Dienst verwenden.
docker_local() {
    env -u DOCKER_HOST -u DOCKER_CONTEXT -u DOCKER_TLS_VERIFY -u DOCKER_CERT_PATH \
        timeout 120s docker --host unix:///var/run/docker.sock "$@"
}

as_project_user() {
    if (( EUID == 0 )); then
        env -u BASH_ENV -u ENV setpriv --reuid="$uid" --regid="$gid" --init-groups --no-new-privs -- "$@"
    else
        "$@"
    fi
}

prepare_nodered_mounts() {
    local runtime=$1 projects=$2 owner=$3 container=$4 entry
    local -a mount_entries runtime_entries project_entries
    check_project_directory "$runtime" "$owner" || return 1
    check_project_directory "$projects" "$owner" || return 1
    check_project_directory "$runtime/projects" "$owner" || return 1
    shopt -s nullglob dotglob
    mount_entries=("$runtime/projects/"*)
    if (( ${#mount_entries[@]} != 0 )); then
        printf 'Der Runtime-Mountpunkt projects enthält Daten. Abbruch.\n' >&2
        return 1
    fi
    if [[ -z $container ]]; then
        runtime_entries=("$runtime/"*)
        project_entries=("$projects/"*)
        for entry in "${runtime_entries[@]}"; do
            if [[ $entry != "$runtime/projects" ]]; then
                printf 'Runtime ist nicht leer; automatische Übernahme unterbleibt.\n' >&2
                return 1
            fi
        done
        if (( ${#project_entries[@]} != 0 )); then
            printf 'Projektverzeichnis ist nicht leer; automatische Übernahme unterbleibt.\n' >&2
            return 1
        fi
    fi
    if [[ ! -d $runtime/projects ]]; then
        if [[ -g $runtime ]]; then
            printf 'Mountpunktanlage blockiert: Runtime-Verzeichnis hat setgid.\n' >&2
            return 1
        fi
        mkdir -m 0750 -- "$runtime/projects" || return 1
        if [[ $(stat -c '%u:%g:%a' -- "$runtime/projects") != "$owner:750" ]]; then
            printf 'Der neue Runtime-Mountpunkt hat unerwartete Eigentümer oder Rechte.\n' >&2
            return 1
        fi
    fi
    check_project_directory "$runtime/projects" "$owner"
}

install_nodered() (
    local image='ghcr.io/node-red/node-red:5.0.9-debian@sha256:260face7ad06c0968dd130717d1f08fa1d9985e6ff20e26d66f366b9d27bc22a'
    local base runtime projects server ids snapshot container state attempt expected_start actual_start
    local -a container_ids=()
    if (( count[PROBLEM] > 0 )); then
        printf 'Node-RED wartet auf die Klärung der Vorprüfung.\n' >&2
        return 1
    fi
    # Das offizielle Image enthält für Projects/SSH einen passwd-Eintrag für UID 1000.
    if [[ $uid != 1000 ]]; then
        printf 'Node-RED benötigt hier Projekt-UID 1000. UID %s erfordert eine gesonderte Image-Anpassung.\n' "$uid" >&2
        return 1
    fi
    command -v python3 >/dev/null || { printf 'Für die sichere Docker-Bestandsprüfung fehlt python3.\n' >&2; return 1; }
    if [[ $(systemctl show --property=ActiveState --value docker.service 2>/dev/null) != active ||
          $(systemctl is-enabled docker.service 2>/dev/null) != enabled ]]; then
        printf 'Docker muss bereits aktiv und für den Systemstart aktiviert sein. Keine Dienständerung vorgenommen.\n' >&2
        return 1
    fi
    server=$(docker_local version --format '{{.Server.Version}}') || return 1
    if [[ ! $server =~ ^([0-9]+)\. || ${BASH_REMATCH[1]} -lt 28 ]]; then
        printf 'Docker-Server %s: sichere Loopback-Portfreigabe setzt mindestens Version 28 voraus.\n' "$server" >&2
        return 1
    fi
    base=$(cd -P -- "$home" && printf '%s/friedrich-projects' "$PWD") || return 1
    runtime="$base/nodered_runtime"
    projects="$base/workspace/nodered/projects"
    # Docker --mount verwendet Kommas als Trennzeichen.
    if [[ $base == *,* || $base == *$'\n'* ]]; then
        printf 'Der Projektpfad enthält ein für Docker --mount ungeeignetes Zeichen.\n' >&2
        return 1
    fi
    ids=$(docker_local container ls -aq --no-trunc) || return 1
    snapshot='[]'
    if [[ -n $ids ]]; then
        mapfile -t container_ids <<< "$ids"
        snapshot=$(docker_local container inspect "${container_ids[@]}") || return 1
    fi
    # JSON strukturiert prüfen; keine vollständigen Inspect-Daten protokollieren.
    container=$(python3 -c '
import json, os, sys
runtime, projects, image, user = sys.argv[1:]
def conflict(message):
    sys.exit("Node-RED-Konflikt: " + message + ". Bestand bleibt erhalten.")
def overlaps(a, b):
    return os.path.commonpath([os.path.realpath(a), b]) in (os.path.realpath(a), b)
selected = None
for c in json.load(sys.stdin):
    config, host = c["Config"], c["HostConfig"]
    name = c["Name"].lstrip("/")
    mounts = c.get("Mounts", [])
    if name != "mynodered":
        shared = any(m.get("Type") == "bind" and
                     any(overlaps(m["Source"], p) for p in (runtime, projects)) for m in mounts)
        if shared or name in ("nodered", "node-red") or "node-red" in config.get("Image", ""):
            conflict("anderer Node-RED-Container oder gemeinsam verwendete Daten (" + name + ")")
        continue
    expected = {"/data": runtime, "/data/projects": projects}
    if len(mounts) != 2 or {m.get("Destination") for m in mounts} != set(expected) or any(m.get("Type") != "bind" or not m.get("RW") or
        expected.get(m.get("Destination")) != m.get("Source") for m in mounts):
        conflict("Bind-Mounts weichen ab")
    env = dict(e.split("=", 1) for e in config.get("Env", []) if "=" in e)
    if (config.get("Image") != image or config.get("User") != user or
        (config.get("Labels") or {}).get("com.friedrich-automation.installer") != "nodered-labor-v1" or
        env.get("HOME") != "/data" or env.get("NODE_RED_ENABLE_PROJECTS") != "true" or
        host.get("RestartPolicy", {}).get("Name") != "unless-stopped" or
        host.get("NetworkMode") != "bridge" or set(c.get("NetworkSettings", {}).get("Networks", {})) != {"bridge"} or
        host.get("Privileged") or host.get("PublishAllPorts") or
        host.get("PortBindings") != {"1880/tcp": [{"HostIp": "127.0.0.1", "HostPort": "1880"}]}):
        conflict("Image, Benutzer, Kennzeichnung, Umgebung, Neustartregel oder Portbindung weichen ab")
    if c["State"]["Status"] not in ("created", "exited", "running") or c["State"].get("Paused"):
        conflict("Containerzustand erlaubt keinen sicheren Start")
    selected = c["Id"]
print(selected or "")
' "$runtime" "$projects" "$image" "$uid:$gid" <<< "$snapshot") || return 1
    if [[ -n $container ]]; then
        # Docker 29 lässt leere optionale Config-Felder bei Image-Inspect weg.
        expected_start=$(docker_local image inspect --format '{{.Id}}|{{json .Config}}' "$image") || return 1
        actual_start=$(docker_local container inspect --format '{{.Image}}|{{json .Config}}' "$container") || return 1
        python3 -c '
import json, sys
def startup(record):
    identity, raw = record.split("|", 1)
    config = json.loads(raw)
    if not identity or not isinstance(config, dict):
        raise ValueError("Unvollständige Docker-Metadaten")
    for field in ("Entrypoint", "Cmd"):
        value = config.get(field)
        if value is not None and (not isinstance(value, list) or
                                  any(not isinstance(item, str) for item in value)):
            raise ValueError("Ungültiger Startbefehl")
    if config.get("WorkingDir") is not None and not isinstance(config["WorkingDir"], str):
        raise ValueError("Ungültiges Arbeitsverzeichnis")
    return (identity, config.get("Entrypoint") or [], config.get("Cmd") or [],
            config.get("WorkingDir") or "")
try:
    expected, actual = sys.stdin.read().splitlines()
    matches = startup(expected) == startup(actual)
except (ValueError, TypeError):
    sys.exit("Node-RED-Bestandsprüfung: Docker-Metadaten sind nicht auswertbar. Bestand bleibt erhalten.")
if not matches:
    sys.exit("Node-RED-Konflikt: Image-ID oder Startbefehl weichen ab. Bestand bleibt erhalten.")
' <<< "$expected_start"$'\n'"$actual_start" || return 1
    fi

    # Als Projektkonto prüfen; auch versteckte Dateien zählen als Bestand.
    # Ein leerer projects-Unterordner dient ausschließlich als Mountpunkt.
    as_project_user "$BASH" --noprofile --norc -u -c "$(declare -f check_project_directory prepare_nodered_mounts)
prepare_nodered_mounts \"\$@\"" bash "$runtime" "$projects" "$uid:$gid" "$container" || return 1

    printf '         Node-RED 5.0.9, ARM64, Benutzer %s:%s, Docker-Server %s\n' "$uid" "$gid" "$server"
    printf '         Runtime %s -> /data\n         Projekte %s -> /data/projects\n' "$runtime" "$projects"
    if [[ -z $container ]]; then
        printf '         Lade das festgelegte Image.\n'
        docker_local pull --platform linux/arm64 "$image" || return 1
        container=$(docker_local container create --name mynodered --platform linux/arm64 \
            --label com.friedrich-automation.installer=nodered-labor-v1 \
            --user "$uid:$gid" --env HOME=/data --env NODE_RED_ENABLE_PROJECTS=true \
            --network bridge --publish 127.0.0.1:1880:1880 --restart unless-stopped \
            --mount "type=bind,src=$runtime,dst=/data" \
            --mount "type=bind,src=$projects,dst=/data/projects" "$image") || return 1
        printf '         Container angelegt.\n'
    else
        printf '         Passender Container vorhanden; Daten und Konfiguration bleiben erhalten.\n'
    fi
    state=$(docker_local container inspect --format '{{.State.Status}}' "$container") || return 1
    if [[ $state != running ]]; then
        printf '         Starte Node-RED.\n'
        docker_local container start "$container" >/dev/null || return 1
    fi
    # Den tatsächlichen Host-Port prüfen, der auch das Ziel des SSH-Tunnels ist.
    for ((attempt=1; attempt<=30; attempt++)); do
        state=$(docker_local container inspect --format '{{.State.Status}}' "$container") || return 1
        if [[ $state == running ]] && python3 -c '
import sys, urllib.request
try:
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open("http://127.0.0.1:1880/", timeout=3) as response:
        sys.exit(0 if response.status == 200 else 1)
except Exception:
    sys.exit(1)' >/dev/null 2>&1; then
            printf '         Editor antwortet über HTTP. Zugang: SSH-Tunnel nach 127.0.0.1:1880.\n'
            return 0
        fi
        sleep 2
    done
    printf 'Node-RED-Editor antwortet nicht innerhalb der begrenzten Startprüfung.\n' >&2
    printf 'Diagnose am Gateway: sudo docker logs --tail 30 %s\n' "$container" >&2
    return 1
)

# Erst nach erfolgreicher Aktivierung UND Neustartabnahme beider Gateways freigeben.
readonly C1_IN_LAB_APPROVED=no
c1_run() (
    local script_dir
    script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || return 1
    /usr/bin/python3 -I -B "$script_dir/c1_network.py" "$@"
)

case $1 in
    bsp-plan) shift; bsp_simulate_install "$@"; exit $? ;;
    bsp-holds) bsp_activate_holds; exit $? ;;
    c1-install) c1_run install; exit $? ;;
    c1-status) c1_run status; exit $? ;;
esac

if [[ $C1_IN_LAB_APPROVED == yes ]]; then
    c1_run install || exit $?
fi

printf 'Friedrich Automation – Labor-Installer\n\nSystem und BSP\n'
os_id=$(os_field ID)
os_version=$(os_field VERSION_ID)
arch=$(uname -m)
kernel=$(uname -r)
printf '         Betriebssystem %s %s, Architektur %s, Kernel %s\n' \
    "${os_id:-unbekannt}" "${os_version:-unbekannt}" "${arch:-unbekannt}" "${kernel:-unbekannt}"
if [[ $os_id == ubuntu && $os_version == 22.04 && $arch == aarch64 ]]; then
    report OK 'Ubuntu 22.04 auf ARM64 entspricht der Laborbasis.'
else
    report PROBLEM 'Erwartet wird Ubuntu 22.04 auf ARM64.'
fi
if [[ -z $kernel || ! -d /lib/modules/$kernel ]]; then
    report PROBLEM 'Zum laufenden Kernel wurde kein Modulverzeichnis gefunden.'
fi

model=$(dt_value /proc/device-tree/model)
compatible=$(dt_value /proc/device-tree/compatible)
printf '         Device Tree: %s\n' "${model:-unbekannt}"
identity="${model,,} ${compatible,,}"
ai7020='(^|[^[:alnum:]])ai7020([^[:alnum:]]|$)'
ai7100='(^|[^[:alnum:]])ai7100([^[:alnum:]]|$)'
nano='p3767-000[345]([^[:alnum:]]|$)'
nx='p3767-000[01]([^[:alnum:]]|$)'
if [[ ( $identity =~ $ai7020 || $identity =~ $nano ) &&
      ( $identity =~ $ai7100 || $identity =~ $nx ) ]]; then
    report PROBLEM 'Die Plattformkennungen im Device Tree widersprechen sich.'
elif [[ $identity =~ $ai7020 ]]; then
    report OK 'Device Tree nennt AI7020.'
elif [[ $identity =~ $ai7100 ]]; then
    report OK 'Device Tree nennt AI7100.'
elif [[ $identity =~ $nano ]]; then
    report OFFEN 'Orin Nano erkannt. FA-Modell am Gerät prüfen.'
elif [[ $identity =~ $nx ]]; then
    report OFFEN 'Orin NX erkannt. Die Modulkennung passt zu AI7100. FA-Modell am Gerät prüfen.'
else
    report OFFEN 'AI7020 oder AI7100 lässt sich aus dem Device Tree nicht bestimmen.'
fi

l4t_file=''
release_line=''
release_pattern='^#[[:space:]]*R([0-9]+).*REVISION:[[:space:]]*([0-9]+\.[0-9]+)([,[:space:]]|$)'
if [[ -r /etc/nv_tegra_release ]]; then
    IFS= read -r release_line < /etc/nv_tegra_release
    if [[ $release_line =~ $release_pattern ]]; then
        l4t_file="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    fi
fi
l4t_core=''
if core_version=$(package_version nvidia-l4t-core); then
    l4t_core=${core_version#*:}
    l4t_core=${l4t_core%%-*}
fi
printf '         L4T-Datei %s, Paket nvidia-l4t-core %s\n' "${l4t_file:-unbekannt}" "${core_version:-unbekannt}"
if [[ -n $l4t_file && -n $l4t_core && $l4t_file != "$l4t_core" ]]; then
    report PROBLEM 'L4T-Datei und installiertes Core-Paket melden unterschiedliche Releases.'
elif [[ ${l4t_file:-$l4t_core} == 36.4.0 ]]; then
    report OK 'L4T R36.4.0 entspricht der Laborbasis.'
else
    report PROBLEM 'Erwartet wird L4T R36.4.0. Release abweichend oder nicht ermittelbar.'
fi

printf '\nPaketverwaltung\n'
if audit=$(dpkg --audit 2>&1) && [[ -z $audit ]]; then
    report OK 'dpkg --audit meldet keine Auffälligkeiten.'
else
    report PROBLEM 'dpkg --audit meldet einen Paketfehler oder konnte nicht ausgeführt werden.'
    [[ -z $audit ]] || printf '%s\n' "$audit"
fi
if selections=$(dpkg --get-selections 2>/dev/null); then
    holds=$(awk '$2 == "hold" { print $1 }' <<< "$selections")
    printf '         Paketsperren (hold)\n%s\n' "${holds:-keine}"
else
    report OFFEN 'Paketsperren konnten nicht gelesen werden.'
fi

printf '\nBenutzer und Projektverzeichnisse\n'
user=$(id -un)
if [[ $EUID == 0 ]]; then
    user=${SUDO_USER:-root}
fi
if [[ -n $user && $user != root ]] && account=$(getent -- passwd "$user"); then
    IFS=: read -r login _ uid gid _ home _ <<< "$account"
    if [[ $uid =~ ^[0-9]+$ && $uid != 0 && $gid =~ ^[0-9]+$ && $home == /* && -d $home ]]; then
        report OK "Benutzer $login, UID $uid, GID $gid, Home $home"
        if (( count[PROBLEM] > 0 )); then
            report OFFEN 'Verzeichnisanlage wartet auf die Klärung der Vorprüfung.'
        elif (
            if (( EUID == 0 )); then
                env -u BASH_ENV -u ENV setpriv --reuid="$uid" --regid="$gid" --init-groups --no-new-privs -- \
                    "$BASH" --noprofile --norc -u -c "$(declare -f check_project_directory create_project_directories)
create_project_directories \"\$@\"" bash "$home" "$uid" "$gid"
            else
                create_project_directories "$home" "$uid" "$gid"
            fi
        ); then
            report OK 'Projekt- und Laufzeitverzeichnisse sind bereit.'
        else
            report PROBLEM 'Projekt- und Laufzeitverzeichnisse konnten nicht vollständig eingerichtet werden.'
        fi
    else
        report PROBLEM "Für $user konnte kein reguläres Benutzer-Home ermittelt werden."
    fi
else
    report PROBLEM 'Projektbenutzer nicht ermittelbar. Als Projektbenutzer oder von dessen Konto mit sudo aufrufen.'
fi

printf '\nLaborsoftware\n'
if docker_version=$(docker --version 2>/dev/null); then
    report OK "$docker_version"
    if install_nodered; then
        report OK 'Node-RED ist für den Laborzugang per SSH-Tunnel bereit.'
    else
        report PROBLEM 'Node-RED konnte nicht sicher eingerichtet oder bestätigt werden. Vorhandene Daten bleiben erhalten.'
    fi
else
    report PROBLEM 'Docker-CLI fehlt. Node-RED benötigt eine vorhandene Docker-Installation.'
fi
if mosquitto_version=$(package_version mosquitto); then
    report OK "Mosquitto-Broker $mosquitto_version"
elif command -v mosquitto >/dev/null; then
    report OK 'Mosquitto-Broker im Suchpfad gefunden.'
else
    report FEHLT 'Mosquitto-Broker nicht gefunden.'
fi
if command -v node-red >/dev/null; then
    report OK 'Node-RED auf dem Host im Suchpfad gefunden.'
elif pgrep -x node-red >/dev/null 2>&1; then
    report OK 'Laufender Node-RED-Prozess sichtbar.'
else
    printf '         Node-RED auf dem Host nicht im Suchpfad gefunden.\n'
fi

show_network() {
    local title=$1 output
    shift
    printf '\n%s\n' "$title"
    if output=$("$@" 2>/dev/null); then
        printf '%s\n' "${output:-keine}"
    else
        report OFFEN 'Abfrage nicht verfügbar.'
    fi
}

printf '\nNetzwerk\n'
show_network 'Schnittstellen und MAC-Adressen' ip -br link show
show_network 'Schnittstellen und IP-Adressen' ip -br address show
show_network 'IPv4-Standardrouten (Haupttabelle)' ip -4 route show default
show_network 'IPv6-Standardrouten (Haupttabelle)' ip -6 route show default
if systemctl is-active --quiet NetworkManager.service 2>/dev/null; then
    show_network 'NetworkManager-Geräte' nmcli device status
    show_network 'Aktive NetworkManager-Verbindungen' nmcli -f NAME,TYPE,DEVICE connection show --active
else
    report OFFEN 'NetworkManager nicht aktiv oder Dienstzustand nicht ermittelbar.'
fi
printf '\nDie physischen LAN-Buchsen müssen auf AI7020 und AI7100 zugeordnet werden.\n'

printf '\nZusammenfassung\nVorhanden %d | Fehlt %d | Offen %d | Probleme %d\n' \
    "${count[OK]}" "${count[FEHLT]}" "${count[OFFEN]}" "${count[PROBLEM]}"
(( count[PROBLEM] == 0 ))
