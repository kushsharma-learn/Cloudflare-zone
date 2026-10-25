# Cloudflare Foundation DNS (Terraform)

Create and manage Cloudflare DNS zones with **Foundation DNS** using Terraform —
**one folder per zone**, applied by **GitHub Actions one job per zone** (a matrix
"loop"). Each zone is created on the **Enterprise** plan, opted in to Foundation
DNS advanced nameservers, and populated with its DNS records. Each zone has its
**own state file**. DNSSEC is intentionally left disabled.

> Foundation DNS is Cloudflare's Enterprise DNS offering (advanced anycast
> nameservers, more resilient and consistent nameserver assignment).
> Docs: <https://developers.cloudflare.com/dns/foundation-dns/>

## Layout

```
.github/workflows/terraform.yml     # CI/CD: plan on PR, apply on merge — one job per zone
dns-zones/                          #  ✏️  EDIT — one folder per zone
├── tfcreated.kushlearn.in/
│   ├── settings/settings.tfvars     #     account id, domain, Foundation DNS on/off, plan
│   └── records/records.tfvars       #     the DNS records for this zone
└── secondzone.kushlearn.in/         #  📄 copy an existing zone folder to add a new zone
    ├── settings/settings.tfvars
    └── records/records.tfvars
engine/                             #  🔒 DO NOT EDIT — all the Terraform code
├── provider.tf
├── backend.tf                      #     R2 remote state (set bucket + account id once; key is per-zone)
├── variables.tf                    #     full field list + allowed values documented inline
├── main.tf                         #     zone + Enterprise subscription + Foundation DNS + records
└── outputs.tf
```

- **`dns-zones/<folder>/`** — the only files you edit. The folder name is the
  zone's id (used for the CI job name and its state file); the real domain is
  `zone_name` inside `settings.tfvars`.
- **Add a zone** by copying an existing zone folder under `dns-zones/` and
  editing its two tfvars (see below).
- **`engine/`** — the Terraform code. CI runs it once per zone folder.

---

## How it works (the "loop")

`.github/workflows/terraform.yml`:
1. **discover** — lists every folder under `dns-zones/`.
2. **terraform** — a **matrix job per zone**. Each job: `terraform init` with a
   **per-zone state key** (`zones/<zone>.tfstate`), collects that zone's
   `-var-file`s, then:
   - on a **pull request** → `terraform plan` (posted as a PR comment),
   - on **merge to `main`** → `terraform apply`.

So adding a zone folder "just works" — no workflow changes. 500 zones = 500
folders = 500 matrix jobs.

> **Scale note:** GitHub caps a matrix at **256 jobs per run**. For more than 256
> zones, split them across batches/workflows (or lower `max-parallel` to respect
> Cloudflare API rate limits). `max-parallel` is set to 20 by default.

---

## Add a zone (the only thing you do)

```bash
cp -r dns-zones/secondzone.kushlearn.in dns-zones/example.net   # copy an existing zone, rename to your domain
# edit dns-zones/example.net/settings/settings.tfvars  -> account_id, zone_name, foundation_dns, plan
# edit dns-zones/example.net/records/records.tfvars      -> the DNS records
```

Commit on a branch, open a PR (the plan is posted as a comment), and merge to
`main` to apply. Repeat for as many zones as you like.

After apply, the per-zone outputs include the nameservers for the registrar:

```
foundation_dns_nameservers   # advanced foundationdns.* names to set at your registrar
standard_name_servers        # standard nameservers (pre-conversion)
```

---

## Run locally (optional)

You can also run a single zone from your terminal:

