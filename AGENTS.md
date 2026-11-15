# MysticRun standing development instructions

## Canonical Android installation baseline

The owner confirmed that **MysticRun v0.6.2 Build 2009** was successfully installed
and launched on their Samsung Android phone, and the updated artwork is visible
and working. This is the canonical installation baseline for all future work.

- Repository: `Lamont-Labs/Mystic-Run`; release branch: `main`.
- Baseline release: `v0.6.2-build2009`.
- Package ID: `com.lamontlabs.knightgargoylewitch.dev`.
- Signing certificate SHA-256:
  `8ccd240d320a0ac8568581d5c7e005538033681d8b882058d673c80719dfd859`.
- Installed baseline version code: `2009`.
- Every future APK must have a version code greater than **2009 and every
  previously published version**, preserving the package and signing identity.

Never change the package ID, regenerate signing keys, introduce a new certificate,
require uninstalling, reset the game, or discard saves. Preserve all game source,
assets, artwork, gameplay, and development progress.

Push completed, verified changes to GitHub. Use the existing automated GitHub
Android release workflow for every signed APK; do not sign production APKs with
Replit-generated keys. Keep all keys, passwords, and backups out of Git and
release assets. Do not introduce recurring manual deployment approvals.

Before automatic publication, GitHub must verify package identity, the pinned
certificate, increasing version code, APK signatures/integrity/alignment, and
baseline update eligibility. Publish successful releases automatically and
provide the direct GitHub APK download URL.

The owner-confirmed Build 2009 installation supersedes earlier uncertainty about
the installed signing identity. Static verification establishes Android update
eligibility, not a physical-device test of each future build. Never claim such a
test was performed without evidence.

Do not rebuild or publish solely to acknowledge these instructions. For explicit
no-APK maintenance changes, use `[skip android release]` in the main merge commit;
gameplay checks still run, while APK compilation/signing/publication are skipped.
Do not use this marker for ordinary completed game changes intended for release.

## Artwork rights

The owner permits the approved concept artwork for **noncommercial game use
only**. Preserve that restriction for derivative art and distributions.
