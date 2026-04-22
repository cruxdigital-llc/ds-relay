#!/usr/bin/env bash
# Pre-flight check stub. v0.1.0 placeholder.
#
# Intent (see standards/artifact-contracts.md):
#   Before any agent runs, verify its contractually-required inputs are present.
#   - Code Writer requires: brief.md, component-rules.md, architecture.md
#   - Story Author requires: brief.md, architecture.md, a11y-report.md, generated component
#   - Visual Reviewer requires: generated component + Figma reference snapshot
#
# When implemented, this hook reads $CLAUDE_TOOL_INPUT for the target agent name,
# looks up its required artifacts in standards/artifact-contracts.md, and exits 1
# if any are missing — blocking the Task dispatch and returning a structured error
# to the orchestrator.
#
# For now, this stub passes everything.
exit 0