```bash
cd engine
export CLOUDFLARE_API_TOKEN="<cloudflare-api-token>"
export AWS_ACCESS_KEY_ID="<R2-access-key-id>"
export AWS_SECRET_ACCESS_KEY="<R2-secret-access-key>"

terraform init -reconfigure -backend-config="key=zones/example.net.tfstate"
terraform apply \
  -var-file=../dns-zones/example.net/settings/settings.tfvars \
  -var-file=../dns-zones/example.net/records/records.tfvars
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

All fields and allowed values are documented inline in `engine/variables.tf` and
in the `examples/zone-template` tfvars.

### Supported record types

- **Simple** (value in `content`): `A`, `AAAA`, `CNAME`, `MX` (+`priority`),
  `NS`, `OPENPGPKEY`, `PTR`, `TXT`.
- **Structured** (value in a `data = {}` block): `CAA`, `CERT`, `DNSKEY`, `DS`,
  `HTTPS`, `LOC`, `NAPTR`, `SMIMEA`, `SRV`, `SSHFP`, `SVCB`, `TLSA`, `URI`.

The example `records.tfvars` ships with `A`, `AAAA`, `CNAME`, `MX`, `NS`, `PTR`,
`TXT`.

---

## Foundation DNS & the nameserver outputs

Foundation DNS is enabled by setting the zone's nameserver type to
`cloudflare.advanced` (done for you when `foundation_dns = true`).

- Overview: <https://developers.cloudflare.com/dns/foundation-dns/>
- Set up advanced nameservers:
  <https://developers.cloudflare.com/dns/foundation-dns/setup/>

A zone is created on **standard** nameservers and then converted to Foundation
DNS, so the engine waits `ns_lookup_delay` (default `30s`) after the conversion
and re-reads the zone, exposing the assigned advanced
`foundationdns.com/.net/.org` names as `foundation_dns_nameservers`. If that
output still shows standard names, raise `ns_lookup_delay` in the zone's
`settings.tfvars` or re-run apply; you can also confirm from the dashboard
(DNS → Records → "Cloudflare nameservers" card).

**Important:** after enabling advanced nameservers you must point your domain at
the assigned nameservers at your registrar. Standard nameservers keep answering
during the transition.

---

## Nameservers & registrar (domain registration / transfer)

Terraform creates the zone and surfaces the nameservers, but **changing the
registrar's nameservers** and **registering / transferring domains** are
registrar operations, not Terraform resources:

- Activate a zone: <https://developers.cloudflare.com/dns/zone-setups/full-setup/setup/>
- With advanced (Foundation DNS) nameservers, copy the assigned values exactly;
  on **Cloudflare Registrar**, contact Cloudflare Support to switch to the
  advanced nameservers.
- Cloudflare Registrar: <https://developers.cloudflare.com/registrar/>
  - Transfer in: <https://developers.cloudflare.com/registrar/get-started/transfer-domains/>
  - Register: <https://developers.cloudflare.com/registrar/get-started/register-domains/>

---

## One-time setup

### 1. Cloudflare API token
Dashboard → **My Profile → API Tokens → Create Custom Token**. Grant (Zone →
All zones or specific): **Zone** Edit, **DNS** Edit, **DNS Settings** Edit; and
**Account → Billing** Write (only if `manage_subscription = true`).

### 2. R2 bucket for state
Create an R2 bucket, then **R2 → Manage R2 API Tokens → Create** (Object Read &
Write) to get an Access Key ID + Secret Access Key. In `engine/backend.tf` set
the `bucket` name and your Account ID in the `endpoints.s3` URL. The state `key`
is supplied per zone at init (CI does this automatically).

### 3. GitHub repository secrets
Repo → **Settings → Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| `CLOUDFLARE_API_TOKEN` | the API token from step 1 |
| `R2_ACCESS_KEY_ID` | the R2 Access Key ID from step 2 |
| `R2_SECRET_ACCESS_KEY` | the R2 Secret Access Key from step 2 |

---

## Requirements

- Terraform >= 1.5
- Providers: `cloudflare/cloudflare` `>= 5.7, < 6.0`, `hashicorp/time` `~> 0.12`
- A Cloudflare **Enterprise** account (Foundation DNS is Enterprise-only)
