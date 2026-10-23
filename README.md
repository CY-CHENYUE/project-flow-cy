# project-flow-cy

把任何项目（代码 / 调研 / 内容 / 方案）当 repo 管的一套 **AI 多 Agent 协作流程**。

核心是三句话：

- 上下文落进文件，不锁在对话里。
- Agent 之间靠 `flow/` 和 `docs/` 异步接力。
- 每轮收工写进展，下一棒从文件接上。

这个 skill 负责两件事：

1. **初始化 / 接入项目**：先判断单体项目、单仓多子项目或多独立仓库，再铺好对应层级的 `flow/`、`docs/`、规则入口、收工自检 hook 和方法论副本。
2. **收工交接**：在 `flow/进展.md` 顶部追加一条交接记录，并在对话中清晰展示同一组事实。

它不处理具体业务内容。业务方案、代码、调研、设计稿仍由对应项目和对应 Agent 完成；`project-flow-cy` 只负责把协作方式和交接结构立起来。

## 适用场景

当你需要：

- 给一个新项目搭 Claude Code / Codex 共用的协作骨架
- 把已有项目接入 `flow/` + `docs/` 文件化流程
- 管理同时包含前端、后端、落地页或多个服务的单仓项目
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

执行时会先读 `references/初始化SOP.md`。存在多个代码目录时，还会读 `references/多子项目结构.md`，先报告项目边界判断，再列出将创建 / 修改的文件，等你确认后动手。已有项目走非破坏合并：缺什么补什么，不覆盖用户已有内容。

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
├── scripts/、src/ 或现有代码目录     # 保留项目自己的代码布局
└── .hooks/ .claude/ .codex/
```

### 单仓多子项目

当前端、后端、落地页共同服务同一个总体项目，并共享仓库、目标和发布节奏时，它们属于一个项目边界。默认结构是：

```text
总体项目/
├── AGENTS.md
├── CLAUDE.md -> AGENTS.md
├── flow/                              # 唯一总体控制层
├── docs/                              # 文档统一入口
│   ├── product/
│   ├── architecture/
│   ├── contracts/                    # API、事件、数据模型
│   ├── modules/
│   │   ├── frontend/
│   │   ├── backend/
│   │   └── landing/
│   └── reviews/
├── frontend/
│   ├── AGENTS.md
│   ├── CLAUDE.md -> AGENTS.md
│   └── <源码、测试、构建配置>
├── backend/
│   ├── AGENTS.md
│   ├── CLAUDE.md -> AGENTS.md
│   └── <源码、测试、构建配置>
├── landing/
│   ├── AGENTS.md
│   ├── CLAUDE.md -> AGENTS.md
│   └── <源码、测试、构建配置>
└── .hooks/ .claude/ .codex/          # 只放根级
```

根级 `flow/` 统一管理总体目标、计划、任务、决策、问题和交接；根级 `docs/` 统一管理产品、架构、跨模块契约和需要集中查找的模块说明。子项目目录主要保存源码、测试和构建配置，不重复创建 `flow/` 或完整 `docs/`。

已有的子项目 README、工具生成文档或必须紧贴代码维护的说明不会被搬走，只会在根级 `docs/README.md` 建索引。若某个子项目有独立 Git 仓库、版本、发布或团队边界，才把它当成独立项目，建立自己的完整协作骨架。

### 开工时先说明需求理解

接入后,Agent 开始新任务、接手任务或目标明显变化时,会先读必要上下文,再用自己的话简短说明你希望达到什么结果、要解决什么问题,必要时补充这次的范围。例如：

> 我理解,你希望 Agent 先说明自己理解的目标和待解决的问题,让你能及时发现理解偏差,完成后也能核对结果是否回应了需求。我会把这一步放进开工约定,并让结尾回应原始目标。

普通补充、进度询问和连续小改动不会反复重述。需求清楚就按已有授权继续执行,不用每次等你确认;推测出的目的会明确标为推断,关键歧义才会提问。结尾通过原有交接字段回应需求,不重复整段开场。

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

- **做了什么**：本轮完成的具体改动。
- **为什么**：本轮工作回应的用户目标与原始问题。
- **怎么理解**：影响接手的假设或边界。
- **产出**：真实文件路径或可点击链接。
- **问题与解决**：执行中的障碍、处理结果及必要验证；无问题时简写“无新增问题”。
- **下一步**：接手方第一个具体动作，或说明本项已完成。

回复默认像上面这样直接显示单层 Markdown 列表，字段名加粗，列表与前后正文留空行，方便阅读和复制。日志保留日期及项目相对路径，回复按客户端使用可点击链接；两处事实一致，不要求逐字相同，也不重复贴摘要。你明确要求纯文本代码块等格式时，会按你的要求呈现。

收尾结合具体改动、产出和验证说明原始目标达到了哪里,未达到或未验证的部分如实交代。

收工检查与记录在最终回复前完成。Codex 直接展示任务结果和交接，本技能的 Stop 只返回 `continue:true`，不会再插入收工续跑消息或在结果后追加“无需更新”；Claude Code 保留每个用户回合最多一次的续跑兜底。

输出规则写在 `SKILL.md` 的「交接输出约定」中，并随入口和模板带入项目。它约定生成内容与 Markdown 结构，无法保证不同客户端的字体、间距和容器外观一致。已有项目需要定向更新入口及规范副本，历史进展保留原样。

## 文件职责

| 路径 | 作用 |
|---|---|
| `SKILL.md` | skill 入口，定义触发和两类操作 |
| `LICENSE` / `NOTICE` | 开源许可证和版权归属说明 |
| `references/初始化SOP.md` | 项目接入流程和自检清单 |
| `references/工作流程.md` | 五段式主循环、接力机制、目录归属 |
| `references/多子项目结构.md` | 单体、monorepo、多独立仓库的边界和目录规则 |
| `references/文档维护SOP.md` | `AGENTS.md` 怎么维护 |
| `references/DESIGN维护SOP.md` | `DESIGN.md` 怎么维护 |
| `references/hook机制.md` | 收工自检 hook 的机制与安装说明 |
| `assets/templates/` | 注入项目的模板文件 |
| `assets/templates/MODULE_AGENTS.md` | 子项目局部规则入口模板 |
| `evals/evals.json` | 项目接入、Hook 升级、需求理解与最终回复行为用例 |
| `tests/test-multi-project-structure.sh` | 校验多子项目规则、模板和评测结构一致性 |
| `tests/test-stop-hook.sh` | 验证 Codex 静默放行，以及 Claude 稳定回合 ID、异常输入与并发防重 |
| `tests/test-codex-stop-hook-e2e.sh` | 显式验证真实 Codex TUI 首次／同会话／退出恢复均无本技能续跑提示 |
| `visual-guide.html` | 可视化说明页 |

## 方法论要点

- **一个项目边界一个控制面**：单仓多子项目只保留一套根级 `flow/`、`docs/` 和 hook。
- **目录归属**：协调 / 推进项目的内容进根级 `flow/`；需要统一发现的知识和方案进根级 `docs/`；代码进对应子项目。
- **规则分层、文档集中**：根级和子项目可以有各自作用域的 `AGENTS.md`，总体文档仍集中管理；代码邻近文档只作为明确例外保留。
- **进展日志**：`flow/进展.md` 是接力棒，新的记录放最上面，顶部那条就是当前 handoff。
- **运行时合同**：根级 `AGENTS.md` 是两个工具共读的规则入口，`CLAUDE.md` 软链到它。
- **文档不漂移**：`AGENTS.md` 固化最终回复前的业务专项检查、文档自检和交接记录。Codex Stop 静默放行，不检查版本或回合 ID；Claude Code 按 `prompt_id` 保留每回合最多一次的续跑兜底。分端机制与历史记录见 `references/hook机制.md`。
- **非破坏接入**：已有项目只补缺失内容，遇到冲突先列清单请用户确认。

## 更新旧项目

这个 skill 是幂等的。已经接入过的项目可以重复运行初始化操作，用来补缺失文件、在确认旧脚本属于 project-flow 后升级根级 Hook，或刷新 `flow/规范/` 下的方法论副本。Codex command handler 没变时不需要因脚本内容更新重新批准；自定义 Hook 仍按冲突处理，不会覆盖。旧版 Codex 自动续跑应随脚本升级为静默放行，并同步入口中的收工前置约定；无需仅为本技能开启全局 hooks。

## 边界

- 不替你写业务方案、代码、调研或设计成品。
- 不自动提交或推送 GitHub。
- 不把一个 monorepo 的每个代码目录机械初始化成独立项目。
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
