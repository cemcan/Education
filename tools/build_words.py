#!/usr/bin/env python3
"""Builds GREVocab/Shared/Resources/words.json.

Word entries (definition, synonyms, etymology, ...) are authored in tools/words/*.yaml.
Example sentences are never written by hand: they are pulled verbatim from the
corpus downloaded by tools/fetch_corpus.sh (public-domain books, BBC News
2004-05, the Reuters 1987 newswire, ABC science and rural news, and US
presidential addresses), so every example is a real quotation with a real source.

Usage:
    tools/fetch_corpus.sh
    python3 tools/build_words.py            # writes words.json
    python3 tools/build_words.py --report   # also prints every candidate pick for review
    python3 tools/build_words.py --survey list.txt   # corpus hits for bare words (choosing new words)
"""
import argparse
import csv
import hashlib
import json
import pickle
import re
import sys
from collections import defaultdict
from pathlib import Path

import yaml

TOOLS = Path(__file__).resolve().parent
CORPUS = TOOLS / ".corpus"
OUTPUT = TOOLS.parent / "GREVocab" / "Shared" / "Resources" / "words.json"
CACHE = CORPUS / "candidates.pickle"

# NLTK's own Gutenberg selection: prose only (verse lines run together once
# line breaks are removed), skipping books already covered by sources.yaml.
NLTK_GUTENBERG = {
    "melville-moby_dick.txt": ("Moby-Dick", "Herman Melville", 1851),
    "chesterton-thursday.txt": ("The Man Who Was Thursday", "G. K. Chesterton", 1908),
    "chesterton-brown.txt": ("The Innocence of Father Brown", "G. K. Chesterton", 1911),
    "chesterton-ball.txt": ("The Ball and the Cross", "G. K. Chesterton", 1909),
    "edgeworth-parents.txt": ("The Parent's Assistant", "Maria Edgeworth", 1796),
}

PRESIDENTS = {
    "Washington": "George Washington", "Jefferson": "Thomas Jefferson", "Madison": "James Madison",
    "Monroe": "James Monroe", "Jackson": "Andrew Jackson", "VanBuren": "Martin Van Buren",
    "Polk": "James K. Polk", "Taylor": "Zachary Taylor", "Pierce": "Franklin Pierce",
    "Buchanan": "James Buchanan", "Lincoln": "Abraham Lincoln", "Grant": "Ulysses S. Grant",
    "Hayes": "Rutherford B. Hayes", "Garfield": "James A. Garfield", "Cleveland": "Grover Cleveland",
    "McKinley": "William McKinley", "Taft": "William Howard Taft", "Wilson": "Woodrow Wilson",
    "Harding": "Warren G. Harding", "Coolidge": "Calvin Coolidge", "Hoover": "Herbert Hoover",
    "Truman": "Harry S. Truman", "Eisenhower": "Dwight D. Eisenhower", "Kennedy": "John F. Kennedy",
    "Johnson": "Lyndon B. Johnson", "Nixon": "Richard Nixon", "Ford": "Gerald Ford",
    "Carter": "Jimmy Carter", "Reagan": "Ronald Reagan", "Clinton": "Bill Clinton",
    "Obama": "Barack Obama", "GWBush": "George W. Bush", "Trump": "Donald Trump", "Biden": "Joe Biden",
}


def president(year, name):
    if name == "Adams":
        return "John Adams" if year < 1800 else "John Quincy Adams"
    if name == "Harrison":
        return "William Henry Harrison" if year < 1850 else "Benjamin Harrison"
    if name == "Roosevelt":
        return "Theodore Roosevelt" if year < 1910 else "Franklin D. Roosevelt"
    if name == "Bush":
        return "George H. W. Bush" if year < 2000 else "George W. Bush"
    return PRESIDENTS.get(name, name)


# --- text cleanup -----------------------------------------------------------

ABBREVIATIONS = ["Mr", "Mrs", "Ms", "Dr", "St", "Messrs", "Mme", "Mlle", "Capt", "Col", "Gen",
                 "Lt", "Sgt", "Rev", "Hon", "Prof", "Sr", "Jr", "vs", "No", "Co", "Inc", "Ltd",
                 "U.S", "U.K", "i.e", "e.g", "viz", "cf", "Esq"]
