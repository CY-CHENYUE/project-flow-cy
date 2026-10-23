# Hook 机制（收工自检）

> 收工检查在最终回复前完成：先执行当前路径生效的 `AGENTS.md`／`CLAUDE.md` 中已有的业务专项检查，再核对文档、项目根 `flow/进展.md`、决策和问题记录，所有操作仍遵守本轮授权。任务结果与交接直接展示在最终回复中。
> Codex Stop 静默放行；Claude Code 保留每个用户回合最多一次的续跑兜底。两端行为有意不同。

## 为什么区分两端

Codex 桌面端可能将 Stop 自动续跑之前的答复收进“用时”详情，并把 Hook 反馈显示在外层。仅调整 Markdown 不能改变这条消息顺序。本技能在 Codex 端停止生成续跑提示：检查和记录前置，Stop 直接返回 `continue:true`，不在结果之后追加“无需更新”。

这不改变客户端本身的折叠规则，也不处理其他 Hook 产生的消息。脚本测试或 TUI 测试不能代替桌面显示的实际观察。

## 作用域

| 内容 | 作用域 | 位置 |
|---|---|---|
| Hook 定义与行为 | 项目级 | 项目根 `.hooks/`、`.claude/settings.json`、`.codex/hooks.json` |
| Codex Hook 能力开关 | 机器级，遵守用户配置 | `~/.codex/config.toml` 的 `features.hooks` 或启动参数 |

一个项目边界只安装一套根级 Hook。单仓多子项目不在子项目重复安装。若加载 Codex 项目级 Hook，遵循项目 trust 与批准要求；无需仅为本技能开启全局 hooks。

## 共享脚本

Claude Code 与 Codex 共用 `.hooks/stop-doccheck.sh`，调用时传入 `claude` 或 `codex`。源码维护在 `assets/templates/.hooks/stop-doccheck.sh`；下方副本供随项目部署的详规独立阅读，修改脚本时必须同步校验：

```bash
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
```

关键语义：

- Codex 分支只输出 `{"continue":true}` 并退出，不读 stdin、不调用 `codex --version`、不检查回合 ID、不生成 marker 或续跑提示。它也不通过日期、关键词或日志内容猜测自检是否完成。
- Claude Code 只接受 `prompt_id`；marker 键同时包含 `session_id`，不同会话和用户回合互不污染。首次通过原子 `mkdir` 成功的调用返回 `decision:block`；同一 scope 后续无论 `stop_hook_active` 是否正确设置，都只返回 `continue:true`。
- Claude 的 marker 表示该用户回合已经触发过，保持单调存在。非法或不适合作为文件名的 ID、缺少 `jq`、缺稳定 scope 或 marker 无法建立时安全放行；脚本不依赖外部 `tr` 或 `id` 命令。
- Claude 的 `reason` 用 `jq -n` 生成，避免手工转义中文和引号；本次保留原有提醒内容。
- 上层项目 Hook 被子目录复用时，Claude 续跑提示先读取当前路径实际生效的 Agent 入口并执行专项检查；两端项目交接仍只写回项目根的 `flow/`，不会在子目录另建控制层。

## 两端薄配置

```jsonc
// .claude/settings.json
{ "hooks": { "Stop": [ { "matcher": "", "hooks": [
  { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.hooks/stop-doccheck.sh\" claude" }
] } ] } }

// .codex/hooks.json
{ "hooks": { "Stop": [ { "hooks": [
  { "type": "command", "command": "root=\"$(git rev-parse --show-toplevel 2>/dev/null || pwd)\"; if [ ! -f \"$root/.hooks/stop-doccheck.sh\" ]; then d=\"$PWD\"; while [ \"$d\" != \"/\" ] && [ ! -f \"$d/.hooks/stop-doccheck.sh\" ]; do d=\"$(dirname \"$d\")\"; done; root=\"$d\"; fi; if [ ! -f \"$root/.hooks/stop-doccheck.sh\" ]; then printf '%s\\n' '{\"continue\":true,\"systemMessage\":\"project-flow stop hook script not found\"}'; exit 0; fi; bash \"$root/.hooks/stop-doccheck.sh\" codex", "timeout": 30, "statusMessage": "收工自检" }
] } ] } }
```

脚本承载行为，配置只负责定位并调用脚本。已有项目保留 command 和其他 handler；只改脚本不会改变 Codex 的 command trusted hash。配置中保留的 `statusMessage` 是运行状态文字，不是自动续跑提示。

## Codex 接入与历史边界

- Codex 的收工要求通过项目入口在最终回复前执行，不依赖本技能的 Stop 续跑；不要仅为本技能要求用户启用全局 hooks，也不要擅自修改全局配置。
- 需要加载项目级 `.codex/hooks.json` 时，遵循项目 trust 与客户端批准要求；首次安装或 command 改动后在支持的 TUI 用 `/hooks` 审核。既有 command 不变时，无需因脚本内容更新重复批准。
- 历史记录：Codex CLI `0.144.1` 曾把 `decision:block` 产生的 continuation prompt 保存为裸 UUID message ID，继续或恢复时触发 `invalid_id_prefix`。`0.145.0` 于 2026-07-27 通过旧机制的首次续跑、同会话继续和退出恢复三段回归，3 个项目 scope 各有 1 个唯一 `msg_...` Hook prompt ID，裸 UUID 与 `invalid_id_prefix` 均为 0。
- 这些历史测试解释旧版的版本门，不构成当前启用续跑的条件，也不能证明桌面端答复一直留在外层。当前脚本已删除 Codex 版本门，对 Codex 一律静默放行。

## 回归测试

在 `project-flow-cy` Skill 源码目录运行确定性测试：

```bash
bash tests/test-stop-hook.sh
```

它覆盖 Codex 无条件静默放行、无输入与外部依赖，以及 Claude 专属 `prompt_id`、错误字段拒绝、不同 session、active-first、重复 Stop、异常输入、缺 `jq`、无外部 `tr`/`id` 和并发首次触发。

真实 Codex TUI 回归会调用在线模型并创建一次性本地 session，默认跳过；明确需要时运行：

```bash
PROJECT_FLOW_RUN_CODEX_TUI_E2E=1 \
  bash tests/test-codex-stop-hook-e2e.sh
```

它验证：

1. 首次回复正常完成，本技能不产生续跑提示；
2. 同一 TUI 再发消息仍正常完成；
3. `/exit` 后按 session ID 新进程恢复仍正常完成；
4. 三次回复各自返回不同完成 token，不能由终端旧画面冒充后续成功；
5. 本技能的 Hook prompt 数为 0，且无 `invalid_id_prefix`。

E2E 使用真实用户认证与配置，不修改全局配置；用户级其他 Hook 可能产生独立提示，但不计入项目 Hook 事件。测试结束会删除测试 session 和临时项目。桌面端是否还将其他内容折叠到“用时”详情，需要在桌面端单独观察。

## 安装

由 `初始化SOP.md` 执行：合并最终回复前的收工约定 → 复制脚本 → `chmod +x .hooks/stop-doccheck.sh` → 保留既有 command 与其他 handler，合并缺失配置 → 验证 Codex 静默放行与 Claude 单次兜底。需要加载 Codex 项目 Hook 时再说明 trust 与批准要求，不要求为本技能开启全局 hooks。
