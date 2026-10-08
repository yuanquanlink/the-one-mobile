# The One Mobile Handoff

更新时间：2026-09-03（API 26 构建闭环）

## 一句话状态

主工程已扩展为 Mobile V1.0 + Brain + Bridge V0.1 + API 26 Skill PoC；`C:\HOS\command-line-tools` 已实测可用，并已完成真实 API 26 ArkTS 编译、debug HAP 打包和 17/17 测试。当前 HAP 是 unsigned，HDC 无目标，故安装与真机 UI 验证尚未开始。

## 2026-09-03 signed-device deployment update（优先于旧记录）

- AppGallery Connect 调试设备登记后，官方 DevEco CLI 自动签名完成；不要替换或提交它写入的本地签名配置与材料。
- Hvigor `SignHap` 完成，当前可部署产物为 `entry\build\default\outputs\default\entry-default-signed.hap`，520,115 bytes，SHA-256 `23AC222FEA2FADDD92CFB762C67921EFACA35A1751237F9E4E029F18A9585A82`。
- 真实 HDC 已检测到并向 Mate 70 Pro 成功安装该 HAP；入口 Ability 启动成功，进程仍在运行，日志有 `Index loaded`。
- 当前不可跳过的运行时问题：Dashboard 在真机截图中不可见，DevEco CLI UI 树也没有可操作节点。不要把 UI smoke、Bridge device test 或应用可用性标为通过。
- 回归基线仍健康：签名和安装后 `tools/test.ps1` 为 17/17 PASS。Bridge 真机联调在页面可见性修复前保持 deferred，避免改变设备端设置。

## 2026-09-03 true-device UI render update（优先于旧记录）

- Mate 70 Pro 已真实显示正式 Dashboard；截图与官方 UI tree 均确认 THE ONE、Quick Capture、Inbox、Codex、Settings 和 Dashboard 内容可见。
- 根因是 API 26 真机上的空 `Navigation` 内容节点，而非 Index 生命周期、`main_pages.json`、资源、主题或窗口尺寸。
- 当前稳定设备基线为全尺寸 `Column` 直接承载 `DashboardPage`。不要把尚未验证的 Navigation 版本重新作为入口。
- Navigation、Quick Capture、Inbox、Codex Tasks、Settings 交互和本地持久化尚未通过真机验收；保持 `DEFERRED`。最新详情见 `TRUE_DEVICE_UI_REPORT.md`。

## 2026-09-03 设备与签名更新（优先于旧记录）

- DevEco Studio 已安装在 `C:\Program Files\Huawei\DevEco Studio`；官方签名命令与登录均可用。
- Mate 70 Pro 已通过 USB/HDC 连接并完成本机调试授权。HDC shell 和 `bm get -u` 成功，DevEco CLI 也列出该设备；不记录设备标识或 UDID。
- 官方 `devecocli signature generate --product default` 分别以默认和唯一团队上下文执行，均在华为后台调试 Profile 创建阶段返回 `missing devices`。无证书、Profile、私钥或 `build-profile.json5` 签名改动产生。
- 唯一剩余人工前置：在 AppGallery Connect 调试设备管理中登记该已连接设备。完成后依次为自动签名 → signed HAP → 安装 → 启动 → 真机冒烟与 Bridge 联调。

## 最新构建证据（本节优先于下方历史记录）

- 工具链：API 26 SDK、OHPM 26.0.0.410、Hvigor 6.26.1、HDC 3.2.0e、Code Linter 6.0.240 均来自 `C:\HOS\command-line-tools`。
- 构建：`tools/build.ps1 -CommandLineRoot 'C:\HOS\command-line-tools'` 输出 `BUILD SUCCESSFUL` 与 `HAP_BUILD_OK`。
- HAP：`entry-default-unsigned.hap`，471,467 bytes，SHA-256 为 `6C9E80ACC93D9E0FB452F85679F48549F6A1E103F995077A359BA039B0C8697F`。
- 首个真实 schema 错误是 `skillProfiles[0].version` 不被 API 26 接受；已移除该字段并重建成功。
- OHPM 官方 registry 对插件元数据两次返回 502；构建脚本只在该恢复失败时链接同版本官方 Command Line Tools 内置插件，随后构建成功。
- `tools/test.ps1`：移动端 8/8、Bridge 9/9，合计 17/17 通过。
- Code Linter 实测 0 errors、47 warnings、1 suggestion；其当前版本以 warnings 返回 exit 1，未将 warning 宣称为 lint 通过。
- `hdc list targets`：`[Empty]`，无设备；HAP 无 signingConfig，因此没有执行安装、启动或真机冒烟。

## 最新部署调查（本节优先于下方历史记录）

- 官方签名方式：优先使用 DevEco Studio/DevEco CLI 自动调试签名；手动方式需要调试证书、调试设备注册和 debug Profile，不能由项目伪造。
- 现有官方 DevEco CLI 的 `signature generate` 会自动生成材料并写回工程，但 `auth status` 实测 `Not logged in`。
- 项目与本机标准配置目录未发现 `.p12`、`.cer`、`.p7b`；未手工添加空 `signingConfig`，以免破坏成功构建。
- 当前唯一阻塞：`BLOCKED BY USER ACTION`，执行 `devecocli auth login` 完成华为开发者登录/授权后，再运行 `devecocli signature generate --product default`。
- 真实 HDC 目标枚举为 `[Empty]`；签名成功后还需连接、解锁 Mate 70 Pro 并确认调试授权。

## 已完成

