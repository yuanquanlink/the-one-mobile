# Changelog

## 1.1.6-signed-device-deployment - 2026-09-03

### Verified

- After AppGallery Connect device registration, official DevEco CLI automatic debug signing completed and Hvigor completed `SignHap`.
- Generated and recorded the signed debug HAP: 520,115 bytes; SHA-256 `23AC222FEA2FADDD92CFB762C67921EFACA35A1751237F9E4E029F18A9585A82`.
- Real HDC detected the authorized USB target and installed the signed HAP successfully.
- HDC started the entry Ability; the process remained alive and logged `Index loaded`.
- Post-signing `tools/test.ps1` remained 17/17 passing.

### Not passed

- The physical device did not expose visible Dashboard nodes after launch. UI smoke and Bridge device testing are not claimed and remain deferred pending that render issue.

## 1.1.5-deployment-signing-investigation - 2026-09-03

### Verified

- 现有 HAP 为 unsigned debug HAP；项目和本机标准配置目录不存在调试签名材料。
- 官方 SDK 含 HAP 签名与打包工具；官方 DevEco CLI 的 `signature generate` 支持自动生成签名材料并写入工程配置。
- `devecocli auth status` 为 `Not logged in`，真实 `hdc list targets` 为 `[Empty]`；没有安装、启动或真机测试结果。

### Blocked by user action

- 必须先完成 `devecocli auth login` 的华为开发者账号登录/授权，才能由官方 CLI 生成合法调试签名；然后连接并授权 Mate 70 Pro。

## 1.1.4-api26-build-closure - 2026-09-03

### Fixed

- `tools/preflight.ps1` now prioritizes and detects `C:\HOS\command-line-tools`, including its SDK, OHPM, Hvigor, HDC, Code Linter and versions.
- `tools/lint.ps1` now uses the current Code Linter positional source-directory syntax.
- `tools/build.ps1` accepts a Command Line Tools root and uses the matching official bundled Hvigor plugin only when the OHPM registry restore fails.
- Removed the API 26-incompatible `skillProfiles[].version` field from `module.json5`.

### Verified

- Preflight: API 26 SDK, OHPM 26.0.0.410, Hvigor 6.26.1, HDC 3.2.0e and Code Linter 6.0.240 are usable from `C:\HOS\command-line-tools`.
- Hvigor `assembleHap`: `BUILD SUCCESSFUL`; generated `entry-default-unsigned.hap` (471,467 bytes, SHA-256 `6C9E80ACC93D9E0FB452F85679F48549F6A1E103F995077A359BA039B0C8697F`).
- `tools/test.ps1`: 17/17 passed.
- `hdc list targets`: empty; no install or device smoke result is claimed. Code Linter reports 0 errors, 47 warnings and 1 suggestion.

## 1.1.3-toolchain-location-audit - 2026-09-03

### Verified

- Bounded filename/directory search found no official HarmonyOS Command Line Tools, API 26 SDK, OHPM, Hvigor, HDC or codelinter.
- `devecocli` 1.3.0-stable is installed, but it is not a replacement for the official HarmonyOS Command Line Tools/SDK.

## 1.1.2-build-closure-recheck - 2026-09-02

### Verified

- After user-confirmed Huawei authorization, preflight still detected no Command Line Tools, API 26 SDK, OHPM, Hvigor, HDC or codelinter on this computer.
- `tools/lint.ps1` and `tools/build.ps1` re-ran and stopped at the toolchain gate; no ArkTS compiler error, HAP or device result was fabricated.
- `tools/test.ps1` re-ran successfully: 17/17 PASS.

## 1.1.1-toolchain-closure - 2026-09-02

### Verified

- 官方下载中心确认 `Command Line Tools 26.0.0 Release`；未登录请求返回 `X-HD-CSRF` 缺失，下载受华为账号会话保护。
- `tools/test.ps1`：17/17 PASS；`tools/lint.ps1` 与 `tools/build.ps1` 在缺失官方工具链时明确失败。
- `tools/preflight.ps1` 已支持自动发现 `C:\Users\The One\Tools\HarmonyOS\CommandLineTools` 及其嵌套解压目录。

## 1.1.0-continuation - 2026-09-02

### Added

