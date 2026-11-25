# Stories

The one list of what is being built. A story is a file here, and it is deleted in the change that ships it.
`AGENTS.md` keeps no roadmap: this directory is the roadmap.

A story is written for an agent, in English, short enough to read in one screen.

## Format

One file per story, `docs/stories/<short-slug>.md`:

```markdown
---
title: Member sees their weekly totals
milestone: 0.3.0
area: progress
status: ready        # draft | ready | in-progress | blocked
value: club          # which paying band or rider it serves, per docs/business.md
effort: 2 days
risk: low            # low | medium | high, with one line why
---

## Story

As a member, I want … so that …

## Acceptance criteria

- [ ] One observable statement per line, each testable without reading the code.
- [ ] …

## Out of scope

- The things this story deliberately does not do.

## Open questions

- Only ones the CEO or the architect must answer, each naming who answers it.
```

## Rules

- A story without acceptance criteria is not ready, and is not started.
- A **feature** — a new screen, endpoint, table or background job — needs a story. A bug fix does not.
- `milestone` is a version, matching the tags in `.github/workflows/release.yml`: `dev` carries
  `X.Y.Z-dev.N` and `main` releases `X.Y.Z`. What ships in a version is the set of stories carrying it, never
  a second list.
- `value` says who pays for it. If nothing in `docs/business.md` justifies the story, it is not ready.
- The architect reviews a story before code. Open questions are answered, or the story waits.
