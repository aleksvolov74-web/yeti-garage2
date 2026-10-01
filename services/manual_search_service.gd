class_name ManualSearchService
extends RefCounted

# Local full-text index for the embedded ŠKODA Yeti owner's manual.
# Search stays completely offline and returns page references + short excerpts.

const INDEX_PATH := "res://data/manual_index.json"

const STOP_WORDS := {
    "как": true, "что": true, "где": true, "когда": true, "почему": true,
    "если": true, "или": true, "для": true, "при": true, "это": true,
    "нет": true, "есть": true, "машина": true, "авто": true,
    "автомобиль": true, "меня": true, "мой": true, "моя": true,
    "моей": true, "с": true, "и": true, "в": true, "на": true,
    "не": true, "по": true
}

# Triggers are intentionally short roots so colloquial queries still find the
# wording used in the official manual (e.g. "антифриз" -> "охлаждающая жидкость").
const ALIASES := {
    "антифриз": ["охлаждающая жидкость", "уровень охлаждающей жидкости"],
    "охлажд": ["охлаждающая жидкость", "температура охлаждающей жидкости"],
    "перегрев": ["температура охлаждающей жидкости", "перегрев"],
    "завод": ["пуск двигателя", "запуск двигателя", "стартер", "аккумуляторная батарея"],
    "стартер": ["пуск двигателя", "стартер", "аккумуляторная батарея"],
    "тормоз": ["тормозная система", "тормозные механизмы", "тормозная жидкость"],
    "масл": ["моторное масло", "уровень моторного масла", "температура масла"],
    "аккум": ["аккумуляторная батарея", "запуск двигателя от аккумуляторной батареи"],
    "предохран": ["предохранители", "блок предохранителей"],
    "дворник": ["стеклоочиститель", "стеклоомыватель"],
    "стеклоочист": ["стеклоочиститель", "стеклоомыватель"],
    "кондиц": ["климатическая установка", "climatronic"],
    "печк": ["отопление", "климатическая установка"],
    "фар": ["освещение", "фары", "лампы накаливания"],
    "колес": ["колёса", "шины"],
    "шин": ["колёса", "шины", "давление в шинах"],
    "давлен": ["давление в шинах"],
    "буксир": ["буксировка автомобиля"],
    "ремн": ["ремни безопасности"],
    "подушк": ["подушки безопасности"],
    "топлив": ["топливо", "уровень топлива", "заправка"],
    "бензин": ["топливо", "заправка"],
    "заправ": ["топливо", "заправка"],
    "лампоч": ["контрольные лампы"],
    "ламп": ["контрольные лампы", "лампы накаливания"],
    "сервис": ["индикатор технического обслуживания", "техническое обслуживание"],
    "то": ["индикатор технического обслуживания", "техническое обслуживание"],
    "epc": ["электронная педаль акселератора"],
    "чек": ["система контроля ог", "контрольная лампа"],
    "check": ["система контроля ог", "контрольная лампа"],
    "abs": ["антиблокировочная система"],
    "asr": ["антипробуксовочная система", "контроль тягового усилия"],
    "esc": ["стабилизация курсовой устойчивости", "программа стабилизации"],
    "airbag": ["подушки безопасности"],
    "акп": ["автоматическая коробка передач"],
    "dsg": ["автоматическая коробка передач"],
    "климат": ["климатическая установка", "climatronic"]
}


const SUFFIXES := [
    "иями", "ями", "ами", "ого", "ему", "ому", "ыми", "ими",
    "ая", "яя", "ое", "ее", "ые", "ие", "ий", "ый", "ой",
    "ах", "ях", "ам", "ям", "ов", "ев", "ы", "и", "а", "я",
    "у", "ю", "е", "о"
]

static var _entries: Array = []
static var _source_entries: Array = []
static var _loaded := false

static func page_entry(page: int) -> Dictionary:
    _ensure_loaded()
    if page < 1 or page > _source_entries.size():
        return {}
    var value = _source_entries[page - 1]
    if value is Dictionary:
        return (value as Dictionary).duplicate(true)
    return {}

