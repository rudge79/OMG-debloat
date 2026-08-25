# OMG-debloat

A debloated Omarchy Linux ISO: no unwanted preinstalled apps or webapps by
default, built on top of a fork of [basecamp/omarchy](https://github.com/basecamp/omarchy)
that stays in sync with upstream.

> **Unofficial.** OMG-debloat is an independent community fork and is
> **not affiliated with, endorsed by, or connected to Basecamp, 37signals,
> or David Heinemeier Hansson (DHH)**, the creators of the original Omarchy.
> "Omarchy" is their project/trademark; this fork only uses the name to
> indicate what it's based on. Questions, bugs, or feature requests about
> Omarchy itself belong at [basecamp/omarchy](https://github.com/basecamp/omarchy),
> not here.

## Which branch, since when

This fork tracks the **`quattro`** branch of `basecamp/omarchy`
(Omarchy 4 / Quickshell-based shell), since
<!-- TODO: fill in the date/commit from which you started tracking,
     e.g. "August 16, 2026 (commit basecamp/omarchy@<sha>)" -->
`<fill in>`.

Upstream changes are pulled in periodically and offered as a pull request
for review (see `.github/workflows/sync-upstream.yml`) — not auto-merged,
since quattro sometimes changes structurally (the entire menu system, for
example, moved to `default/omarchy/omarchy-menu.jsonc` mid-stream).

## What's concretely different from upstream

- **Package list** (`install/omarchy-base.packages`): the following
  default packages have been removed — `aether`, `chromium`, `cliamp`,
  `docker`, `docker-buildx`, `docker-compose`, `ufw-docker`,
  `gpu-screen-recorder`, `kdenlive`, `libreoffice-fresh`, `lazydocker`,
  `localsend`, `obs-studio`, `obsidian`, `pinta`, `xournalpp`.
- **Webapps** (`applications/`): `HEY`, `Basecamp`, `WhatsApp`,
  `Google Photos`, `Google Contacts`, `Google Messages`, `YouTube`, `X`,
  `Discord`, `Zoom`, `Google Maps` have been removed.
- **Crash fixes** made necessary by the removals above:
  - `bin/omarchy-provision-user`: hardcoded Chromium/HEY defaults no longer
    fail hard during first boot (`|| true`).
  - `install/config/enable-services.sh`: `docker.socket` is only enabled if
    the unit file actually exists.
  - `install/config/firewall.sh`: `install_ufw_docker_rules` is only called
    if `ufw-docker` is actually installed.
- **Diagnostic tooling** (original to this repo): `find-hardcoded-deps.sh`
  scans the checkout for remaining hard references to removed
  packages/webapps, flagging risky patterns such as `systemctl enable/start`,
  `xdg-settings`, and `command -v`.

The full build-and-debug journey — including every issue hit along the
way — is documented in
[`omarchy-debloat-proces.md`](./omarchy-debloat-proces.md).

## Credits / provenance

- **[basecamp/omarchy](https://github.com/basecamp/omarchy)** — the
  original project this fork is based on. MIT licensed; see `LICENSE` in
  this repo (carried over unchanged).
- **[omacom-io/omarchy-iso](https://github.com/omacom-io/omarchy-iso)** and
  **[omacom-io/omarchy-pkgs](https://github.com/omacom-io/omarchy-pkgs)** —
  the ISO builder and package source material used to build this fork into
  an installable ISO (built in unchanged via `--local-source`).
- **`omarchy-cleaner.sh`** in this repo was originally written by
  **Max ([@maxart](https://github.com/maxart), upstream:
  [maxart/omarchy-cleaner](https://github.com/maxart/omarchy-cleaner))**,
  released under the MIT License. Thank you — it saved a huge amount of
  work. In this repo the script has been extended with support for the
  newer `bindings.lua` format (alongside the legacy `bindings.conf`),
  removal of npm CLI stubs, and a more extensive gum-based interface; see
  the git history of `omarchy-cleaner.sh` for the exact diff against the
  upstream version.

## License

This repo (the patches on top of omarchy-source, `find-hardcoded-deps.sh`,
the build/sync workflows) is released under the **MIT License**, in line
with all the sources above. See `LICENSE`. Carried-over files
(omarchy-source, `omarchy-cleaner.sh`) retain their original copyright
notice; see those files and the section above.

## Building

```bash
git clone <this-fork> omarchy-source
git clone https://github.com/omacom-io/omarchy-iso.git
git clone https://github.com/omacom-io/omarchy-pkgs.git

cd omarchy-iso
./bin/omarchy-iso-make --local-source ../omarchy-source ../omarchy-pkgs
```

Output: `release/omarchy-*-local.iso`. See `omarchy-debloat-proces.md` for
build infrastructure notes (disk space), QEMU testing, and the automated
CI workflows in `.github/workflows/`.
