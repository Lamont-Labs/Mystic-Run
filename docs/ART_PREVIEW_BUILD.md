# Isolated Android art preview

The separately installed **Mystic Run Art Preview** uses `com.lamontlabs.knightgargoylewitch.artpreview`. Its development key is independent of the existing owner game key. It keeps its own save data and does not update or replace `com.lamontlabs.knightgargoylewitch.dev`.

The explicit exporter option is `tools/build_android.py --art-preview`. The default exporter retains the owner package and now checks its established signing certificate. An isolated preview is not an owner-signed update or a Google Play release.

The material checkpoint and actual engine review are in `MATERIAL_FINISH_REFINEMENT.md`. This record is committed before exporting the reviewed source. Verified artifact metadata will be added only after the APK exists and passes the package, signature, ZIP and alignment checks.

The exporter checks the preserved certificate for the selected variant before export. It temporarily applies the APK identity and version, preserves the Play preset, and restores both source configuration files after success or failure. Three regression tests cover successful export configuration, failed export followed by an owner export, and malformed preset rejection. Private key material remains outside Git.
