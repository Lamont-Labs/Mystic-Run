"""Fail-closed checks shared by replacement-key signing and release delivery."""
import re
import zipfile

PACKAGE = 'com.lamontlabs.knightgargoylewitch.dev'
SIGNING_ALIAS = 'mysticrun'
PERMANENT_CERTIFICATE = '8ccd240d320a0ac8568581d5c7e005538033681d8b882058d673c80719dfd859'


def verify_signature(report, expected=PERMANENT_CERTIFICATE):
    fingerprints = re.findall(r'^Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]+)$', report, re.M)
    if fingerprints != [expected]:
        raise ValueError('Expected exactly one signer with the pinned signing certificate')
    if not re.search(r'^Number of signers: 1$', report, re.M):
        raise ValueError('Expected exactly one APK signer')
    for scheme in (2, 3):
        if not re.search(r'^Verified using v'+str(scheme)+r' scheme \([^\n]+\): true$', report, re.M):
            raise ValueError(f'APK v{scheme} signature was not verified')


def verify_resources(apk, tools, command):
    """Use aapt2, not legacy aapt: its file-reference format is intentional."""
    table = command([tools/'aapt2', 'dump', 'resources', apk])
    markers = re.findall(r'\(file\)[^\n]*', table)
    paths = re.findall(r'\(file\)\s+([^\s]+)', table)
    if not paths or len(paths) != len(markers) or any(not p.startswith('res/') for p in paths):
        raise ValueError('Resource file-reference parse was empty or invalid')
    with zipfile.ZipFile(apk) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)) or archive.testzip() is not None:
            raise ValueError('APK ZIP integrity or duplicate-entry check failed')
        if 'resources.arsc' not in names or 'AndroidManifest.xml' not in names:
            raise ValueError('APK resource table or manifest is missing')
        missing = sorted(set(paths)-set(names))
        if missing:
            raise ValueError('Resource table references missing packaged files: '+', '.join(missing))
        xml_files = ['AndroidManifest.xml'] + sorted(n for n in names if n.startswith('res/') and n.endswith('.xml'))
    for name in xml_files:
        xml = command([tools/'aapt2', 'dump', 'xmltree', '--file', name, apk])
        if not re.search(r'^\s*E: ', xml, re.M):
            raise ValueError('Packaged XML did not parse: '+name)
    return {'resource_integrity_verified': True, 'resource_file_references_checked': len(paths),
            'packaged_xml_files_checked': len(xml_files)}
