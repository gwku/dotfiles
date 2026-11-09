---
name: seo-2026
description: Evidence-based SEO and AI-search visibility (AI Overviews, AI Mode, ChatGPT search, Perplexity, Copilot) for any website or webshop - audit, prioritise, implement and measure. Use this skill whenever the user mentions SEO, search rankings, organic traffic, indexing, Search Console, Core Web Vitals, structured data or schema, sitemaps, robots.txt, llms.txt, AI crawlers, GEO/AEO/LLMO, "getting cited by AI", AI Overviews, AI Mode, E-E-A-T, content strategy for search, a core or spam update hit, product feed/Merchant Center visibility, or asks to "improve findability", "optimize for Google/AI", or review a page or site for search - even if they never say "SEO". Also use before writing or changing titles, metadata, internal linking, schema, rendering strategy or site structure in any web project.
---

# SEO 2026: audit, prioritise, implement, measure

Knowledge verified against primary sources on **2026-11-09**. Search changes fast, so treat anything in the "Volatile facts" list (end of this file) as needing a re-check if the date is more than a few months old.

## The one idea that drives everything

Google states, in its own May 2026 guide ("Optimizing your website for generative AI features on Google Search"), that AI Overviews and AI Mode are "rooted in our core Search ranking and quality systems" and that optimizing for them "is still SEO". There is no separate AI ranking system to game. The practical consequences:

1. Sound SEO fundamentals are also the AI-visibility strategy for Google. Do not sell the user a separate "GEO" project for it.
2. Other AI engines (ChatGPT search, Perplexity, Copilot, Claude) are different retrieval systems. For those, three extra things matter: being crawlable by their search bots, having the content in the initial HTML (they do not run JavaScript), and being mentioned and cited across the wider web.
3. A large share of the "GEO" advice online is vendor marketing built on correlations. Grade every recommendation by evidence before you act on it (see `references/evidence-and-myths.md`). Skipping a useless tactic is as valuable as doing a useful one, because the user's time is the scarce resource.

No skill can promise rankings. What it can do is remove the things that block visibility, concentrate effort where evidence says it pays off, and set up measurement so the user learns what worked. Say that plainly to the user instead of guaranteeing outcomes.

## Workflow

Work through these phases in order. Skip a phase only when the user has already supplied its output.

### 1. Establish context (ask little, infer much)

Inspect the repo and, if given, the live URL to determine: site type (content/publisher, B2B lead-gen, local business, webshop, SaaS/app), framework and rendering mode (static, SSR, SPA/CSR), target markets and languages (default assumption for this team: Netherlands/Belgium, Dutch plus English), and what data sources are available. Ask the user only for what you cannot infer: the primary goal (leads, sales, brand reach) and the 5-10 most valuable queries or topics.

If the Search Console, GA4 or Merchant Center MCP tools are connected (names containing `google-search-console`, `google-analytics`, `google-merchant-center`), use them in phase 2. Real query data beats guessing. `detect_quick_wins` and `enhanced_search_analytics` in Search Console are good starting points; use `index_inspect` for individual URLs.

### 2. Audit

Run the bundled script for a fast, deterministic technical baseline. It uses only the Python standard library:

```bash
python3 ~/.claude/skills/seo-2026/scripts/seo_audit.py https://example.com/ --pages 8
```

It fetches the homepage plus sampled internal links and reports: status and redirects, title and meta description, canonical, robots directives, headings, language/hreflang, JSON-LD validity and types, image alt coverage, how much text exists in the raw HTML (a proxy for what non-JS crawlers see), robots.txt rules per search and AI crawler, sitemap reachability, and `llms.txt` presence (informational only). Use `--json` for machine-readable output. For a repo with no live site yet, review the code for the same items by reading templates and config instead.

Then audit what the script cannot see, using the checklists:
- Technical foundation, rendering, structured data, performance: `references/technical-checklist.md`
- Content quality, E-E-A-T, AI-content rules, spam policy exposure: `references/content-and-quality.md`
- AI-engine visibility (crawlers, citations, off-site mentions): `references/ai-visibility.md`
- Webshops, local, multilingual: `references/ecommerce-local-international.md`

Look at the code, not only the rendered page. Many of the biggest problems live in templates: a noindex left from staging, a canonical pointing at the wrong host, a client-rendered product description, a robots.txt that blocks CSS/JS.

### 3. Prioritise

Produce a ranked list, not a dump. Score each finding on three axes and sort by impact over effort:

- **Impact**: does it block crawling/indexing (critical), suppress many pages (high), or polish a few pages (low)?
- **Evidence**: A = stated by Google/Bing/OpenAI/Anthropic documentation; B = consistent independent studies; C = vendor correlation or anecdote. Do not build a plan on C-level items. List them separately as "optional experiments".
- **Effort**: hours, days, or a project.

