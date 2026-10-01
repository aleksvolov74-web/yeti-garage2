# Yeti Garage 0.19.17-local — width + manual reader

- Android width: `stretch/aspect=expand` enabled; dashboard uses one adaptive MarginContainer with 14 px side gutters.
- Main page: vertical swipe remains available even on tall devices, so content cannot become hard-clipped by system bars.
- Manual: every page/chapter turn resets scroll to the true top after layout, not only before layout.
- Manual: scroll extent is recalculated across four deferred Android layout passes (wrap -> nested controls -> figures -> range).
- Manual: final content height gets +220 px reserve plus a 140 px in-content tail so the last line/figure can be lifted above the Android navigation area.
- Manual resize recalculates extent without unexpectedly jumping the reader to the top.
