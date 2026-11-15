# MysticRun — isolated Unity engine evaluation

**Status: source prepared; Unity execution is BLOCKED, not verified playable.**

This does not replace or migrate the Godot game. It does not contain the rejected
Godot cutout deformation or the experimental fourteen-part rig. The source
provides a small native Unity movement evaluation and a static approved Knight
reference; a polished Unity-animated Knight has **not** been authored or tested.

## Exact prerequisite

Unity Editor **6000.3.28f1** (`8f082d2fe476`), a legitimately activated license,
and access to the editor/build machine are required. No editor is available on
the current workspace PATH. No Unity integration was returned by catalog search.

Unity's official Personal documentation requires activation through **Unity
Hub**; the documented command-line activation procedure does not apply to
Personal. Personal eligibility must also be confirmed. Do not put Unity
passwords, license files, keystores or signing backups into this repository.
No paid plan or service has been requested or purchased.

No multi-gigabyte editor download was started without an activation path.
Unattended, no-paid-services GitHub **Unity** builds remain unverified. The
existing Godot Android release workflow has not been changed.

## Included source

- Unity's `CharacterController` handles movement/collision; `Mathf.SmoothDamp`
  handles lane response rather than porting the custom Godot steering class.
- Unity Input System Enhanced Touch and keyboard feed a small, separately
  tested latest-intent buffer. These are evaluation swipe controls, not a
  promise that production touch/combat mappings have been migrated.
- Buffered jump, coyote window, crouch clearance and feet-preserving capsule
  resize are prepared in source. Their Unity behavior is **untested**.
- A native Cinemachine follow camera is prepared.
- Unity 2D Animation is pinned for subsequent authoring, but the current
  reference `SpriteRenderer` is explicitly **static**. Do not claim this is a
  complete character rig or animation set.
- Editor setup creates a textured collision-test surface and two diagnostic
  fixtures. These are not a premium Castle Heights rebuild.
- An unconditional Android build guard prevents accidental debug-key APKs
  until an approved release integration and save migration are implemented.

Pinned packages were checked against Unity's 6000.3 documentation and registry:
2D Animation **13.0.6**, Cinemachine **3.1.7**, Input System **1.20.1**.

## Open after an authorized editor is available

1. From the repository root, run `python3 tools/prepare_unity_evaluation.py`.
   This copies and hash-verifies only two approved public artwork files.
2. In Unity Hub, add **this directory**, not the repository root, and open it
   with the pinned editor. Let the Package Manager resolve the dependencies.
3. Enable **Input System Package (New)** under Player Settings → Active Input
   Handling if Unity requests it; restart the editor when required.
4. Choose **MysticRun → Prepare Engine Evaluation Scene**.
5. Press Play. Arrows/A,D steer; Space/Up jumps; Down/S slides. On supported
   touch hardware, swipe horizontally/up/down.

The editor-generated scene and materials should be committed only after an
actual Unity import, compilation and visual test. Preserve generated `.meta`
files when that first verified import is performed.

## What has actually been verified

```sh
dotnet run --project tests/unity-intent/UnityIntentChecks.csproj --configuration Release
python3 tools/check_unity_readiness.py --report tests/evidence/unity-readiness.json
```

The .NET console harness compiles the **portable `RunnerIntent.cs` only**.
It checks eighteen intent/buffering/lane contracts. It does not compile the
Unity-dependent scripts or validate native physics, Cinemachine, Enhanced Touch,
rendering, animation, performance or Android. The similarly named GitHub
workflow is deliberately labeled **portable source checks — not engine validation**.

## Android and save protection

The existing Godot game and its saves remain untouched. This source never reads
or writes owner progress and never accesses signing credentials.

The future Unity app must retain:

- Package: `com.lamontlabs.knightgargoylewitch.dev`.
- Certificate SHA-256:
  `8ccd240d320a0ac8568581d5c7e005538033681d8b882058d673c80719dfd859`.
- A version code greater than 2009 **and every previously published release**.

Identical package/certificate are necessary for update eligibility, but do not
migrate save formats or engine-specific file locations. Explicitly read and
convert the old Godot saves before enabling production release. Continue to use
the trusted existing GitHub signing/publishing boundary; never auto-generate a
debug key or require uninstalling the installed app.

All copied concept art remains restricted to **noncommercial game use**.

## Official references

- https://unity.com/releases/editor/whats-new/6000.3.28f1
- https://docs.unity.com/en-us/engine/6000.3/manual/packages-list/packages-all/pack-safe/com-unity-2d-animation
- https://docs.unity.com/en-us/engine/6000.3/manual/packages-list/packages-all/pack-safe/com-unity-cinemachine
- https://docs.unity.com/en-us/engine/6000.3/manual/packages-list/packages-all/pack-safe/com-unity-inputsystem
- https://docs.unity.com/en-us/engine/6000.3/manual/get-started/install-and-upgrade/licenses-and-activation/license-activation-methods
