#!/usr/bin/env python3
"""Generate an RSS feed from compiled reading-list wiki pages."""

from __future__ import annotations

import argparse
import email.utils
import re
import sys
import unicodedata
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urljoin


COMPILED_DIRS = ("entities", "concepts", "comparisons", "queries")
HANGUL_RE = re.compile(r"[가-힣]")
INDEX_ROW_RE = re.compile(
    r"^\|\s*\[([^\]]+)\]\(([^)]+)\)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|"
)


@dataclass(frozen=True)
class WikiEntry:
    title: str
    relative_path: str
    link_path: str
    updated: str
    created: str
    summary: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate reading-list RSS feeds from compiled wiki pages or raw sources."
    )
    parser.add_argument("--wiki-dir", default="wiki", help="Wiki directory to scan.")
    parser.add_argument(
        "--mode",
        choices=("compiled", "raw"),
        default="compiled",
        help="Feed mode: compiled wiki pages or raw-source items. Default: compiled",
    )
    parser.add_argument(
        "--site-url",
        default="",
        help="Absolute site URL used as the base for RSS item links.",
    )
    parser.add_argument(
        "--output",
        default="wiki/feed.xml",
        help="RSS XML output path. Default: wiki/feed.xml",
    )
    parser.add_argument(
        "--allow-non-korean-summary",
        action="store_true",
        help="Allow RSS item descriptions without Hangul.",
    )
    return parser.parse_args()


def strip_quotes(value: str) -> str:
    value = unicodedata.normalize("NFC", value.strip())
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def split_frontmatter(markdown: str) -> tuple[dict[str, str], str]:
    if not markdown.startswith("---\n"):
        return {}, markdown

    end = markdown.find("\n---", 4)
    if end == -1:
        return {}, markdown

    raw_frontmatter = markdown[4:end]
    body = markdown[end + len("\n---") :].lstrip()
    data: dict[str, str] = {}

    for line in raw_frontmatter.splitlines():
        if not line.strip() or line.startswith(" ") or ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = strip_quotes(value)

    return data, body


def first_body_paragraph(body: str) -> str:
    paragraph: list[str] = []
    for raw_line in body.splitlines():
        line = raw_line.strip()
        if not line:
            if paragraph:
                break
            continue
        if line.startswith("#"):
            continue
        if line.startswith("|") or line.startswith("```"):
            continue
        paragraph.append(line)

    return " ".join(paragraph).strip()


def section_text(body: str, heading: str) -> str:
    lines = body.splitlines()
    collecting = False
    collected: list[str] = []
    target = f"## {heading}"
    for raw_line in lines:
        line = raw_line.rstrip()
        if line == target:
            collecting = True
            continue
        if collecting and line.startswith("## "):
            break
        if collecting:
            stripped = line.strip()
            if stripped:
                collected.append(stripped)
    return " ".join(collected).strip()


def normalize_tags(value: str) -> list[str]:
    value = value.strip()
    if not value.startswith("[") or not value.endswith("]"):
        return []
    inner = value[1:-1].strip()
    if not inner:
        return []
    parts = [part.strip().strip('"\'') for part in inner.split(",")]
    return [part for part in parts if part]


def load_index_summaries(wiki_dir: Path) -> dict[str, str]:
    index_path = wiki_dir / "index.md"
    if not index_path.exists():
        return {}

    summaries: dict[str, str] = {}
    for line in index_path.read_text(encoding="utf-8").splitlines():
        match = INDEX_ROW_RE.match(line)
        if not match:
            continue
        link = match.group(2).strip()
        summary = match.group(3).strip()
        if not link or link.startswith("http"):
            continue
        normalized = Path(link).as_posix()
        summaries[normalized] = summary
        summaries[f"{wiki_dir.name}/{normalized}"] = summary

    return summaries


def parse_date(value: str) -> datetime:
    value = value.strip()
    if not value:
        return datetime(1970, 1, 1, tzinfo=timezone.utc)

    try:
        return datetime.strptime(value[:10], "%Y-%m-%d").replace(tzinfo=timezone.utc)
    except ValueError:
        pass

    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return parsed.astimezone(timezone.utc)
    except ValueError:
        return datetime(1970, 1, 1, tzinfo=timezone.utc)


def rss_date(value: str) -> str:
    return email.utils.format_datetime(parse_date(value), usegmt=True)


def has_hangul(value: str) -> bool:
    return bool(HANGUL_RE.search(unicodedata.normalize("NFC", value)))