ABBR_RE = re.compile(r"\b(" + "|".join(re.escape(a) for a in ABBREVIATIONS) + r")\.")
SENTENCE_SPLIT = re.compile(r"(?<=[.!?])[\"'”’)]*\s+(?=[\"'“‘(]?[A-Z])")


def strip_gutenberg(text, start_marker=None):
    if start_marker:
        i = text.find(start_marker)
        if i < 0:
            raise SystemExit(f"start marker not found: {start_marker!r}")
        text = text[i:]
    start = re.search(r"\*\*\*\s*START OF.*?\*\*\*|\*END\*THE SMALL PRINT.*?\n", text)
    end = re.search(r"\*\*\*\s*END OF|End of (the )?Project Gutenberg", text)
    return text[start.end() if start else 0: end.start() if end else len(text)]


def paragraphs(text):
    for block in re.split(r"\n\s*\n", text.replace("\r", "")):
        block = re.sub(r"\s+", " ", block).strip()
        if block:
            yield block


def sentences(paragraph):
    protected = ABBR_RE.sub(lambda m: m.group(1) + "․", paragraph)
    for s in SENTENCE_SPLIT.split(protected):
        yield s.replace("․", ".").strip()


def clean(s):
    s = s.replace("_", "")  # Gutenberg italics markers
    s = re.sub(r"\s+([,;:.!?])", r"\1", s)
    s = re.sub(r"\s+", " ", s).strip()
    s = s.replace("--", "—")
    return s


def looks_usable(s, relaxed=False):
    lo, hi = (35, 340) if relaxed else (55, 260)
    if not (lo <= len(s) <= hi):
        return False
    if not re.match(r"^[\"'“‘(]?(I|A|[A-Z][a-z]+)\b(?!\.)", s) or s.count(")") > s.count("(") or not re.search(r"[.!?][\"'”’)]*$", s):
        return False
    letters = [c for c in s if c.isalpha()]
    if sum(c.isupper() for c in letters) > 0.3 * len(letters):  # headlines, shouting
        return False
    if re.search(r"\d{3,}|\b(mln|dlrs|pct|cts|billion|million)\b|[\[\]{}<>|*#@=]|\bchapter\b", s, re.I):
        return False
    # Unbalanced quotes usually mean a fragment of dialogue spanning sentences.
    if s.count('"') % 2 or s.count("“") != s.count("”"):
        return False
    return True


# --- corpus loading -----------------------------------------------------------

def load_corpus(sources):
    """Yields (sentence, source dict)."""
    for b in sources["books"]:
        path = CORPUS / "books" / f"{b['repo']}.txt"
        if not path.exists():
            print(f"warning: missing {path.name}; run tools/fetch_corpus.sh", file=sys.stderr)
            continue
        meta = {"kind": "literature", "source": b["title"], "author": b["author"], "year": b.get("year")}
        if b.get("translator"):
            meta["author"] = f"{b['author']} (tr. {b['translator']})"
        text = strip_gutenberg(path.read_text(encoding="utf-8", errors="replace"), b.get("start"))
        for p in paragraphs(text):
            for s in sentences(p):
                yield s, meta

    for fname, (title, author, year) in NLTK_GUTENBERG.items():
        path = CORPUS / "gutenberg" / fname
        if path.exists():
            meta = {"kind": "literature", "source": title, "author": author, "year": year}
            for p in paragraphs(path.read_text(encoding="latin-1")):
                for s in sentences(p):
                    yield s, meta

    for path in sorted((CORPUS / "inaugural").glob("*.txt")):
        m = re.match(r"(\d{4})-(\w+)", path.stem)
        year = int(m.group(1))
        meta = {"kind": "speech", "source": "Inaugural Address", "author": president(year, m.group(2)), "year": year}
        for p in paragraphs(path.read_text(encoding="latin-1")):
            for s in sentences(p):
                yield s, meta

    for path in sorted((CORPUS / "state_union").glob("*.txt")):
        m = re.match(r"(\d{4})-(\w+?)(?:-\d)?$", path.stem)
        year = int(m.group(1))
        lines = path.read_text(encoding="latin-1").splitlines()
        meta = {"kind": "speech", "source": "State of the Union Address",
                "author": president(year, m.group(2)), "year": year}
        for line in lines[1:]:
            for s in sentences(line):
                yield s, meta

    for split in ("training", "test"):
        for path in sorted((CORPUS / "reuters" / split).glob("*"), key=lambda p: int(p.name)):
            raw = path.read_text(encoding="latin-1").splitlines()
            if not raw:
                continue
            headline = raw[0].strip().title()
            body = "\n".join(raw[1:])
            # Paragraphs in Reuters files start with deeper indentation.
            body = re.sub(r"\n {4,}", "\n\n", body)
            body = re.sub(r"\s+Reuter\s*$", "", body)
            meta = {"kind": "news", "source": f"Reuters, “{headline}”", "author": None, "year": 1987}
            for p in paragraphs(body):
                for s in sentences(p):
                    yield s, meta


    # BBC News articles from 2004-05 (Greene & Cunningham's BBC dataset): headline, blank line, body.
    bbc = CORPUS / "bbc.csv"
    if bbc.exists():
        with bbc.open(encoding="utf-8", errors="replace", newline="") as f:
            for row in csv.DictReader(f):
                headline, _, body = row["news"].strip().partition("\n")
                meta = {"kind": "news", "source": f"BBC News, “{headline.strip()}”", "author": None, "year": None}
                for p in paragraphs(body):
                    for s in sentences(p):
                        yield s, meta

    # Australian Broadcasting Corporation science and rural news (NLTK "abc").
    for name, desk in (("science.txt", "ABC Science"), ("rural.txt", "ABC Rural")):
        path = CORPUS / "abc" / name
        if path.exists():
            meta = {"kind": "news", "source": f"{desk} (Australian Broadcasting Corporation)", "author": None, "year": None}
            for line in path.read_text(encoding="latin-1").splitlines():
                for s in sentences(line.strip()):
                    yield s, meta


