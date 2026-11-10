# To move out

These files belong in the private ops repository, not here. `AGENTS.md` keeps operations out of this repository; they wait here only until they are moved.

| Here | What it is |
|------|------------|
| `infra-demo/` | OpenTofu for the public demo on Scaleway (VPS, managed PostgreSQL, registry, backup bucket). Was `infra/demo/`. |
| `deploy-demo/` | Compose, Caddy, restic backups and update timers for the demo host. Was `deploy/demo/`. |
| `.github/workflows/demo-image.yml` | CI that ran the tests and pushed the demo image. Was `.github/workflows/demo-image.yml`; GitHub does not run it from here. |

Paths inside these files still use their old locations. Do not extend this folder: move it out, then delete it.
