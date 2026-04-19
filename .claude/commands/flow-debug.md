---
description: 通过读取 FLOW.log 和产物分析已完成的 /dev 或 /fix 运行记录，找出并修复问题。默认"可修改"模式，任何代码改动前需用户确认。最多 2 轮修复。
argument-hint: <feature-or-bug-name> [optional: additional context or "only-analyze"]
---

Invoke `@flow-debugger` to analyze a past `/dev` or `/fix` run and optionally fix issues.

User input: $ARGUMENTS

## 前置解析

从 `$ARGUMENTS` 提取：
- **feature-or-bug name**（必需）: 第一个词
- **额外说明**（可选）: 后续文字，如"帮我修掉 review round 2 提的那几个问题"或"只分析，不要修"

## 执行

### Step 1: 寻找目标

```bash
FEATURE=$(echo "$ARGUMENTS" | awk '{print $1}')

# 先找 specs
if [ -d ".dev-flow/specs/${FEATURE}" ]; then
  TARGET=".dev-flow/specs/${FEATURE}"
elif [ -d ".dev-flow/fixes/${FEATURE}" ]; then
  TARGET=".dev-flow/fixes/${FEATURE}"
else
  echo "❌ 找不到 ${FEATURE} 对应的流程目录"
  echo ""
  echo "已知的流程："
  ls .dev-flow/specs/ 2>/dev/null | sed 's|^|  specs/|'
  ls .dev-flow/fixes/ 2>/dev/null | sed 's|^|  fixes/|'
  exit 1
fi

echo "找到: ${TARGET}"
```

### Step 2: 快速验证

```bash
if [ ! -f "${TARGET}/FLOW.log" ]; then
  echo "⚠️ ${TARGET} 中没有 FLOW.log，可能不是通过 /dev 或 /fix 生成的。"
  echo "是否继续（Y/n）？"
  # 等待用户确认
fi

# 看 FLOW.log 是否有 header 和 footer
HAS_HEADER=$(head -5 "${TARGET}/FLOW.log" | grep -c "FLOW LOG:" || echo 0)
HAS_FOOTER=$(tail -10 "${TARGET}/FLOW.log" | grep -c "COMPLETED:" || echo 0)

if [ "$HAS_HEADER" = "0" ]; then
  echo "⚠️ 日志没有 header，可能损坏。"
fi
if [ "$HAS_FOOTER" = "0" ]; then
  echo "⚠️ 日志没有 footer，可能是未完成的流程（/dev 或 /fix 中途被打断？）。"
fi
```

### Step 3: 设置当前 flow（让 flow-debugger 的日志写入目标 FLOW.log）

```bash
# 保存原有 .current-flow（如果有）
if [ -f .dev-flow/.current-flow ]; then
  cp .dev-flow/.current-flow .dev-flow/.current-flow.bak
fi

# 临时指向目标 flow
BASE_TYPE=$(echo "$TARGET" | sed 's|^\.dev-flow/||' | cut -d/ -f1)
echo "${BASE_TYPE}/${FEATURE}" > .dev-flow/.current-flow
```

### Step 4: Invoke @flow-debugger

告诉 flow-debugger：

```
目标 flow: <TARGET>
额外说明: <从 $ARGUMENTS 提取的第二部分，或 "（无）">

请按你的 workflow 执行：
1. 读 FLOW.log 和所有产物
2. 识别问题
3. 判断是否可以自动修
4. 按需提出修复方案 + 等用户确认 + 修 + 验证 + 报告

如用户特别声明"只分析不要修"，则跳过修复步骤，直接产出 DEBUG-REPORT.md。
```

### Step 5: Handle flow-debugger output

- **如果 flow-debugger 给出修复方案**：直接透传给用户确认。用户确认后把确认信号回传给 flow-debugger，它会执行修复。
- **如果 flow-debugger 输出 DEBUG-REPORT.md**：告诉用户文件位置和"可以把这份报告粘给 GPT 二次分析"。
- **如果 flow-debugger 拒绝（如日志损坏）**：透传拒绝理由。

### Step 6: 清理

```bash
# 还原原有 .current-flow
if [ -f .dev-flow/.current-flow.bak ]; then
  mv .dev-flow/.current-flow.bak .dev-flow/.current-flow
else
  rm -f .dev-flow/.current-flow
fi
```

### Step 7: 最终总结

给用户：
- 分析结果：发现了 N 个问题
- 修复结果（如修了）：成功 / 失败 / 部分成功
- 下一步建议
- 日志追加内容：显示这次 debug 往 FLOW.log 追加了哪些行

## 典型用法示例

**只分析，不修**：
```
/flow-debug avatar-upload 只分析不要修
```

**默认（分析 + 修复）**：
```
/flow-debug login-bug
```

**带具体指令**：
```
/flow-debug password-reset 帮我修掉 review 提的 i18n 问题
```

## Rules

- **默认可修改代码模式**，但每次改动前 flow-debugger 必有确认门
- 修复循环最多 2 轮（由 flow-debugger 内部控制）
- 绝不自动 commit
- 绝不 force push
- 运行结束必须还原 `.current-flow`（即使中途出错）

## 与其他命令的区别

- 区别于 `/dev` 和 `/fix`: 这两个是**跑新流程**，`/flow-debug` 是**复盘已完成的流程**
- 区别于 `/review`: `/review` 只看当前 git diff，`/flow-debug` 看历史流程的全部产物
- 区别于 @debugger agent: @debugger 在 /fix 中做代码根因分析，@flow-debugger 做运行日志复盘
