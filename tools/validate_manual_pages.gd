extends SceneTree

var errors: Array[String] = []
var rows: Array = []
var app: Control

func frames(count: int) -> void:
    for index in range(count):
        await process_frame

func visible_popup() -> PopupPanel:
    for window in root.get_embedded_subwindows():
        if window is PopupPanel and window.visible:
            return window
    return null

func _initialize() -> void:
    await process_frame
    ProjectSettings.set_setting("application/testing/mobile_ui", true)
    root.content_scale_size = Vector2i.ZERO
    root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    root.gui_embed_subwindows = true
    app = load("res://scenes/app/app.tscn").instantiate()
    root.add_child(app)
    await frames(8)
    var manual = load("res://services/manual_search_service.gd")
    var entries: Array = []
    for page in range(1, app.OFFICIAL_MANUAL_TOTAL_PAGES + 1):
        entries.append(manual.page_entry(page))
    for viewport in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(420, 780), Vector2i(430, 932)]:
        root.size = viewport
        DisplayServer.window_set_size(viewport)
        await frames(6)
        for entry in entries:
            var page := int(entry.page)
            app.call("_open_official_manual", page)
            await frames(20)
            var popup := visible_popup()
            if popup == null:
                errors.append("missing page %d" % page)
                continue
            var scrolls := popup.find_children("*", "ScrollContainer", true, false)
            var scroll := scrolls[0] as ScrollContainer
            var margin := scroll.get_child(0) as MarginContainer
            var content := margin.get_child(0) as VBoxContainer
            var labels := content.find_children("*", "Label", true, false)
            # Last real textual block precedes the footer. Retain its full text as evidence.
            var last_text: Label = null
            for label in labels:
                if label.get_theme_font_size("font_size") >= 15 and not label.text.strip_edges().is_empty():
                    last_text = label
            var bar := scroll.get_v_scroll_bar()
            scroll.scroll_vertical = int(maxf(0, bar.max_value - bar.page))
            await frames(3)
            var ok := last_text != null
            if last_text != null:
                var rect := last_text.get_global_rect()
                var visible := scroll.get_global_rect()
                ok = rect.end.y <= visible.end.y + 2 and last_text.get_visible_line_count() >= last_text.get_line_count()
                if not ok:
                    errors.append("last text clipped page %d at %s" % [page, viewport])
            rows.append({"page": page, "viewport": str(viewport), "last_text": last_text.text if last_text != null else "", "bottom_reachable": ok, "scroll_max": bar.max_value - bar.page})
            if page in [143, 145, 146]:
                await RenderingServer.frame_post_draw
                DirAccess.make_dir_recursive_absolute("res://build/ux/manual")
                root.get_texture().get_image().save_png("res://build/ux/manual/%d_%d_%d.png" % [viewport.x, viewport.y, page])
            popup.hide()
            await frames(2)
        print("MANUAL_VIEWPORT_CHECKED: ", viewport, " pages=", entries.size())
        # Exercise each real chapter button, not only the helper method.
        for section in app.OFFICIAL_MANUAL_SECTIONS:
            app.call("_open_official_manual")
            await frames(20)
            var popup := visible_popup()
            if popup == null:
                errors.append("missing contents")
                continue
            var selected: Button = null
            for button in popup.find_children("*", "Button", true, false):
                if button.text == section.title:
                    selected = button
                    break
            if selected == null:
                errors.append("missing chapter " + str(section.title))
            else:
                selected.pressed.emit()
                await frames(20)
                var expected := "стр. %d" % int(section.page)
                var found := false
                for label in popup.find_children("*", "Label", true, false):
                    if label.text.contains(expected): found = true
                # Reader label can use the printed page instead of document page.
                var expected_title: String = str(load("res://services/manual_search_service.gd").page_entry(int(section.page)).get("title", ""))
                for label in popup.find_children("*", "Label", true, false):
                    if label.text == expected_title: found = true
                if not found: errors.append("wrong chapter route " + str(section.title))
            popup.hide()
            await frames(2)
    DirAccess.make_dir_recursive_absolute("res://build/ux")
    var file := FileAccess.open("res://build/ux/manual_pages.json", FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks": rows, "errors": errors, "physical_android": "NOT_RUN"}, "  "))
    file.close()
    for error in errors: print("MANUAL_FAILURE: ", error)
    print("MANUAL_PAGES_VALIDATION=" + ("PASS" if errors.is_empty() else "FAIL"))
    quit(0 if errors.is_empty() else 1)
