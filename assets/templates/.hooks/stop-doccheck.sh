#!/usr/bin/env bash
# Stop hook —— Codex 静默放行；Claude Code 每个用户回合续跑一次自检。
# 用法: stop-doccheck.sh [claude|codex]
tool="${1:-claude}"

continue_safe() {
  printf '%s\n' '{"continue":true}'
  exit 0
}

case "$tool" in
  claude)
    docname="CLAUDE.md"
    scope_field="prompt_id"
    ;;
  codex)
    # 自检与交接在最终回复前完成；Stop 不追加会让答复折叠的续跑提示。
    continue_safe
    ;;
  *)
    continue_safe
    ;;
esac

input="$(cat)"
command -v jq >/dev/null 2>&1 || continue_safe
sid="$(printf '%s' "$input" | jq -r '
  if type == "object" and (.session_id | type) == "string"
  then .session_id else empty end
' 2>/dev/null || true)"
scope="$(printf '%s' "$input" | jq -r --arg field "$scope_field" '
  if type == "object"
    and (.[$field] | type) == "string"
    and (.[$field] | length > 0)
  then .[$field] else empty end
' 2>/dev/null || true)"
active="$(printf '%s' "$input" | jq -r '
  if type == "object" and .stop_hook_active == true then "true" else "false" end
' 2>/dev/null || echo false)"
[ -n "$sid" ] && [ -n "$scope" ] || continue_safe

case "${sid}:${scope}" in
  *[!A-Za-z0-9._:-]*) continue_safe ;;
esac
case "${UID:-}" in
  '' | *[!0-9]*) continue_safe ;;
esac
key="${#sid}-${sid}-${#scope}-${scope}"
marker_root="/tmp/project-flow-stopcheck-${UID}"
mkdir -p "$marker_root" 2>/dev/null || continue_safe
marker="$marker_root/${tool}-${key}"

if [ "$active" = "true" ]; then
  mkdir "$marker" 2>/dev/null || true
  continue_safe
fi

if ! mkdir "$marker" 2>/dev/null; then
  [ -d "$marker" ] && continue_safe
  continue_safe
fi

reason="【收工自检】先读取当前路径生效的 ${docname}；若其中有业务专项收工检查，先执行该检查且不扩大本轮授权。① 文档:本轮若有 结构/方案、心智模型、方向、外部资料、设计 变更 → 提议更新对应层级的 ${docname} 或 DESIGN.md,列出修改点等确认。② 交接:在本 Hook 所属项目根的 flow/进展.md 最上面追加一条进展(做了什么/为什么/怎么理解/产出/问题与解决/下一步)，按 flow/规范/工作流程.md 的交接输出约定向用户展示同一组事实：默认单层 Markdown 列表、加粗字段名、前后留空行；用户明确格式优先,决策落 decisions.md、坑落 踩坑记录.md。都没有就回复「无需更新」。"
jq -n --arg r "$reason" '{decision:"block", reason:$r}'
