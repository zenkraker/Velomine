# Astro Starlight 0.43.x (with Astro 7.4.x)

Checked 2026-11-26 from the npm registry (`npm view`). *Unverified* items were not confirmed; run `npm audit` after adding it.

## Need
The presentation site (`site/`) needs a documentation section (quick start, self-hosting, clubs, coaching, privacy) with a sidebar, search, next and previous links, dark mode and English and Italian. The platform has none of this. Writing it by hand in plain HTML is workable for about ten pages and then the navigation has to be edited on every page.

## Alternatives considered
- **Docusaurus** (what Immich uses): a React single-page app that ships a large JavaScript bundle and breaks the "no JavaScript" decision of the site. Rejected.
- **mdBook:** one Rust binary, small, but plain, weak i18n, and another toolchain. Not chosen.
- **VitePress:** Vue app, ships JavaScript. Not chosen.
- **Hand-written HTML:** zero dependencies; we maintain the navigation ourselves. The fallback if Starlight is dropped.

## Licence
MIT (Starlight and Astro). Compatible with this project.

## Maintenance
- Starlight 0.43.2, modified 2026-11-26; Astro 7.4.13, modified 2026-11-18, MIT. Both are maintained by the Astro organisation, which also runs the Astro framework itself.
- Commit activity, maintainer count and issue response times: *unverified*.
- Starlight is pre-1.0, so minor versions can contain breaking changes.

## Security
- Known advisories: `npm install` of Astro 7.4.13 and Starlight 0.43.2 on 2026-11-26 added 269 packages and `npm audit` reported 0 vulnerabilities.
- Direct dependencies of Starlight (not the full tree): `@astrojs/mdx`, `@astrojs/sitemap`, `pagefind`, `@pagefind/default-ui`, `astro-expressive-code`, `i18next`, `unified`, `vfile`, `hast-*`, `mdast-*`, `remark-directive`, `yaml`, `klona`, `satteri`, `@astrojs/markdown-satteri`, and a few more. The full tree is large; it is a build-time tree only and nothing of it runs on a server of ours.
- It runs only at build time, in CI and in the dev container. It is not in the web image and not in any self-hosted stack.

## Platform support
- Build tool only. Astro 7.4 needs Node `>=22.23.4`; the dev container has Node 24.22.3.
- The output is static HTML and CSS, published to GitHub Pages like the rest of `site/`.

## Size and performance
Pages are static HTML. Search is Pagefind, built at build time, with a small client script that loads only when someone opens search. Starlight's other client scripts (theme toggle, mobile menu, search) are the only JavaScript, and they must stay free of third-party requests.

## Risk and exit plan
- Risk: pre-1.0 API changes; a large build-time dependency tree.
- Exit: the content is Markdown with front matter. Moving to another generator, or to hand-written HTML, means changing the config and the layout, not the text.

## Recommendation
Approve with conditions (see `approved.md`): build tool only, exact versions with a committed lock file, output kept free of third-party requests, cookies and analytics.