def outlet(meta):
    """Groups news sources by publisher, e.g. every Reuters story counts as one outlet."""
    source = meta["source"]
    return "ABC" if source.startswith("ABC ") else source.split(",")[0]


# --- picking ------------------------------------------------------------------

def word_forms(entry):
    forms = set(entry.get("forms", []))
    forms.add(entry["word"])
    return {f.lower() for f in forms}


def score(s, meta):
    n = len(s)
    sc = -abs(n - 140) / 40.0
    if meta["kind"] != "literature":
        sc += 0.5
    if s.startswith(("“", '"', "'")):
        sc -= 0.3
    if ";" in s:
        sc -= 0.3
    return sc


def pick(candidates, entry, taken=frozenset()):
    """Three examples from distinct sources: a news quote, a literary one, and a speech
    (or a second outlet) when they exist; never the same author twice if avoidable."""
    exclude = [x.lower() for x in entry.get("exclude", [])]
    pool = sorted(((score(s, m), s, m) for s, m in candidates
                   if s not in taken and not any(x in s.lower() for x in exclude)), key=lambda t: -t[0])
    chosen = []

    def take(kind=None, distinct_author=True):
        for _, s, m in pool:
            if kind and m["kind"] != kind:
                continue
            if any(c["source"] == m["source"] and c["author"] == m["author"] for c in chosen):
                continue
            if distinct_author and m["author"] and any(c["author"] == m["author"] for c in chosen):
                continue
            if any(c["text"] == s for c in chosen):
                continue
            if kind == "news" and any(c["kind"] == "news" and outlet(c) == outlet(m) for c in chosen):
                continue
            chosen.append({"text": s, **m})
            return True
        return False

    take("news")
    take("literature")
    take("speech") or take("news")
    while len(chosen) < 3 and take("literature"):
        pass
    while len(chosen) < 3 and take():
        pass
    while len(chosen) < 3 and take(distinct_author=False):
        pass
    order = {"news": 0, "literature": 1, "speech": 2}
    chosen.sort(key=lambda e: order[e["kind"]])
    return chosen[:3]


def auto_forms(word):
    """Rough inflections for surveying bare words before they have authored `forms`."""
    forms = {word, word + "s", word + "es", word + "ed", word + "d", word + "ing", word + "ly"}
    if word.endswith("e"):
        forms |= {word[:-1] + "ing", word[:-1] + "ity", word[:-1] + "ation"}
    if word.endswith("y"):
        forms |= {word[:-1] + "ies", word[:-1] + "ied", word[:-1] + "ily"}
    if word.endswith("ous"):
        forms |= {word + "ness", word[:-3] + "ity"}
    if word.endswith("ent") or word.endswith("ant"):
        forms |= {word[:-1] + "ce", word[:-1] + "cy"}
    return forms


