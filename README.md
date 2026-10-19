# Follett Corporation — Cloudflare Foundation DNS (Terraform)

Create and manage Cloudflare DNS zones with **Foundation DNS** using Terraform.
Each zone is created on the **Enterprise** plan, opted in to Foundation DNS
advanced nameservers, and populated with its DNS records. DNSSEC is
intentionally left disabled.

> Foundation DNS is Cloudflare's Enterprise DNS offering (advanced anycast
> nameservers, more resilient and consistent nameserver assignment).
> Docs: <https://developers.cloudflare.com/dns/foundation-dns/>

## Layout

All the files **you edit** live under `dns-zones/` — one folder per domain, each
with a `settings/` and a `records/` subfolder. All the Terraform code **you
never edit** lives in a single `engine/` folder at the bottom.

```
dns-zones/                       #  ✏️  EDIT — one folder per zone (copy per domain)
└── example.com/                 #  ← COPY this whole folder to add zone 2, 3, 4, …
    ├── settings/
    │   └── settings.tfvars       #     account id, domain, Foundation DNS on/off, plan
    └── records/
        └── records.tfvars        #     the DNS records for this zone

engine/                          #  🔒 DO NOT EDIT — all the Terraform code (run Terraform here)
├── provider.tf
├── backend.tf                   #     R2 remote state (set bucket + account id once)
├── variables.tf                 #     full field list + allowed values documented inline
├── main.tf                      #     zone + Enterprise subscription + Foundation DNS + records
└── outputs.tf
```

- **`dns-zones/<domain>/`** — the only files you touch. Copy this folder per
  zone; settings and records are kept in separate subfolders on purpose.
- **`engine/`** — the shared Terraform code. One engine drives every zone; each
  zone gets its **own state** via a Terraform *workspace* (below).

---

## Add a zone

```bash
cd dns-zones
cp -r example.com follett.com     # name the folder after your domain
# edit follett.com/settings/settings.tfvars   -> account_id, zone_name, foundation_dns, plan
# edit follett.com/records/records.tfvars       -> the DNS records
```

## Apply a zone

Run Terraform from `engine/`, using a **workspace per zone** so each zone keeps
its own state, and point `-var-file` at that zone's two tfvars:

```bash
cd engine

# credentials — passed at execution time, never stored in the repo:
export CLOUDFLARE_API_TOKEN="<your-cloudflare-api-token>"   # manages the DNS resources
export AWS_ACCESS_KEY_ID="<your-R2-access-key-id>"          # R2 state bucket
export AWS_SECRET_ACCESS_KEY="<your-R2-secret-access-key>"  # R2 state bucket

terraform init

# once per zone — create + select a workspace named after the domain:
terraform workspace new follett.com      # (later: terraform workspace select follett.com)

terraform apply \
  -var-file=../dns-zones/follett.com/settings/settings.tfvars \
  -var-file=../dns-zones/follett.com/records/records.tfvars
```

Then read the nameservers to configure at your registrar:

```bash
terraform output name_servers
```

> **Why workspaces + `-var-file`?** One shared `engine/` keeps the code in a
> single place, and a workspace per domain gives every zone an isolated state
> file — so you can add, change, or destroy one zone without touching the
> others. The tfvars live in `dns-zones/`, so Terraform does not auto-load them;
> you pass them explicitly.

### Scaling to many zones (e.g. 3,200)

```bash
cd engine
terraform init
for d in ../dns-zones/*/ ; do
  zone="$(basename "$d")"
  [ "$zone" = "example.com" ] && continue        # skip the template
  terraform workspace new "$zone" 2>/dev/null || terraform workspace select "$zone"
  terraform apply -auto-approve \
    -var-file="../dns-zones/$zone/settings/settings.tfvars" \
    -var-file="../dns-zones/$zone/records/records.tfvars"
done
```

---

## What each zone gets

| Setting | Resource | Notes |
|---|---|---|
| Zone creation | `cloudflare_zone` | `type = "full"` (Cloudflare is authoritative/primary DNS) |
| **Enterprise plan** | `cloudflare_zone_subscription` | `rate_plan.id = "enterprise"`; set `manage_subscription = false` if your contract auto-provisions |
| **Foundation DNS** | `cloudflare_zone_dns_settings` | `nameservers.type = "cloudflare.advanced"` (advanced anycast nameservers) |
| DNS records | `cloudflare_dns_record` | one per entry in `records.tfvars` |
| DNSSEC | — | **not configured** (left disabled, by design) |