static func search(query: String, limit: int = 3) -> Array:
    _ensure_loaded()
    var q := _normalize(query)
    if q.length() < 2 or _source_entries.is_empty():
        return []

    var terms := _expanded_terms(q)
    var scored: Array = []
    for entry_value in _source_entries:
        var entry: Dictionary = entry_value
        var page := int(entry.get("page", 0))
        var source_page := int(entry.get("source_document_page", page))
        # Contents/index pages are useful for navigation but noisy in full-text search.
        # After 0.19.22, `page` is the in-app subpage index, while source_page keeps
        # the original 246-page document position. Filter by the original document.
        if source_page < 9 or source_page >= 238:
            continue

        var haystack := str(entry.get("search_text", ""))
        var title_norm := _normalize(str(entry.get("title", "")))
        var score := 0
        if title_norm.contains(q):
            score += 90
        elif haystack.contains(q):
            score += 65

        for term_value in terms:
            var term := str(term_value)
            if term.length() < 3:
                continue
            var phrase := term.contains(" ")
            if title_norm.contains(term):
                score += 36 if phrase else 22
            elif haystack.contains(term):
                score += 24 if phrase else 7

        # Context bonuses for common action/problem queries.
        var chapter := str(entry.get("chapter", ""))
        if _query_has_root(q, "замен") and _query_has_root(q, "колес"):
            if haystack.contains("замена колеса"):
                score += 60
            if chapter == "Самостоятельные действия":
                score += 12
        if _query_has_root(q, "буксир") and haystack.contains("буксировка"):
            score += 45
        if _query_has_root(q, "завод") and (haystack.contains("пуск двигателя") or haystack.contains("запуск двигателя")):
            score += 35
        if _query_has_root(q, "топлив") and (title_norm.contains("топлив") or haystack.contains("указатель уровня топлива")):
            score += 35
        if (q.contains("антифриз") or _query_has_root(q, "охлажд") or _query_has_root(q, "перегрев")) and title_norm.contains("охлаждающей жидкости"):
            score += 70
        if _query_has_root(q, "масл") and title_norm.contains("моторного масла"):
            score += 45
        if _query_has_root(q, "тормоз") and title_norm.contains("тормоз"):
            score += 35
        if (q.contains("epc") or q.contains("чек") or q.contains("check")) and (haystack.contains("электронная педаль акселератора") or haystack.contains("система контроля ог")):
            score += 55

        if score <= 0:
            continue
        var row: Dictionary = entry.duplicate(true)
        row["score"] = score
        row["snippet"] = _make_snippet(str(entry.get("text", "")), terms)
        scored.append(row)

    scored.sort_custom(func(a, b):
        var score_a := int(a.get("score", 0))
        var score_b := int(b.get("score", 0))
        if score_a == score_b:
            return int(a.get("page", 0)) < int(b.get("page", 0))
        return score_a > score_b
    )

    var result: Array = []
    for row in scored:
        if result.size() >= maxi(1, limit):
            break
        result.append(row)
    return result

static func _ensure_loaded() -> void:
    if _loaded:
        return
    _loaded = true
    if not FileAccess.file_exists(INDEX_PATH):
        return
    var raw := FileAccess.get_file_as_string(INDEX_PATH)
    var parsed = JSON.parse_string(raw)
    if parsed is Array:
        _entries = parsed
        var grouped: Dictionary = {}
        var source_order: Array[int] = []
        for entry_value in _entries:
            if not (entry_value is Dictionary):
                continue
            var entry: Dictionary = entry_value
            var source_page := int(entry.get("source_document_page", entry.get("page", 0)))
            if source_page < 1:
                continue
            if not grouped.has(source_page):
                var source_entry: Dictionary = entry.duplicate(true)
                source_entry["page"] = source_page
                source_entry["source_document_page"] = source_page
                source_entry["part"] = 1
                source_entry["part_total"] = 1
                source_entry["blocks"] = []
                source_entry["text"] = ""
                source_entry["search_text"] = ""
                grouped[source_page] = source_entry
                source_order.append(source_page)
            var target: Dictionary = grouped[source_page]
            var blocks: Array = target.get("blocks", [])
            var entry_blocks = entry.get("blocks", [])
            if entry_blocks is Array:
                for block in entry_blocks:
                    blocks.append(block)
            target["blocks"] = blocks
            for field in ["text", "search_text"]:
                var existing := str(target.get(field, ""))
                var addition := str(entry.get(field, ""))
                if addition != "":
                    target[field] = addition if existing == "" else existing + "\n" + addition
        source_order.sort()
        _source_entries.clear()
        for source_page in source_order:
            _source_entries.append(grouped[source_page])

