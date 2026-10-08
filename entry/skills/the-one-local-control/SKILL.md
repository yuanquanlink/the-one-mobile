---
name: the-one-local-control
description: 将内容保存到 The One 本地 Inbox，或在 The One 本地 Manual Codex Task Queue 中创建任务
---

## 能力边界

仅在用户明确要求使用 **The One** 保存内容或创建任务时调用。

本 Skill：

- 先写入 The One 应用沙箱内的本地数据。
- 可以由用户配置的 The One Bridge 后续同步。
- 不直接修改 Obsidian 或 `D:\AI_Knowledge`。
- 不声称已经把任务发送给 Codex；任务进入 `manual_codex_adapter` 队列。

不要调用的情况：

- 用户只是讨论一个想法，没有要求保存。
- 用户要求直接修改真实知识库文件。
- 用户要求任务已经自动在 Codex 中执行完成。

## 场景 1：保存到 The One（save_to_brain）

典型话术：“把这段内容保存到 The One”、“用 The One 记下这个想法”。

### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'the-one-local-control' --scriptPath 'scripts/TheOneSkill.ets' --functionName 'save_to_brain' --args '{
  "arg1": "要保存的内容",
  "arg2": "idea"
}')
```

```json
{
  "args": {
    "type": "object",
    "required": ["arg1"],
    "properties": {
      "arg1": { "type": "string", "minLength": 1, "description": "要保存的正文" },
      "arg2": { "type": "string", "enum": ["idea", "note", "material", "task"], "default": "note" }
    }
  }
}
```

### 执行返回值

成功时 `status` 为 `success`，`data.destination` 固定为 `local_inbox`。失败时 `status` 为 `failed`，并返回 `ERR_INVALID_PARAMS` 或 `ERR_INTERNAL` 以及建议。

```json
{
  "type": "object",
  "required": ["type", "status"],
  "properties": {
    "type": { "const": "result" },
    "status": { "enum": ["success", "failed"] },
    "data": { "type": "object" },
    "errCode": { "enum": ["ERR_INVALID_PARAMS", "ERR_INTERNAL"] },
    "errMsg": { "type": "string" },
    "suggestion": { "type": "string" }
  }
}
```

## 场景 2：创建任务（create_codex_task）

典型话术：“在 The One 创建一个 Codex 任务”、“让 The One 记下这个待执行任务”。

### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'the-one-local-control' --scriptPath 'scripts/TheOneSkill.ets' --functionName 'create_codex_task' --args '{
  "arg1": "整理本周学习笔记",
  "arg2": "输出一份 Markdown 总结"
}')
```

```json
{
  "args": {
    "type": "object",
    "required": ["arg1"],
    "properties": {
      "arg1": { "type": "string", "minLength": 1, "description": "任务标题" },
      "arg2": { "type": "string", "description": "任务说明" }
    }
  }
}
```

### 执行返回值

成功时 `data.queue` 固定为 `manual_codex_adapter`；这表示任务已进入 The One 本地队列，不表示 Codex 已自动执行。

```json
{
  "type": "object",
  "required": ["type", "status"],
  "properties": {
    "type": { "const": "result" },
    "status": { "enum": ["success", "failed"] },
    "data": { "type": "object" },
    "errCode": { "enum": ["ERR_INVALID_PARAMS", "ERR_INTERNAL"] },
    "errMsg": { "type": "string" },
    "suggestion": { "type": "string" }
  }
}
```
