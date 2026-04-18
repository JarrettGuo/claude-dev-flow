---
name: search-codebase
description: Search the codebase for relevant code by topic, symbol, or pattern. Uses native Grep/Glob by default, can upgrade to GitLab-based search if the gitlab MCP is configured.
---

# Search Codebase

给 agent 一个统一的"找相关代码"能力。默认用原生工具，有 gitlab MCP 时可扩展到跨仓库搜索。

## 能力范围

**负责**：
- 在当前代码库找与主题/功能/错误相关的文件
- （启用 gitlab 时）跨相关仓库搜索
- 返回按相关性排序的结果
- 尊重 `.gitignore` 和常见忽略规则

**不负责**：
- 修改代码
- 理解业务含义（调用方自己判断）

## 输入

- 描述主题的文字（如 "user profile avatar upload"）
- 或具体 symbol（如 "getUserProfile"）
- 或一段错误信息

## 路由表

| 优先级 | 判断条件 | 实现 | 所需 MCP | 当前状态 |
|-------|---------|------|---------|---------|
| 1 | 查询明确要求跨仓库搜索 + gitlab MCP 可用 | 调用 gitlab MCP 的 search API | `gitlab` | ⚪ 未启用 |
| 2 | 默认（当前仓库内） | 原生 Grep + Glob 组合 | 无 | ✅ 已启用 |

## 执行流程（原生实现）

1. **分词**：把输入拆成若干关键词
2. **Glob 筛选**：根据项目结构（client/ 或 server/）筛出候选目录
3. **Grep 搜索**：对每个关键词做搜索，合并结果
4. **排序**：
   - 同一文件命中多个关键词 → 更相关
   - 路径含关键词 → 更相关
   - 命中在函数定义/类定义位置 → 更相关
5. **截断**：返回前 10 个最相关位置

## 输出格式

```
## Query
<原始查询>

## Strategy Used
<gitlab-api / grep-based>

## Top Matches

### 1. path/to/file.ts:42-58
<一句话说明为什么相关>
<可选：命中行的前后 3 行上下文>

### 2. path/to/other.ts:120
...
```

## 扩展此 Skill

要升级跨仓库搜索：

1. 用 `/add-skill` 让 Claude 引导启用 gitlab MCP
2. 或手动配置 gitlab MCP，路由表状态改为 ✅

详见 `.claude/docs/add-plugin-guide.md`。
