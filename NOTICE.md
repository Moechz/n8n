# NOTICE — third-party components and attributions

This package (`n8ndocker`, TOS 7 Docker application) is an independent packaging by Moechz of
the upstream **n8n Workflow Automation** project.

## 1. Upstream application — n8n Workflow Automation

- Project: https://github.com/n8n-io/n8n
- Licence: **Sustainable Use License (fair-code)**
- Relationship: the upstream application is used **unmodified**, inside the container
  image. No upstream source code is redistributed in this package.

## 2. Container image — n8nio/n8n:2.41.3

- Registry: Docker Hub (`n8nio/n8n:2.41.3`)
- Maintainer: n8nio
- The image is pulled from Docker Hub at install time and is not redistributed here.

## 3. Components inside the image

The image is built by its maintainer on top of a base distribution and bundles the
application's own dependencies. Their licences are documented in the image's package
metadata; they are shipped inside the image only and are not redistributed as separate
files by this package.

## 4. This packaging

The files authored for this package — `docker-compose.yml`, `config.ini`,
`n8ndocker.lang`, `n8ndocker.svg`, `entrypoint.sh` (when present), build scripts and this
documentation — are released under the same licence as the upstream project where
required, and otherwise under **GPL-3.0** (see `LICENSE`).

## 5. Trademarks

“n8n Workflow Automation”, “TerraMaster” and “TOS” are trademarks or registered trademarks of their
respective owners. Their use here is descriptive only. This package is **not affiliated
with, sponsored or endorsed by** the upstream project or TerraMaster.

## 6. Icon

The application icon in `src/n8ndocker.svg` is a mark drawn or assembled for this package; it
does not reproduce a third-party logo unless the icon was taken from the upstream project,
in which case it is used only to identify that project.

## 7. Contact

Moechz — moechz@163.com — <https://www.moechz.com/>
