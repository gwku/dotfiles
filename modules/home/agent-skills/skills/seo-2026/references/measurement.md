# Measurement: baseline, tools, and honest attribution

AI search visibility is only partly measurable. Triangulate from several imperfect sources rather than chasing one precise number.

## Tool by tool (state as of Nov 2026)

### Google Search Console
- Verify a **Domain property** (DNS) to see all protocols and subdomains.
- **Performance report**: AI Overviews and AI Mode impressions *and clicks* are counted inside the normal **Web** search type; they can't be isolated there. Track total clicks, impressions, CTR and position by query, page, country, device. Segment branded vs non-branded queries (regex filter on the brand name and common misspellings): non-branded informational is where AI summaries bite; branded is the health of your reputation.
- **Search Generative AI performance report** (announced 3 Jun 2026; rolled out to all sites by 31 Aug 2026 per Google's note): impressions of your URLs inside generative AI features in Search (AI Overviews, AI Mode together) and Discover, by page, country, device and date. **No clicks, CTR or queries.** Use it to see which pages are being surfaced, and compare against Performance report trends. Google says more metrics will follow.
- Index coverage / Pages report, sitemaps, Core Web Vitals, Manual actions, Security issues, Crawl stats (shows Googlebot request volume, response times and host problems).
- With the Search Console MCP: `search_analytics` / `enhanced_search_analytics` for query data, `detect_quick_wins` for pages at positions 4-15 with high impressions, `index_inspect` for per-URL status, `list_sitemaps` / `get_sitemap` for sitemap health.

### Bing Webmaster Tools
- Verify the site (import from Search Console is the fast path). Submit the sitemap. Enable **IndexNow** where content changes often.
- **AI Performance** report (public preview Feb 2026; expanded June 2026 with Intents, Topics, Citation Share, Compare; Topics Portfolio beta Oct 2026): citations of your pages across Microsoft Copilot, Bing AI summaries and select partners; cited pages, grounding queries, trends, and citation share. Microsoft says the figures are a sample and "not a ranking system": use them directionally. It's the only first-party citation data any engine currently gives publishers, so it is worth the 10-minute setup even for Google-focused sites. The *grounding queries* show the real questions that retrieve your content; mine them for content ideas.

### GA4 (or server-side/consent-aware alternative)
- Create a custom channel group or exploration that captures AI referrals by source: `chatgpt.com`, `chat.openai.com`, `perplexity.ai`, `claude.ai`, `gemini.google.com`, `copilot.microsoft.com`, `bing.com/chat`, `you.com`, `poe.com`, `duckduckgo.com` (AI chat). GA4 now has a native "AI Assistant" default channel for some of these sources; check yours.
- Clicks from Google AI Overviews and AI Mode arrive with a google.com referrer and are filed under **Organic Search**; they can't be separated reliably. Don't claim to measure them in GA4.
- Many AI assistants strip referrers or open in-app, so some visits show as Direct. Treat AI referral numbers as a floor. Look at landing pages that rise in Direct traffic without campaigns.
- Track conversions from these sources, not just sessions. AI referral visitors often convert at different rates; the point is value, not volume.
- Add UTM-less detection via landing-page + referrer patterns in BigQuery if you need precision.
- Real data via the GA4 MCP: `run_report` with `sessionSource` / `sessionDefaultChannelGroup` dimensions.

### Manual prompt panel (monthly, ~30 minutes)
- Choose 15-30 prompts a real buyer would ask: category ("beste ... voor ..."), comparison, problem, local, brand. Include Dutch and English where relevant.
- Run them in Google (AI Overview/AI Mode), ChatGPT with search, Perplexity, Copilot and Claude with search. Record per prompt and engine: are you mentioned, cited (URL), in what position, with what claim, which competitors, any factual errors.
- Use a fixed sheet so month-on-month is comparable. Responses vary run to run, so repeat each prompt 2-3 times and score presence as a rate, not a yes/no.
- Treat wrong claims as tasks: find the source page (yours or third party) and fix or correct it.
- Third-party "AI visibility" tools (Profound, Peec, Otterly, Semrush AI toolkit, etc.) automate this; they sample non-deterministic outputs and are vendor-defined. Fine for trend watching, not for hard KPI promises. Google warns against tools claiming "internal Google metrics".

### Server logs / CDN analytics
Count requests from `Googlebot`, `Bingbot`, `OAI-SearchBot`, `GPTBot`, `ChatGPT-User`, `Claude-SearchBot`, `ClaudeBot`, `PerplexityBot` with response codes. Verify bots by published IP ranges where precision matters (user agents are spoofable). Rising 4xx/5xx for a search bot is an urgent fix.

## Baseline to record before any change
1. Search Console: 3 months of clicks, impressions, CTR, position; branded vs non-branded split; top 20 pages and queries; indexed page count; CWV status.
2. Bing: indexed pages; AI Performance citations and grounding queries if available.
3. GA4: organic sessions, AI-referral sessions, conversions and revenue from organic.
4. Prompt panel results (first run).
5. Audit script output saved to a dated file.

## KPI set that matches how search works now
- Non-branded clicks and impressions for target topics (is demand captured?).
- Branded query volume (is awareness growing?). A rising brand search trend is the best proxy that AI mentions and PR are working.
- Share of target prompts where you are cited (prompt panel) and Bing citation share.
- Conversions and revenue from organic and AI referrals.
- Index coverage of important URLs; share of URLs passing Core Web Vitals.
- Not recommended as headline KPIs: average position alone, total traffic alone, domain "authority" scores from vendors, AI-visibility index numbers you can't audit.

## Cadence and evaluation windows
- Weekly: Search Console errors, manual actions, crawl anomalies after releases.
- Monthly: KPI review, prompt panel, content refresh list.
- Quarterly: audit rerun, content pruning/merging, authority/PR review.
- Judge changes after 8-12 weeks. Do not attribute changes during a core update rollout (check developers.google.com/search/status). Annotate GA4 and keep a change log (date, URLs, what changed) so results can be explained later.

## Reporting to stakeholders
Say what is measured and what is inferred. Example wording: "Impressions in Google's AI features rose 40% (Search Console generative AI report). Clicks from those features can't be separated from organic, so we track total non-branded organic clicks and conversions as the outcome." Never present a vendor AI-visibility score as ground truth.
