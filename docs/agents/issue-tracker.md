# Issue tracker: local markdown

Issues and stories for this repo live as markdown files in `docs/stories/`, which `AGENTS.md` and
`docs/stories/README.md` already define as the one list of what is being built. There is no GitHub
Issues tracker and no `.scratch/` directory.

## Conventions

- One file per story: `docs/stories/<short-slug>.md`, deleted in the change that ships it.
- The YAML frontmatter of `docs/stories/README.md` is the contract: `title`, `milestone`, `area`,
  `status`, `value`, `effort`, `risk`. `status` is `draft`, `ready`, `in-progress` or `blocked`.
- The body holds `## Story` and `## Acceptance criteria`, each criterion testable without reading
  the code, exactly as that README asks.
- Triage state is the `status:` field, not a label: `draft` is untriaged, `ready` is fully
  specified and ready for an agent, `blocked` waits on a human or another story.
- Conversation history appends under a `## Notes` heading at the bottom of the file.
- Everything else — scratch notes, half-formed ideas, links — is not a story and stays out of
  `docs/stories/`. The maintainer's own notes live outside the repository.

## When a skill says "publish to the issue tracker"

Write or update one file under `docs/stories/`, in the format above, with `status: draft` unless the
maintainer says otherwise.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The maintainer normally passes the path or the story slug
directly; `docs/stories/README.md` is the index.

## Wayfinding operations

Used by `/wayfinder` when an effort is too big for one story. The map is a story file with
`status: blocked` and one child story per ticket.

- **Map**: `docs/stories/<effort>-0-map.md`.
- **Child ticket**: `docs/stories/<effort>-<NN>-<slug>.md`, numbered from `01`, with the question in
  the body under `## Story`.
- **Blocking**: a `Blocked by: NN, NN` line in the body. A ticket is unblocked when every story it
  lists has shipped or is `ready`.
- **Frontier**: scan `docs/stories/` for files that are open, unblocked and unclaimed; first by
  number wins.
- **Claim**: set `status: in-progress` and save before any work.
- **Resolve**: append the answer under `## Answer`, delete the file in the change that ships it,
  then append a one-line pointer to the map's `## Notes`.
