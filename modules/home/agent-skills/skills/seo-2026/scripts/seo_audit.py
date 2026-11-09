#!/usr/bin/env python3
"""Fast technical SEO + AI-crawler baseline audit. Python standard library only.

Usage:
    python3 seo_audit.py https://example.com/ [--pages 6] [--json] [--timeout 15]

What it checks (see ../SKILL.md for how to interpret and prioritise):
  * host hygiene: http->https, www/non-www consolidation, real 404 behaviour
  * robots.txt: reachable, sitemaps, allow/block status per search + AI crawler
  * whether the homepage answers differently to bot user agents (WAF/CDN blocking)
  * sitemap reachability and a sample of its URLs
  * per page (homepage + sampled internal links): status, redirects, indexability,
    title, meta description, canonical, headings, lang, hreflang, JSON-LD, alt text,
    amount of text in the raw HTML (what non-JS crawlers see), snippet-limiting controls
  * llms.txt presence (informational only: Google does not use it)

It fetches only public pages with plain GET requests, a handful per run, with a
descriptive User-Agent. It never executes JavaScript, so "words in raw HTML" shows
what AI crawlers that do not render JS can see.
"""

import argparse
import json
import random
import re
import string
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from urllib.robotparser import RobotFileParser

TOOL_UA = "Mozilla/5.0 (compatible; seo-2026-audit/1.0)"
MAX_BYTES = 2_000_000

# (token used in robots.txt, user-agent string used for the bot-treatment probe or None, purpose)
BOTS = [
    ("Googlebot", "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)", "Google Search + AI Overviews/AI Mode"),
    ("Bingbot", "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)", "Bing + Copilot"),
    ("OAI-SearchBot", "Mozilla/5.0 (compatible; OAI-SearchBot/1.4; +https://openai.com/searchbot)", "ChatGPT search"),
    ("ChatGPT-User", "Mozilla/5.0 (compatible; ChatGPT-User/1.0; +https://openai.com/bot)", "ChatGPT user fetch"),
    ("Claude-SearchBot", "Mozilla/5.0 (compatible; Claude-SearchBot/1.0)", "Claude search"),
    ("PerplexityBot", "Mozilla/5.0 (compatible; PerplexityBot/1.0; +https://perplexity.ai/perplexitybot)", "Perplexity search"),
    ("GPTBot", None, "OpenAI training (business decision)"),
    ("ClaudeBot", None, "Anthropic training (business decision)"),
    ("Google-Extended", None, "Gemini training/grounding in other Google systems (business decision)"),
    ("CCBot", None, "Common Crawl (feeds many training sets)"),
]
SEARCH_BOT_TOKENS = {"Googlebot", "Bingbot", "OAI-SearchBot", "Claude-SearchBot", "PerplexityBot"}


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k):
        return None


_opener = urllib.request.build_opener(_NoRedirect)


def fetch(url, ua=TOOL_UA, timeout=15, max_hops=8, want_body=True):
    """GET url, following redirects manually. Returns dict with hops list."""
    hops, cur = [], url
    for _ in range(max_hops + 1):
        req = urllib.request.Request(cur, headers={"User-Agent": ua, "Accept": "text/html,application/xhtml+xml,application/xml,text/plain;q=0.9,*/*;q=0.5", "Accept-Language": "nl,en;q=0.8"})
        try:
            resp = _opener.open(req, timeout=timeout)
            status, headers = resp.status, resp.headers
            body = resp.read(MAX_BYTES) if want_body else b""
        except urllib.error.HTTPError as e:
            status, headers = e.code, e.headers
            try:
                body = e.read(MAX_BYTES) if want_body else b""
            except Exception:
                body = b""
        except Exception as e:  # DNS, TLS, timeout
            return {"url": url, "final_url": cur, "status": None, "error": f"{type(e).__name__}: {e}", "hops": hops, "headers": {}, "body": ""}
        if status in (301, 302, 303, 307, 308) and headers.get("Location"):
            nxt = urllib.parse.urljoin(cur, headers["Location"])
            hops.append((status, cur, nxt))
            cur = nxt
            continue
        charset = "utf-8"
        m = re.search(r"charset=([\w-]+)", headers.get("Content-Type", "") or "", re.I)
        if m:
            charset = m.group(1)
        try:
            text = body.decode(charset, errors="replace")
        except LookupError:
            text = body.decode("utf-8", errors="replace")
        return {"url": url, "final_url": cur, "status": status, "error": None, "hops": hops, "headers": {k.lower(): v for k, v in headers.items()}, "body": text}
    return {"url": url, "final_url": cur, "status": None, "error": "redirect loop or too many redirects", "hops": hops, "headers": {}, "body": ""}


class PageParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.title = ""
        self._in_title = False
        self.meta = {}
        self.canonical = None
        self.hreflang = []
        self.h = {"h1": [], "h2": 0, "h3": 0}
        self._cur_h = None
        self.links = []
        self.imgs = 0
        self.imgs_no_alt = 0
        self.jsonld = []
        self._in_ld = False
        self._ld_buf = []
        self.lang = None
        self.text_words = 0
        self._skip = 0
        self.scripts = 0
        self.data_nosnippet = False
        self.http_resources = 0
        self.root_marker = False

    def handle_starttag(self, tag, attrs):
        a = {k.lower(): (v or "") for k, v in attrs}
        if tag == "html":
            self.lang = a.get("lang")
        elif tag == "title":
            self._in_title = True
        elif tag == "meta":
            key = (a.get("name") or a.get("property") or a.get("http-equiv") or "").lower()
            if key:
                self.meta[key] = a.get("content", "")
        elif tag == "link":
            rel = a.get("rel", "").lower().split()
            if "canonical" in rel and self.canonical is None:
                self.canonical = a.get("href")
            if "alternate" in rel and a.get("hreflang"):
                self.hreflang.append((a["hreflang"], a.get("href", "")))
        elif tag in ("h1", "h2", "h3"):
            self._cur_h = tag
            if tag != "h1":
                self.h[tag] += 1
            else:
                self.h["h1"].append("")
        elif tag == "a" and a.get("href"):
            self.links.append(a["href"])
        elif tag == "img":
            self.imgs += 1
            if "alt" not in a:
                self.imgs_no_alt += 1
            if a.get("src", "").startswith("http://"):
                self.http_resources += 1
        elif tag == "script":
            self._skip += 1
            if a.get("type", "").lower() == "application/ld+json":
                self._in_ld = True
                self._ld_buf = []
            else:
                self.scripts += 1  # JSON-LD is data, not app code
            if a.get("src", "").startswith("http://"):
                self.http_resources += 1
        elif tag in ("style", "noscript", "template"):
            self._skip += 1
        if tag == "div" and a.get("id") in ("root", "app", "__next", "__nuxt", "svelte"):
            self.root_marker = True
        if "data-nosnippet" in a:
            self.data_nosnippet = True

    def handle_endtag(self, tag):
        if tag == "title":
            self._in_title = False
        elif tag in ("h1", "h2", "h3"):
            self._cur_h = None
        elif tag == "script":
            if self._in_ld:
                self.jsonld.append("".join(self._ld_buf))
                self._in_ld = False
            self._skip = max(0, self._skip - 1)
        elif tag in ("style", "noscript", "template"):
            self._skip = max(0, self._skip - 1)

    def handle_data(self, data):
        if self._in_title:
            self.title += data
        if self._in_ld:
            self._ld_buf.append(data)
        if self._skip:
            return
        if self._cur_h == "h1" and self.h["h1"]:
            self.h["h1"][-1] += data
        self.text_words += len(data.split())


def jsonld_types(blocks):
    types, invalid = [], 0
    def walk(o):
        if isinstance(o, dict):
            t = o.get("@type")
            if t:
                types.extend(t if isinstance(t, list) else [t])
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)
    for b in blocks:
        try:
            walk(json.loads(b))
        except Exception:
            invalid += 1
    return sorted(set(map(str, types))), invalid


def add(findings, sev, scope, msg):
    findings.append({"severity": sev, "scope": scope, "message": msg})


