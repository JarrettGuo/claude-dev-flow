---
description: 为当前改动生成符合团队规范的 commit 消息，遵循 Angular 简化版约定。
argument-hint: [optional hint about the change]
---

Use the `format-commit` skill to analyze current changes and produce a commit message.

User's hint (if any): $ARGUMENTS

## 执行

1. 通过 Bash 读取 `git status` 和 `git diff --staged`（若空则 `git diff`）
2. 按 `format-commit` skill 的逻辑分析
3. 输出：
   - 变更分析
   - 推荐 commit message
   - 备选方案
   - 提交命令
   - 红旗警告（如有）

## 规则

- **绝不自动执行 `git commit`** —— 只给用户命令
- **绝不超过 50 字符的 subject**
- **绝不在 subject 结尾加标点**
- 如果 diff 完全为空，告诉用户没有改动
