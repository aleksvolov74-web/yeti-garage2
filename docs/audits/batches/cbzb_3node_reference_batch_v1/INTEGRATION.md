# CBZB-5node-VALIDATION — integration pending runtime validation

Base validation commit: ff73f211e73db4d3f8f72838eebc97eb0a57810b.
Version preserved: 0.20.29 / 69. Local and remote main were not changed.
Source ZIP: /storage/emulated/0/Download/YetiGarage_CBZB_3node_REFERENCE_ONLY_batch_v1.zip.
All seven SHA256SUMS entries passed, including the copied WebP bytes.

Only engine_block_group, engine_upper_end and cylinder_head_group catalog and active audit records were updated. Each uses its own supplied WebP and REFERENCE_ONLY. Before records are retained in integration_history.json; original review and previous two-node integration remain unchanged. Ten existing marker positions match the manifest; identifiers and numbers are preserved. Original WebP views were opened and each coordinate compared with its named visible component.

Data validation PASS: 24 sections, 90 nodes, 90 images, 0 missing images, 376 markers; 52 VERIFIED_ARCHITECTURE, 38 REFERENCE_ONLY, 0 active FAIL_ARCHITECTURE. Images added 0, assignments replaced 3, physical WebP added 3, physical WebP replaced 0, markers added 0, repositioned 10, new part IDs 0. Protected images and all unrelated catalog records match the base commit. git diff --check and JSON parsing passed.

Existing runtime validators now include all five corrected nodes, portrait dimensions for the three new images, and expected 52/38 totals. Workflow dispatch accepts CBZB-5node-VALIDATION. These tests have NOT passed locally yet.

BLOCKER: local Godot 4.7.2 Linux ARM64 aborts with signal 11 during --headless --import in this Alpine/Android environment. The retry with --text-driver Dummy also aborts. Runtime catalog validation subsequently reports TechnicalDiagramCanvas is undeclared because import did not produce the global script class cache. Logs: /tmp/yeti-3node-import.log, /tmp/yeti-3node-import-verbose.log, /tmp/yeti-3node-import-nofont.log, /tmp/yeti-3node-import-dummy.log, /tmp/yeti-3node-fault.log.

Startup, rendered UI at 360x780 / 420x780, marker interaction, cards, search, zoom/pan/reset, dropdown, scrolling/focus, diagnostics/warning UI and runtime regressions are NOT VALIDATED. No Android export, commit, push or workflow dispatch was performed after the failed import. No APK artifact or APK SHA256 is available. Physical Android: NOT TESTED (adb devices returned no device). Native keyboard and system bars: NOT TESTED.

Existing historical marker findings outside these three nodes remain unchanged; this batch is not a new global audit and does not certify exact geometry, VIN applicability or repair procedures.

## Authorized CI recovery checkpoint

User explicitly authorized a technical validation-branch checkpoint before runtime tests, solely to run the unchanged Godot 4.7.2 container on Ubuntu 24.04 x86_64. CI must pass import and all mandatory validators before Android export. The previous blocked state above describes the local attempt, not a CI result.

Local executable: /tmp/godot-4.7.2/Godot_v4.7.2-stable_linux.arm64.
Reported version: 4.7.2.stable.official.ed1daf0bf.
Host architecture: aarch64; Alpine tools within Android environment.
Failed command: /tmp/yeti-godot-run --headless --path . --import.
The wrapper invokes /tmp/yeti-glibc/usr/glibc-compat/lib/ld-linux-aarch64.so.1 --library-path LIBRARIES /tmp/godot-4.7.2/Godot_v4.7.2-stable_linux.arm64 with those arguments. LIBRARIES comprises /tmp/yeti-glibc/usr/glibc-compat/lib, /tmp/yeti-deb/usr/lib/aarch64-linux-gnu, /tmp/yeti-deb/freetype/usr/lib/aarch64-linux-gnu and each /tmp/yeti-deb/extracted/*/usr/lib/aarch64-linux-gnu directory.
Exit status recorded by the execution tool: 134. Godot's crash handler reports signal 11; the process then aborts. A verbose retry (--headless --display-driver headless --audio-driver Dummy --path . --editor --quit --verbose) reached EditorTheme generation and editor help-cache regeneration. Last messages listed unexposed internal editor classes (AnimationMarkerEdit, AnimationNodeBlendSpace1DEditor, AnimationNodeStateMachineEditor, etc.); no specific project resource was identified in the crash trace.
Memory at recovery: total 7622 MiB, available 2134 MiB, free 422 MiB; swap total 4192 MiB, free 2322 MiB. Disk available 31.1 GiB. These readings are snapshots, not proof of the crash cause. Root cause remains unestablished; do not attribute it to a project resource or memory exhaustion without evidence.
No additional local imports or deletion of .godot were attempted during recovery. CI uses a fresh checkout, since .godot is untracked/ignored. The October 6 ZIP, runtime logs and temporary files are excluded from the checkpoint.