def audit_page(url, timeout):
    r = fetch(url, timeout=timeout)
    f = []
    page = {"url": url, "final_url": r["final_url"], "status": r["status"], "redirect_hops": len(r["hops"]), "findings": f}
    if r["error"]:
        add(f, "critical", url, f"Fetch failed: {r['error']}")
        return page, None, []
    if r["status"] != 200:
        add(f, "critical", url, f"Returns HTTP {r['status']}")
    if len(r["hops"]) > 1:
        add(f, "warning", url, f"Redirect chain of {len(r['hops'])} hops: " + " -> ".join(h[2] for h in r["hops"]))
    if any(h[0] in (302, 307) for h in r["hops"]):
        add(f, "info", url, "Uses a temporary redirect (302/307); use 301/308 if the move is permanent")
    ctype = r["headers"].get("content-type", "")
    if "html" not in ctype.lower():
        add(f, "info", url, f"Not HTML ({ctype or 'no content-type'}); page checks skipped")
        return page, None, []
    p = PageParser()
    try:
        p.feed(r["body"])
    except Exception as e:
        add(f, "warning", url, f"HTML parse problem: {e}")
    xrt = r["headers"].get("x-robots-tag", "")
    robots_meta = (p.meta.get("robots", "") + " " + p.meta.get("googlebot", "")).lower() + " " + xrt.lower()
    if "noindex" in robots_meta:
        add(f, "critical", url, f"noindex present ({robots_meta.strip()}). Confirm this is intended; it removes the page from Search and AI answers")
    if "nofollow" in robots_meta and "noindex" not in robots_meta:
        add(f, "warning", url, "Page-level nofollow present; internal links on it pass no signals")
    if "nosnippet" in robots_meta or re.search(r"max-snippet:\s*0", robots_meta):
        add(f, "warning", url, "nosnippet / max-snippet:0 limits snippets and text shown in AI features")
    if p.data_nosnippet:
        add(f, "info", url, "data-nosnippet used on some elements; verify they should be withheld from snippets")
    title = p.title.strip()
    if not title:
        add(f, "critical", url, "Missing <title>")
    elif len(title) > 65:
        add(f, "info", url, f"Title is {len(title)} chars; likely truncated in results")
    elif len(title) < 15:
        add(f, "info", url, f"Title is only {len(title)} chars")
    desc = p.meta.get("description", "").strip()
    if not desc:
        add(f, "warning", url, "Missing meta description (affects snippet/CTR, not rankings)")
    elif len(desc) > 175:
        add(f, "info", url, f"Meta description is {len(desc)} chars; may be truncated")
    canon = p.canonical
    if not canon:
        add(f, "warning", url, "Missing rel=canonical")
    else:
        abs_c = urllib.parse.urljoin(r["final_url"], canon)
        if urllib.parse.urlsplit(abs_c).netloc != urllib.parse.urlsplit(r["final_url"]).netloc:
            add(f, "warning", url, f"Canonical points to a different host: {abs_c}")
        elif abs_c.rstrip("/") != r["final_url"].split("#")[0].rstrip("/") and r["status"] == 200:
            add(f, "info", url, f"Canonical differs from the fetched URL: {abs_c}")
    h1s = [x.strip() for x in p.h["h1"] if x.strip()]
    if len(h1s) == 0:
        add(f, "warning", url, "No <h1> in the raw HTML")
    elif len(h1s) > 1:
        add(f, "info", url, f"{len(h1s)} <h1> elements")
    if not p.lang:
        add(f, "warning", url, "<html lang> missing")
    if "viewport" not in p.meta:
        add(f, "warning", url, "Missing viewport meta (mobile-first indexing)")
    if p.text_words < 50 and p.scripts > 0:
        add(f, "critical", url, f"Only {p.text_words} words of text in the raw HTML but {p.scripts} script tags: likely client-side rendered. Non-JS crawlers (most AI bots) see almost nothing")
    elif p.text_words < 150 and p.root_marker:
        add(f, "warning", url, f"Only {p.text_words} words in raw HTML and an SPA root element: check server-side rendering")
    elif p.text_words < 150:
        add(f, "info", url, f"Only {p.text_words} words of text in raw HTML (thin or JS-injected?)")
    if p.imgs and p.imgs_no_alt:
        add(f, "info", url, f"{p.imgs_no_alt}/{p.imgs} images have no alt attribute (decorative images may use alt=\"\")")
    types, invalid = jsonld_types(p.jsonld)
    if invalid:
        add(f, "warning", url, f"{invalid} JSON-LD block(s) are not valid JSON")
    if p.http_resources and r["final_url"].startswith("https://"):
        add(f, "warning", url, f"{p.http_resources} resource(s) loaded over http:// (mixed content)")
    if p.hreflang:
        langs = {l.lower() for l, _ in p.hreflang}
        self_ref = any(urllib.parse.urljoin(r["final_url"], h).rstrip("/") == r["final_url"].rstrip("/") for _, h in p.hreflang)
        if not self_ref:
            add(f, "warning", url, "hreflang set present but no self-referencing entry")
        if "x-default" not in langs:
            add(f, "info", url, "hreflang has no x-default entry")
    if not (p.meta.get("og:title") and p.meta.get("og:image")):
        add(f, "info", url, "Open Graph title/image incomplete (affects sharing previews)")
    page.update({
        "title": title, "title_len": len(title), "description_len": len(desc), "canonical": canon,
        "h1": h1s[:3], "h2_count": p.h["h2"], "lang": p.lang, "words_raw_html": p.text_words,
        "jsonld_types": types, "hreflang": [f"{l}" for l, _ in p.hreflang][:12],
        "images": p.imgs, "images_without_alt": p.imgs_no_alt,
    })
    return page, p, p.links


