# Automatic verified Android development releases

## Approval and trust

A pull request merged into protected `main` is the release approval. Main requires
the GitHub Actions `core` check, an up-to-date branch, a pull request, and resolved
conversations. Administrators are subject to protection; force pushes and deletion
are disabled. No additional human deployment review is needed.

The Android workflow reacts only to successful **push** executions of Gameplay core
checks on canonical main, or a manual main retry. Before accessing the signing
environment it queries GitHub to verify the current protected main SHA and a
successful canonical gameplay run for that exact SHA. PR and fork events cannot
reach signing. Stale completion events fail closed.

Both environments allow the `main` branch only, not tags or other branches.
Signing secrets stay exclusively in `android-signing`, never repository secrets.
Only the signing job references them. It restores the existing key into a private
temporary file after compilation and removes it even on failure. Checkout does not
persist credentials. The publisher has release-write permission but no signing
secrets; compilation and signing have only repository-read permission.

Changes to main code or trusted workflows remain a security-sensitive operation.
Environment branch restrictions cannot independently distinguish two workflows on
the same trusted branch. Required passing checks and protected-main PR merges are
the trust boundary; repository administrators must protect their accounts.

## Build and publication

The release workflow is serialized without cancelling in-progress releases.
Version codes exceed the workflow baseline, every known published build tag, and
committed release records. Publication checks monotonicity again, failing closed
if another publisher has already used a newer code. Failed reruns do not replace
an existing release. Retry the workflow to allocate a fresh code.

Every build runs gameplay core and Android contract tests, compiles unsigned,
and signs with the existing permanent alias and pinned certificate. The signer
verifies package/version, v2/v3 signatures, APK ZIP/resource integrity, unchanged
game payload, and ZIP/native 16 KB alignment. Unsigned and signed inputs are kept
as Actions artifacts for 30 days.

A separate job downloads the same run's signed artifact, independently checks
its certificate, package/version, signatures, resources, ZIP/native alignment,
hash, and provenance, then publishes a uniquely versioned GitHub prerelease.
It downloads the published APK and checks its SHA-256 against the verified input.
The release contains the APK, public manifest, signature report, and SHA256SUMS.
No signing key, password, or backup is a release asset.

The former manual reconstruction workflow remains available for historical
recovery; new builds do not require a committed reconstruction record.

## Installation compatibility

Package: `com.lamontlabs.knightgargoylewitch.dev`

Permanent replacement certificate SHA-256:
`8ccd240d320a0ac8568581d5c7e005538033681d8b882058d673c80719dfd859`

An APK can update an installation only when the package and signing identity match
and its version code is higher. This certificate cannot update the older
legacy-key installation. The phone's installed certificate/version has not been
observed, so compatibility with that particular installation is not confirmed.
No workflow uninstalls, installs, clears data, or otherwise touches a phone.
Noncommercial concept-art rights continue to apply.
