#!/bin/bash
# find-hardcoded-deps.sh
#
# Searches an Omarchy source checkout for remaining hard references to
# packages/webapps that were removed from omarchy-base.packages / applications/.
# Meant to find all "first-boot surprise" spots in one go, instead of
# running into them one at a time during VM testing.
#
# v2: risk pattern extended with 'command -v'/'which'/'type -p', after an
# indirect call (ufw_docker_bin=$(command -v ufw-docker) inside a
# function) was missed by v1 — that only crashed when the empty variable
# was actually invoked, not on a literal package-name line.
#
# Usage:
#   ./find-hardcoded-deps.sh [path-to-omarchy-source]
#
# Default path: ~/omarchy-source

set -uo pipefail

REPO="${1:-$HOME/omarchy-source}"

if [[ ! -d "$REPO" ]]; then
  echo "Error: '$REPO' does not exist or is not a directory." >&2
  echo "Usage: $0 [path-to-omarchy-source]" >&2
  exit 1
fi

cd "$REPO" || exit 1

# --- Adjust these two lists if your package/webapp selection changes ---

REMOVED_PACKAGES=(
  aether chromium cliamp docker docker-buildx docker-compose ufw-docker
  gpu-screen-recorder kdenlive libreoffice-fresh lazydocker localsend
  obs-studio obsidian pinta xournalpp
)

REMOVED_WEBAPPS=(
  HEY Basecamp WhatsApp "Google Photos" "Google Contacts" "Google Messages"
  YouTube X Discord Zoom "Google Maps"
)

# Directories we search (scripts that run during install/first-boot/runtime).
# test/ and .git are deliberately excluded: test code may mention package
# names without that being a real runtime dependency.
SEARCH_DIRS=(install bin default config)
EXISTING_DIRS=()
for d in "${SEARCH_DIRS[@]}"; do
  [[ -d "$d" ]] && EXISTING_DIRS+=("$d")
done

# Patterns that are often an UNCONDITIONAL, and therefore risky, assumption
# that a package/app is present. Hits on these are flagged separately.
RISKY_PATTERN='systemctl (enable|start|restart)|xdg-settings|xdg-mime default|omarchy-pkg-add|omarchy-pkg-drop|command -v|which |type -p'

REPORT="$REPO/hardcoded-deps-report.txt"
: >"$REPORT"

echo "Scanning $REPO for remaining references to removed packages/webapps..."
echo "Report will be written to: $REPORT"
echo

total_hits=0
total_risky=0

search_term() {
  local term="$1"
  local label="$2"
  local hits

  hits=$(grep -rnw -I --include="*.sh" -i -- "$term" "${EXISTING_DIRS[@]}" 2>/dev/null)
  [[ -z "$hits" ]] && return 0

  {
    echo "=================================================================="
    echo "## $label"
    echo "=================================================================="
  } >>"$REPORT"

  while IFS= read -r line; do
    total_hits=$((total_hits + 1))
    if [[ "$line" =~ $RISKY_PATTERN ]]; then
      total_risky=$((total_risky + 1))
      echo "⚠ RISK: $line" >>"$REPORT"
    else
      echo "  info:   $line" >>"$REPORT"
    fi
  done <<<"$hits"

  echo >>"$REPORT"
}

echo "--- Packages ---"
for pkg in "${REMOVED_PACKAGES[@]}"; do
  search_term "$pkg" "Package: $pkg"
done

echo "--- Webapps ---"
for app in "${REMOVED_WEBAPPS[@]}"; do
  # Search both the plain name and the .desktop-filename form
  search_term "$app" "Webapp: $app"
  slug=${app// /}
  [[ "$slug" != "$app" ]] && search_term "$slug" "Webapp (joined): $slug"
done

echo
echo "Done. $total_hits hit(s) found, of which $total_risky match a risky pattern"
echo "(systemctl enable/start, xdg-settings, xdg-mime default, omarchy-pkg-add/drop)."
echo
echo "View the full report with:"
echo "  less '$REPORT'"
echo
echo "Or jump straight to only the risky lines with:"
echo "  grep '⚠ RISK' '$REPORT'"
