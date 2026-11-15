"""Repair Godot 4.7.2's dangling themed-icon entry before APK signing.

The standard exporter skips themed_icon.xml even though resources.arsc keeps
its original file reference. Restore only the compiled XML from the pinned
official template; do not recompile the table or change the active icon.
"""
import hashlib
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile

from fetch_android_template import EXPECTED

THEMED_ICON = "res/mipmap-anydpi-v26/themed_icon.xml"
ICON_NAMES = ("icon_background", "icon_foreground", "icon_monochrome", "themed_icon")


def resource_files(table):
    files = set(re.findall(r"\(file\)\s+(res/[^\s]+)", table))
    if not files:
        raise ValueError("No file references parsed; require aapt2 resource-table output")
    return files


def inspect_table(aapt, apk):
    result = subprocess.run(
        [str(aapt), "dump", "resources", str(apk)],
        capture_output=True, text=True, check=True, timeout=60,
    )
    return result.stdout


def repair_themed_icon(apk, template, aapt):
    """Restore the known missing entry; fail closed on any other missing file."""
    apk, template = Path(apk), Path(template)
    table = inspect_table(aapt, apk)
    with zipfile.ZipFile(apk) as archive:
        missing = resource_files(table) - set(archive.namelist())
    if not missing:
        return {"restored": [], "all_resource_files_present": True}
    if missing != {THEMED_ICON}:
        raise ValueError("Unexpected missing Android resources: " + ", ".join(sorted(missing)))
    if not template.is_file() or hashlib.sha256(template.read_bytes()).hexdigest() != EXPECTED["android_debug.apk"]:
        raise ValueError("Icon repair requires the checksum-pinned official debug template")
    original_table = inspect_table(aapt, template)
    for name in ICON_NAMES:
        pattern = r"resource (0x[0-9a-f]+) mipmap/" + name + r"\b"
        target, original = re.search(pattern, table), re.search(pattern, original_table)
        if not target or not original or target.group(1) != original.group(1):
            raise ValueError("Template icon resource IDs do not match: " + name)
    with zipfile.ZipFile(template) as original:
        xml = original.read(THEMED_ICON)
    with tempfile.TemporaryDirectory(prefix="mystic-icon-", dir=apk.parent) as tmp:
        repaired = Path(tmp) / "repaired.apk"
        with zipfile.ZipFile(apk) as before, zipfile.ZipFile(repaired, "w") as after:
            for entry in before.infolist():
                with before.open(entry) as source, after.open(entry, "w") as output:
                    shutil.copyfileobj(source, output)
            after.writestr(THEMED_ICON, xml, compress_type=zipfile.ZIP_DEFLATED)
        with zipfile.ZipFile(apk) as before, zipfile.ZipFile(repaired) as after:
            if after.testzip() or resource_files(table) - set(after.namelist()):
                raise ValueError("Repaired APK failed resource/ZIP integrity checks")
            for entry in before.infolist():
                if before.read(entry.filename) != after.read(entry.filename):
                    raise ValueError("Icon repair changed an existing APK entry")
        repaired.replace(apk)
    return {
        "restored": [THEMED_ICON],
        "template_sha256": EXPECTED["android_debug.apk"],
        "existing_entries_unchanged": True,
        "all_resource_files_present": True,
    }
