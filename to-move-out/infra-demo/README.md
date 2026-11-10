# Velomine demo infrastructure

One VPS, one managed PostgreSQL database, one private network, one DNS zone and
one backup bucket. No modules, no remote state, no tenancy.

This is a **demo** stack. It is not the production home for real member data.

## What it creates

- `STARDUST1-S` app VPS on Ubuntu 24.04, with Docker and a `deploy` user.
- `DB-DEV-S` managed PostgreSQL, private network only, 7-day backups.
- `velomine` database on that instance.
- Private network between the VPS and the database.
- Private Scaleway Container Registry namespace.
- Object Storage bucket in another region for restic backups.
- A records for `demo`, the root and `www`.

## What it does not create

- Tenancy, tenant catalog, per-tenant databases or migrations.
- A block volume. The demo uses the VPS disk and restic backups. Add a block
  volume before a real club.
- HA, a load balancer, a second app instance or shared storage.
- The application deployment. That is `deploy/demo/`.

## Apply

```bash
cd infra/demo
cp terraform.tfvars.example terraform.tfvars
# edit project_id, domain and bucket name

export SCW_ACCESS_KEY=...
export SCW_SECRET_KEY=...
export TF_VAR_db_password="$(openssl rand -base64 32)"
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
export TF_VAR_admin_cidr="$(curl -fsS https://ifconfig.me)/32"

tofu init
tofu plan
tofu apply
```

The password, state and real `terraform.tfvars` stay out of Git. Local state is
plaintext; move to encrypted remote state before real data.

## Notes

- The database's initial user is the app user and runs the EF Core migrations.
  Splitting migration and runtime roles is a production hardening step.
- `DB-DEV-S` uses local database storage; resize the node type when needed.
- `STARDUST1-S` has 1 GB RAM. It is enough for a demo, not for a club's first
  real ingestion load. Change `instance_type` to `DEV1-S` before that.
- Scaleway blocks outbound SMTP by default. `enable_default_security = false`
  unblocks it only after the account is authorised.
- The registry namespace and bucket name must be unique.
- Backups are restic snapshots to the bucket; see `deploy/demo/`.

## Host credentials

The VPS needs read access to the registry and read/write access to the backup
bucket. It must never hold the account's API key: that key can delete the
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

