"""Small C1 tests: synthetic NIC/profile data, no real subprocess or root I/O."""
import contextlib
import copy
import importlib.util
import io
import json
from pathlib import Path, PurePosixPath
import stat
import subprocess
from types import SimpleNamespace
import unittest
from unittest import mock

SPEC = importlib.util.spec_from_file_location(
    "simple_c1_under_test", Path(__file__).resolve().parents[1] / "c1_network.py")
C1 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(C1)
U1, U2, U3 = (f"00000000-0000-0000-0000-{n:012d}" for n in (1, 2, 3))
M1, M2, M3 = (f"02:00:00:00:00:{n:02x}" for n in (11, 12, 13))
PORTS = {"LAN1": {"name": "synthetic-alpha", "mac": M1},
         "LAN2": {"name": "synthetic-beta", "mac": M2}}
TOKEN = "0123456789abcdef"


def row(key, name="", identity="", auto="yes"):
    return {"connection.uuid": key, "connection.interface-name": name,
            "802-3-ethernet.mac-address": identity, "connection.autoconnect": auto,
            "match.interface-name": ""}


def rows_fixture():
    return {U1: row(U1, PORTS["LAN1"]["name"]), U2: row(U2, PORTS["LAN2"]["name"])}


class Isolated(unittest.TestCase):
    def setUp(self):
        patcher = mock.patch.object(C1.subprocess, "run", side_effect=AssertionError("No real subprocess"))
        patcher.start()
        self.addCleanup(patcher.stop)


class RunHardwareTests(Isolated):
    def test_run_fixed_environment_timeout_no_shell_and_failures(self):
        with mock.patch.object(C1.subprocess, "run", return_value=SimpleNamespace(stdout="ok")) as run:
            self.assertEqual(C1.run("nmcli", "--version"), "ok")
            self.assertEqual(run.call_args.args, (("nmcli", "--version"),))
            options = run.call_args.kwargs
            self.assertEqual(options["env"], {"PATH": "/usr/sbin:/usr/bin:/sbin:/bin", "LC_ALL": "C"})
            self.assertEqual(options["timeout"], 30)
            self.assertTrue(options["check"])
            self.assertFalse(options.get("shell", False))
        for error in (OSError("private detail"), subprocess.CalledProcessError(1, "nmcli"),
                      subprocess.TimeoutExpired("nmcli", 30)):
            with self.subTest(error=type(error).__name__), mock.patch.object(C1.subprocess, "run", side_effect=error):
                with self.assertRaises(C1.Incomplete) as caught:
                    C1.run("nmcli")
                self.assertNotIn("private detail", str(caught.exception))

    def test_mac_normalizes_and_rejects_zero_multicast_bad_shape(self):
        self.assertEqual(C1.mac(M1.upper()), M1)
        for value in ("00:00:00:00:00:00", "ff:ff:ff:ff:ff:ff", "01:00:00:00:00:01", "invalid"):
            with self.subTest(value=value), self.assertRaises(C1.Incomplete):
                C1.mac(value)

    def hardware(self, extra=None, missing=False, duplicate_mac=False):
        drivers = {PORTS["LAN1"]["name"]: "r8168", PORTS["LAN2"]["name"]: "lan743x"}
        if extra:
            drivers["synthetic-extra"] = extra
        if missing:
            del drivers[PORTS["LAN2"]["name"]]
        devices = [{"ifname": n, "link_type": "ether", "address": M3} for n in drivers]
        devices += [{"ifname": "l4tbr0", "link_type": "ether"}, {"ifname": "lo", "link_type": "loopback"}]

        class SysPath(PurePosixPath):
            def exists(self):
                return self.name == "device" and self.parent.name in drivers

        def command(*args):
            if args == ("ip", "-j", "link", "show"):
                return json.dumps(devices)
            if args[:2] == ("ethtool", "-i"):
                return "driver: " + drivers[args[2]]
            if args[:2] == ("ethtool", "-P"):
                return "Permanent address: " + (M1 if args[2] == PORTS["LAN1"]["name"] or duplicate_mac else M2)
            raise AssertionError(args)

        with mock.patch.object(C1, "Path", SysPath), mock.patch.object(C1, "run", side_effect=command) as run:
            result = C1.hardware()
            self.assertTrue(all(c.args[-1] in drivers for c in run.call_args_list if c.args[0] == "ethtool"))
            return result

    def test_hardware_uses_permanent_mac_and_ignores_unrelated_driver(self):
        self.assertEqual(self.hardware(), PORTS)
        self.assertEqual(self.hardware(extra="synthetic-unrelated"), PORTS)

    def test_missing_duplicate_driver_or_duplicate_mac_blocks(self):
        for options in ({"missing": True}, {"extra": "r8168"}, {"extra": "lan743x"}, {"duplicate_mac": True}):
            with self.subTest(options=options), self.assertRaises(C1.Incomplete):
                self.hardware(**options)


