# 初始化 SOP(把一个项目接入协作流程)

> 一身两用:**执行规范**(skill / AI 照着把项目接入)+ **验证清单**(跑完逐项核对,确认已正确接入)。

---

## 原则
- 新项目全量铺开;**已有项目非破坏合并**(缺啥补啥,不覆盖)。
- **幂等**:可重复跑,不产生重复或破坏。
- **一个项目边界一个控制面**:单仓多子项目只建一套根级 `flow/`、`docs/` 和 hook;子项目不机械复制控制层。
- **文档默认集中**:跨模块和需要统一查找的文档进入根级 `docs/`;不搬动已有 README、生成文档或必须紧贴代码的说明。
- 动手前先列「将创建 / 修改清单」给用户确认(同 `文档维护SOP.md` 的提议 → 确认 → 写入)。
- 已有 JSON 配置用结构化方式合并;不能安全合并时,只生成建议文件并请用户确认,不硬改。

## 步骤
1. **扫描项目边界**:
   - 看根级和候选子目录的 `.git`、workspace / 构建配置、包清单、CI 和发布方式。
   - 列出有独立职责的候选子项目;排除 `node_modules/`、`dist/`、`build/`、临时目录和普通工具目录。
   - 按 `多子项目结构.md` 判断单体项目、单仓多子项目或多个独立仓库。拿不准就把判断依据列给用户确认。
2. **判断接入状态**:每个确认的项目边界有无 `AGENTS.md` / 已有内容 → 决定全量铺或非破坏合并。
3. **先报清单并确认**:说明边界判断、根级将创建 / 修改的文件、各子项目局部入口,以及明确不会创建 / 移动的内容。用户确认后再动手。
4. **铺根级骨架**:每个项目边界只建一套 `flow/`(`charter.md` `plan.md` `进展.md` `decisions.md` `踩坑记录.md` `tasks/`)+ `docs/`(放 `README.md`)。保留已有代码布局;只有全新单体代码项目且用户需要时才补 `scripts/` 或 `src/`,不替 monorepo 猜造业务目录。〔归属规则见 `工作流程.md`〕
5. **根级入口注入**:
   - 写 `AGENTS.md`(从 `templates/AGENTS.md`:精要规则 + 约束 + 目录地图 + 指针;已有项目则**合并**进现有 AGENTS.md)。
   - 带入开工时的需求理解与收尾回应约定,使日常任务也遵循;新任务或目标实质变化时简述目标和原始问题,明确需求后继续,不新增确认关卡。详见 `工作流程.md` 的「需求理解与结果回应」。
   - 建软链:`ln -s AGENTS.md CLAUDE.md`(Windows 改复制一份)。
   - (可选)写 `DESIGN.md`——仅当项目有设计 / 创意工作。
6. **单仓多子项目的局部入口**:
   - 每个有独立职责的子项目从 `templates/MODULE_AGENTS.md` 生成 `<module>/AGENTS.md`,替换项目名、子项目路径和根级相对路径占位符。
   - 在同目录建立 `CLAUDE.md -> AGENTS.md`(Windows 改复制)。局部入口只写本模块职责、命令、约束和根级指针。
   - 不在子项目重复创建 `flow/`、`docs/`、`.hooks/`、`.claude/`、`.codex/`;不移动已有局部文档。根级 `docs/README.md` 对保留在模块内的文档加索引。
7. **装根级 hook**:复制 `.hooks/stop-doccheck.sh` → `chmod +x` → 写根级 `.claude/settings.json` 与 `.codex/hooks.json`。
   - Codex Stop 直接返回 `continue:true`,不读取输入、不检查版本或回合 ID、不自动续跑;将最终回复前的业务专项检查、文档自检、交接和记录要求合并到根级 `AGENTS.md`。Claude Code 保留按 `prompt_id` 每回合最多一次的续跑兜底。
   - **不擅自改全局 `~/.codex/config.toml`**,也不要求仅为本技能开启 Codex hooks;收工要求由 Agent 在最终回复前主动执行。
   - 若需要加载 Codex 项目级 Hook,项目需 trust,首次添加或修改 command 时按客户端要求批准;保留既有 command 和其他 handler。〔细节见 `hook机制.md`〕
