# AI-engine visibility: crawlers, citations, and what to do beyond Google

Scope: ChatGPT search, Claude, Perplexity, Microsoft Copilot/Bing, Gemini, and Google's AI Overviews / AI Mode. For Google's own features the answer is "do normal SEO well" (see `evidence-and-myths.md`). This file covers the extra layer.

## How these engines get content

1. **Search/retrieval index**: a vendor crawler builds an index; the assistant retrieves from it at answer time ("grounding") and cites pages. Blocking the vendor's *search* bot removes you from that assistant's answers.
2. **Live fetch on user request**: the assistant fetches a URL the user supplied or the model decides to open. Often ignores robots.txt because a human triggered it.
3. **Training crawl**: collects data to train models. Blocking opts out of training, with no direct effect on answer citations (but see the caveat below).
4. **Borrowed index**: some assistants use a third party's index (Copilot uses Bing; others have used Bing or Google results). Ranking well in Bing therefore matters for Copilot and some others, which is why Bing Webmaster Tools is worth setting up.

## Crawler reference (verified from vendor docs, Nov 2026)

| Vendor | User agent | Purpose | Effect of blocking in robots.txt |
|---|---|---|---|
| Google | `Googlebot` | Search index, also the source for AI Overviews / AI Mode | Removes you from Search and its AI features. Never block. |
| Google | `Google-Extended` (robots token) | Controls use of content for Gemini model training and grounding in some other Google systems | Does not affect Search ranking or inclusion in AI Overviews/AI Mode (those follow Googlebot and snippet controls). |
| OpenAI | `OAI-SearchBot` | Surfaces sites in ChatGPT search | Removes you from ChatGPT search results. Changes take ~24h. |
| OpenAI | `GPTBot` | Training of foundation models | Opts out of training only. Independent setting. |
| OpenAI | `ChatGPT-User` | Fetches on behalf of a user action | "robots.txt rules may not apply". Not for automatic crawling. |
| Anthropic | `Claude-SearchBot` | Improves search result quality for Claude users | Blocking "may reduce your site's visibility and accuracy in user search results". |
| Anthropic | `ClaudeBot` | Collects web content that may contribute to training | Opts out of training. |
| Anthropic | `Claude-User` | Fetches when a Claude user asks | User-initiated. |
| Perplexity | `PerplexityBot` | Surfaces and links sites in Perplexity results; not used to train foundation models | Removes you from Perplexity results. |
| Perplexity | `Perplexity-User` | User-initiated fetch | "Generally ignores robots.txt rules". |
| Microsoft | `Bingbot` | Bing index; feeds Copilot and Bing AI summaries | Never block. |

Anthropic notes that since 30 Oct 2026 it also recognises a machine-readable training-preference signal, and that rules naming ClaudeBot in robots.txt take precedence over a general setting. Re-read vendor pages before editing production rules; user agent lists change.

### robots.txt policy to recommend

Default for a business that wants visibility (most clients): **allow all search/retrieval and user-initiated agents, decide training bots as a business choice.**

```
# Search and retrieval bots: allow (they decide whether you appear in AI answers)
User-agent: OAI-SearchBot
Allow: /

User-agent: Claude-SearchBot
Allow: /

User-agent: PerplexityBot
Allow: /

# Training bots: business decision. Uncomment to opt out of model training.
# User-agent: GPTBot
# Disallow: /
# User-agent: ClaudeBot
# Disallow: /
# User-agent: Google-Extended
# Disallow: /

Sitemap: https://example.com/sitemap.xml
```

Things to explain to the user when they decide:
- Publishers selling content licences or wary of unlicensed training often block the training bots. Brands that want to be recommended usually don't care about training and gain nothing from blocking.
- Blocking a training bot is not guaranteed to stop all use, and allowing one does not guarantee citations.
- Paths that must stay private should be protected by authentication, not robots.txt.
- Also check the CDN/WAF: a managed "AI bot" block rule in Cloudflare, Vercel, Akamai etc. can silently block the search bots you wanted to allow. Verify with the audit script and server logs.
- Server logs (or CDN analytics) are the ground truth for which AI bots actually visit and what status they get.

