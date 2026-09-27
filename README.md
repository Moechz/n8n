# n8n-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [n8n Workflow Automation](https://github.com/n8n-io/n8n).

## What this is

A four-file TOS Docker application archive (`n8ndocker.tar.gz`) that installs
n8n Workflow Automation on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `n8ndocker`)
- `n8ndocker.lang` — 23-language superset (TOS requires 14)
- `n8ndocker.svg` — application icon (1588 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `n8nio/n8n:2.41.3`

## How it works

| | |
|---|---|
| Container image | `n8nio/n8n:2.41.3` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8001/` (container port 5678) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/home/node/.n8n` → `/Volume1/DockerAppData/n8ndocker/data` |
| Logs | `docker logs n8ndocker` (stdout/stderr) |

All state lives in the application data folder: `config` holds the encryption key, `database.sqlite` the workflows, credentials and execution history, `nodes/` community nodes, `storage/` binary files, and `public-url.txt` the optional public address.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper** (not a privilege shim): the image already runs as the unprivileged `node` user; `src/entrypoint.sh` only wires up the optional public URL described in the next bullet and then hands over to the upstream `docker-entrypoint.sh` through `tini`.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 5678.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Correct public links.** The upstream image builds webhook, form and OAuth callback URLs from `WEBHOOK_URL` and defaults to `http://localhost:5678/`, which no other device can reach. `src/entrypoint.sh` reads an optional `public-url.txt` from the application data folder and passes it to n8n, so the setting lives in the data volume and survives container updates.
- **Login works over plain HTTP.** `N8N_SECURE_COOKIE=false`, because TOS opens the app as `http://<NAS-IP>:<port>` and a `Secure` cookie would be dropped by the browser, making login loop.
- **Timezone.** `TZ` and `GENERIC_TIMEZONE` are both set, so Schedule triggers fire at the local time instead of the upstream `America/New_York` default.
- **Readiness probe.** The healthcheck uses n8n's own readiness endpoint (`/healthz/readiness`): it answers 503 while the database migrations still run and 200 only when the instance can serve traffic, so the container is not reported healthy before it is usable (`start_period: 120s` covers a slow disk on the first start).
- **Telemetry off.** `N8N_DIAGNOSTICS_ENABLED=false`.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `data/config` | n8n instance encryption key (credentials are encrypted with it) | first start | static | never overwritten; required to decrypt saved credentials |
| `data/database.sqlite` | workflows, credentials, users and execution history (SQLite) | first start | grows with every execution; enable execution pruning in n8n for long-term use | never overwritten; the app owns it |
| `data/nodes/package.json` | registry of community nodes installed from the n8n UI | first start | one entry per installed community node | managed by n8n |
| `data/storage` | binary data (uploaded files) when file-based binary storage is enabled | first start | grows with uploaded/attached files | managed by n8n |
| `data/n8nEventLog.log` | instance event log (startup, version changes) | first start | small, appended per event | safe to delete |
| `data/public-url.txt` | optional public base URL for webhook/form/OAuth links (see the file) | first start by the entrypoint wrapper | static | never overwritten; edit it to point links at your NAS |
| `/Volume1/DockerAppData/n8ndocker/data` | n8n Workflow Automation application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/n8ndocker.tar.gz + .sha256
scripts/build.sh 2.41.3-2   # packaging iteration bump
scripts/build.sh 2.41.3-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/n8ndocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v2.41.3-1`**, assets `n8ndocker.tar.gz` +
   `n8ndocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `n8ndocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `2.41.3-1` → automated validation → review.

## License / branding

n8n Workflow Automation is distributed by its upstream authors under **Sustainable Use License (fair-code)**. The container image is the official image from Docker Hub (`n8nio/n8n:2.41.3`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

n8n is **fair-code**, not an OSI-approved open-source project: the
Sustainable Use License allows free internal and personal use, but not
reselling n8n itself as a service. See
https://docs.n8n.io/sustainable-use-license/ for the exact terms. Only the
official Docker Hub image is used here; no upstream source code is
redistributed.


## Limitations

Webhook, form and OAuth callback links are built from the public base URL. Until you set one in `public-url.txt` they use `http://localhost:5678/` and only work on the NAS itself.
The bundled database is SQLite inside the application data folder. For heavy or multi-user workloads n8n supports an external PostgreSQL; that requires editing `docker-compose.yml`.
The app is served over plain HTTP on the LAN. Do not expose the published port to the internet; put it behind a TLS reverse proxy if you need remote access.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
