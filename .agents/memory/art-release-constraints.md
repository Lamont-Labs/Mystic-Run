---
name: Art and release constraints
description: Owner-stated artwork rights and Android release requirements.
---

The approved character concept is permitted for “Game use, noncommercial only.”

**Why:** The owner explicitly specified this rights limitation.

**How to apply:** Keep this restriction on concept-derived art and distributions.

Preserve the existing permanent replacement signing identity. Never generate a
new key. The owner wants future approved releases to build, sign, verify, and
publish automatically, without recurring owner approval or manual signing tasks.

**Why:** The owner explicitly requested continuity of the installation identity
and elimination of repetitive release operations.

**How to apply:** Treat a verified protected-main merge as release approval;
keep credentials isolated and compatibility claims conditional on the installed
package, certificate, and version. Never modify the phone installation.

The owner confirmed successfully installing and launching v0.6.2 Build 2009 on
their Samsung Android phone, with the updated artwork visible and working. This
is the canonical installation baseline; all subsequent builds must update it or
its successors directly, without uninstalling or resetting the game.

**Why:** The owner explicitly confirmed installation and required this baseline
to supersede earlier uncertainty about their installed identity.

**How to apply:** Follow the locked identity and release rules in `AGENTS.md`.
Do not keep asking for the old APK or report that the baseline is unconfirmed.
Distinguish verified update eligibility from an actual test of each future APK
on the physical phone.