def collect_entries(wiki_dir: Path, allow_non_korean_summary: bool) -> list[WikiEntry]:
    summaries = load_index_summaries(wiki_dir)
    entries: list[WikiEntry] = []
    errors: list[str] = []

    for section in COMPILED_DIRS:
        section_dir = wiki_dir / section
        if not section_dir.exists():
            continue

        for path in sorted(section_dir.rglob("*.md")):
            markdown = path.read_text(encoding="utf-8")
            frontmatter, body = split_frontmatter(markdown)
            relative_to_wiki = path.relative_to(wiki_dir).as_posix()
            link_path = f"{wiki_dir.name}/{relative_to_wiki}"

            title = frontmatter.get("title") or path.stem.replace("-", " ").title()
            updated = frontmatter.get("updated") or frontmatter.get("created") or ""
            created = frontmatter.get("created") or updated
            summary = summaries.get(relative_to_wiki) or summaries.get(link_path)
            if not summary:
                summary = first_body_paragraph(body)

            if not summary:
                errors.append(f"{path}: missing RSS summary")
            elif not allow_non_korean_summary and not has_hangul(summary):
                errors.append(f"{path}: Korean-first summary required")

            entries.append(
                WikiEntry(
                    title=title,
                    relative_path=relative_to_wiki,
                    link_path=link_path,
                    updated=updated,
                    created=created,
                    summary=summary,
                )
            )

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        raise SystemExit(1)

    return sorted(entries, key=lambda entry: (parse_date(entry.updated), entry.title), reverse=True)


def collect_raw_entries(wiki_dir: Path, allow_non_korean_summary: bool) -> list[WikiEntry]:
    entries: list[WikiEntry] = []
    errors: list[str] = []
    raw_root = wiki_dir / 'raw' / 'raindrop' / 'items'
    if not raw_root.exists():
        return []

    for path in sorted(raw_root.rglob('*.md')):
        markdown = path.read_text(encoding='utf-8')
        frontmatter, body = split_frontmatter(markdown)
        relative_to_wiki = path.relative_to(wiki_dir).as_posix()
        link_path = f"{wiki_dir.name}/{relative_to_wiki}"

        title = frontmatter.get('title') or path.stem.replace('-', ' ').title()
        updated = frontmatter.get('updated') or frontmatter.get('synced_at') or frontmatter.get('created') or ''
        created = frontmatter.get('created') or updated
        note = section_text(body, 'Note')
        excerpt = section_text(body, 'Excerpt')
        tags = normalize_tags(frontmatter.get('tags', '[]'))
        if note == 'None':
            note = ''
        if excerpt == 'None':
            excerpt = ''
        summary = note or excerpt or title or first_body_paragraph(body)
        if tags:
            tag_suffix = f" [tags] {', '.join(tags)}"
            summary = f"{summary}{tag_suffix}" if summary else tag_suffix.strip()

        if not summary:
            errors.append(f"{path}: missing RSS summary")
        elif not allow_non_korean_summary and not has_hangul(summary):
            errors.append(f"{path}: Korean-first summary required")

        entries.append(
            WikiEntry(
                title=title,
                relative_path=relative_to_wiki,
                link_path=link_path,
                updated=updated,
                created=created,
                summary=summary,
            )
        )

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        raise SystemExit(1)

    return sorted(entries, key=lambda entry: (parse_date(entry.updated), entry.title), reverse=True)


def build_feed(site_url: str, entries: list[WikiEntry]) -> ET.ElementTree:
    base_url = site_url.rstrip("/") + "/"
    rss = ET.Element("rss", version="2.0")
    channel = ET.SubElement(rss, "channel")

    ET.SubElement(channel, "title").text = "reading-list wiki"
    ET.SubElement(channel, "link").text = site_url.rstrip("/")
    ET.SubElement(channel, "description").text = (
        "Raindrop raw sources compiled into Korean-first wiki pages."
    )
    ET.SubElement(channel, "language").text = "ko"

    if entries:
        ET.SubElement(channel, "lastBuildDate").text = rss_date(entries[0].updated)

    for entry in entries:
        item = ET.SubElement(channel, "item")
        link = urljoin(base_url, entry.link_path)
        ET.SubElement(item, "title").text = entry.title
        ET.SubElement(item, "link").text = link
        ET.SubElement(item, "guid", isPermaLink="true").text = link
        ET.SubElement(item, "pubDate").text = rss_date(entry.updated or entry.created)
        ET.SubElement(item, "description").text = entry.summary

    ET.indent(rss, space="  ")
    return ET.ElementTree(rss)


def main() -> int:
    args = parse_args()
    site_url = args.site_url.strip()
    if not site_url:
        print("--site-url is required for RSS links", file=sys.stderr)
        return 2

    wiki_dir = Path(args.wiki_dir)
    if not wiki_dir.exists():
        print(f"Wiki directory not found: {wiki_dir}", file=sys.stderr)
        return 2

    entries = (
        collect_raw_entries(wiki_dir=wiki_dir, allow_non_korean_summary=args.allow_non_korean_summary)
        if args.mode == 'raw'
        else collect_entries(wiki_dir=wiki_dir, allow_non_korean_summary=args.allow_non_korean_summary)
    )
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    build_feed(site_url, entries).write(
        output_path,
        encoding="utf-8",
        xml_declaration=True,
        short_empty_elements=False,
    )
    print(f"Wrote {output_path} with {len(entries)} item(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
