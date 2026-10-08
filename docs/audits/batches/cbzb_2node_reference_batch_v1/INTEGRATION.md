# Partial CBZB two-node reference integration

Base: `172652ac9bb6c40d1314e2653fb5f89a85330081`. Version remains 0.20.29 / 69.

Only `engine_bottom_end` and `boost_group` change. Both are REFERENCE_ONLY. Four-cylinder bottom-end and electric V465 component categories were visually checked on the supplied originals and numbered overlays; these synthetic reference visuals do not establish exact factory geometry, VIN revision or installation routing.

The original manifest is preserved byte for byte. `integration_history.json` records the user-authorized path override: engine_bottom_end uses `engine_bottom_end_cbzb_reference_v1.webp`, preserving the original shared `engine_bottom_end.webp` and all engine_block_group data. boost_group has no other node sharing its image. One physical WebP is added, one replaced; no added diagram coverage or markers. All 10 batch coordinates change, existing part IDs/numbers/names remain.

Totals: 24 sections, 90/90 images, 376 markers, 55 VERIFIED_ARCHITECTURE / 35 REFERENCE_ONLY. The three remaining FAIL_ARCHITECTURE nodes are engine_block_group, engine_upper_end, cylinder_head_group. The immutable historical review and its previous 33 coordinate fixes are retained.

Validation runs strict whole-catalog/image/history comparisons, catalog/fault routes, Godot import/startup, rendered 360x780 and 420x780 UI, all 10 replacement marker touches and part-row selections, focus/search routes, zoom/pan/fit/numbers and scroll. Desktop synthetic touch checks do not replace a physical Android device test. No connected Android device is available; real keyboard and system bars remain untested.

The APK artifact is explicitly labelled CBZB-2node-PARTIAL. It is for device review, not a release or a claim that the full catalog has been corrected.