Every field and its allowed values is documented inline in
`engine/variables.tf` and in the tfvars templates.

### Supported record types

All Cloudflare DNS record types are supported. Two shapes:

- **Simple** (value goes in `content`): `A`, `AAAA`, `CNAME`, `MX` (+`priority`),
  `NS`, `OPENPGPKEY`, `PTR`, `TXT`.
- **Structured** (value goes in a `data = { … }` object): `CAA`, `CERT`,
  `DNSKEY`, `DS`, `HTTPS`, `LOC`, `NAPTR`, `SMIMEA`, `SRV`, `SSHFP`, `SVCB`,
  `TLSA`, `URI`.

The exact `data` fields for each type are listed at the top of the `records`
variable in `engine/variables.tf` (they mirror the Cloudflare API record
models). The example `records.tfvars` ships with `A`, `AAAA`, `CNAME`, `MX`,
`NS`, `PTR`, and `TXT`.

---

## Remote state (Cloudflare R2)

State is stored in **your** R2 bucket via the S3-compatible backend
(`engine/backend.tf`). Set two placeholders once:

- `bucket` → your R2 bucket name
- the account id in `endpoints.s3` → your Cloudflare Account ID

Credentials are **never stored in the repo** — pass them at execution time
(R2 → *Manage R2 API Tokens* → Access Key ID + Secret Access Key):

```bash
export AWS_ACCESS_KEY_ID="<R2 Access Key ID>"
export AWS_SECRET_ACCESS_KEY="<R2 Secret Access Key>"
terraform init
# …or pass them to init explicitly:
#   terraform init -backend-config="access_key=..." -backend-config="secret_key=..."
```

Because the engine uses a workspace per zone, each zone's state lives at its own
path inside the bucket.

---

## Foundation DNS

Foundation DNS is enabled by setting the zone's nameserver type to
`cloudflare.advanced` (done for you when `foundation_dns = true`).

- Overview: <https://developers.cloudflare.com/dns/foundation-dns/>
- Set up advanced nameservers:
  <https://developers.cloudflare.com/dns/foundation-dns/setup/>

**Important:** after enabling advanced nameservers you must point your domain at
the assigned nameservers at your registrar. Standard nameservers keep answering
during the transition.

---

## Nameservers & registrar (domain registration / transfer)

Terraform creates the zone and tells you which nameservers to use
(`terraform output name_servers`), but **changing the registrar's nameservers**
and **registering / transferring domains** are registrar operations, not
Terraform resources:

- Activate a zone (point nameservers at Cloudflare):
  <https://developers.cloudflare.com/dns/zone-setups/full-setup/setup/>
- With advanced (Foundation DNS) nameservers, copy the assigned values exactly;
  if the domain is on **Cloudflare Registrar**, contact Cloudflare Support to
  switch it to the advanced nameservers.
- Cloudflare Registrar: <https://developers.cloudflare.com/registrar/>
  - Transfer domains in:
    <https://developers.cloudflare.com/registrar/get-started/transfer-domains/>
  - Register domains:
    <https://developers.cloudflare.com/registrar/get-started/register-domains/>

---

## One-time setup: Cloudflare API token

Dashboard → **My Profile → API Tokens → Create Token → Create Custom Token**.
Grant:

**Zone** (All zones, or the specific zones):
- **Zone** · Edit — create the zone
- **DNS** · Edit — create records
- **DNS Settings** · Edit — enable Foundation DNS

**Account**:
- **Billing** · Write — only if `manage_subscription = true`

Export it before running Terraform:

```bash
export CLOUDFLARE_API_TOKEN="<your-token>"
```

Token docs:
<https://developers.cloudflare.com/fundamentals/api/get-started/create-token/>

> **State** is kept in R2 (see *Remote state* above), with a workspace per zone
> so every domain has an isolated state file in the bucket.

---

## Requirements

- Terraform >= 1.5
- Cloudflare provider `>= 5.7, < 6.0`
- A Cloudflare **Enterprise** account (Foundation DNS is Enterprise-only)
