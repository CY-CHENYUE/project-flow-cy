# project-flow-cy

把任何项目（代码 / 调研 / 内容 / 方案）当 repo 管的一套 **AI 多 Agent 协作流程**。

核心是三句话：

- 上下文落进文件，不锁在对话里。
- Agent 之间靠 `flow/` 和 `docs/` 异步接力。
- 每轮收工写进展，下一棒从文件接上。

这个 skill 负责两件事：

1. **初始化 / 接入项目**：给项目铺好 `flow/`、`docs/`、`AGENTS.md`、`CLAUDE.md`、收工自检 hook 和方法论副本。
2. **收工交接**：在 `flow/进展.md` 顶部追加一条交接记录，并把同一条贴回对话。

它不处理具体业务内容。业务方案、代码、调研、设计稿仍由对应项目和对应 Agent 完成；`project-flow-cy` 只负责把协作方式和交接结构立起来。

## 适用场景

当你需要：

- 给一个新项目搭 Claude Code / Codex 共用的协作骨架
- 把已有项目接入 `flow/` + `docs/` 文件化流程
- 让多个 AI 会话、多个终端或多个模型之间能稳定接力
- 收工时生成一条下一棒能直接复制使用的 handoff
- 把方法论副本随项目保存，避免换会话后丢规则

就用这个 skill。

## 安装

把仓库 clone 到你的 skill 扫描目录。目录位置取决于客户端配置；常见做法：

```bash
# Codex / 本机统一技能目录示例
git clone https://github.com/CY-CHENYUE/project-flow-cy ~/.codex/skills/project-flow-cy

# 如果你的 Claude Code 扫描 ~/.claude/skills
git clone https://github.com/CY-CHENYUE/project-flow-cy ~/.claude/skills/project-flow-cy
```

如果你用的是统一的技能仓库，也可以把本仓库作为子目录放进去，例如：

```bash
git clone https://github.com/CY-CHENYUE/project-flow-cy ~/Documents/cc-skills/project-flow-cy
```

安装或更新后，新开会话，确认 skill 列表里出现 `project-flow-cy`。

## 怎么用

### 初始化 / 接入项目

在目标项目目录里说：

```text
用 project-flow-cy 接入协作流程
```

或：

```text
给这个项目搭 flow/docs 协作骨架
```

执行时会先读 `references/初始化SOP.md`，然后列出将创建 / 修改的文件，等你确认后再动手。已有项目走非破坏合并：缺什么补什么，不覆盖用户已有内容。

初始化后的典型结构：

```text
项目/
├── AGENTS.md  ←→ CLAUDE.md
├── DESIGN.md                        # 可选，设计 / 创意项目才建
├── flow/
│   ├── charter.md
│   ├── plan.md
│   ├── 进展.md
│   ├── decisions.md
│   ├── 踩坑记录.md
│   ├── tasks/
│   └── 规范/
├── docs/
├── scripts/ 或 src/                 # 代码项目才需要
└── .hooks/ .claude/ .codex/
```

### 收工交接

当你完成一棒，需要交给下一个 Agent / 会话：

```text
写个 handoff
```

或：

```text
交接给下一个 agent
```

skill 会在 `flow/进展.md` 顶部追加一条记录，字段包括：

- 做了什么
- 为什么这么做
- 怎么理解
- 产出路径
- 问题和解决
- 下一步

同一条也会贴回对话，方便你直接复制给别的 Agent。

## 文件职责

| 路径 | 作用 |
|---|---|
| `SKILL.md` | skill 入口，定义触发和两类操作 |
| `LICENSE` / `NOTICE` | 开源许可证和版权归属说明 |
| `references/初始化SOP.md` | 项目接入流程和自检清单 |
| `references/工作流程.md` | 五段式主循环、接力机制、目录归属 |
| `references/文档维护SOP.md` | `AGENTS.md` 怎么维护 |
| `references/DESIGN维护SOP.md` | `DESIGN.md` 怎么维护 |
| `references/hook机制.md` | 收工自检 hook 的机制与安装说明 |
| `assets/templates/` | 注入项目的模板文件 |
| `visual-guide.html` | 可视化说明页 |

## 方法论要点

- **目录归属**：协调 / 推进项目的内容进 `flow/`；交付物本身进 `docs/`、`scripts/` 或 `src/`。
- **进展日志**：`flow/进展.md` 是接力棒，新的记录放最上面，顶部那条就是当前 handoff。
- **运行时合同**：根级 `AGENTS.md` 是两个工具共读的规则入口，`CLAUDE.md` 软链到它。
- **文档不漂移**：Stop hook 在收工时提醒是否要更新文档、写进展、落决策或记踩坑。
- **非破坏接入**：已有项目只补缺失内容，遇到冲突先列清单请用户确认。

## 更新旧项目

这个 skill 是幂等的。已经接入过的项目可以重复运行初始化操作，用来补缺失文件或刷新 `flow/规范/` 下的方法论副本。

## 边界

- 不替你写业务方案、代码、调研或设计成品。
- 不自动提交或推送 GitHub。
- 不擅自覆盖已有 `AGENTS.md`、`CLAUDE.md`、hook 配置或用户文档。
- 不擅自修改全局 Codex / Claude 配置。

## 关注公众号

<div align="center">
  <p>扫码关注公众号，获取更新与交流反馈</p>
  <img src="assets/wechat-qr.jpg" alt="WeChat Official Account QR Code" width="200">
</div>

## 许可

GPL-3.0-or-later。

使用、复制、修改或分发本项目时，请保留 CY-CHENYUE 的版权和许可证声明；如果分发修改版或派生版本，也需要按同一许可证开源。
