# Content, E-E-A-T and quality: what ranks and what gets demoted in 2026

## The standard Google applies

Google's helpful-content self-assessment and the Search Quality Rater Guidelines (updated through 2026) are the closest thing to a published rubric. Summarised:

- **Original value**: does the page provide original information, reporting, research or analysis, a substantial and complete treatment of the topic, insight beyond the obvious, and more value than other pages on the topic? "Non-commodity" content, with a unique point of view, is the 2026 phrasing in Google's AI guide.
- **E-E-A-T** (Experience, Expertise, Authoritativeness, Trust; trust is the centre): show first-hand experience (photos, test results, screenshots, case numbers), real authors with verifiable credentials, an About/contact page, transparent business details, clear editorial and review policies for YMYL topics (health, money, legal, safety). E-E-A-T is not a ranking factor you can switch on with markup; it's what raters and systems look for as signals of quality.
- **Authorship**: Google "strongly encourages" accurate bylines. Fabricated authors, AI-generated headshots, invented credentials are explicitly labelled deception.
- **People-first**: written for a defined audience, satisfies the need so the reader doesn't have to go back and search again. No preferred word count.
- **Search-engine-first red flags**: content produced mainly to attract search visits, summarising what others said without adding value, chasing trending topics outside the site's expertise, fake freshness (date changes without real updates), promising answers that don't exist.

## AI-assisted content: allowed, with conditions

Google does not penalise content for being AI-generated. It penalises low-value content however it is produced. Its guidance (updated October 2026) calls it **"critical to manually factcheck and review all AI-generated content for accuracy and trustworthiness before publishing"**, including titles, schema and alt text. Quality Rater Guidelines treat AI content with little originality or human input as potentially Lowest quality.

Working rules:
1. Use AI for drafting structure, research support, editing and translation checks; a named human with subject knowledge owns every published claim.
2. Add what a model can't know: real data, interviews, product testing, photos, local detail, pricing, outcomes, customer cases.
3. Verify every statistic, quote, price, date, legal or medical statement against a primary source and link it.
4. Never publish at scale without per-page differentiation. Scaled content abuse = "many pages generated for the primary purpose of manipulating search rankings and not helping users", regardless of method. It applies to AI Overviews and AI Mode (Google, May 2026). Industry trackers report that sites with many thin pages lose visibility sitewide and that scaled content featured heavily in the 2026 core and spam updates; that part is third-party analysis, not a Google statement.
5. Disclose AI assistance where readers would reasonably expect to know (Google's helpful-content questions ask whether AI use is evident through disclosures).
6. Programmatic pages (locations, comparisons, integrations) are fine only if each page has unique, useful data or experience; otherwise consolidate into one strong page.

## Search intent and topical depth

- Map each target query to one dominant intent (informational, commercial investigation, transactional, navigational, local). Check the live results and AI Overview for the query: the format that wins (guide, category page, tool, video, forum thread) is the format to build. Don't write a blog post for a query where Google shows product listings.
- One primary page per intent. Two pages chasing the same query cannibalise each other. Use Search Console (Performance > query > pages) to detect it, then merge, redirect or differentiate.
- **Query fan-out (A)**: AI Overviews and AI Mode split a question into many sub-searches. A page that answers the main question and the obvious follow-ups (cost, alternatives, how to choose, risks, who it's for, comparisons, what next) is eligible for more of those sub-queries. Build clusters: a strong hub page, supporting pages for distinct sub-intents, strong internal links both ways. Don't pad.
- Lead with the answer. A concise, direct answer near the top (then the supporting detail) serves readers, featured snippets and AI summarisers alike. This is good writing, not an AI trick.
- Specifics beat generalities: numbers with sources, named examples, dated facts, step-by-step detail, tables where comparisons exist. Generic "ultimate guide" text that restates the top 10 results is exactly the commodity content that lost visibility in 2026.
- Add a visible, honest "last reviewed/updated" date on content that goes stale (prices, regulations, software). Re-review key pages quarterly or when facts change.

## Page-level craft

- Title and H1 reflect the query and promise; the first 100 words confirm it.
- Short paragraphs, descriptive subheadings, lists and tables where they help scanning; images, video, diagrams that add information, with captions and alt text. Important content in text form (A), not only inside images or video.
- Visible author box with a link to a real author page (bio, credentials, other work, social profiles). Reviewer credits on YMYL.
- Cite and link out to primary sources when you rely on them. Outbound links to good sources do not hurt rankings.
- Internal links: from every new page to its hub and siblings; from high-authority pages (home, popular posts) to pages you want to push; with descriptive anchors.
- Avoid: doorway pages, tag/archive pages with thin content set to index, auto-translated content without review, comment/forum spam, hidden text, keyword-stuffed footers.

## Spam policy exposure checklist (all apply to AI features too)

- Scaled content abuse, site reputation abuse (third-party content on your strong domain primarily to exploit its ranking; the policy is now framed as site reputation, and enforcement in the EEA works differently since 30 Aug 2026 per one report: verify), expired domain abuse.
- Link spam: bought links, link exchanges at scale, hidden links, large-scale guest-post campaigns with optimised anchors, comment/forum signatures. Use `rel="sponsored"` for paid, `rel="ugc"` for user content.
- Cloaking, sneaky redirects, hidden text; misleading structured data; fake reviews.
- Check Search Console > Security & Manual Actions regularly.

## Links and mentions (authority)

Links still matter as evidence of reputation, but the efficient, durable approach in 2026 is to earn them as a by-product of being the best source: original research, tools, data, expert commentary, local partnerships, quality PR. For AI engines the correlational data points to **brand mentions across independent sites** as strongly associated with visibility, so digital PR and community presence serve both goals. Don't buy mentions; Google warns inauthentic mentions are "not as helpful as they seem", and low-quality link schemes risk spam actions.

## Recovering from a core or spam update

1. Confirm it's the update: compare Search Console dates against the rollout window (developers.google.com/search/status). Wait until the rollout is complete before changing anything.
2. Segment losses by page type and query intent. Look for common traits: thin, templated, affiliate-only, outdated, no author, off-topic for the site.
3. Improve or prune. Merge duplicates, delete or noindex pages that add nothing, deepen the pages that should win, add real expertise and sourcing. Cosmetic rewrites do not work.
4. Expect recovery, if any, at a later core update. Document the changes; set expectations for months, not weeks.
5. For spam-update hits: remove the violating tactic (scaled pages, unnatural links, site-reputation content), then wait for the next spam update or submit a reconsideration request if there's a manual action.
