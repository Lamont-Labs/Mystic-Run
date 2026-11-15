import copy
import unittest
from pathlib import Path

from android_release_automation import REPO, approved_source, next_version, published_codes


class AutomaticReleaseTests(unittest.TestCase):
    def setUp(self):
        self.sha = "a" * 40
        self.branch = {"protected": True, "commit": {"sha": self.sha}}
        self.run = {
            "head_sha": self.sha, "head_branch": "main", "event": "push",
            "conclusion": "success", "path": ".github/workflows/core-checks.yml",
            "head_repository": {"full_name": REPO},
        }

    def test_current_protected_main_is_accepted(self):
        approved_source(self.branch, [self.run], self.sha)

    def test_unprotected_or_stale_main_is_rejected(self):
        for branch in ({"protected": False, "commit": {"sha": self.sha}},
                       {"protected": True, "commit": {"sha": "b" * 40}}):
            with self.assertRaises(ValueError):
                approved_source(branch, [self.run], self.sha)

    def test_untrusted_and_failed_runs_are_rejected(self):
        changes = [
            ("event", "pull_request"), ("event", "workflow_dispatch"),
            ("conclusion", "failure"), ("conclusion", "cancelled"),
            ("head_branch", "feature"), ("head_sha", "b" * 40),
            ("path", ".github/workflows/other.yml"),
            ("head_repository", {"full_name": "fork/Mystic-Run"}),
        ]
        for key, value in changes:
            with self.subTest(key=key, value=value):
                run = copy.deepcopy(self.run)
                run[key] = value
                with self.assertRaises(ValueError):
                    approved_source(self.branch, [run], self.sha)
        with self.assertRaises(ValueError):
            approved_source(self.branch, [], self.sha)

    def test_version_increases_beyond_releases_and_records(self):
        self.assertEqual(next_version(8, [1029], []), 2008)
        self.assertEqual(next_version(8, [9000], []), 9001)
        self.assertEqual(next_version(8, [9000], [{"signed_manifest": {"version_code": 9500}}]), 9501)
        with self.assertRaises(ValueError):
            next_version(8, [2100000000], [])

    def test_all_published_tags_including_previews_are_counted(self):
        pages = [[{"tag_name": "v0.6.1-build1032"}],
                 [{"tag_name": "v0.6.2-art-preview-build2012"}, {"tag_name": "misc"}]]
        self.assertEqual(published_codes(pages), [1032, 2012])

    def test_workflow_keeps_secrets_out_of_gate_and_publisher(self):
        workflow = (Path(__file__).resolve().parents[1] / ".github/workflows/android-apk.yml").read_text()
        gate = workflow.split("  gate:", 1)[1].split("  android:", 1)[0]
        publisher = workflow.split("  publish:", 1)[1]
        self.assertNotIn("secrets.", gate)
        self.assertNotIn("secrets.", publisher)
        self.assertIn("environment: android-signing", workflow)
        self.assertIn("environment: android-release", publisher)
        self.assertIn("persist-credentials: false", gate)
        self.assertIn("needs: [gate, android]", publisher)
        self.assertLess(workflow.index("Compile unsigned APK"), workflow.index("secrets.MYSTICRUN_KEYSTORE_BASE64"))
        self.assertNotIn("pull_request_target:", workflow)
        self.assertNotIn("contents: write", workflow.split("  publish:", 1)[0])


if __name__ == "__main__":
    unittest.main()
