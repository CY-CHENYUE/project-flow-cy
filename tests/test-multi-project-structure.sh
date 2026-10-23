#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v jq >/dev/null 2>&1 || {
  echo "FAIL: jq is required" >&2
  exit 1
}

require_file() {
  local path="$1"
  [ -f "$ROOT/$path" ] || {
    echo "FAIL: missing $path" >&2
    exit 1
  }
}

require_text() {
  local path="$1"
  local text="$2"
  grep -Fq "$text" "$ROOT/$path" || {
    echo "FAIL: $path does not contain: $text" >&2
    exit 1
  }
}

require_file "references/多子项目结构.md"
require_file "assets/templates/MODULE_AGENTS.md"
require_file "evals/evals.json"
require_file "tests/test-codex-stop-hook-e2e.sh"

require_text "SKILL.md" "一个项目边界一个控制面"
require_text "SKILL.md" "assets/templates/MODULE_AGENTS.md"
require_text "SKILL.md" "最终回复"
require_text "SKILL.md" 'Stop 直接返回 `continue:true`'
require_text "references/初始化SOP.md" "不在子项目重复创建"
require_text "references/hook机制.md" '`prompt_id`'
require_text "references/hook机制.md" '{"continue":true}'
require_text "assets/templates/AGENTS.md" "最终回复"
require_text "references/文档维护SOP.md" "规则就近,文档集中"
require_text "README.md" "单仓多子项目"

if grep -R -n -E '5 份详规|5份详规|五份详规' \
  "$ROOT/SKILL.md" "$ROOT/README.md" "$ROOT/references"; then
  echo "FAIL: stale five-reference wording remains" >&2
  exit 1
fi

jq -e '
  .skill_name == "project-flow-cy" and
  (.evals | length) >= 4 and
  all(.evals[];
    (.prompt | type == "string" and length > 0) and
    (.expected_output | type == "string" and length > 0) and
    (.expectations | type == "array" and length > 0)
  )
' "$ROOT/evals/evals.json" >/dev/null

echo "PASS: multi-project structure rules and evals are consistent"
