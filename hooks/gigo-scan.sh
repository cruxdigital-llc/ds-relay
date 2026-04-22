#!/usr/bin/env bash
# Post-write rule-violation scanner. Scans Write/Edit output for forbidden patterns
# and appends findings to the current run's reports/gigo-scan.log. Does not block.
#
# Discovers the run directory by walking up from the written file path, looking for a
# runs/<uuid>/ ancestor. If none is found, the write isn't pipeline output — skip.
#
# Quality Gate consumes the log to decide whether to fail the run.

set -euo pipefail

input="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  echo "gigo-scan: jq not installed; skipping (install jq to enable GIGO scans)" >&2
  exit 0
fi

path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"

# Only scan source-like files in the component output.
case "$path" in
  *.tsx|*.ts|*.css|*.module.css) ;;
  *) exit 0 ;;
esac

if [ ! -f "$path" ]; then
  exit 0
fi

# Walk up from $path looking for a runs/<uuid>/ ancestor to locate the run directory.
run_dir=""
dir="$(dirname "$path")"
while [ "$dir" != "/" ] && [ "$dir" != "." ]; do
  parent="$(dirname "$dir")"
  base="$(basename "$dir")"
  parent_base="$(basename "$parent")"
  if [ "$parent_base" = "runs" ] && [[ "$base" =~ ^[a-f0-9-]+$ ]]; then
    run_dir="$dir"
    break
  fi
  dir="$parent"
done

# If we couldn't find a run dir, this isn't pipeline output — skip.
if [ -z "$run_dir" ]; then
  exit 0
fi

findings=()

# Rule 1: CSS custom property with fallback value — forbidden.
if grep -qE 'var\(--[a-zA-Z0-9_-]+,[[:space:]]*[^)]+\)' "$path"; then
  matches="$(grep -nE 'var\(--[a-zA-Z0-9_-]+,[[:space:]]*[^)]+\)' "$path" | head -5)"
  findings+=("TOKEN_FALLBACK: CSS custom property with fallback value (forbidden — tokens must resolve)
$matches")
fi

# Rule 2: Hardcoded hex color outside tokens files.
if [[ "$path" != *tokens* ]] && [[ "$path" != *.module.css.d.ts ]]; then
  if grep -qE '#[0-9a-fA-F]{3,8}\b' "$path"; then
    matches="$(grep -nE '#[0-9a-fA-F]{3,8}\b' "$path" | head -5)"
    findings+=("HARDCODED_HEX: Hardcoded hex color outside a tokens file (should use token)
$matches")
  fi
fi

# Rule 3: [UNRESOLVED] or [PENDING] markers in component source (these belong in brief.md, not in code).
if [[ "$path" == *.tsx ]] || [[ "$path" == *.ts ]] || [[ "$path" == *.css ]]; then
  if grep -qE '\[(UNRESOLVED|PENDING)\]' "$path"; then
    matches="$(grep -nE '\[(UNRESOLVED|PENDING)\]' "$path" | head -5)"
    findings+=("UNRESOLVED_IN_SOURCE: [UNRESOLVED] or [PENDING] marker leaked into component source
$matches")
  fi
fi

# Rule 4: `disabled` attribute on menu items / listbox options (should be aria-disabled).
if [[ "$path" == *.tsx ]]; then
  if grep -qE 'role="(menuitem|option)"' "$path" && grep -qE '[[:space:]]disabled[=[:space:]]' "$path"; then
    findings+=("ARIA_DISABLED_MISUSE: Likely use of native 'disabled' attribute on a menuitem/option (should be aria-disabled)")
  fi
fi

if [ "${#findings[@]}" -eq 0 ]; then
  exit 0
fi

mkdir -p "$run_dir/reports"
{
  echo ""
  echo "## GIGO scan @ $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "File: $path"
  for f in "${findings[@]}"; do
    echo ""
    echo "$f"
  done
} >> "$run_dir/reports/gigo-scan.log"

# Non-blocking: Quality Gate reads gigo-scan.log and decides.
exit 0