- 完整审计原有 30 个 ArkTS 文件、配置、资源、脚本和文档；当前为 36 个 ArkTS 文件。
- Mobile：Inbox 搜索/筛选/编辑/删除；Task Queue 搜索/详情/编辑/删除/四态/重试；Settings Bridge 配置、连接测试、同步、统计与限定测试数据清理。
- 数据：schema v2、旧字段迁移、坏 JSON 可恢复备份、坏记录跳过、upsert、同步队列状态。
- Bridge：本地 JSON、损坏恢复、幂等 ID、显式 upsert、shared secret、请求限制、任务状态、真实 Inbox/Task/fixture 搜索、Manual Codex Adapter。
- API：health/version/inbox/tasks/task detail/task patch/search。
- Brain：Bridge 本地检索 UI、离线反馈、真实结果解析；Task 详情支持刷新远端状态。
- Skill PoC：API 26 `skillProfiles` + `SKILL.md` + ArkTS 脚本，两个入口均复用现有服务且明确本地边界。
- 自动化：8 项移动端契约测试 + 9 项 Bridge/phone mock 测试全部通过。
- 一键脚本：preflight/lint/build/test/start-bridge/check-bridge/dev。
- 实际启动 Bridge，并从另一个进程请求 `/health` 成功。
- 本地 Git 小提交已完成；没有 push、没有新建远端。

## 历史工具链调查结论（已被最新构建证据取代）

- 已有官方 DevEco CLI 1.3.0-stable；Node 24.18.0、npm 12.0.2、Java 26、Git 2.54.0 可用。
- 在用户指定的 Downloads、Desktop、Documents、AppData、Tools、HarmonyOS 与 Program Files 范围内，仅按目录名/工具文件名搜索；仍未发现 DevEco Studio、官方 Command Line Tools、API 26 SDK、OHPM、Hvigor、HDC、codelinter、hstack。
- `devecocli` 1.3.0-stable 存在于 `C:\Users\The One\AppData\Roaming\npm`，但 `ohpm`、`hvigorw`、`hdc`、`codelinter` 均不存在；说明只安装了 DevEco CLI，而没有 HarmonyOS Command Line Tools/SDK。
- 官方 Command Line Tools 文档确认 SDK 已内嵌，命令行路线可行。
- 官方下载应用的服务调用先检查华为账号登录，并可能要求协议/实名状态。未绕过登录、协议或身份校验。
- 当前官方下载中心显示 `Command Line Tools 26.0.0 Release`；此前未登录请求返回 `X-HD-CSRF` 缺失，但本轮阻塞的直接原因是本机安装结果未检测到。
- `winget` 的 DevEco 3.1.0.501 过旧，不适合 API 26，未安装。

## 历史构建与测试证据（已被最新构建证据取代）

- `tools/preflight.ps1`：本轮重新运行，结论 `PREFLIGHT_BLOCKED`，所有 HarmonyOS 构建、设备和 lint 工具均缺失。
- `devecocli check lint`：运行，返回 `DevEco Studio installation not found in default locations.`；未进入 ArkTS lint。
- `tools/build.ps1`：运行；`PROJECT_VALIDATION_OK` 后因工具链缺失 fail-fast。
- `tools/test.ps1`：本轮重新运行；17/17 测试通过。
- `tools/lint.ps1`：本轮重新运行；已找到官方配置，因 `codelinter` 不存在而 fail-fast。
- Bridge 启动：`THE_ONE_BRIDGE_READY http://127.0.0.1:4319`。
- 协议探测：`BRIDGE_HEALTH_PASS the-one-mobile-bridge protocol=1.0.0`。
- HAP、Preview、签名、设备连接、安装：均无成功证据。

## 关键架构决定

1. Local-first：先落本地，再按设置同步；失败记录为 `failed`，不丢手机数据。
2. 以客户端 ID 做幂等；相同负载重试返回 existing，冲突负载返回 409。
3. Bridge 默认 loopback；非 loopback 没有 24 字符 Token 就拒绝启动。
4. 不伪造 Codex API；当前任务只入 Manual Queue。
5. 不伪造 Obsidian：`POST /api/search` 明示本地索引能力和 `obsidianConnected:false`。
6. Skill 仅做官方 API 26 文档支持的最小 PoC，并保持为现有服务的薄适配器；打包与运行状态仍为 BLOCKED。
7. 不在无法编译时把 Share receiver、服务卡片冒险塞进主 Build。

## 首次工具链解锁后的顺序

1. 运行 `tools/preflight.ps1`，确认 API 26、OHPM、Hvigor、HDC、codelinter 路径。
2. 运行 `tools/lint.ps1`，修复官方 Code Linter 的真实结果。
3. 用工具链自带官方 API 26 Empty Ability/Skill 模板对比 `modelVersion`、Hvigor 插件和配置；只做必要机械对齐。
4. 运行 `tools/build.ps1`，按 `BUILD_ERRORS.md` 记录真实 ArkTS 根错误并循环修复。
5. 编译成功后才接入官方 Share Kit receiver；再单独建立服务卡片验证分支。
6. 用户本人配置调试签名、连接 Mate 70 Pro 并授权，再做安装、冷启动、持久化和 UI 回归。

当前应先定位已解压工具的实际完整目录；无需再次重做代码审计或下载来源调查。

## 常用命令

```powershell
cd 'C:\Users\The One\Documents\Codex\2026-09-01\the-one-mobile'
.\tools\preflight.ps1
.\tools\test.ps1
.\tools\lint.ps1
.\tools\build.ps1
.\tools\start-bridge.ps1
.\tools\check-bridge.ps1
```

先看 `START_HERE_TOMORROW.md`，详细证据看 `THE_ONE_OVERNIGHT_FINAL_REPORT.md`。
