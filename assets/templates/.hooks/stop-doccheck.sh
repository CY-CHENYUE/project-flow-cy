#!/usr/bin/env bash
# Stop hook —— 每个回合收尾触发一次续跑,提示按文档维护 SOP 自检。
# 用法: stop-doccheck.sh [claude|codex]
tool="${1:-claude}"
slug="$(basename "$PWD" | tr -c '[:alnum:]_.-' '_')"
input="$(cat)"
sid="$(printf '%s' "$input" | jq -r '.session_id // "nosid"' 2>/dev/null || echo nosid)"
turn="$(printf '%s' "$input" | jq -r '.turn_id // empty' 2>/dev/null || true)"
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
key="${turn:-$sid}"
key="$(printf '%s' "$key" | tr -c '[:alnum:]_.-' '_')"
marker="/tmp/${tool}-${slug}-stopcheck-${key}"
docname="CLAUDE.md"; [ "$tool" = "codex" ] && docname="AGENTS.md"

if [ "$active" = "true" ] || [ -f "$marker" ]; then
  printf '%s\n' '{"continue":true}'        # 已续跑/触发过,放行避免循环
  exit 0
fi
touch "$marker" 2>/dev/null || true

reason="【收工自检】① 文档:本轮若有 结构/方案、心智模型、方向、外部资料、设计 变更 → 提议更新 ${docname}(注明层级)或 DESIGN.md,列出修改点等确认。② 交接:在 flow/进展.md 最上面追加一条进展(做了什么/为什么/怎么理解/产出路径/问题→解决/下一步)并把这条贴在回复里给用户看,决策落 decisions.md、坑落 踩坑记录.md。都没有就回复「无需更新」。"
jq -n --arg r "$reason" '{decision:"block", reason:$r}'