def internal_links(base_url, links, limit):
    host = urllib.parse.urlsplit(base_url).netloc.lower().removeprefix("www.")
    seen, out = set(), []
    skip_ext = re.compile(r"\.(jpg|jpeg|png|gif|webp|svg|avif|pdf|zip|css|js|ico|xml|mp4|woff2?)(\?|$)", re.I)
    skip_path = re.compile(r"(login|logout|cart|winkelwagen|checkout|account|wp-admin|wp-json|feed|cdn-cgi|\?add-to-cart)", re.I)
    for href in links:
        if href.startswith(("mailto:", "tel:", "javascript:", "#")):
            continue
        u = urllib.parse.urljoin(base_url, href).split("#")[0]
        s = urllib.parse.urlsplit(u)
        if s.scheme not in ("http", "https") or s.netloc.lower().removeprefix("www.") != host:
            continue
        if skip_ext.search(u) or skip_path.search(u):
            continue
        key = (s.path.rstrip("/") or "/")
        if key == "/" or key in seen:
            continue
        seen.add(key)
        out.append(u)
    # prefer variety of first path segment so we sample different templates
    by_seg, ordered = {}, []
    for u in out:
        seg = urllib.parse.urlsplit(u).path.strip("/").split("/")[0]
        by_seg.setdefault(seg, []).append(u)
    while len(ordered) < limit and any(by_seg.values()):
        for seg in list(by_seg):
            if by_seg[seg] and len(ordered) < limit:
                ordered.append(by_seg[seg].pop(0))
    return ordered


def check_robots(origin, sample_urls, timeout):
    res = {"url": origin + "/robots.txt", "status": None, "bots": [], "sitemaps": [], "findings": []}
    f = res["findings"]
    r = fetch(res["url"], timeout=timeout)
    res["status"] = r["status"]
    if r["error"] or r["status"] != 200:
        sev = "info" if r["status"] == 404 else "warning"
        add(f, sev, "robots.txt", f"robots.txt not available (status {r['status'] or r['error']}). Without it all bots are allowed by default; add one that lists your sitemap")
        parser_text = ""
    else:
        parser_text = r["body"]
    rp = RobotFileParser()
    rp.parse(parser_text.splitlines())
    res["sitemaps"] = rp.site_maps() or []
    if r["status"] == 200 and not res["sitemaps"]:
        add(f, "warning", "robots.txt", "No Sitemap: line in robots.txt")
    for token, _ua, purpose in BOTS:
        allowed_all = all(rp.can_fetch(token, u) for u in sample_urls)
        res["bots"].append({"bot": token, "purpose": purpose, "allowed_on_sampled_urls": allowed_all})
        if not allowed_all and token in SEARCH_BOT_TOKENS:
            add(f, "critical" if token in ("Googlebot", "Bingbot") else "warning", "robots.txt", f"{token} ({purpose}) is blocked from sampled URLs. This removes you from that engine's results/answers")
    if not rp.can_fetch("*", origin + "/"):
        add(f, "critical", "robots.txt", "Homepage disallowed for all user agents (User-agent: * Disallow: /)")
    # blocked rendering resources
    if re.search(r"(?im)^\s*disallow:\s*/(wp-content|assets|static|_next|js|css)\b", parser_text):
        add(f, "warning", "robots.txt", "Disallow rule on an assets/static path; blocking CSS/JS can hurt rendering")
    return res


def probe_bot_treatment(url, timeout):
    """Compare homepage status for browser-like UA vs bot UAs; differences hint at WAF/CDN bot rules."""
    base = fetch(url, ua=TOOL_UA, timeout=timeout, want_body=False)
    out, f = [], []
    for token, ua, purpose in BOTS:
        if not ua:
            continue
        r = fetch(url, ua=ua, timeout=timeout, want_body=False)
        out.append({"bot": token, "status": r["status"], "error": r["error"]})
        if base["status"] == 200 and r["status"] in (401, 403, 429, 503):
            add(f, "warning", "bot-access", f"{token} user agent gets HTTP {r['status']} while a normal client gets 200. Possible CDN/WAF bot rule. (Spoofed user agents are sometimes blocked by IP verification even when real bots are allowed, so confirm in server logs)")
    return out, f


