extends SceneTree

var errors: Array[String] = []

func frames(count: int) -> void:
    for index in range(count): await process_frame

func _initialize() -> void:
    await process_frame
    ProjectSettings.set_setting("application/testing/mobile_ui", true)
    root.content_scale_size = Vector2i.ZERO
    root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    root.gui_embed_subwindows = true
    var storage := root.get_node("Storage")
    var sample: Dictionary = storage.call("demo_data")
    sample.saved_faults = [{"id":"glyph-check", "warning_id":"abs", "title":"ABS — сохранённая неисправность", "status":"NEW"}]
    storage.set("data", sample)
    var app: Control = load("res://scenes/app/app.tscn").instantiate()
    root.add_child(app)
    await frames(8)
    for viewport in [Vector2i(360,780), Vector2i(390,844), Vector2i(420,780), Vector2i(430,932)]:
        root.size = viewport
        DisplayServer.window_set_size(viewport)
        await frames(10)
        for label in app.find_children("*", "Label", true, false):
            if not label.is_visible_in_tree(): continue
            if label.text.contains("руб."):
                for character in "руб.":
                    if not label.get_theme_font("font").has_char(character.unicode_at(0)):
                        errors.append("missing currency glyph")
            if label.get_global_rect().end.x > viewport.x + 1:
                errors.append("home horizontal overflow at " + str(viewport))
        await RenderingServer.frame_post_draw
        DirAccess.make_dir_recursive_absolute("res://build/ux/home-glyphs")
        root.get_texture().get_image().save_png("res://build/ux/home-glyphs/%dx%d.png" % [viewport.x,viewport.y])
    for error in errors: print("HOME_UX_FAILURE: ", error)
    print("HOME_UX_VALIDATION=" + ("PASS" if errors.is_empty() else "FAIL"))
    quit(0 if errors.is_empty() else 1)
