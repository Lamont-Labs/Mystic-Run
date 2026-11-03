"""Check the packaged manifest, independently of export preset intentions."""
import re


def inspect_package(metadata):
    def sdk(label):
        match = re.search(r"^" + label + r":'([0-9]+)'", metadata, re.M)
        if not match:
            raise ValueError('Packaged manifest has no numeric ' + label)
        return int(match.group(1))

    minimum, target = sdk('sdkVersion'), sdk('targetSdkVersion')
    permissions = sorted(set(re.findall(r"^uses-permission(?:-[0-9]+)?: name='([^']+)'", metadata, re.M)))
    if target < 36:
        raise ValueError('Android target API must be at least 36 for the current Play submission requirement')
    if minimum != 24:
        raise ValueError('Unexpected minimum Android API; expected 24')
    if permissions != ['android.permission.VIBRATE']:
        raise ValueError('Offline privacy contract changed: unexpected packaged permissions ' + repr(permissions))
    return {'min_sdk': minimum, 'target_sdk': target, 'permissions': permissions,
            'offline_permissions_verified': True}