8. **方法论详规随项目**:把 6 份详规复制进根级 `flow/规范/`(自包含)。〔或改为引用中心版——待定 #3〕

## 已有项目的非破坏合并细则
- 模板文件不存在才复制;已有 `flow/*.md`、`docs/README.md`、`DESIGN.md` 默认不覆盖。
- `AGENTS.md` 已存在:在文件末尾维护一个 `<!-- project-flow-cy:start -->` / `<!-- project-flow-cy:end -->` 包住的协作约定块;已有该块则只更新块内内容,块外原文不动。
- `CLAUDE.md`:不存在则软链到 `AGENTS.md`;已是正确软链则跳过;若已存在且不是该软链,列为冲突项请用户确认,不要覆盖。
- 子项目局部入口遵守同一规则:已有 `<module>/AGENTS.md` 就只维护明确标记的 project-flow 块;已有 `<module>/CLAUDE.md` 且不是正确软链时列为冲突项。不要把根级 `AGENTS.md` 全文复制进模块。
- 已有子项目 `docs/`、README 或其他说明不迁移、不删除。需要统一发现时,只提议在根级 `docs/README.md` 增加索引;已有索引块只更新块内内容。
- `.hooks/stop-doccheck.sh`:不存在则复制;存在则先比对内容,确认它就是旧版 project-flow 脚本时更新,否则生成 `.hooks/stop-doccheck.project-flow-cy.new.sh` 并请用户确认。
- `.claude/settings.json` 与 `.codex/hooks.json`:不存在则复制;存在则只补 `Stop` 事件下本脚本的 command handler,保留其他 hook。若 JSON 解析失败或结构不明,生成 `.project-flow-cy.suggested.*.json` 并请用户确认。
- `flow/规范/`:可覆盖更新这 6 份方法论副本,因为它们是 skill 注入的规范副本;覆盖前仍在清单里说明。

## 接入自检(跑完逐项核对)
- [ ] 已报告项目边界判断;单仓多子项目没有被误拆成多套总体流程,独立仓库也没有被误合并
- [ ] 根级 `flow/`(charter/plan/进展/decisions/踩坑记录/tasks)与 `docs/` 已建;已有代码目录保持原样
- [ ] `AGENTS.md` 存在;读 `CLAUDE.md` = `AGENTS.md`(软链解析正确)
- [ ] AGENTS.md 里有:目录地图 + 开工/收工 + 核心约束 + 详规指针;明确最终回复前完成检查和记录,Codex 不等待 Stop 续跑
- [ ] 根级入口包含需求理解约定及详规指针;收尾仍用六项字段,以“为什么”回应用户目标与原始问题,普通补充不重复重述
- [ ] 每个有独立职责的子项目都有局部 `AGENTS.md` 与同源 `CLAUDE.md`;根级相对路径均可解析
- [ ] 子项目没有新增重复的 `flow/`、`docs/` 或 hook;保留在模块内的文档已从根级 `docs/README.md` 索引
- [ ] (若有设计工作)`DESIGN.md` 存在
- [ ] 在 `project-flow-cy` Skill 源码目录运行 `bash tests/test-stop-hook.sh`;确认目标项目 `.hooks/stop-doccheck.sh` 可执行:Codex 直接输出 `continue:true`,不读取输入或调用版本、ID、内容检测;Claude 只按 `prompt_id` 界定回合,首次 Stop 输出 `decision:block`,同一 scope 的 active 或重复 Stop 输出 `continue:true`,缺稳定 ID、非法输入等异常安全放行
- [ ] 需要验证 Codex 实际 Stop 与恢复行为时,显式运行 `PROJECT_FLOW_RUN_CODEX_TUI_E2E=1 bash tests/test-codex-stop-hook-e2e.sh`,确认首次回复、同会话继续、退出恢复均无本技能续跑提示;桌面折叠状态须另行实际观察
- [ ] `.claude/settings.json`、`.codex/hooks.json` 已写
- [ ] 若使用 Codex 项目级 Hook,已按客户端要求完成 trust 与必要批准;未为本技能改动全局 hooks 开关,其他 handler 已保留
- [ ] 根级 `flow/规范/` 下 6 份详规齐
- [ ] `flow/charter.md` 已开始填