## Making content retrievable and quotable

1. **Content in initial HTML.** AI crawlers do not run JavaScript (grade B, verify live). SSR/static output for everything you want cited.
2. **Fast, stable responses.** Bots have timeouts; slow or error-prone pages are dropped. Return 200 quickly to bot user agents.
3. **Plain, extractable structure.** Descriptive headings, an answer-first paragraph, lists and tables for comparable facts, definitions stated explicitly, one idea per section. This is ordinary good writing. Google explicitly says you do not need to chunk or rewrite for AI; the retrieval systems of other engines reward the same clarity.
4. **Self-contained facts.** Each key claim (price, spec, policy, location, date, who/what/how many) is stated in text on the page with its qualifiers, so a quoted sentence is accurate out of context. Wrong or ambiguous facts get repeated wrongly by AI answers; correcting them requires fixing the source pages.
5. **Source-backed specifics.** Statistics with a named source, quotes from named experts, original data and methodology. The GEO paper and later vendor studies associate these with higher citation rates; it also builds trust for humans.
6. **Entity clarity.** Consistent business name, address, description, logo, and profile links across the site, `Organization` schema with `sameAs`, Google Business Profile, Bing Places, LinkedIn, Wikipedia/Wikidata where genuinely notable, Crunchbase or industry directories. Assistants resolve "who is this company" from many sources; inconsistency creates wrong answers.
7. **Freshness where it matters.** Pricing, availability, opening hours, regulations, software versions. Keep truly current, show honest dates, and use IndexNow for Bing.
8. **A dedicated, crawlable page for each thing people ask about** (service, product, location, comparison, pricing, "how it works", "vs alternatives", policies). Assistants can only cite what exists as a clear page.

## Off-site: where the strongest correlations are

The best-supported driver of AI-answer inclusion, beyond being crawlable and relevant, is **being talked about credibly by independent sources** (grade B/C, correlational). Practical, legitimate actions:

- Digital PR: original research, benchmarks, surveys or data a journalist or industry blog will cite. One citable dataset outperforms ten generic posts.
- Expert presence: bylined articles, podcast and conference appearances, contributed quotes, with real people and credentials.
- Reviews and listings: collect genuine reviews on the platforms your buyers use (Google, Trustpilot, G2/Capterra, Kiyoh and Trustpilot are common in NL, sector directories). Respond to them.
- Community: participate truthfully in Reddit, LinkedIn, Quora, niche forums and YouTube with disclosed affiliation. Do not astroturf or seed fake threads: it violates platform rules, gets detected, and Google calls manufactured mentions unhelpful.
- Partnerships and associations: listings on partner, supplier, chamber of commerce and industry association pages (also local-SEO relevant).
- Wikipedia/Wikidata only if the organisation or topic meets notability rules; never self-promote.

## Controlling what AI shows (optional)

- Google: `nosnippet`, `data-nosnippet`, `max-snippet`, `noindex` limit what Search (including AI features) can show; `Google-Extended` limits training/grounding in other Google systems. Using them reduces visibility, so apply only to content the user wants withheld. Search Console may also offer a property-level control over inclusion in generative AI features; confirm in the account before advising.
- OpenAI, Anthropic, Perplexity: robots.txt rules as above.
- There is no way to guarantee how an assistant describes you. Monitor and correct the sources.

## Agent-readiness (low priority, only if relevant)

Google's guide lists review of web.dev's agent-friendly guidance and the Universal Commerce Protocol as optional "if you have extra time". Practical baseline that costs little: accessible HTML forms and buttons with real labels, stable URLs, clear states and error messages, no CAPTCHAs on read-only flows. For shops, see `ecommerce-local-international.md`.
