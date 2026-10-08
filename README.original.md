# The One Mobile

The One Mobile 是 The One 的 HarmonyOS 原生手机端，目标设备为 HUAWEI Mate 70 Pro，目标系统为 HarmonyOS 7 / OpenHarmony 7 / API 26。工程使用 ArkTS、ArkUI、Stage Model、`UIAbility` 与 `Navigation + NavPathStack`，不是 Android、Flutter 或 WebView 包装。

当前链路：

```text
Mate 70 Pro → The One Mobile → The One Bridge → Windows
                                           ├→ Manual Codex Task Queue
                                           └→ 显式配置的本地知识目录
```

## 当前真实状态

- 手机源码：V1.0 功能、Brain 本地检索页与 API 26 Skill PoC 已实现，并已由官方 API 26 Hvigor 真实编译，因此 `SOURCE READY`。
- Bridge：V0.1 可编译、可启动，9 项测试与真实协议探测通过。
- 同步：phone mock 的创建、显式 upsert 编辑、幂等重试、检索、任务状态刷新闭环通过；真机网络路径待 HAP 验证。
- HAP / Preview / 真机：已生成 unsigned debug HAP；未配置 signingConfig，且 HDC 无连接设备，因此 Preview、安装与真机验证尚未成功。
- `D:\AI_Knowledge`：本轮未读取、未修改；知识适配器只在系统 TEMP 假知识库测试。

完整状态见 `STATUS.md` 与 `THE_ONE_OVERNIGHT_FINAL_REPORT.md`。

## 手机端 V1.0

- Dashboard：品牌、欢迎语、Quick Capture、Inbox/Task 待处理计数、主入口与离线提示。
- Capture：`idea / note / material / task`、标签、长文本、非空校验、本地优先保存。
- Inbox：列表、搜索、全部/待处理/已处理筛选、详情、编辑、状态切换、删除确认。
- Task Queue：创建、搜索、详情、编辑、删除、`pending / sent / done / failed`、手动重试同步。
- Brain：经 Bridge 搜索真实 Inbox、Task 与显式配置的 fixture 知识目录；离线或无结果均明确提示。
- Settings：Bridge 地址/端口/Token、测试连接、自动同步、立即同步、设备名、数据统计、限定测试数据清理二次确认。
- 数据层：Preferences + Repository；schema v2 迁移、坏 JSON 保留备份、坏记录隔离、`local / pending / synced / failed` 同步状态。
- 网络：Network Kit、5 秒连接/读取超时、离线不崩溃、ID 幂等。

Preferences 仍适合当前小规模数据。所有读写封装在 Repository 内，未来数据增长后可迁移 RDB，不需要重写页面。

## Bridge V0.1

Node.js + TypeScript、无运行时第三方依赖，提供：

- `GET /health`
- `GET /api/version`
- `POST /api/inbox`、`GET /api/inbox`
- `POST /api/tasks`、`GET /api/tasks`、`GET /api/tasks/:id`
- `PATCH /api/tasks/:id`
- `POST /api/search`

`bridge/protocol.json` 是机器可读协议，`bridge/API.md` 是人工说明。Inbox 与 Task 编辑使用显式 `upsert: true`，避免把编辑同步成重复记录；不带 upsert 的冲突仍返回 409。

Bridge 默认只监听 `127.0.0.1`。监听局域网地址时必须提供至少 24 字符的会话 Token；不会自动公网穿透、改防火墙或改路由器。Codex 集成是明确的 `ManualCodexAdapter`，不会假装存在公开 Codex 任务 API。知识搜索明确返回 `bridge_local_index` 和 `obsidianConnected: false`。

## 一键命令

```powershell
cd 'C:\Users\The One\Documents\Codex\2026-09-01\the-one-mobile'

.\tools\preflight.ps1
.\tools\test.ps1
.\tools\lint.ps1
.\tools\build.ps1
.\tools\start-bridge.ps1
.\tools\check-bridge.ps1
```

局域网模式示例（Token 只存在当前进程，不写入 Git）：

```powershell
$pairingToken = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
.\tools\start-bridge.ps1 -HostAddress '0.0.0.0' -Port 4317 -Token $pairingToken
```

在手机 Settings 中填写电脑局域网 IPv4、端口和同一个 Token。只在可信局域网使用；不要开放公网端口。

## 工程结构

```text
entry/src/main/ets/       ArkTS 手机端
  model/                  数据与同步状态
  pages/                  Dashboard/Capture/Inbox/Task/Brain/Settings
  repository/             数据访问、迁移后 CRUD
  services/               业务、BridgeClient、SyncService
  storage/                Preferences 与 StorageMigration
bridge/                   Windows 本地 Bridge、适配器与 Node 测试
entry/skills/             API 26 应用 Skill PoC
tests/                    手机端主机契约测试
tools/                    preflight/lint/build/test/start/check/dev
```

## 官方工具链

使用华为官方 **HarmonyOS Command Line Tools 26.0.0 Release（Windows）**；其内含 HarmonyOS SDK、hvigorw、ohpm、codelinter 等。本机已在 `C:\HOS\command-line-tools` 实测 API 26、OHPM、Hvigor、HDC 与 Code Linter，当前状态为 `TOOLCHAIN READY`。

- Command Line Tools 文档：https://developer.huawei.com/consumer/cn/doc/doccenter-deveco-studio/ide-commandline-get
- 官方下载入口：https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos
- DevEco Studio：https://developer.huawei.com/consumer/cn/deveco-studio/
- Share Kit 接收：https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/share-interface-description

脚本会优先自动发现 `C:\HOS\command-line-tools`。`tools/preflight.ps1` 已输出 `PREFLIGHT_READY`，`tools/build.ps1` 已输出 `HAP_BUILD_OK` 并生成真实 `.hap`。真机运行必须使用合法签名 HAP：本机官方 DevEco CLI 支持 `devecocli signature generate`，但当前未登录华为开发者账号；详情见 `DEVICE_DEPLOYMENT_REPORT.md`。

## 隐私与边界

- `.env`、Bridge 数据、证书、HAP、密钥均已忽略。
- 不记录 IMEI、完整序列号、账号、密码或真实 Token。
- 手机删除记录和清理明确测试数据都需要确认。
- Bridge 的知识根目录必须显式配置且强制限制路径；开发测试不指向真实知识库。
- API 26 Skill PoC 已作为薄适配器接入现有 Service：`save_to_brain` 只写本地 Inbox，`create_codex_task` 只进入 Manual Queue；未声称已打包、注册或真机运行。
- 分享接收和服务卡片仍未并入未经官方编译验证的主链路，具体原因见最终报告。
