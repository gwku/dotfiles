# Technical SEO checklist

Order matters: a problem in an earlier section can make later sections irrelevant. Items marked **(A)** are stated by Google documentation.

## 1. Crawlability and indexability (check first, fix first)

- robots.txt returns 200, does not block the site or its CSS/JS/images, lists the sitemap(s). **(A)**: crawling must be allowed in robots.txt *and* by any CDN/WAF/hosting layer. Test with a Googlebot user agent against a real URL; bot-protection rules (Cloudflare, Vercel firewall, WordPress security plugins) silently block crawlers more often than robots.txt does.
- No `noindex` (meta or `X-Robots-Tag`) on pages that should rank. Staging flags that leaked to production are a classic.
- Every indexable URL returns 200. Redirects are single-hop 301/308. No redirect chains or loops; no soft-404s (200 with "not found" content).
- One canonical URL per page: self-referencing `rel=canonical`, absolute URL, same protocol and host as the redirect target. Parameters, trailing-slash and www/non-www variants all resolve to it.
- Important pages are reachable through crawlable `<a href>` links within a few clicks of the homepage. Links created only by JavaScript click handlers are invisible.
- XML sitemap: contains only canonical, indexable, 200 URLs; accurate `<lastmod>` (only update when content truly changes); referenced in robots.txt and submitted in Search Console. Split by type for large sites (sitemap index).
- Preview controls: do not apply `nosnippet`, `max-snippet:0` or `data-nosnippet` to content meant to surface in search or AI answers. **(A)** These control what is shown, including in AI features.
- Faceted navigation and internal search results are controlled (canonical to the clean listing, `noindex` for thin combinations, or robots rules) so crawl budget is not burned on infinite URL spaces. Matters mostly for sites above a few thousand URLs.

## 2. Rendering

- The primary content, headings, internal links, product info, price and availability are in the **initial HTML response**. Test: `curl -s -A "Mozilla/5.0" URL | grep -i "<some phrase from the page>"`. If the phrase is missing, the page depends on client-side JS.
- Why it matters: Googlebot renders JS (delayed, resource-limited), but major AI crawlers do not execute it. A CSR-only page is partly or fully invisible to ChatGPT search, Claude and Perplexity.
- Fix hierarchy: static generation or SSR for content pages (Next.js/Nuxt/Astro/SvelteKit/Laravel/WordPress already do this by default); islands/hydration for interactivity; prerendering as a last resort for legacy SPAs.
- Metadata (title, description, canonical, robots, hreflang, JSON-LD) must be in the server-rendered `<head>`, not injected after load.
- Lazy loading must not hide content: use native `loading="lazy"` for images below the fold and never for the LCP image; infinite scroll needs paginated, linkable URLs.
- Google recommends following its JavaScript SEO guide and notes perfectly semantic HTML is "not required" but recommended: use real headings, lists, tables, `<nav>`, `<main>`, `<article>`, `<button>` vs `<a>` correctly.

## 3. On-page essentials (per template, not per page)

- `<title>`: unique, front-loads the main topic, roughly 50-60 characters of visible length, brand at the end. Don't stuff keywords. Google may rewrite weak titles.
- `<meta name="description">`: unique, written as a pitch for the click (roughly 120-160 characters). Not a ranking factor; it influences CTR and is often what snippets draw from.
- One `<h1>` that matches the page's intent; logical `<h2>/<h3>` hierarchy; headings describe content (not decoration).
- Descriptive internal anchor text; meaningful image `alt` text (not keyword stuffing); descriptive file names; `width`/`height` attributes to prevent layout shift.
- URL structure: short, readable, lowercase, hyphens, stable. Don't change URLs without 301s and a reason.
- `<html lang>` correct; `hreflang` bidirectional and self-referencing when there are language/region variants (see `ecommerce-local-international.md`).
- Open Graph / Twitter tags for sharing (not ranking, but they shape click-through from social and messaging apps, and some AI/link-preview systems use them).
- HTTPS everywhere with HSTS; no mixed content; a proper 404 page that returns 404.

## 4. Structured data (JSON-LD)

Principle **(A)**: markup must match visible page content; no special markup exists for AI features; structured data is for rich-result eligibility and clear entity data.

Worth implementing where it applies and Google supports a feature (always check the current search gallery):
- `Organization` (site-wide: name, logo, URL, `sameAs` profiles, contact). Helps entity clarity and knowledge-panel accuracy.
- `WebSite` (+ name). `BreadcrumbList` on deep pages.
- `Article`/`BlogPosting` with `author` (a real Person with a profile URL), `datePublished`, `dateModified` (honest).
- `Product` + `Offer` (price, currency, availability) + `AggregateRating`/`Review` only if the reviews are real and visible on-page; merchant return and shipping policies via `MerchantReturnPolicy` / `OfferShippingDetails`. Keep identical to the Merchant Center feed.
- `LocalBusiness` subtype for physical locations (address, geo, opening hours, phone) consistent with the Google Business Profile.
- `VideoObject`, `Event`, `Recipe`, `JobPosting`, `SoftwareApplication`, `Course` when the page is genuinely that.

Skip: new `FAQPage`/`HowTo` markup for rich results (not displayed in Search in 2026), invented ratings, markup for content not on the page, and hidden or duplicated schema stacks from multiple plugins. Pick one source of truth (framework component, SEO plugin) and validate with the Rich Results Test and Search Console enhancement reports.

## 5. Page experience and performance

Thresholds at the 75th percentile of real-user (field) data: **LCP <= 2.5 s, INP <= 200 ms, CLS <= 0.1**. Use CrUX/PageSpeed Insights field data and Search Console's Core Web Vitals report; lab scores (Lighthouse) are for debugging only.

Highest-yield fixes:
- LCP: server response time (TTFB; cache HTML at the edge), preload and `fetchpriority="high"` for the hero image, modern formats (AVIF/WebP) at correct sizes, no lazy-loading the hero, remove render-blocking CSS/JS.
- INP: break up long tasks, defer third-party scripts (tag managers, chat widgets, consent tools), avoid heavy hydration on interactive elements, debounce handlers.
- CLS: reserve space for images/embeds/ads/banners; load web fonts with `font-display: swap` and size-adjusted fallbacks; never insert content above existing content.
- Mobile first: Google indexes the mobile version. The mobile page must contain the same content, structured data and metadata as desktop.
- Intrusive interstitials and aggressive cookie walls that cover content hurt users and can hurt performance; keep consent banners lightweight.

## 6. Security, hygiene and migrations

- No hacked/injected content or spammy outbound links; keep CMS plugins patched; monitor Search Console Security issues and Manual actions.
- Migrations (domain, CMS, URL changes): crawl before; map every old URL to its closest new equivalent with a 301; keep the old redirects for at least a year; update canonicals, sitemaps, internal links; use the Change of Address tool for domain moves; monitor index coverage and traffic daily for weeks after.
- Don't leave `X-Robots-Tag: noindex` on PDFs or assets you want found, and don't allow indexing of PDFs you don't.
- Expired or purchased domains repurposed for unrelated content, and third-party "parasite" content on your domain that you don't oversee, fall under spam policies (expired domain abuse, site reputation abuse). Audit subdirectories and subdomains that host partner or sponsored content.

## 7. Fresh-content signalling

- Accurate `lastmod` in the sitemap, and visible "last updated" dates only when the update is real.
- Optional: **IndexNow** pings Bing and participating engines when content is added, updated or removed (Bing says it helps keep search and AI experiences fresh). Google does not use IndexNow; rely on sitemaps and Search Console for Google. Cheap to add on sites that change often (news, inventory, jobs).