def check_sitemaps(candidates, timeout):
    res, f = [], []
    tried = candidates or []
    for sm in tried[:3]:
        r = fetch(sm, timeout=timeout)
        entry = {"url": sm, "status": r["status"], "urls": 0, "type": None, "sample_issues": []}
        if r["error"] or r["status"] != 200:
            add(f, "warning", "sitemap", f"Sitemap {sm} returned {r['status'] or r['error']}")
            res.append(entry)
            continue
        try:
            root = ET.fromstring(r["body"].encode("utf-8", errors="replace"))
            tag = root.tag.split("}")[-1]
            locs = [e.text.strip() for e in root.iter() if e.tag.split("}")[-1] == "loc" and e.text]
            entry["type"] = tag
            entry["urls"] = len(locs)
            if tag == "urlset" and locs:
                for u in random.sample(locs, min(3, len(locs))):
                    rr = fetch(u, timeout=timeout, want_body=False)
                    if rr["status"] != 200 or rr["hops"]:
                        entry["sample_issues"].append(f"{u} -> {rr['status']} ({len(rr['hops'])} redirects)")
                if entry["sample_issues"]:
                    add(f, "warning", "sitemap", f"Sitemap contains non-200/redirecting URLs (sampled): {'; '.join(entry['sample_issues'])}")
            if tag == "urlset" and not locs:
                add(f, "warning", "sitemap", f"Sitemap {sm} is empty")
        except ET.ParseError as e:
            add(f, "warning", "sitemap", f"Sitemap {sm} is not valid XML: {e}")
        res.append(entry)
    if not tried:
        add(f, "warning", "sitemap", "No sitemap found (neither in robots.txt nor at /sitemap.xml)")
    return res, f


def host_hygiene(start_url, timeout):
    f, info = [], {}
    s = urllib.parse.urlsplit(start_url)
    host = s.netloc
    bare = host.removeprefix("www.")
    variants = {f"http://{host}/": "http version", f"https://{'www.' + bare if not host.startswith('www.') else bare}/": "alternate www/non-www host"}
    finals = {}
    for v, label in variants.items():
        r = fetch(v, timeout=timeout, want_body=False)
        finals[label] = r["final_url"]
        info[label] = {"start": v, "final": r["final_url"], "status": r["status"], "hops": len(r["hops"])}
        if r["error"]:
            if label == "alternate www/non-www host":
                add(f, "info", "hosts", f"Alternate host {v} unreachable ({r['error']}); fine if intentional, but users who type it will fail")
            continue
        if label == "http version" and not r["final_url"].startswith("https://"):
            add(f, "critical", "hosts", f"http:// does not redirect to https:// (ends at {r['final_url']})")
        if label == "alternate www/non-www host":
            if urllib.parse.urlsplit(r["final_url"]).netloc.lower() != host.lower():
                add(f, "warning", "hosts", f"Alternate host {v} ends at {r['final_url']}, not {host}: choose one host and 301 the other")
    bogus = f"{s.scheme}://{host}/{''.join(random.choices(string.ascii_lowercase, k=14))}-seo-404-test"
    r = fetch(bogus, timeout=timeout)
    info["404_test"] = {"url": bogus, "status": r["status"]}
    if r["status"] == 200:
        add(f, "warning", "hosts", "Non-existent URLs return 200 (soft 404). They should return 404/410")
    elif r["status"] and r["status"] not in (404, 410):
        add(f, "info", "hosts", f"Non-existent URL returned {r['status']}; expected 404")
    return info, f


