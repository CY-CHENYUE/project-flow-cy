---
name: project-flow-cy
description: 用一套基于文件的多 Agent 协作流程来初始化和管理项目,并在 Claude Code 与 Codex 之间用 flow/进展.md 进展日志接力。两个操作——(1) 把一个项目接入流程:铺好 flow/(控制层)+ docs/(内容层)、生成 AGENTS.md 并软链 CLAUDE.md、装收工自检 hook、复制方法论详规进项目;(2) 收工交接:在 flow/进展.md 追加一条进展(做了什么/为什么/产出路径/下一步,交接棒)。当用户说"用这套流程/协作流程初始化项目""接入协作流程""给项目搭 flow/docs 文档结构""初始化项目文档体系""建项目协作骨架""写交接卡""写个 handoff""生成交接卡""交接给下一个 agent/会话"时,必须使用本 skill。即使没明确点名,只要是要给项目搭这套 docs/flow 协作骨架、或在 agent/会话之间做结构化交接,也应主动使用。仅用于"项目协作流程的搭建与交接",不处理具体业务内容。
---

# project-flow-cy

把任何项目(代码 / 调研 / 内容 / 方案)当 repo 管:**上下文落进文件,Agent 之间靠 `flow/`、`docs/` 异步接力,跨模型评审做质量门。** 本 skill 负责**搭建与维护这套协作结构**,以及在 Agent 间**收工交接(进展日志)**。

- 完整方法论详规在 `references/`(`工作流程.md` / `文档维护SOP.md` / `DESIGN维护SOP.md` / `hook机制.md` / `初始化SOP.md`)。
- 注入项目的模板实体在 `assets/templates/`。

## 先判断用户要哪个操作
- 要"初始化 / 接入 / 搭结构 / 建骨架" → **操作 A**
- 要"收工 / 交接 / 写交接卡 / handoff / 交接给下一个" → **操作 B**(在进展日志追加一条)
- 拿不准就先问一句,别猜。

---

## 操作 A:初始化 / 接入项目

把当前项目接入协作流程,产出标准结构。**完整步骤与验证清单在 `references/初始化SOP.md`——执行前先读它。** 要点(对应 R5 非破坏):

1. **判断状态**:目录是否已有 `AGENTS.md` / 内容。新项目全量铺;**已有项目非破坏合并(缺啥补啥,绝不覆盖已有内容)**。
2. **先列清单等确认**:把"将创建 / 修改的文件"列给用户,确认后再动手。
3. **铺目录**:建 `flow/`(`charter.md` `plan.md` `进展.md` `decisions.md` `踩坑记录.md` `tasks/`)+ `docs/`,内容从 `assets/templates/` 复制。**代码项目**另建 `scripts/`(或 `src/`)放代码。
4. **入口**:用 `assets/templates/AGENTS.md` 生成项目 `AGENTS.md`(替换 `<项目名>`;已有 AGENTS.md 则**合并**精要规则进去);`ln -s AGENTS.md CLAUDE.md`(Windows 改复制);可选 `DESIGN.md`(仅当项目有设计 / 创意工作)。
5. **装 hook**:复制 `assets/templates/.hooks/`、`.claude/`、`.codex/` 到项目;`chmod +x .hooks/stop-doccheck.sh`;检测 Codex `features.hooks` 是否有效(当前默认 true,若被关才提醒用户开 `~/.codex/config.toml` 或 `--enable hooks`)——**不擅自改全局 config**;提醒 Codex 项目需 trust 且 `/hooks` 批准。详见 `references/hook机制.md`。
6. **详规随项目**:把 `references/` 下 5 份详规复制到项目 `flow/规范/`(自包含)。
7. **跑接入自检**:逐项核对 `references/初始化SOP.md` 末尾清单(软链是否解析正确、hook 是否输出合法 JSON、目录是否齐),把结果报告给用户。
8. **收尾**:引导用户开始填 `flow/charter.md`。

幂等:可重复跑,不产生重复或破坏(也是更新老项目详规副本的方式)。

---

## 操作 B:收工交接(在进展日志追加一条)

把当前会话这一棒的进展,**追加到 `flow/进展.md` 最上面**,供下一个 Agent / 会话接力。**一个 append 文件,不是一张张攒卡**;顶部那条 = 当前交接棒。

1. 在 `flow/进展.md` 顶部加一条(模板在文件里),填:
   - **做了什么 / 为什么 / 怎么理解 / 产出(路径)/ 问题→解决 / 下一步**(接手方第一个动作)。
   - **并把这条同时贴在回复里**——用户当场看到 + 能直接复制给别的 Agent。
2. 决策追加 `flow/decisions.md`;问题 / 踩坑追加 `flow/踩坑记录.md`。
3. **铁律:只带「指针 + 增量」**——「产出」给 `docs/`·`scripts/` 路径(**出方案就给 `docs/specs/xxx.md`,让下一棒对照实现**),不重抄内容。

---

## 一直要守的铁律(来自方法论)
- 审稿模型 ≠ 产出模型;产出落文件;先 plan 后 act;一会话一焦点;从根本解决不打补丁。
- **目录归属(R1)**:协调 / 推进项目的 → `flow/`;要交付的内容 → `docs/`(知识)或 `scripts/`·`src/`(代码)。
- 需要展开规则时按需读 `references/` 下对应详规,别把全文塞进当前上下文。
