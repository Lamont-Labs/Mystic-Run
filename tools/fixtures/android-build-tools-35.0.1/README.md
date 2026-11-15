# Android Build-Tools 35.0.1 output fixtures

These small text excerpts preserve public output from the repository's pinned
Android Build-Tools 35.0.1 checks. The known-good resource and XML output came
from the icon-fixed build; the missing-themed-icon resource table and warning
came from the preceding build, whose table still referenced the absent XML
file. The `apksigner` report is reduced to the scheme and public certificate
lines needed by the verifier.

The resource excerpts use the actual commands
`aapt2 dump resources <apk>` and
`aapt2 dump xmltree --file <path> <apk>`. No APK, private signing material,
phone data, or credentials are stored here. The two legacy `aapt` files are
negative controls: one contains a truncated legacy-style table and one contains
only whitespace, both of which must fail closed instead of looking like a
successful empty resource parse.
