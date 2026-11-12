"""Small C1 installer tests; generated identities and TEST-NET IPs are TEST DATA.

All files are temporary. Linux metadata, locking and NetworkManager boundaries
are simulated; inspect/plan/install/backup/legacy guards execute real code.
No gateway or real subprocess is used. These addresses are no allocation advice.
"""
import contextlib
import copy
import hashlib
import importlib.util
import io
import ipaddress
import json
from pathlib import Path
import stat
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock
import uuid

SPEC = importlib.util.spec_from_file_location(
    "c1_install_under_test", Path(__file__).resolve().parents[1] / "c1_network.py")
C1 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(C1)


def smac(number):
    return ":".join(f"{b:02x}" for b in bytes([2]) + number.to_bytes(5, "big"))


def suuid(number):
    return str(uuid.UUID(int=0xC1000000 + number))


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="c1-small-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / "state"
        self.backup = self.root / "profile-backup"
        self.old_conf = self.base / "old-unmanaged.conf"
        self.ports = {"LAN1": dict(name="synthetic-first", mac=smac(11)),
                      "LAN2": dict(name="synthetic-second", mac=smac(12))}
        self.rows, self.paths = {}, {}
        for number, role in ((101, "LAN1"), (102, "LAN2")):
            key = suuid(number)
            self.rows[key] = dict.fromkeys(C1.FIELDS, "")
            self.rows[key].update({
                "connection.uuid": key, "connection.interface-name": self.ports[role]["name"],
                "connection.autoconnect": "yes", "match.interface-name": self.ports[role]["name"],
                "match.path": "synthetic-pci-path", "match.driver": "synthetic-driver",
                "match.kernel-command-line": "synthetic-boot-condition",
                "ipv4.method": "manual" if role == "LAN1" else "auto", "ipv4.never-default": "yes",
                "ipv4.addresses": str(ipaddress.IPv4Address("203.0.113.0") + number) + "/24",
                "ipv4.gateway": "", "ipv4.dns": "203.0.113.53", "ipv4.dns-search": "synthetic.invalid",
                "ipv4.routes": "198.51.100.0/24 203.0.113.1", "ipv4.route-metric": "120",
                "ipv6.method": "manual", "ipv6.never-default": "no", "ipv6.addresses": "2001:db8::10/64",
                "ipv6.gateway": "2001:db8::1", "ipv6.dns": "2001:db8::53", "ipv6.routes": "2001:db8:1::/64"})
            self.paths[key] = self.base / (key + ".nmconnection")
        self.active = {suuid(101): self.ports["LAN1"]["name"]}
        self.persist()
        self.original = self.file_bytes()
        self.commands, self.locks = [], 0
        self.fail_after = self.ignore_write = None

        @contextlib.contextmanager
        def locked():
            self.locks += 1
            self.root.mkdir(exist_ok=True)
            yield

        patches = dict(ROOT=self.root, BACKUP=self.backup, OLD_CONF=self.old_conf,
                       hardware=lambda: copy.deepcopy(self.ports),
                       profiles=lambda: (copy.deepcopy(self.rows), copy.deepcopy(self.active)),
                       profile_path=lambda key: self.paths[key], private=self.private,
                       locked=locked, run=self.native)
        for name, value in patches.items():
            patcher = mock.patch.object(C1, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)
        patcher = mock.patch.object(C1.subprocess, "run", side_effect=AssertionError("Real subprocess forbidden"))
        patcher.start()
        self.addCleanup(patcher.stop)
        self.output = io.StringIO()
        patcher = mock.patch.object(C1.sys, "stdout", self.output)
        patcher.start()
        self.addCleanup(patcher.stop)

    def persist(self):
        for key, path in self.paths.items():
            path.write_text(json.dumps(self.rows[key]), encoding="utf-8")

    def file_bytes(self):
        return {key: path.read_bytes() for key, path in self.paths.items()}

    def private(self, path, directory=False):
        # Only the Linux ownership/mode boundary is faked on Windows.
        path.lstat()
        if path.is_symlink() or not (path.is_dir() if directory else path.is_file()):
            raise C1.Incomplete("Synthetic unsafe path")
        return SimpleNamespace(st_uid=0, st_gid=0,
                               st_mode=(stat.S_IFDIR | 0o700) if directory else (stat.S_IFREG | 0o600))

    def manifest(self):
        return json.loads((self.backup / "manifest.json").read_text())["profiles"]

    def assert_original_backup(self):
        entries = self.manifest()
        self.assertEqual(len(entries), 2)
        for entry, role, number in zip(entries, ("LAN1", "LAN2"), (101, 102)):
            key = suuid(number)
            self.assertEqual({k: entry[k] for k in ("role", "uuid", "mac", "path", "uid", "gid", "mode")},
                             dict(role=role, uuid=key, mac=self.ports[role]["mac"], path=str(self.paths[key]),
                                  uid=0, gid=0, mode="0600"))
            data = (self.backup / entry["file"]).read_bytes()
            self.assertEqual(data, self.original[key])
            self.assertEqual(entry["sha256"], hashlib.sha256(data).hexdigest())

    def native(self, *args):
        self.assertEqual(args[:4], ("nmcli", "connection", "modify", "uuid"))
        self.assert_original_backup()  # Both complete originals precede EVERY write.
        self.commands.append(args)
        key = args[4]
        changes = dict(zip(args[5::2], args[6::2]))
        self.assertEqual(changes, {"802-3-ethernet.mac-address": smac(11 if key == suuid(101) else 12),
                                   "connection.interface-name": "", "match.interface-name": ""})
        if key != self.ignore_write:
            self.rows[key].update(changes)
            self.paths[key].write_text(json.dumps(self.rows[key]), encoding="utf-8")
        if key == self.fail_after:
            raise C1.Incomplete("Synthetic failure after persisted modify")
        return ""

    def set_bound(self):
        for role, number in (("LAN1", 101), ("LAN2", 102)):
            self.rows[suuid(number)].update({"802-3-ethernet.mac-address": self.ports[role]["mac"],
                                             "connection.interface-name": "", "match.interface-name": ""})

    def test_install_changes_only_three_binding_fields_and_keeps_originals(self):
        before_rows, before_active = copy.deepcopy(self.rows), copy.deepcopy(self.active)
        self.assertEqual(C1.install(), 0)
        self.assertEqual([a[4] for a in self.commands], [suuid(101), suuid(102)])
        self.assertEqual(self.active, before_active)
        self.assert_original_backup()
        for role, number in (("LAN1", 101), ("LAN2", 102)):
            key = suuid(number)
            expected = dict(before_rows[key])
            expected.update({"802-3-ethernet.mac-address": self.ports[role]["mac"],
                             "connection.interface-name": "", "match.interface-name": ""})
            self.assertEqual(self.rows[key], expected)
            self.assertEqual(json.loads(self.paths[key].read_text()), expected)
        self.assertFalse(self.old_conf.exists())

    def test_swapped_names_preserve_uuids_then_repeat_without_any_write(self):
        self.ports["LAN1"]["name"], self.ports["LAN2"]["name"] = self.ports["LAN2"]["name"], self.ports["LAN1"]["name"]
        for role, number in (("LAN1", 101), ("LAN2", 102)):
            key = suuid(number)
            self.rows[key]["connection.interface-name"] = self.ports[role]["name"]
            self.active[key] = self.ports[role]["name"]
        self.persist()
        self.original = self.file_bytes()
        self.assertEqual(C1.install(), 0)
        self.ports["LAN1"]["name"], self.ports["LAN2"]["name"] = self.ports["LAN2"]["name"], self.ports["LAN1"]["name"]
        self.active = {suuid(101): self.ports["LAN1"]["name"], suuid(102): self.ports["LAN2"]["name"]}
        files = self.file_bytes()
        before = len(self.commands), self.locks, (self.backup / "manifest.json").read_bytes()
        self.assertEqual(C1.install(), 0)
        self.assertEqual((len(self.commands), self.locks, (self.backup / "manifest.json").read_bytes()), before)
        self.assertEqual(self.file_bytes(), files)

    def test_active_or_inactive_lan2_is_never_activated_or_disconnected(self):
        for active in (False, True):
            with self.subTest(lan2_active=active):
                self.rows[suuid(102)]["802-3-ethernet.mac-address"] = ""
                self.rows[suuid(102)]["connection.interface-name"] = self.ports["LAN2"]["name"]
                if active:
                    self.active[suuid(102)] = self.ports["LAN2"]["name"]
                else:
                    self.active.pop(suuid(102), None)
                before = dict(self.active)
                self.assertEqual(C1.install(), 0)
                self.assertEqual(self.active, before)

    def test_already_bound_noop_creates_no_directory_lock_or_backup(self):
        self.set_bound()
        for check in (False, True):
            self.assertEqual(C1.install(check=check), 0)
        self.assertFalse(self.root.exists())
        self.assertEqual(self.locks, 0)
        self.assertFalse(self.commands)

    def test_bound_install_and_status_reject_missing_or_unsaved_second_source_before_lock(self):
        self.set_bound()
        for reason in ("Synthetic missing persistent source", "Synthetic Unsaved profile"):
            for check in (False, True):
                with self.subTest(reason=reason, check=check):
                    queried = []

                    def source(key):
                        queried.append(key)
                        if key == suuid(102):
                            raise C1.Incomplete(reason)
                        return self.paths[key]

                    with mock.patch.object(C1, "profile_path", side_effect=source):
                        with self.assertRaisesRegex(C1.Incomplete, reason):
                            C1.install(check=check)
                    self.assertEqual(queried, [suuid(101), suuid(102)])
                    self.assertEqual(self.locks, 0)
                    self.assertFalse(self.root.exists())
                    self.assertFalse(self.commands)
                    self.assertEqual(self.file_bytes(), self.original)

    def test_check_is_readonly_when_binding_is_missing(self):
        files = self.file_bytes()
        self.assertEqual(C1.install(check=True), 1)
        self.assertEqual(self.file_bytes(), files)
        self.assertFalse(self.root.exists())
        self.assertEqual(self.locks, 0)
        self.assertFalse(self.commands)

    def test_reinspect_after_lock_can_observe_concurrent_completed_install(self):
        before = copy.deepcopy(self.rows)
        self.set_bound()
        after = copy.deepcopy(self.rows)
        with mock.patch.object(C1, "profiles", side_effect=((before, self.active), (after, self.active))):
            self.assertEqual(C1.install(), 0)
        self.assertEqual(self.locks, 1)
        self.assertFalse(self.backup.exists())
        self.assertFalse(self.commands)

    def test_bound_after_lock_still_validates_both_persistent_sources(self):
        before = copy.deepcopy(self.rows)
        self.set_bound()
        after = copy.deepcopy(self.rows)
        queried = []

        def source(key):
            queried.append(key)
            self.assertEqual(self.locks, 1)
            if key == suuid(102):
                raise C1.Incomplete("Synthetic source became Unsaved while waiting")
            return self.paths[key]

        with mock.patch.object(C1, "profiles", side_effect=((before, self.active), (after, self.active))), \
                mock.patch.object(C1, "profile_path", side_effect=source):
            with self.assertRaisesRegex(C1.Incomplete, "Unsaved while waiting"):
                C1.install()
        self.assertEqual(queried, [suuid(101), suuid(102)])
        self.assertFalse(self.backup.exists())
        self.assertFalse(self.commands)
        self.assertEqual(self.file_bytes(), self.original)

    def test_existing_valid_backup_is_reused_and_never_overwritten(self):
        self.assertEqual(C1.install(), 0)
        saved = {p.name: p.read_bytes() for p in self.backup.iterdir()}
        self.rows[suuid(102)]["connection.interface-name"] = self.ports["LAN2"]["name"]
        self.assertEqual(C1.install(), 0)
        self.assertEqual({p.name: p.read_bytes() for p in self.backup.iterdir()}, saved)

    def test_invalid_existing_backup_blocks_without_overwrite_or_profile_write(self):
        self.root.mkdir()
        items, _ = C1.inspect()
        C1.backup(items, self.paths)
        saved = {p.name: p.read_bytes() for p in self.backup.iterdir()}
        for case in ("bad-json", "wrong-identity", "corrupt-copy", "missing-copy"):
            with self.subTest(case=case):
                for name, data in saved.items():
                    (self.backup / name).write_bytes(data)
                if case == "bad-json":
                    (self.backup / "manifest.json").write_bytes(b"{")
                elif case == "wrong-identity":
                    data = json.loads(saved["manifest.json"])
                    data["profiles"][1]["uuid"] = suuid(199)
                    (self.backup / "manifest.json").write_text(json.dumps(data))
                elif case == "corrupt-copy":
                    (self.backup / "profile-2.nmconnection").write_bytes(b"synthetic corruption")
                else:
                    (self.backup / "profile-2.nmconnection").unlink()
                current = {p.name: p.read_bytes() for p in self.backup.iterdir()}
                with self.assertRaises((C1.Incomplete, OSError, ValueError)):
                    C1.install()
                self.assertEqual({p.name: p.read_bytes() for p in self.backup.iterdir()}, current)
                self.assertEqual(self.file_bytes(), self.original)
                self.assertFalse(self.commands)

    def test_second_backup_source_failure_precedes_writes_and_partial_backup_blocks_retry(self):
        def fail(path, directory=False):
            if path == self.paths[suuid(102)]:
                raise C1.Incomplete("Synthetic unreadable second original")
            return self.private(path, directory)
        with mock.patch.object(C1, "private", side_effect=fail):
            with self.assertRaises(C1.Incomplete):
                C1.install()
        first = (self.backup / "profile-1.nmconnection").read_bytes()
        with self.assertRaises((C1.Incomplete, OSError)):
            C1.install()
        self.assertEqual((self.backup / "profile-1.nmconnection").read_bytes(), first)
        self.assertEqual(self.file_bytes(), self.original)
        self.assertFalse(self.commands)

    def test_same_original_path_for_both_profiles_blocks_before_backup(self):
        with mock.patch.object(C1, "profile_path", return_value=self.paths[suuid(101)]):
            with self.assertRaises(C1.Incomplete):
                C1.install()
        self.assertFalse(self.backup.exists())
        self.assertFalse(self.commands)

    def test_profile_source_switch_after_modify_reports_manual_recovery(self):
        calls = {key: 0 for key in self.paths}
        def source(key):
            calls[key] += 1
            return self.paths[key] if calls[key] == 1 else self.base / "unexpected-source"
        with mock.patch.object(C1, "profile_path", side_effect=source):
            with self.assertRaisesRegex(C1.Incomplete, "manuell wiederherstellen"):
                C1.install()
        self.assertEqual(len(self.commands), 2)
        self.assert_original_backup()

    def test_second_modify_failure_retains_partial_result_and_manual_recovery_message(self):
        self.fail_after = suuid(102)
        with self.assertRaisesRegex(C1.Incomplete, "kein automatischer Rückfall") as error:
            C1.install()
        self.assertIn(str(self.backup), str(error.exception))
        self.assertIn("manuell wiederherstellen", str(error.exception))
        self.assertEqual(len(self.commands), 2)
        self.assertNotEqual(self.file_bytes(), self.original)
        self.assert_original_backup()

    def test_missing_binding_after_modify_is_detected_without_automatic_rollback(self):
        self.ignore_write = suuid(102)
        with self.assertRaisesRegex(C1.Incomplete, "Profiländerung unvollständig"):
            C1.install()
        self.assertEqual(self.rows[suuid(101)]["802-3-ethernet.mac-address"], smac(11))
        self.assertEqual(self.rows[suuid(102)]["802-3-ethernet.mac-address"], "")
        self.assert_original_backup()

    def test_legacy_pending_blocks_before_lock_and_preserves_marker_and_profiles(self):
        self.root.mkdir()
        token = f"{0xC1001:016x}"
        marker = self.root / "pending"
        marker.write_text(token)
        with self.assertRaisesRegex(C1.Incomplete, "rollback-manual " + token):
            C1.install()
        self.assertEqual(marker.read_text(), token)
        self.assertEqual(self.locks, 0)
        self.assertFalse(self.commands)
        self.assertFalse(self.backup.exists())
        self.assertEqual(self.file_bytes(), self.original)
        marker.unlink()

        @contextlib.contextmanager
        def pending_while_waiting_for_lock():
            self.locks += 1
            marker.write_text(token)
            yield

        with mock.patch.object(C1, "locked", pending_while_waiting_for_lock):
            with self.assertRaisesRegex(C1.Incomplete, "rollback-manual " + token):
                C1.install()
        self.assertEqual(self.locks, 1)
        self.assertFalse(self.commands)
        self.assertFalse(self.backup.exists())

    def test_legacy_only_complete_terminal_states_pass_the_readonly_check(self):
        self.root.mkdir()
        token = f"{0xC1002:016x}"
        directory = self.root / token
        directory.mkdir()
        path = directory / "state.json"
        for status in ("prepared", "applying", "pending", "rolling-back", "rollback-failed",
                       "committed", "rolled-back", "aborted", "missing", "malformed", "wrong-id"):
            with self.subTest(status=status):
                path.write_text(json.dumps(dict(id=token, status=status)))
                if status == "missing":
                    path.unlink()
                elif status == "malformed":
                    path.write_text("{")
                elif status == "wrong-id":
                    path.write_text(json.dumps(dict(id=token + "x", status="committed")))
                if status in ("committed", "rolled-back", "aborted"):
                    self.assertEqual(C1.install(check=True), 1)
                else:
                    with self.assertRaises(C1.Incomplete):
                        C1.install(check=True)
                self.assertFalse(self.commands)
                self.assertEqual(self.locks, 0)

    def test_old_unmanaged_conf_blocks_even_bound_profiles_and_is_not_removed(self):
        self.set_bound()
        self.old_conf.write_bytes(b"synthetic legacy config")
        for check in (False, True):
            with self.assertRaisesRegex(C1.Incomplete, "Unmanaged-Datei"):
                C1.install(check=check)
        self.assertEqual(self.old_conf.read_bytes(), b"synthetic legacy config")
        self.assertFalse(self.root.exists())
        self.assertFalse(self.commands)


if __name__ == "__main__":
    unittest.main()