static func _expanded_terms(q: String) -> Array[String]:
    var terms: Array[String] = []
    var raw_tokens := q.split(" ", false)
    if q.length() >= 3:
        _push_unique(terms, q)

    var normalized_tokens: Array[String] = []
    for token_value in raw_tokens:
        var token := str(token_value)
        if token.length() >= 2:
            normalized_tokens.append(token)
        if token.length() < 3 or STOP_WORDS.has(token):
            continue
        _push_unique(terms, token)
        var stem := _stem(token)
        if stem.length() >= 4:
            _push_unique(terms, stem)

    for trigger_value in ALIASES.keys():
        var trigger := str(trigger_value)
        var matched := false
        for token in normalized_tokens:
            if trigger.length() <= 3:
                if token == trigger:
                    matched = true
                    break
            elif token.length() >= 4 and (token.begins_with(trigger) or trigger.begins_with(token)):
                matched = true
                break
        if not matched:
            continue
        for alias_value in ALIASES[trigger]:
            _push_unique(terms, _normalize(str(alias_value)))

    # Compound intent gets a precise phrase instead of generic expansion.
    if _query_has_root(q, "замен") and _query_has_root(q, "колес"):
        _push_unique(terms, "замена колеса")
    if _query_has_root(q, "замен") and _query_has_root(q, "ламп"):
        _push_unique(terms, "замена ламп")
    return terms

static func _query_has_root(q: String, root: String) -> bool:
    for token_value in q.split(" ", false):
        var token := str(token_value)
        if token.begins_with(root):
            return true
    return false

static func _push_unique(values: Array[String], value: String) -> void:
    var clean := _normalize(value)
    if clean.length() >= 2 and not values.has(clean):
        values.append(clean)

static func _stem(word: String) -> String:
    for suffix_value in SUFFIXES:
        var suffix := str(suffix_value)
        if word.ends_with(suffix) and word.length() - suffix.length() >= 4:
            return word.substr(0, word.length() - suffix.length())
    return word

static func _make_snippet(text: String, terms: Array[String]) -> String:
    var clean := text.replace("\n", " ").replace("\r", " ")
    while clean.contains("  "):
        clean = clean.replace("  ", " ")
    clean = clean.strip_edges()
    if clean == "":
        return ""

    var lower := clean.to_lower().replace("ё", "е")
    var best_pos := -1
    for term_value in terms:
        var term := str(term_value)
        if term.length() < 4:
            continue
        var pos := lower.find(term)
        if pos >= 0 and (best_pos < 0 or pos < best_pos):
            best_pos = pos
    if best_pos < 0:
        best_pos = 0

    var start := maxi(0, best_pos - 72)
    var length := mini(220, clean.length() - start)
    var snippet := clean.substr(start, length).strip_edges()
    if start > 0:
        snippet = "…" + snippet
    if start + length < clean.length():
        snippet += "…"
    return snippet

static func _normalize(value: String) -> String:
    var result := value.strip_edges().to_lower().replace("ё", "е")
    var separators := [".", ",", ";", ":", "!", "?", "(", ")", "[", "]", "{", "}", "\"", "'", "«", "»", "/", "\\", "-", "—", "–", "\n", "\r", "\t", "•", "›"]
    for separator_value in separators:
        result = result.replace(str(separator_value), " ")
    while result.contains("  "):
        result = result.replace("  ", " ")
    return result.strip_edges()
