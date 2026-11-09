# Evidence ledger: what is proven, what is folklore

Read this before recommending any tactic you are not certain about, and whenever the user brings a "GEO hack" they saw online. Grades:

- **A** = stated in primary documentation from the search engine or AI vendor.
- **B** = consistent independent data, but not confirmed by the vendor, or an older study that may have aged.
- **C** = single-vendor correlation, anecdote, or marketing. Do not base a plan on it.

Verified 2026-11-09. The SEO vendor ecosystem produces a lot of confident statistics; most are correlational and many come from companies that sell GEO tooling. When a number matters, find the original study and check its method.

## Google: how AI features work

| Claim | Grade | Notes |
|---|---|---|
| AI Overviews and AI Mode run on core Search ranking and quality systems; GEO/AEO is "still SEO" | A | Google's guide, May 2026 |
| To appear: page must be indexed and eligible to show a snippet; "no additional requirements" | A | ai-features doc |
| No special schema.org markup, AI text files, or markup/Markdown files are needed | A | ai-features doc and 2026 guide |
| llms.txt is not used by Google Search | A | 2026 guide: "Google Search itself doesn't use them" |
| Chunking content into small pieces is not required | A | 2026 guide |
| You need not write differently for generative AI search | A | 2026 guide |
| Both features may use "query fan-out" (many related sub-searches) | A | ai-features doc. Implication: cover the topic's sub-questions with depth, so one page answers several fan-out queries |
| AI Overviews only appear when "additive to classic Search" | A | Many queries never trigger one |
| AI-feature clicks and impressions are inside the Search Console "Web" search type; a dedicated Generative AI report shows impressions only | A | Blog, 2026-06-03; rollout to all sites announced 2026-08-31 |
| Existing spam policies apply to AI Overviews and AI Mode; no new categories | A | Policy doc update, 15 May 2026 (reported) |
| Manually fact-check and review AI-generated content before publishing | A | Google's AI-content guidance, updated Oct 2026 |
| No preferred word count | A | Helpful content doc |
| Faking freshness by changing dates without substantive changes is search-engine-first behaviour | A | Helpful content doc |
| Fabricated creator profiles are deception | A | Helpful content doc; Quality Rater Guidelines |

## Structured data

| Claim | Grade | Notes |
|---|---|---|
| Structured data must match visible content; it earns rich results where Google supports the type | A | |
| FAQ rich results no longer appear in Google Search (2026) | B | Many sources quote a notice added to Google's FAQ doc around May 2026; I did not read it directly. Keeping existing FAQPage markup is harmless; don't add new FAQ schema hoping for a rich result. Showing real Q&A on the page is still good content. |
| HowTo rich results are gone | A | Retired 2023 |
| Product, Article, Organization, BreadcrumbList, LocalBusiness, Review snippet, Event, Recipe, VideoObject still produce features | B | Check the current search gallery before promising a feature |
| Schema increases AI citations | C | An Ahrefs analysis found no causal lift; SE Ranking saw FAQ-schema pages cited less. Schema's value is rich results and unambiguous entity data, not an AI boost |

## llms.txt and similar files

| Claim | Grade | Notes |
|---|---|---|
| Major AI search engines request llms.txt and use it for answers | C | Ahrefs 2026 study (137K sites): 97% of llms.txt files never fetched; one dataset showed PerplexityBot reading it zero times vs 775 robots.txt fetches. A conflicting report says OpenAI bots fetch it sometimes. No vendor documents using it for ranking or citation |
| Adding it is harmful | C | No evidence. It is cheap (under an hour) and harmless |

Verdict: not worth prioritising. If the user wants it anyway (e.g. a documentation site where developers use coding assistants), ship a short curated one, set no expectation of ranking or citation gains, and say so.

## What seems to correlate with being cited by AI engines (all B/C, correlational)

- Brand mentions across the web: Ahrefs (75K brands) found branded web mentions correlate ~0.66 with AI Overview visibility versus ~0.22 for backlinks; AirOps reports similar. Most citation-driving mentions sit on third-party domains. Google cautions that manufacturing "inauthentic mentions" is not as helpful as it seems. Interpretation: be genuinely known (PR, partnerships, reviews, communities, original research people reference), do not buy mentions.
- Referring domains/overall authority still predict ChatGPT citations in SE Ranking data (confounded with brand size).
- Freshness: Ahrefs (17M cited URLs) found cited pages ~26% fresher than organic results on average. Keep important pages truly current; do not fake it.
- Overlap with Google's top 10 is partial and varies by study (12-38% in reported figures), so ranking well is helpful but not the whole story.
- Pages that state a clear answer, give sourced statistics, quotes and specifics are cited more in the original GEO research (Aggarwal et al., KDD 2024; tested on a research setup, not production engines) and in vendor follow-ups. This matches good editorial practice anyway, so adopt it as writing quality, not as a hack.
- Longer, list-dense pages correlate with citations in one 21K-citation study. Google says length itself doesn't matter. Treat as: comprehensive pages answer more fan-out queries.
- Reddit, Wikipedia, YouTube, review sites and forums are cited heavily in several datasets. Being discussed truthfully where your audience talks is plausible leverage. Do not astroturf; it violates platform rules and can backfire.

## Traffic impact of AI Overviews

Evidence is directionally negative for informational queries and mixed on size:

- Seer Interactive: ~61% organic CTR drop on informational AIO queries (mid-2024 to mid-2025), then a levelling-off/partial rebound in early 2026; brands cited inside an AIO saw ~35% higher organic CTR than uncited.
- Ahrefs: position-1 CTR on AIO keywords fell from 7.3% (Mar 2024) to 1.6% (Dec 2025) in one analysis; another reports ~34.5% lower CTR.
- Pew: 8% of visits with a click when an AIO is shown vs 15% without.
- Google says clicks from AIO pages are "higher quality".

Implication for strategy: informational top-of-funnel traffic is the most exposed. Shift emphasis toward queries with commercial or transactional intent, branded demand, and content AI summaries cannot replace (tools, original data, first-hand reviews, local, inventory, pricing). Report impressions, brand queries and conversions, not clicks alone.

## Core Web Vitals

LCP <= 2.5 s, INP <= 200 ms, CLS <= 0.1, assessed at the 75th percentile of real-user data: unchanged in primary documentation and most 2026 sources. One vendor blog claims a March 2026 tightening to 2.0 s / 150 ms; I found no confirmation, so do not use those numbers. Treat page experience as a tie-breaker and a conversion lever, not a ranking silver bullet; fix severe failures, don't chase perfect scores.

## AI crawler JavaScript rendering

Vercel/MERJ (Dec 2024) found the major AI crawlers (GPTBot, OAI-SearchBot, ClaudeBot and others) fetch JavaScript files but do not execute them. Googlebot does render. Grade B: it's an older study, so verify on the live site: view the raw HTML (`curl`) and check that the main content, headings, product details and internal links are present. If they aren't, non-Google AI engines cannot see them.

## Core updates in 2026 (what is known)

Confirmed by trackers (Google gave only generic descriptions): core updates 27 Mar-8 Apr and 21 May-2 Jun 2026 (after a Dec 2025 update); spam updates in March, June, August and September-October 2026. Reported pattern: official sources, specialist sites and established brands gained; thin affiliate pages, aggregators, directories, thin ecommerce and scaled/programmatic AI content lost. Google publishes no recovery recipe other than the helpful-content self-assessment; recovery tends to arrive only with a later core update after genuine improvement.
