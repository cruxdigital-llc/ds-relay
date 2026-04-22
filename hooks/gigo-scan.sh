#!/usr/bin/env bash
# GIGO (garbage-in, garbage-out) post-write scan stub. v0.1.0 placeholder.
#
# Intent:
#   After any Write/Edit touches pipeline output, scan the diff for rule
#   violations and append findings to pipeline-state.yaml. Patterns to detect:
#
#   - `var\(--[^,)]+,\s*[^)]+\)`  → CSS custom property with fallback value (forbidden)
#   - `#[0-9a-fA-F]{3,8}` outside *.tokens.* files → hardcoded hex
#   - `[UNRESOLVED]` or `[PENDING]` in an output file without a corresponding
#      penalty row in pipeline-state.yaml.gigo_log
#   - Title-case text in user-facing strings (delegated to DS adapter's
#      editorial-voice check)
#
# The scan does not block. Quality Gate consumes the report and decides
# whether to fail the run.
exit 0
