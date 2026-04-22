#!/usr/bin/env bash
# Pre-flight artifact check. Blocks agent dispatch when required inputs are missing.
#
# Hook contract: reads JSON tool input from stdin; exits 0 to allow, exits 1 to block.
# Discovers the run directory by scanning the subagent's prompt for a runs/<uuid>/ path.
# If no run dir is detected, the dispatch is not a pipeline agent invocation — pass through.

set -euo pipefail

input="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  echo "enforce-preflight: jq not installed; skipping (install jq to enable pre-flight checks)" >&2
  exit 0
fi

# Extract the subagent being dispatched.
agent="$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // .tool_input.agent // empty')"

if [ -z "$agent" ]; then
  # Not an agent dispatch — probably a non-Task tool call.
  exit 0
fi

# Extract the full prompt text passed to the subagent.
prompt="$(printf '%s' "$input" | jq -r '.tool_input.prompt // .tool_input.description // empty')"

# Discover the run directory from the prompt text.
# The orchestrator references artifact paths like /path/to/target/runs/<uuid>/brief.md
# in the subagent prompt. Extract the runs/<uuid>/ prefix.
run_dir="$(printf '%s' "$prompt" | grep -oE '(^|[^a-zA-Z0-9_/])[^[:space:]]*/runs/[a-f0-9-]+' | head -1 | sed 's/^[^a-zA-Z0-9_/]//')"

if [ -z "$run_dir" ]; then
  # No pipeline run directory detected — not a pipeline dispatch.
  exit 0
fi

# Required artifacts per pipeline agent.
# Kept in sync with standards/artifact-contracts.md.
case "$agent" in
  design-analyst)
    required=()
    ;;
  library-researcher)
    required=("brief.md")
    ;;
  component-architect)
    required=("brief.md")
    ;;
  code-writer)
    required=("brief.md" "component-rules.md" "architecture.md")
    ;;
  accessibility-auditor)
    required=("brief.md" "architecture.md")
    ;;
  story-author)
    required=("brief.md" "architecture.md")
    ;;
  visual-reviewer)
    required=("brief.md" "architecture.md")
    ;;
  quality-gate)
    required=()
    ;;
  pipeline-review)
    required=("pipeline-state.yaml")
    ;;
  adapter-onboarder)
    # Onboarder runs outside a pipeline run — not enforced here.
    exit 0
    ;;
  *)
    # Unknown agent — pass through.
    exit 0
    ;;
esac

missing=()
for f in "${required[@]}"; do
  if [ ! -f "$run_dir/$f" ]; then
    missing+=("$f")
  fi
done

if [ "${#missing[@]}" -ne 0 ]; then
  {
    echo "PRE-FLIGHT FAILED: agent '$agent' requires these artifacts in $run_dir but they are missing:"
    for m in "${missing[@]}"; do
      echo "  - $m"
    done
    echo ""
    echo "The orchestrator must dispatch earlier-phase agents before '$agent' can run."
    echo "See standards/artifact-contracts.md for the full dependency graph."
  } >&2
  exit 1
fi

exit 0
