#!/usr/bin/env python3
"""Split oversized ŠKODA Yeti manual entries into stable in-app subpages.

The source manual keeps its original printed page number in `manual_page`.
`page` becomes the in-app document index after splitting. Long text blocks are
split only at safe sentence/bullet boundaries; figures stay intact.
"""
from __future__ import annotations

import json
import math
import re
import sys
from pathlib import Path

TARGET_COST = 1500.0
SPLIT_THRESHOLD = 1800.0

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "data" / "manual_index.json"

NOTICE_TITLES = {
    "warning": "ВНИМАНИЕ",
    "caution": "ОСТОРОЖНО",
    "note": "Примечание",
    "eco": "Окружающая среда",
}


def is_continuation(current_text: str, next_text: str) -> bool:
    current_text = current_text.strip()
    next_text = next_text.strip()
    if not current_text or not next_text:
        return False
    if current_text[-1] in ".!?;:» )":
        return False
    first = next_text[0]
    return first.lower() == first and first.upper() != first


def normalize_bullet_continuations(blocks: list[dict]) -> list[dict]:
    result: list[dict] = []
    i = 0
    while i < len(blocks):
        current = dict(blocks[i])
        if current.get("type") == "bullet":
            merged = str(current.get("text", "")).strip()
            while i + 1 < len(blocks):
                nxt = blocks[i + 1]
                if nxt.get("type") != "paragraph":
                    break
                nxt_text = str(nxt.get("text", "")).strip()
                if not is_continuation(merged, nxt_text):
                    break
                merged = f"{merged} {nxt_text}".strip()
                i += 1
            current["text"] = merged
        result.append(current)
        i += 1
    return result


def split_text(text: str, max_chars: int) -> list[str]:
    text = " ".join(text.split()).strip()
    if not text or len(text) <= max_chars:
        return [text] if text else []

    # Warning/note blocks often contain several source bullets separated by ■.
    if "■" in text:
        prefix, *raw_parts = text.split("■")
        units: list[str] = []
        if prefix.strip():
            units.append(prefix.strip())
        units.extend("■" + part.strip() for part in raw_parts if part.strip())
    else:
        units = [
            piece.strip()
            for piece in re.split(r"(?<=[.!?])\s+|(?<=;)\s+", text)
            if piece.strip()
        ]

    # A source block can have no punctuation at all. Fall back to word chunks.
    if len(units) == 1 and len(units[0]) > max_chars:
        words = units[0].split()
        units = []
        current: list[str] = []
        current_len = 0
        for word in words:
            extra = len(word) + (1 if current else 0)
            if current and current_len + extra > max_chars:
                units.append(" ".join(current))
                current = [word]
                current_len = len(word)
            else:
                current.append(word)
                current_len += extra
        if current:
            units.append(" ".join(current))

    packed: list[str] = []
    current = ""
    for unit in units:
        if not current:
            current = unit
        elif len(current) + 1 + len(unit) <= max_chars:
            current += " " + unit
        else:
            packed.append(current)
            current = unit
    if current:
        packed.append(current)

    final: list[str] = []
    for piece in packed:
        if len(piece) > int(max_chars * 1.35):
            final.extend(split_text(piece, max_chars))
        else:
            final.append(piece)
    return final


def explode_large_blocks(blocks: list[dict]) -> list[dict]:
    result: list[dict] = []
    for block in blocks:
        block_type = str(block.get("type", "paragraph"))
        text = str(block.get("text", "")).strip()
        if block_type in {"warning", "caution", "note", "eco"}:
            max_chars = 310
        elif block_type in {"paragraph", "bullet"}:
            max_chars = 380
        else:
            max_chars = 999999

        if not text or len(text) <= max_chars or block_type not in {
            "paragraph", "bullet", "warning", "caution", "note", "eco"
        }:
            result.append(dict(block))
            continue

        parts = split_text(text, max_chars)
        for part_index, part in enumerate(parts):
            new_block = dict(block)
            new_block["text"] = part
            if block_type in NOTICE_TITLES and part_index > 0:
                base_title = str(block.get("title", "")).strip() or NOTICE_TITLES[block_type]
                new_block["title"] = f"{base_title} — продолжение"
            elif block_type == "bullet" and part_index > 0:
                # One logical bullet may need several blocks; only the first gets a dot.
                new_block["type"] = "paragraph"
            result.append(new_block)
    return result


def block_cost(block: dict) -> float:
    block_type = str(block.get("type", "paragraph"))
    text = str(block.get("text", "")).strip()
    length = len(text)

    if block_type == "figure_ref":
        source_w = max(1.0, float(block.get("image_width", 330)))
        source_h = max(1.0, float(block.get("image_height", 180)))
        display_h = max(108.0, min(230.0, 318.0 * source_h / source_w))
        return display_h + 82.0
    if block_type == "heading":
        return 28.0 * max(1, math.ceil(length / 34.0)) + 8.0
    if block_type == "bullet":
        return 24.0 * max(1, math.ceil(length / 34.0)) + 6.0
    if block_type in NOTICE_TITLES:
        return 62.0 + 21.0 * max(1, math.ceil(length / 41.0))
    return 25.0 * max(1, math.ceil(length / 37.0)) + 6.0


