# Framework Rules

本文档汇总 claude-dev-flow 框架下所有 command 和 agent 必须遵守的**全局规则**。

每个 command 和 agent 的 `## Rules` 章节都应引用本文档，然后再列出其特有规则。

---

## 一、版本控制铁律

这些规则**不可违反**，任何 agent 和 command 都必须遵守。

1. **绝不自动 commit**。所有 commit 动作必须由用户亲自执行。框架只能"给出建议的 commit message"，不能 `git commit`。
2. **绝不 force push**。不使用 `-f` / `--force` / `--force-with-lease`。
3. **merge 必须 `--no-ff`**，保留分支历史。
4. **不修改用户确认范围外的文件**。如果需要改动预期之外的文件，停下询问。

## 二、日志规范

所有在 `/dev` `/fix` 流程内运行的 agent 和 command，必须遵守 `.claude/skills/flow-log/SKILL.md` 的日志格式与双通道规则（写入 FLOW.log + echo 到 stderr）。

## 三、输出风格

所有 command 和 agent 的终端输出，必须遵守 `.claude/docs/output-style.md` 的规则。核心是：**少说废话，多给信号**。

## 四、栈无关原则

Agent 和 command 中**不得硬编码技术栈假设**。所有技术栈、目录结构、命名规范、git scope 候选，均从项目根目录 `CLAUDE.md` 读取。

## 五、栈外执行的约束

本框架下的所有文件操作都由 Claude Code（或等价的 AI 执行实例）完成。AI 执行实例必须：

- 任何异常立即停下报告，不自行决策修复方向
- 每个多步骤改动之间等待用户显式确认
- 不在一次对话里连做超过 3 个文件的独立改动（如需要，拆成多步）

---

## 引用方式

在 command 或 agent 的 `## Rules` 章节开头写：

```
遵守 .claude/docs/framework-rules.md 的全部约定。
本命令/agent 特有规则：

- ...

- ...
```
