#!/usr/bin/env bash
set -u
export LC_ALL=C

usage() {
    printf 'Aufruf: %s labor\nBestandsaufnahme, Projektverzeichnisse und Node-RED für den SSH-Tunnel.\n' "$0"
}

if [[ $# == 1 && ( $1 == --help || $1 == -h ) ]]; then
    usage
    exit 0
fi
if [[ $# != 1 || $1 != labor ]]; then
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
