# Hook 机制(收工自检)

> 每个回合收尾的 Stop hook,用一次自动续跑做**收工自检**:① 文档要不要更新(按 `文档维护SOP.md` / `DESIGN维护SOP.md`)② 在 `flow/进展.md` 追加一条进展(交接棒)。
> 这是文档不漂移的**兜底**——没 hook 也要自觉,有 hook 多一层保险。

---

## 作用域(R2)
| 东西 | 作用域 | 放哪 |
|---|---|---|
| hook 定义(脚本 + 两端配置) | **项目级**,随项目走 | 项目内 `.hooks/`、`.claude/settings.json`、`.codex/hooks.json` |
| Codex hook 能力开关 | **一次性全局**,当前默认开 | `~/.codex/config.toml` 的 `features.hooks`(或启动 `--enable hooks`) |

一句话:**行为跟项目,机器能力开关一次性全局**。Claude Code 无此总开关。Codex 项目级 `.codex/` 层只有在项目被 trust 后才会加载。
(为什么项目级:全局会在每个目录都弹自检,而那些地方没 `AGENTS.md` 可维护,纯噪音。)

## 共享脚本 `.hooks/stop-doccheck.sh`
两端共用一个脚本,只在调用时传 `claude` / `codex` 区分(reason 覆盖"文档自检 + 进展日志交接"两件):

```bash
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

reason="【收工自检】① 文档:本轮若有 结构/方案、心智模型、方向、外部资料、设计 变更 → 提议更新 ${docname}(注明层级)或 DESIGN.md,列出修改点等确认。② 交接:在 flow/进展.md 最上面追加一条进展(做了什么/为什么/怎么理解/产出路径/问题→解决/下一步),决策落 decisions.md、坑落 踩坑记录.md。都没有就回复「无需更新」。"
jq -n --arg r "$reason" '{decision:"block", reason:$r}'
```

要点:
- **统一输出**:首次 `{"decision":"block",...}` 会让 Stop hook 续跑一次自检;之后 `{"continue":true}` 放行。Codex 里 `decision:block` 不是拒绝本轮,而是自动创建一条 continuation prompt。
- **防循环**:优先看 `stop_hook_active`;再用 `/tmp` 下的 `turn_id`(没有则 `session_id`) marker 兜底。
- **reason 用 `jq -n` 生成**:中文 + 引号不用手动转义。
- 改这段 5 问清单,只改脚本一处,两端同步。

## 两端配置(thin,只调脚本)
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

## Codex 侧注意
- Codex 当前 `features.hooks` 默认 true;若用户显式关了,提醒在 `~/.codex/config.toml` 加 `[features]\nhooks = true` 或用 `--enable hooks`。
- 项目级 `.codex/hooks.json` 只有在项目被 Codex trust 后加载;首次添加 / 改动后需在 Codex TUI 输入 `/hooks` **审核批准**。批准绑定当前 `trusted_hash`,改了 `command` 要重新批准。**逻辑放在脚本里,以后改脚本不触发重批**(command 没变)。
- Codex `Stop` hook 返回 `decision:block` 会让 Codex 继续一轮并把 `reason` 当作续跑提示;因此脚本必须在续跑时返回 `{"continue":true}` 防止循环。

## 安装
由 `初始化SOP.md` 执行:复制脚本 → `chmod +x .hooks/stop-doccheck.sh` → 写两端配置 → 检测 Codex `features.hooks` 有效状态(若被关再提醒开启,不擅自改全局 config)→ 提醒 trust 项目与 `/hooks` 批准。