class ProfilePlanTests(Isolated):
    def test_profiles_reads_only_five_fields_and_optional_match(self):
        rows = rows_fixture()
        rows[U1]["802-3-ethernet.mac-address"] = M1.upper()

        def command(*args):
            if args[-1] == "--active":
                return f"{U1}:{PORTS['LAN1']['name']}"
            if args[-2:] in (("uuid", U1), ("uuid", U2)):
                self.assertEqual(args[5], ",".join(C1.FIELDS))
                return "\n".join(f"{k}:{v}" for k, v in rows[args[-1]].items() if k != "match.interface-name")
            self.assertEqual(args[5], "UUID,TYPE")
            return f"{U1}:ethernet\n{U2}:802-3-ethernet\n{U3}:bridge"

        with mock.patch.object(C1, "run", side_effect=command):
            actual, active = C1.profiles()
        rows[U1]["802-3-ethernet.mac-address"] = M1
        self.assertEqual(actual, rows)
        self.assertEqual(active, {U1: PORTS["LAN1"]["name"]})
        self.assertEqual(set(C1.FIELDS), set(row(U1)))

    def test_duplicate_missing_unknown_fields_or_active_uuid_blocks(self):
        valid = "\n".join(f"{k}:{v}" for k, v in row(U1).items())
        for fields, active in ((valid + "\nconnection.uuid:" + U1, ""),
                               (valid.replace("connection.autoconnect:yes", "unknown:yes"), ""),
                               (valid.replace("connection.autoconnect:yes\n", ""), ""),
                               (valid, f"{U1}:one\n{U1}:two")):
            def command(*args):
                return active if args[-1] == "--active" else fields if args[-1] == U1 else f"{U1}:ethernet"
            with self.subTest(fields=fields, active=active), mock.patch.object(C1, "run", side_effect=command):
                with self.assertRaises((C1.Incomplete, ValueError)):
                    C1.profiles()

    def test_named_profiles_only_three_binding_fields_keep_ip_auto_and_other_matches(self):
        rows = rows_fixture()
        for data in rows.values():
            data.update({"ipv4.method": "manual", "ipv4.never-default": "yes", "ipv4.dns": "192.0.2.53",
                         "ipv4.routes": "203.0.113.0/24", "match.path": "pci-synthetic", "match.driver": "kept"})
        before = copy.deepcopy(rows)
        items = C1.plan(PORTS, rows, {})
        self.assertEqual([i["uuid"] for i in items], [U1, U2])
        self.assertFalse(C1.bound(items, rows))
        for item in items:
            self.assertEqual(C1.desired(item), {"802-3-ethernet.mac-address": item["mac"],
                                               "connection.interface-name": "", "match.interface-name": ""})
        self.assertEqual(rows, before)
        for item in items:
            rows[item["uuid"]].update(C1.desired(item))
        self.assertTrue(C1.bound(items, rows))
        rows[U2]["match.interface-name"] = "synthetic-old"
        self.assertFalse(C1.bound(items, rows))

    def test_active_unnamed_fallback_on_both_ports_never_overrides_conflicting_binding(self):
        for role, key in (("LAN1", U1), ("LAN2", U2)):
            rows = rows_fixture()
            rows[key]["connection.interface-name"] = ""
            active = {key: PORTS[role]["name"]}
            self.assertEqual(len(C1.plan(PORTS, rows, active)), 2)
            for field, wrong in (("802-3-ethernet.mac-address", M3), ("connection.interface-name", "synthetic-wrong")):
                bad = copy.deepcopy(rows)
                bad[key][field] = wrong
                with self.subTest(role=role, field=field), self.assertRaises(C1.Incomplete):
                    C1.plan(PORTS, bad, active)

    def test_bound_profiles_survive_swapped_names_and_extra_unrelated_profile(self):
        rows = {U1: row(U1, identity=M1), U2: row(U2, identity=M2), U3: row(U3, identity=M3)}
        ports = copy.deepcopy(PORTS)
        ports["LAN1"]["name"], ports["LAN2"]["name"] = ports["LAN2"]["name"], ports["LAN1"]["name"]
        items = C1.plan(ports, rows, {U1: ports["LAN1"]["name"], U2: ports["LAN2"]["name"]})
        self.assertEqual([i["uuid"] for i in items], [U1, U2])

    def test_missing_multiple_mixed_candidates_generic_auto_and_foreign_active_block(self):
        for change in ("missing", "two-names", "mac-plus-name", "generic-auto", "foreign-active", "own-on-foreign"):
            rows, active = rows_fixture(), {}
            if change == "missing":
                del rows[U2]
            elif change == "two-names":
                rows[U3] = row(U3, PORTS["LAN2"]["name"], auto="no")
            elif change == "mac-plus-name":
                rows[U3] = row(U3, identity=M2)
            elif change == "generic-auto":
                rows[U3] = row(U3)
            elif change == "foreign-active":
                active[U3] = PORTS["LAN2"]["name"]
            else:
                active[U2] = "synthetic-foreign"
            with self.subTest(change=change), self.assertRaises(C1.Incomplete):
                C1.plan(PORTS, rows, active)


