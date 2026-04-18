# Hello World 示例

这是一个最简单的 Claude Dev Flow 使用示例。

## 任务描述

创建一个简单的 Node.js 脚本，输出 "Hello, Claude Dev Flow!"

## 执行流程

### 1. Strategist（任务分析）

**任务类型**: code-dev
**执行路径**: strategist → reader → designer → builder → verifier → learner

### 2. Reader（代码读取）

检查项目结构，确认无冲突文件。

### 3. Designer（方案设计）

**文件**: `examples/hello.js`
**内容**: 单文件 Node.js 脚本
**依赖**: 无

### 4. Builder（代码实现）

```javascript
// examples/hello.js
console.log('Hello, Claude Dev Flow!');
```

### 5. Verifier（验证）

```bash
node examples/hello.js
# 预期输出: Hello, Claude Dev Flow!
```

### 6. Learner（经验总结）

- 任务类型: 简单脚本创建
- 执行时间: < 1分钟
- 无异常或风险点

## 运行方法

```bash
cd claude-dev-flow
node examples/hello.js
```

## 预期输出

```
Hello, Claude Dev Flow!
```