- Brain 页面与 Bridge 本地检索，真实搜索 Inbox、Task 和显式 fixture 根目录，不伪造 Obsidian 连接。
- 机器可读 `bridge/protocol.json`、人工 API 文档与 `tools/check-bridge.ps1` 协议探测。
- API 26 应用 Skill PoC：`save_to_brain`、`create_codex_task`，复用现有 Service/Repository。
- 官方 `code-linter.json5` 推荐规则集与 fail-fast `tools/lint.ps1`。

### Changed

- Inbox/Task 同步支持显式 upsert 编辑；Task 详情可刷新 Bridge 远端状态。
- ArkTS 静态门禁增加正则字面量、内联 JSON 对象、构造器参数属性和 `any/unknown` 检查。
- Dashboard Brain 入口改为明确的 Bridge 本地检索文案。

### Verified

- `tools/test.ps1`：17/17 PASS（移动端契约 8，Bridge 9）。
- Bridge 真实启动后 `tools/check-bridge.ps1` 输出 `BRIDGE_HEALTH_PASS`，协议 `1.0.0`。
- `tools/lint.ps1` 与 `tools/build.ps1` 均已执行；因官方 Command Line Tools/API 26 SDK 缺失而按预期阻塞，未伪造 lint、HAP 或运行时结论。

## 1.0.0-overnight - 2026-09-02

### Added

- Mobile V1.0：Inbox 搜索/筛选/编辑，Task Queue 详情/编辑/删除/失败/重试，Settings Bridge 配置与数据统计。
- schema v2 数据迁移、坏数据保留、同步状态与离线恢复。
- The One Bridge V0.1：安全监听、鉴权、JSON 持久化、幂等 API、任务状态、fixture 知识搜索和 Manual Codex Adapter。
- 4 项移动端主机契约测试、7 项 Bridge/phone mock 集成测试。
- `tools/test.ps1`、`tools/start-bridge.ps1`、`tools/dev.ps1`、构建错误与产物登记文档。

### Changed

- preflight 同时支持官方 Command Line Tools 路线，并检查 codelinter、hstack、npm、Git。
- build 的解锁说明优先指向内嵌 SDK 的官方 Command Line Tools。
- README、HANDOFF、STATUS 和用户动作按证据重新整理。

### Verified

- `tools/test.ps1`：11/11 PASS。
- Bridge TypeScript build 成功；真实启动和 `/health` HTTP 200 成功。
- `tools/build.ps1` 已运行但在工具链预检处阻塞；未生成 HAP，源码仍为 `NOT READY`。

## 0.1.0-round2 - 2026-09-02

### Added

- `tools/preflight.ps1`：自动诊断 DevEco Studio、API 26 SDK、OHPM、Hvigor、HDC、设备、Node、Java 与 DevEco CLI。
- `STATUS.md` 与第二轮证据化结果报告。

### Changed

- `tools/build.ps1` 现在先运行静态验收和环境预检，再执行 OHPM 依赖恢复、Hvigor `assembleHap` 和 HAP 产物核对。
- README、HANDOFF、USER_ACTION_REQUIRED 按真实工具链状态更新。

### Verified

- 30 个 ArkTS 源文件及全部工程配置/资源/脚本/文档完成全量审计。
- 自定义静态验收返回 `PROJECT_VALIDATION_OK`。
- 官方 DevEco CLI 1.3.0-stable 已安装；lint/build/device 探测因 DevEco Studio 缺失而明确阻塞。
- 未生成 HAP，未运行 Preview，未完成真机安装。

## 0.1.0 - 2026-09-01

### Added

- HarmonyOS 7 / API 26 ArkTS + ArkUI + Stage Model 原生工程骨架。
- 深色、极简的 The One Dashboard 与首页 Quick Capture。
- Inbox 本地持久化、列表、详情、状态切换和删除确认。
- Codex Tasks 创建、查看、本地持久化和三态管理。
- Preferences、Repository、Service 分层架构。
- `BridgeClient` / `SyncService` 扩展接口和 V0.2 TODO。
- 工程静态验收脚本及 README / HANDOFF / USER_ACTION_REQUIRED 文档。

### Not yet verified

- API 26 Hvigor 编译、Preview 和 Mate 70 Pro 真机安装；当前电脑缺少 DevEco Studio 与 HarmonyOS SDK。