Order of attack that is right for nearly every site: (1) anything stopping indexing or crawling, (2) content that exists only in client-side JavaScript, (3) duplicate/canonical/redirect hygiene, (4) page-level relevance (titles, headings, intent match) on the money pages, (5) internal linking toward the pages that earn revenue, (6) genuine content gaps and depth, (7) structured data that earns a real feature (Product, Organization, Article, Breadcrumb, LocalBusiness), (8) page experience, (9) off-site authority and brand mentions, (10) measurement upgrades. Items 1-3 routinely beat everything else combined, which is why they come first.

### 4. Implement

Make changes directly in the project when the user wants fixes, in small reviewable commits. Prefer fixes at the template or component level over per-page edits so one change improves hundreds of URLs. After each batch:
- Re-run `seo_audit.py` and show the before/after.
- Validate structured data against the visible page content (markup must match what users see) with Google's Rich Results Test or the Schema.org validator.
- Never generate pages in bulk to chase long-tail queries. Google's spam policy on scaled content abuse applies to AI Overviews and AI Mode too, and SEO trackers report that thin, aggregated or programmatic content lost most in the 2026 core and spam updates (Google itself published no detail). Every new page needs a reason to exist that a competitor's page does not already satisfy.

When writing or revising copy, follow `references/content-and-quality.md`. In short: answer the query early and plainly, add something only this site can add (first-hand experience, original data, specifics, pricing, photos, named expert), cite sources, show real authorship, keep dates honest. Do not rewrite content "for AI", chunk it into fragments, or invent author profiles.

### 5. Measure and close the loop

Set up measurement before declaring victory (`references/measurement.md`): Search Console (including the Search Generative AI performance report, impressions only), Bing Webmaster Tools (AI Performance, citation data), GA4 with an AI-referral channel for ChatGPT/Perplexity/Claude/Copilot clicks, and a small fixed prompt set checked monthly across AI engines. Record a baseline now. Judge changes over 8-12 weeks, because crawling, indexing and core-update re-evaluation are slow, and never judge during a core update rollout.

## What to deliver

Unless the user asks for something else, end with this structure (keep it tight; the user should be able to act on it in one read):

```
## Summary
Site type, goal, overall health in 2-3 sentences. What is the single biggest lever?

## Prioritised actions
| # | Action | Why (evidence A/B/C) | Impact | Effort | Status |

## What I changed   (only if implemented)
Files and the effect of each.

## What I deliberately did not do
Tactics that look relevant but lack evidence (e.g. llms.txt, FAQ schema for rich results), so the user does not wonder.

## Measurement plan
Baseline numbers, what to check and when.
```

## Hard rules (and why)

- **Never block Googlebot or Bingbot, and never noindex something the user wants found.** One misplaced directive removes pages from AI answers as well, because eligibility requires being indexed with a snippet allowed.
- **Do not add `nosnippet`, `max-snippet:0` or `data-nosnippet` to content that should appear in AI answers.** Those controls limit what Google shows, including in AI features.
- **Distinguish search bots from training bots in robots.txt.** Blocking OAI-SearchBot or Claude-SearchBot removes the site from ChatGPT or Claude search; blocking GPTBot or ClaudeBot only opts out of model training. Which to allow is a business decision: surface the trade-off and let the user choose. See the crawler table in `references/ai-visibility.md`.
- **Do not fabricate authors, reviews, ratings, credentials or dates.** Google's guidance calls fake creator profiles deception, and fake review markup risks manual actions. Updating a date without a substantive change is also called out as search-engine-first behaviour.
- **Do not promise or imply guaranteed rankings or AI citations.**
- **Do not trust third-party claims of "internal Google metrics".** Google's own guide warns against them.
- **Check whether facts in this skill are stale** if the date above is old; use the volatile facts list below.

## Volatile facts: re-verify before relying on them

| Fact | Check at |
|---|---|
| Google's AI guidance and the "myths" list | developers.google.com/search/docs/fundamentals/ai-optimization-guide and /search/docs/appearance/ai-features |
| Search Console generative AI report scope (impressions only as of Nov 2026) | developers.google.com/search/blog/2026/06/gen-ai-performance-reports |
| FAQ rich results (removed from Search in 2026) and other rich result eligibility | developers.google.com/search/docs/appearance/structured-data/search-gallery |
| Core Web Vitals thresholds (LCP 2.5 s, INP 200 ms, CLS 0.1 at the 75th percentile) | web.dev/articles/vitals |
| AI crawler user agents | developers.openai.com/api/docs/bots, privacy.claude.com (Anthropic crawler article), docs.perplexity.ai/guides/bots |
| Bing AI Performance and IndexNow | blogs.bing.com/webmaster |
| Latest core and spam update dates | developers.google.com/search/status |
| Agentic commerce protocols (UCP, ACP) | developers.google.com/search/docs and Merchant Center docs |

If a check shows a change, trust the primary source over this file and tell the user what changed.