def chunk_blocks(blocks: list[dict]) -> list[list[dict]]:
    chunks: list[list[dict]] = []
    current: list[dict] = []
    current_cost = 0.0

    for block in blocks:
        cost = block_cost(block) + 10.0
        block_type = str(block.get("type", "paragraph"))

        # Do not strand a section heading as the last thing on a subpage.
        if block_type == "heading" and current and current_cost > TARGET_COST * 0.62:
            chunks.append(current)
            current = []
            current_cost = 0.0

        if current and current_cost + cost > TARGET_COST:
            chunks.append(current)
            current = []
            current_cost = 0.0

        current.append(block)
        current_cost += cost

    if current:
        chunks.append(current)

    for index in range(len(chunks) - 1):
        while len(chunks[index]) > 1 and chunks[index][-1].get("type") == "heading":
            chunks[index + 1].insert(0, chunks[index].pop())

    # Heading protection can intentionally start a new chunk early. If two
    # neighboring chunks still fit within the target together, merge them back so
    # we do not create silly one-heading/one-paragraph subpages.
    index = 0
    while index < len(chunks) - 1:
        left_cost = sum(block_cost(block) + 10.0 for block in chunks[index])
        right_cost = sum(block_cost(block) + 10.0 for block in chunks[index + 1])
        if left_cost + right_cost <= SPLIT_THRESHOLD:
            chunks[index] = chunks[index] + chunks[index + 1]
            del chunks[index + 1]
            if index > 0:
                index -= 1
        else:
            index += 1

    return chunks or [[]]


def normalize_search(value: str) -> str:
    value = value.strip().lower().replace("ё", "е")
    separators = [
        ".", ",", ";", ":", "!", "?", "(", ")", "[", "]", "{", "}",
        '"', "'", "«", "»", "/", "\\", "-", "—", "–", "\n", "\r", "\t", "•", "›", "■"
    ]
    for separator in separators:
        value = value.replace(separator, " ")
    while "  " in value:
        value = value.replace("  ", " ")
    return value.strip()


def blocks_text(blocks: list[dict]) -> str:
    return " ".join(str(block.get("text", "")).strip() for block in blocks if str(block.get("text", "")).strip())


def main() -> int:
    data = json.loads(INDEX.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise SystemExit("manual_index.json is not an array")
    if data and "source_document_page" in data[0]:
        raise SystemExit("manual_index.json already contains split-page metadata; refusing to split twice")

    virtual_pages: list[dict] = []
    source_to_first_virtual: dict[int, int] = {}
    split_sources: list[tuple[int, int | None, int]] = []

    for source_entry in data:
        source_page = int(source_entry.get("page", len(source_to_first_virtual) + 1))
        blocks_value = source_entry.get("blocks", [])
        blocks = [dict(block) for block in blocks_value if isinstance(block, dict)] if isinstance(blocks_value, list) else []
        prepared = explode_large_blocks(normalize_bullet_continuations(blocks))
        total_cost = sum(block_cost(block) + 10.0 for block in prepared)
        chunks = chunk_blocks(prepared) if total_cost > SPLIT_THRESHOLD else [prepared]

        source_to_first_virtual[source_page] = len(virtual_pages) + 1
        if len(chunks) > 1:
            split_sources.append((source_page, source_entry.get("manual_page"), len(chunks)))

        for part_index, chunk in enumerate(chunks, start=1):
            entry = dict(source_entry)
            entry["page"] = len(virtual_pages) + 1
            entry["source_document_page"] = source_page
            entry["part"] = part_index
            entry["part_total"] = len(chunks)
            entry["blocks"] = chunk

            chunk_text = blocks_text(chunk)
            entry["text"] = chunk_text
            search_seed = " ".join(
                part for part in [
                    str(entry.get("chapter", "")),
                    str(entry.get("title", "")),
                    chunk_text,
                ] if part
            )
            entry["search_text"] = normalize_search(search_seed)
            virtual_pages.append(entry)

    INDEX.write_text(json.dumps(virtual_pages, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    section_sources = [1, 4, 9, 140, 162, 177, 207, 226, 238]
    section_virtual = {source: source_to_first_virtual[source] for source in section_sources}

    print(json.dumps({
        "source_pages": len(data),
        "virtual_pages": len(virtual_pages),
        "split_source_pages": len(split_sources),
        "section_virtual_pages": section_virtual,
        "sample_splits": [
            {"source_page": s, "manual_page": m, "parts": p}
            for s, m, p in split_sources
            if m in {161, 162, 163, 164, 165, 167, 207, 208, 209, 210}
        ],
    }, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