def collect(sources, form_index, lowercase_only=frozenset()):
    """Maps each headword to its (sentence, source) candidates, cached on disk.
    Words in `lowercase_only` (august, pacific, ...) ignore capitalized matches."""
    key = hashlib.sha256(json.dumps([sorted(form_index.items()), sorted(lowercase_only),
                                     (TOOLS / "sources.yaml").read_text(),
                                     Path(__file__).read_text()]).encode()).hexdigest()
    if CACHE.exists():
        cached = pickle.loads(CACHE.read_bytes())
        if cached.get("key") == key:
            return cached["candidates"], cached["fallback"]

    # Longer or shorter sentences are kept aside for rare words that need them.
    candidates, fallback = defaultdict(list), defaultdict(list)
    for raw, meta in load_corpus(sources):
        hits = set()
        for token in re.findall(r"[A-Za-z]+", raw):
            word = form_index.get(token.lower())
            if word and not (word in lowercase_only and not token.islower()):
                hits.add(word)
        if not hits:
            continue
        s = clean(raw)
        bucket = candidates if looks_usable(s) else fallback if looks_usable(s, relaxed=True) else None
        if bucket is None:
            continue
        for word in hits:
            bucket[word].append((s, meta))
    CACHE.write_bytes(pickle.dumps({"key": key, "candidates": dict(candidates), "fallback": dict(fallback)}))
    return defaultdict(list, candidates), defaultdict(list, fallback)


def load_entries():
    entries = []
    for path in sorted((TOOLS / "words").glob("*.yaml")):
        entries += yaml.safe_load(path.read_text())["words"]
    seen = set()
    for e in entries:
        if e["word"] in seen:
            raise SystemExit(f"duplicate word: {e['word']}")
        seen.add(e["word"])
    return sorted(entries, key=lambda e: e["word"])


def survey(sources, words):
    form_index = {f: w for w in words for f in auto_forms(w)}
    candidates, fallback = collect(sources, form_index)
    for w in words:
        kinds = defaultdict(int)
        for _, m in candidates[w]:
            kinds[m["kind"]] += 1
        print(f"{w}\t{len(candidates[w])}\t{len(fallback[w])}\t{kinds['news']}\t{kinds['literature']}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--survey", metavar="WORDLIST")
    args = ap.parse_args()

    sources = yaml.safe_load((TOOLS / "sources.yaml").read_text())
    if args.survey:
        words = [w.strip().lower() for w in Path(args.survey).read_text().split() if w.strip()]
        return survey(sources, list(dict.fromkeys(words)))

    entries = load_entries()
    form_index = {}
    for e in entries:
        for f in word_forms(e):
            form_index[f] = e["word"]
    lowercase_only = frozenset(e["word"] for e in entries if e.get("lowercase_only"))
    candidates, fallback = collect(sources, form_index, lowercase_only)

    out, thin, taken = [], [], set()  # `taken`: a sentence illustrates only one word
    for e in entries:
        examples = pick(candidates[e["word"]], e, taken)
        if len(examples) < 3:
            examples = pick(candidates[e["word"]] + fallback[e["word"]], e, taken)
        taken.update(ex["text"] for ex in examples)
        if len(examples) < 3:
            thin.append(f"{e['word']} ({len(examples)})")
        for ex in examples:
            if ex["author"] is None:
                del ex["author"]
            if ex.get("year") is None:
                ex.pop("year", None)
        out.append({
            "id": e["word"],
            "word": e["word"],
            "partOfSpeech": e["pos"],
            "ipa": e["ipa"],
            "phonetic": e["phonetic"],
            "definition": e["definition"],
            "synonyms": e.get("synonyms", []),
            "antonyms": e.get("antonyms", []),
            "relatedWords": e.get("related", []),
            **({"etymology": e["etymology"]} if e.get("etymology") else {}),
            "examples": examples,
        })
        if args.report:
            print(f"\n== {e['word']}  ({len(candidates[e['word']])} candidates)")
            for ex in examples:
                print(f"   [{ex['kind'][0]}] {ex['text']}\n        — {ex.get('author', '')}, {ex['source']}")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {len(out)} words to {OUTPUT.relative_to(TOOLS.parent)}")
    if thin:
        print("fewer than 3 examples: " + ", ".join(thin), file=sys.stderr)


if __name__ == "__main__":
    main()