class SourceLegacyCliTests(Isolated):
    def test_profile_path_rejects_temporary_unsaved_unsafe_originals(self):
        filename = "/etc/NetworkManager/system-connections/synthetic profile.nmconnection"
        for change in ("valid", "readonly", "unsaved", "flags", "run", "symlink", "readable", "owner"):
            values = {"Unsaved": "false", "Flags": "uint32 0", "Filename": repr(filename)}
            if change in ("unsaved", "flags"):
                values["Unsaved" if change == "unsaved" else "Flags"] = "true" if change == "unsaved" else "uint32 2"
            if change == "run":
                values["Filename"] = repr("/run/NetworkManager/system-connections/synthetic.nmconnection")

            class ProfilePath(PurePosixPath):
                def resolve(self):
                    return self

                def lstat(self):
                    mode = 0o400 if change == "readonly" else 0o644 if change == "readable" else 0o600
                    return SimpleNamespace(st_mode=stat.S_IFREG | mode, st_uid=1000 if change == "owner" else 0)

                def is_symlink(self):
                    return change == "symlink"

            def command(*args):
                return f"(<{values[args[-1]]}>,)" if args[-1] in values else "(objectpath '/org/freedesktop/NetworkManager/Settings/7',)"

            with self.subTest(change=change), mock.patch.object(C1, "Path", ProfilePath), mock.patch.object(C1, "run", side_effect=command):
                if change in ("valid", "readonly"):
                    self.assertEqual(str(C1.profile_path(U1)), filename)
                else:
                    with self.assertRaises(C1.Incomplete):
                        C1.profile_path(U1)

    def test_legacy_guard_terminal_only_and_pending_old_conf_block_without_writes(self):
        for state in ("committed", "rolled-back", "aborted", "pending", "prepared", "applying", "rolling-back",
                      "rollback-failed", "unknown", "invalid", "missing", "wrong-id", "marker", "marker-symlink", "old-conf"):
            root, marker, directory, source, oldconf = (mock.MagicMock() for _ in range(5))
            root.exists.return_value, root.is_symlink.return_value = True, False
            root.__truediv__.return_value = marker
            marker.exists.return_value, marker.is_symlink.return_value = state == "marker", state == "marker-symlink"
            marker.is_file.return_value, marker.read_text.return_value = True, TOKEN
            directory.name = TOKEN
            directory.__truediv__.return_value = source
            source.read_text.return_value = "not-json" if state == "invalid" else json.dumps(
                {"id": "different" if state == "wrong-id" else TOKEN, "status": "committed" if state == "wrong-id" else state})
            if state == "missing":
                source.read_text.side_effect = FileNotFoundError()
            root.iterdir.return_value = [] if state in ("marker", "marker-symlink", "old-conf") else [directory]
            oldconf.exists.return_value, oldconf.is_symlink.return_value = state == "old-conf", False
            with self.subTest(state=state), mock.patch.object(C1, "ROOT", root), mock.patch.object(C1, "OLD_CONF", oldconf), mock.patch.object(C1, "private"):
                if state in ("committed", "rolled-back", "aborted"):
                    C1.legacy_guard()
                else:
                    with self.assertRaises(C1.Incomplete):
                        C1.legacy_guard()
                marker.unlink.assert_not_called()
                source.write_text.assert_not_called()

    def test_cli_install_status_root_platform_and_removed_actions(self):
        cases = ((["install"], "linux", 0, 7), (["status"], "linux", 0, 7),
                 (["install"], "linux", 1000, 1), (["status"], "win32", 0, 1),
                 (["verify", TOKEN], "linux", 0, 2), (["ethercat-on"], "linux", 0, 2),
                 (["install", TOKEN], "linux", 0, 2), ([], "linux", 0, 2))
        for argv, platform, uid, code in cases:
            with self.subTest(argv=argv, platform=platform), mock.patch.object(C1.sys, "argv", ["c1.py", *argv]), \
                    mock.patch.object(C1.sys, "platform", platform), mock.patch.object(C1.os, "geteuid", return_value=uid, create=True), \
                    mock.patch.object(C1, "install", return_value=7) as install, contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(C1.main(), code)
                if code == 7:
                    install.assert_called_once_with(check=argv[0] == "status")
                else:
                    install.assert_not_called()


if __name__ == "__main__":
    unittest.main()
