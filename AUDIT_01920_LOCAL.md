# 0.19.20 local — manual scroll extent fix

## Reproduced from screen recording
The page transition itself is correct: pages 161→162→163… open at the top.
The failure is vertical extent: on long pages the scroll reaches its maximum while visible content still continues below the bottom edge. Examples in the supplied recording include pages 161, 162 and 164.

## Root cause addressed
The reader relied on the cached minimum/size of the top VBox. On Android, wrapped Labels nested in warning/note/figure cards can finish wrapping after the parent container's scroll range has already been computed. Several nested manual-card controls also did not explicitly expand horizontally, which makes wrapped-height propagation less reliable.

## Changes
- Removed the old deferred multi-pass height heuristic.
- Wait for real process frames before locking the page extent.
- Measure the bottom of all actually drawn descendants, not just the top VBox cached size.
- Force the measured height + 180 px runway on the actual scroll content child.
- Reset stale custom height before every page render.
- Cancel stale layout coroutines when a different page is opened.
- Added horizontal EXPAND_FILL to warning/note/eco cards and figure card internals so wrapped label heights propagate correctly.
- Page navigation still resets to top, but this is not treated as the cause of the clipping bug.
- Home screen remains non-scrollable from 0.19.18.

## Repro check after build
Open chapter “Правила вождения”. On pages 161, 162, 164, 167 scroll to the absolute bottom. The final card/text must be fully visible and there must be extra blank runway above the Android navigation bar. Then use next-page arrow: the new page must open at top.
