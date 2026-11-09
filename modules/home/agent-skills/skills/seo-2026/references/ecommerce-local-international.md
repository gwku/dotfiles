# Ecommerce, local and multilingual SEO

Google's AI guide singles out these as the places where structured business data matters: "Optimize local business and ecommerce details" using **Merchant Center feeds and Google Business Profiles**, keeping them current and consistent with the site.

## Webshops

### Product and category pages
- Every product page: unique title and H1 (brand + model + key attribute), unique description (not the supplier boilerplate copied across 500 shops), real specs in HTML text (not images or tabs that load only on click), price and availability visible in the initial HTML, multiple good images with alt text, clear shipping and returns info, real reviews.
- Category pages are usually the money pages for non-branded queries. Give each one an intro with buying guidance (short, useful, near the top), filters that do not create crawl traps, internal links to subcategories and best sellers, and pagination with crawlable links. Do not hide the SEO text at the very bottom of a 200-product page and consider it done; place useful guidance where users read it.
- Variants (size/colour): either one canonical product page with variant selection, or separate URLs only for variants people search for separately (with unique content). Avoid indexing dozens of near-identical variant URLs.
- Out-of-stock: keep the page (200) with alternatives if it will return; 301 to the closest equivalent or category if permanently discontinued; 410 if nothing relevant exists. Reflect availability in `Offer.availability`.
- Faceted navigation: allow indexing only for facets with real search demand (e.g. "witte sneakers dames"), canonicalise or noindex the rest.

### Structured data and feeds
- `Product` with `Offer`, `priceCurrency`, `price`, `availability`, `brand`, `gtin/mpn/sku`, and real `AggregateRating`/`Review`; `MerchantReturnPolicy` and `OfferShippingDetails`. Values must match the visible page and the feed. Mismatches cause disapprovals and lost rich results.
- Merchant Center: free listings feed Google Shopping surfaces, and per Google the feed and Business Profile data support eligibility and accuracy in AI features. Keep titles, GTINs, prices, availability, shipping and returns current; fix disapprovals; use automatic improvements and the diagnostics report; keep feed refresh frequent for volatile stock. If the Merchant Center MCP tools are available, use `gmc_list_disapproved_products`, `gmc_summarize_product_issues`, `gmc_demoted_products` and `gmc_product_performance` to find concrete wins.
- **Agentic commerce (emerging, verify before investing):** Google announced the Universal Commerce Protocol (UCP) in Jan 2026 with partners such as Shopify; checkout inside AI Mode/Gemini relies on UCP and feed attributes (reports mention a `native_commerce` attribute; confirm in Merchant Center docs). OpenAI's Agentic Commerce Protocol (ACP) launched with Instant Checkout in 2025, and several sources report that native checkout was scaled back in March 2026 while product feeds still support discovery. Shopify and other platforms are adding these integrations. Action: on Shopify/Woo/Magento, enable the platform's AI-commerce features when stable; otherwise ensure the product catalog is clean, complete and machine-readable. Do not rebuild checkout for a protocol still in flux.
- Reviews: collect verified reviews, display them on-page, and mark them up honestly. Self-serving or fake reviews risk manual actions.

### Trust and conversion signals (these help rankings indirectly and conversions directly)
Visible contact details, KvK/company data, VAT info, returns and shipping policy, payment options, security badges that are real, customer reviews, delivery times. Google's quality systems treat shopping pages as high-trust contexts.

## Local SEO

- Google Business Profile: correct primary category, secondary categories, services, hours (including holidays), photos, products, Q&A answered, posts occasionally, reviews answered. Name/address/phone identical to the website and to citations (NAP consistency).
- One landing page per location and per core service-location combination that has real substance (staff, photos, area details, local proof, directions), not 200 templated "service in [city]" pages (that is scaled/doorway content).
- `LocalBusiness` (or subtype) JSON-LD matching the profile. Embed a map and clear contact details in HTML text.
- Reviews: steady flow of genuine reviews with a direct review link; never offer incentives that violate Google's policy; respond to all.
- Citations: Bing Places, Apple Business Connect, industry and regional directories (Telefoonboek / Detelefoongids, Yelp where relevant), chamber of commerce. AI assistants consult these.
- For AI answers about "best X near me", reviews text, category fit and consistent entity data are what's available to the model. Encourage reviews that describe the service concretely.

## Multilingual and multi-region (default markets here: NL, BE, EN)

- Dutch (nl-NL), Flemish (nl-BE), English (en) can use separate URLs per locale (subfolder or ccTLD) with **bidirectional `hreflang`**, a self-reference, and an `x-default`. Cross-check with the audit script's hreflang output. Hreflang is a hint to pick the right variant, and it only works when every variant links back.
- Translate and adapt with a native reviewer; do not publish raw machine translation at scale (scaled content risk). Localise currency, units, legal info, examples and search terms: Dutch users search differently from translated English keywords. Do keyword research in the target language.
- `<html lang>` set per page; canonical per language version (self-referencing, not pointing to the other language).
- Don't auto-redirect users by IP/language in a way that blocks crawlers; offer a language switcher with crawlable links.
- AI context: Google's AI Overviews and AI Mode are available in Dutch in the Netherlands and Belgium (AI Mode launched in NL on 10 Oct 2025). Measure Dutch-market impressions in the Search Console generative AI report filtered by country. Reported ad rollout in AI Mode to more countries (Oct 2026): confirm for NL before planning.
- GDPR/ePrivacy: consent tooling affects analytics completeness. Consent Mode v2 and server-side measurement reduce the gap; expect under-reported organic and AI-referral sessions when consent is denied.

## Publishers and content sites

- Original reporting, named authors, corrections policy, clear separation between editorial and sponsored content (`rel="sponsored"`, labels). Third-party/sponsored content hosted on your domain mainly to borrow its ranking is a site reputation abuse risk.
- Informational traffic is the most exposed to AI Overviews. Build direct relationships (newsletter, app, community) and original content (data, analysis, tools, video) that summaries can't substitute; make sure your brand is the cited source.
- Google Discover rewards fresh, original, visually strong content with a clear topic identity; the generative AI report now also covers Discover impressions.

## SaaS and B2B lead gen

- Own the commercial-intent pages: solution, use-case, industry, integration (only where genuinely substantive), comparison/alternatives (fair, specific, with evidence), pricing (state real numbers or ranges; assistants often answer pricing questions and will use third-party guesses if you don't), security/compliance, documentation.
- Documentation and help content is heavily used by AI assistants; keep it indexable, in HTML, versioned and accurate.
- Case studies with named customers, numbers and quotes are strong E-E-A-T and citation material.
- Capture demand where buyers research: G2/Capterra/Trustpilot profiles, industry communities, analyst and partner listings.