def main():
    ap = argparse.ArgumentParser(description="Technical SEO and AI-crawler baseline audit")
    ap.add_argument("url")
    ap.add_argument("--pages", type=int, default=6, help="total pages to audit incl. homepage (default 6)")
    ap.add_argument("--timeout", type=int, default=15)
    ap.add_argument("--json", action="store_true", help="output JSON instead of Markdown")
    a = ap.parse_args()

    start = a.url if re.match(r"^https?://", a.url) else "https://" + a.url
    s = urllib.parse.urlsplit(start)
    origin = f"{s.scheme}://{s.netloc}"
    report = {"target": start, "findings": []}
    allf = report["findings"]

    home, parser, links = audit_page(start, a.timeout)
    pages = [home]
    allf += home["findings"]
    if home["status"] is None:
        out(report, a.json, pages)
        sys.exit(2)
    sample = internal_links(home["final_url"], links, max(0, a.pages - 1))
    for u in sample:
        pg, _, _ = audit_page(u, a.timeout)
        pages.append(pg)
        allf += pg["findings"]
    report["pages"] = pages

    # cross-page duplicates
    titles = {}
    for pg in pages:
        if pg.get("title"):
            titles.setdefault(pg["title"], []).append(pg["url"])
    for t, urls in titles.items():
        if len(urls) > 1:
            add(allf, "warning", "duplicates", f"Same <title> on {len(urls)} sampled pages: '{t}'")

    hosts, hf = host_hygiene(start, a.timeout)
    report["hosts"] = hosts
    allf += hf

    sample_urls = [pg["final_url"] for pg in pages if pg.get("status") == 200][:5] or [start]
    robots = check_robots(origin, sample_urls, a.timeout)
    report["robots"] = robots
    allf += robots["findings"]

    bot_probe, bf = probe_bot_treatment(start, a.timeout)
    report["bot_probe"] = bot_probe
    allf += bf

    sm_candidates = robots["sitemaps"] or [origin + "/sitemap.xml"]
    sitemaps, sf = check_sitemaps(sm_candidates, a.timeout)
    if not robots["sitemaps"] and sitemaps and sitemaps[0]["status"] != 200:
        sf = [{"severity": "warning", "scope": "sitemap", "message": "No sitemap declared in robots.txt and /sitemap.xml not found"}]
    report["sitemaps"] = sitemaps
    allf += sf

    llms = fetch(origin + "/llms.txt", timeout=a.timeout, want_body=False)
    report["llms_txt"] = {"present": llms["status"] == 200}
    add(allf, "info", "llms.txt", ("llms.txt present. " if llms["status"] == 200 else "No llms.txt. ") + "Informational only: Google does not use it and studies show AI crawlers rarely fetch it. Do not prioritise.")

    out(report, a.json, pages)


def out(report, as_json, pages):
    order = {"critical": 0, "warning": 1, "info": 2}
    report["findings"].sort(key=lambda x: order[x["severity"]])
    if as_json:
        print(json.dumps(report, indent=2, default=str))
        return
    counts = {k: sum(1 for x in report["findings"] if x["severity"] == k) for k in order}
    print(f"# SEO baseline audit: {report['target']}\n")
    print(f"Findings: {counts['critical']} critical, {counts['warning']} warnings, {counts['info']} info. Pages audited: {len(pages)}\n")
    for sev, title in (("critical", "Critical (fix first)"), ("warning", "Warnings"), ("info", "Info")):
        items = [x for x in report["findings"] if x["severity"] == sev]
        if not items:
            continue
        print(f"## {title}")
        for x in items:
            print(f"- [{x['scope']}] {x['message']}")
        print()
    print("## Pages")
    print("| URL | Status | Words (raw HTML) | Title len | H1 | JSON-LD types |")
    print("|---|---|---|---|---|---|")
    for pg in pages:
        print(f"| {pg['final_url']} | {pg['status']} | {pg.get('words_raw_html', '-')} | {pg.get('title_len', '-')} | {(pg.get('h1') or ['-'])[0][:40]} | {', '.join(pg.get('jsonld_types') or []) or '-'} |")
    if "robots" in report:
        print("\n## Crawler access (robots.txt on sampled URLs)")
        print("| Bot | Purpose | Allowed |")
        print("|---|---|---|")
        for b in report["robots"]["bots"]:
            print(f"| {b['bot']} | {b['purpose']} | {'yes' if b['allowed_on_sampled_urls'] else 'BLOCKED'} |")
        print(f"\nSitemaps declared: {', '.join(report['robots']['sitemaps']) or 'none'}")
    if report.get("bot_probe"):
        print("\n## Homepage status by bot user agent (WAF/CDN check)")
        print(", ".join(f"{b['bot']}: {b['status'] or b['error']}" for b in report["bot_probe"]))
    print("\nNote: this checks the raw HTML and public files only. It cannot judge content quality, intent match, backlinks, or real-user performance (use Search Console and CrUX for those).")


if __name__ == "__main__":
    main()
