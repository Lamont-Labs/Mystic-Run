"""Build must reject manifest regressions that would invalidate its privacy claim."""
import unittest
from android_policy import inspect_package


GOOD = "sdkVersion:'24'\ntargetSdkVersion:'36'\nuses-permission: name='android.permission.VIBRATE'\n"


class PackagePolicyTests(unittest.TestCase):
    def test_offline_api_36_manifest(self):
        self.assertEqual(inspect_package(GOOD)['target_sdk'], 36)

    def test_old_target_is_rejected(self):
        with self.assertRaises(ValueError):
            inspect_package(GOOD.replace("targetSdkVersion:'36'", "targetSdkVersion:'35'"))

    def test_network_permission_is_rejected(self):
        with self.assertRaises(ValueError):
            inspect_package(GOOD + "uses-permission: name='android.permission.INTERNET'\n")

    def test_missing_sdk_is_rejected(self):
        with self.assertRaises(ValueError):
            inspect_package(GOOD.replace("sdkVersion:'24'\n", ""))


if __name__ == '__main__':
    unittest.main()
