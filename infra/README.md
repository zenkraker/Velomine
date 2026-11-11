# Velomine infrastructure

OpenTofu for the hosted environments on Scaleway: the demo, and dev, staging and
prod. No modules, no tenancy. What runs on the machines is in `deploy/host/`.

## What it creates

Demo:

- `STARDUST1-S` VPS on Ubuntu 24.04, with Docker and a `deploy` user.
- `DB-DEV-S` managed PostgreSQL, private network only, 7-day backups, with the
  `velomine` database.
- A record for `demo`.

Dev, staging and prod:

- One `DEV1-M` VPS (4 GB) for the three environments.
- One `DB-DEV-S` managed PostgreSQL instance with a database and a user per
  environment (`velomine_dev`, `velomine_staging`, `velomine_prod`). A user can
  connect only to its own database. The initial user `velomine_admin` is for
  the operator only.
- A records for `dev`, `staging` and `app` (prod).

Shared:

- One private network between the VPSs and the databases. The security group
  opens 80/443 to everyone and 22 to `admin_cidr` only.
- Object Storage bucket in another region for restic backups.
- A records for the root and `www`, pointing at the host that runs `apex_env`.
- A private Scaleway Container Registry namespace. Images are on GHCR now
  (`ghcr.io/zenkraker/velomine`); remove the namespace once the demo pulls from
  GHCR.

## What it does not create

- Tenancy, tenant catalog, per-tenant databases or migrations.
- A block volume. The demo uses the VPS disk and restic backups. Add a block
  volume before a real club.
- HA, a load balancer, a second app instance or shared storage.
- The application deployment. That is `deploy/host/`.

## Apply

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# edit project_id, domain and bucket name

export SCW_ACCESS_KEY=...
export SCW_SECRET_KEY=...
export TF_VAR_db_password="$(openssl rand -base64 32)"
export TF_VAR_envs_db_admin_password="$(openssl rand -base64 32)"
export TF_VAR_env_db_passwords="{dev=\"$(openssl rand -hex 24)\",staging=\"$(openssl rand -hex 24)\",prod=\"$(openssl rand -hex 24)\"}"
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
export TF_VAR_admin_cidr="$(curl -fsS https://ifconfig.me)/32"

tofu init
tofu plan
tofu apply
```

Keep the passwords in your secret store: the environment files in
`deploy/host/envs/` need them. The passwords, state and real `terraform.tfvars`
stay out of Git. The state is local and holds the passwords in plaintext: move it
to an encrypted remote backend before prod holds real data.

**Upgrading an existing demo-only state:** the dev/staging/prod resources are
additive and the demo resources keep their addresses. `tofu plan` must show only
additions (and the root and `www` records unchanged while `apex_env` is `demo`).
If it shows anything to destroy or replace, stop.

## Notes

- The database's initial user is the app user and runs the EF Core migrations.
  Splitting migration and runtime roles is a production hardening step.
- `DB-DEV-S` uses local database storage; resize the node type when needed.
- `STARDUST1-S` has 1 GB RAM. It is enough for a demo, not for a club's first
  real ingestion load. Change `instance_type` to `DEV1-S` before that.
- Scaleway blocks outbound SMTP by default. `enable_default_security = false`
  unblocks it only after the account is authorised.
- The registry namespace and bucket name must be unique.
- Backups are restic snapshots to the bucket; see `deploy/host/`.
- Moving `apex_env` to `prod` points `velomine.eu` and `www` at the envs VPS; run
  `deploy.sh` there with `APEX_ENV=prod` first, so the certificate is ready.

## Host credentials

Each VPS needs read/write access to the backup bucket, and nothing else: it pulls
the public image from GHCR without credentials. (The registry permission below is
for the demo until it moves to GHCR.) It must never hold the account's API key: that key can delete the
database and create Instances. Create a dedicated IAM application instead.

```bash
ORG=<organization-id>; PROJ=<project-id>
H="X-Auth-Token: $SCW_SECRET_KEY"   # the operator's key, never the host's

APP=$(curl -s -X POST -H "$H" -H 'Content-Type: application/json' \
  "https://api.scaleway.com/iam/v1alpha1/applications" \
  -d "{\"name\":\"velomine-demo-host\",\"organization_id\":\"$ORG\"}" \
  | jq -r .id)

curl -s -X POST -H "$H" -H 'Content-Type: application/json' \
  "https://api.scaleway.com/iam/v1alpha1/policies" -d "{
    \"name\":\"velomine-demo-host\",\"organization_id\":\"$ORG\",\"application_id\":\"$APP\",
    \"rules\":[
      {\"permission_set_names\":[\"ObjectStorageObjectsRead\",\"ObjectStorageObjectsWrite\",\"ObjectStorageObjectsDelete\",\"ObjectStorageBucketsRead\"],\"project_ids\":[\"$PROJ\"]},
      {\"permission_set_names\":[\"ContainerRegistryReadOnly\"],\"project_ids\":[\"$PROJ\"]}
    ]}"

curl -s -X POST -H "$H" -H 'Content-Type: application/json' \
  "https://api.scaleway.com/iam/v1alpha1/api-keys" \
  -d "{\"application_id\":\"$APP\",\"default_project_id\":\"$PROJ\",\"description\":\"velomine-demo-host\"}"
```

The last call returns the `access_key`/`secret_key` to put in
`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` of `backup.env` and to use for
`docker login`. Check it before trusting it:

- `DELETE /rdb/v1/regions/<region>/instances/<id>` must answer `403`;
- `restic snapshots` and `docker pull` must still work.

Notes:

- IAM permissions are project-scoped, not per bucket. Object storage can write
  and delete objects in every bucket of the project, but cannot delete a bucket
  or its configuration. Bucket versioning keeps deleted objects recoverable
  for 30 days.
- `PATCH` on a policy ignores `rules`; recreate the policy to change them.
- Rotate by creating a new API key, replacing it on the host, then deleting the
  old key.

