# 初始化 SOP(把一个项目接入协作流程)

> 一身两用:**执行规范**(skill / AI 照着把项目接入)+ **验证清单**(跑完逐项核对,确认已正确接入)。

---

## 原则
- 新项目全量铺开;**已有项目非破坏合并**(缺啥补啥,不覆盖)。
- **幂等**:可重复跑,不产生重复或破坏。
- 动手前先列「将创建 / 修改清单」给用户确认(同 `文档维护SOP.md` 的提议 → 确认 → 写入)。
- 已有 JSON 配置用结构化方式合并;不能安全合并时,只生成建议文件并请用户确认,不硬改。

## 步骤
1. **判断状态**:目录有无 `AGENTS.md` / 已有内容 → 决定全量铺 or 合并。
2. **目录骨架**:建 `flow/`(`charter.md` `plan.md` `进展.md` `decisions.md` `踩坑记录.md` `tasks/`)+ `docs/`(放 `README.md`)。**代码项目**另建 `scripts/`(或 `src/`)放代码。〔归属规则见 `工作流程.md`〕
3. **入口注入**:
   - 写 `AGENTS.md`(从 `templates/AGENTS.md`:精要规则 + 约束 + 目录地图 + 指针;已有项目则**合并**进现有 AGENTS.md)。
   - 建软链:`ln -s AGENTS.md CLAUDE.md`(Windows 改复制一份)。
   - (可选)写 `DESIGN.md`——仅当项目有设计 / 创意工作。
4. **装 hook**:复制 `.hooks/stop-doccheck.sh` → `chmod +x` → 写 `.claude/settings.json` 与 `.codex/hooks.json`。
   - Codex 当前 `features.hooks` 默认 true;检测有效状态,若被关才**提醒用户**开(或 `--enable hooks`),**不擅自改全局 `~/.codex/config.toml`**。
   - 提醒:Codex 项目级 `.codex/` 层需项目 trust,且需 `/hooks` 审核批准。〔细节见 `hook机制.md`〕
5. **方法论详规随项目**:把 5 份详规复制进 `flow/规范/`(自包含)。〔或改为引用中心版——待定 #3〕

## 已有项目的非破坏合并细则
- 模板文件不存在才复制;已有 `flow/*.md`、`docs/README.md`、`DESIGN.md` 默认不覆盖。
- `AGENTS.md` 已存在:在文件末尾维护一个 `<!-- project-flow-cy:start -->` / `<!-- project-flow-cy:end -->` 包住的协作约定块;已有该块则只更新块内内容,块外原文不动。
- `CLAUDE.md`:不存在则软链到 `AGENTS.md`;已是正确软链则跳过;若已存在且不是该软链,列为冲突项请用户确认,不要覆盖。
- `.hooks/stop-doccheck.sh`:不存在则复制;存在则先比对内容,确认它就是旧版 project-flow 脚本时更新,否则生成 `.hooks/stop-doccheck.project-flow-cy.new.sh` 并请用户确认。
- `.claude/settings.json` 与 `.codex/hooks.json`:不存在则复制;存在则只补 `Stop` 事件下本脚本的 command handler,保留其他 hook。若 JSON 解析失败或结构不明,生成 `.project-flow-cy.suggested.*.json` 并请用户确认。
- `flow/规范/`:可覆盖更新这 5 份方法论副本,因为它们是 skill 注入的规范副本;覆盖前仍在清单里说明。

## 接入自检(跑完逐项核对)
- [ ] `flow/`(charter/plan/进展/decisions/踩坑记录/tasks)与 `docs/` 已建;代码项目有 `scripts/`·`src/`
- [ ] `AGENTS.md` 存在;读 `CLAUDE.md` = `AGENTS.md`(软链解析正确)
- [ ] AGENTS.md 里有:目录地图 + 开工/收工 + 核心约束 + 详规指针
- [ ] (若有设计工作)`DESIGN.md` 存在
- [ ] `.hooks/stop-doccheck.sh` 可执行:首次 `printf '%s' '{"session_id":"t","turn_id":"t1","stop_hook_active":false}' | bash .hooks/stop-doccheck.sh codex` 输出 `decision:block`;续跑 `printf '%s' '{"session_id":"t","turn_id":"t1","stop_hook_active":true}' | bash .hooks/stop-doccheck.sh codex` 输出 `continue:true`
- [ ] `.claude/settings.json`、`.codex/hooks.json` 已写
- [ ] Codex 项目已 trust;`features.hooks` 未被关闭;`/hooks` 已批准
- [ ] `flow/规范/` 下 5 份详规齐
- [ ] `flow/charter.md` 已开始填
