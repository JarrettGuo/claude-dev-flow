---
description: 对未提交的改动或指定文件进行对抗性审查，无需完整 dev 流程。
argument-hint: [file-path or empty for git diff]
---

Invoke `@reviewer` on: $ARGUMENTS

## 执行逻辑

如果未提供参数，审查当前未提交改动：
- 先跑 `git diff --staged`
- 若无暂存内容，跑 `git diff`
- 若两者都空，告诉用户"无改动可 review"

如果提供了文件路径，审查该文件对照团队规范。

展示 reviewer 的完整报告。

## 使用场景

- 自己写了一段代码想快速确认是否符合规范
- `/dev` 或 `/fix` 走完之后想再过一遍
- 集成进 pre-commit 前的自检

## Rules

遵守 `.claude/docs/framework-rules.md` 的全部约定。重点：

- 绝不自动 commit、不 force push
- 遵守 `.claude/docs/output-style.md` 的输出风格（少说废话、合并预检、不要自述）
- 不修改用户确认范围外的文件

本命令特有规则：

- 只调用 reviewer 并透传其完整报告，不自作主张修改或精简 review 意见
- 绝不自动修复 reviewer 指出的问题——本命令只做审查，不做修改
- diff 为空时明确告诉用户"无改动可 review"，不要硬跑 reviewer
