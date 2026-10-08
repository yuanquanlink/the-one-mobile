# The One Mobile Status

更新时间：2026-09-03

```text
PROJECT
The One Mobile

TARGET
HarmonyOS 7 / API 26

TOOLCHAIN
READY: C:\HOS\command-line-tools

DEVECO STUDIO
READY: C:\Program Files\Huawei\DevEco Studio (6.1.1.300 installer series)

DEVECO CLI AUTH
READY: verified only in the scoped direct-connection process

SOURCE
READY: API 26 ArkTS COMPILED

MOBILE BUILD
SUCCESS: DEBUG assembleHap

HAP
SIGNED DEBUG GENERATED: entry-default-signed.hap

MOBILE TESTS
PASS

BRIDGE
READY

BRIDGE TESTS
PASS

SYNC
PASS

SHARE
PARTIAL

SERVICE CARD
BLOCKED

SKILL
POC COMPILED / RUNTIME NOT VERIFIED

PREVIEW
BLOCKED

DEVICE
CONNECTED: Mate 70 Pro via USB / HDC (device identifier withheld)

INSTALL
SUCCESS

NEXT BLOCKER
DASHBOARD RENDER PASS: physical-device screenshot and DevEco UI tree confirm the visible dashboard. NAVIGATION / PAGE ACTIONS remain deferred because the API 26 Navigation root path renders an empty content area on this device.
```

## 证据口径

- `SOURCE READY`：`C:\HOS\command-line-tools` 的 API 26 SDK 与 Hvigor 6.26.1 已完成真实 ArkTS 编译和 `assembleHap`。
- `MOBILE TESTS PASS`：8 项主机侧源码/协议契约测试通过；不代表 ArkTS 运行时或真机 UI 已通过。
- `BRIDGE READY / TESTS PASS`：TypeScript 编译通过，9 项 Node 测试通过；一键启动后真实协议探测成功。
- `SYNC PASS`：phone mock → Bridge → 创建/upsert/检索/状态更新的主机集成闭环通过；手机网络运行时仍待 HAP/真机验证。
- `SHARE PARTIAL`：官方 Share Kit 接收方案已核实，但因无 API 26 编译器未把不可编译验证的接收入口并入主分支。
- 服务卡片、Preview、设备、签名、安装均没有成功证据。
- `SKILL POC COMPILED / RUNTIME NOT VERIFIED`：Skill 配置与 ArkTS 薄适配脚本已经过官方 API 26 编译和 HAP 打包；平台注册与真机调用未验证。
- `TOOLCHAIN READY`：`C:\HOS\command-line-tools` 实测包含 API 26 SDK、OHPM 26.0.0.410、Hvigor 6.26.1、HDC 3.2.0e、Code Linter 6.0.240 与 bundled Node 24.14.1。
- `DEVECO CLI AUTH READY`：在仅对该子进程清空代理变量的直连环境中，`devecocli auth status` 实测返回已登录用户（已脱敏）。常规代理环境下的 `auth status` 会误报未登录，因此后续 DevEco CLI 登录/签名命令必须沿用该受限直连环境；系统代理和 TLS 设置未改动。
- `DEVICE CONNECTED`：真实 HDC 3.2.0e 已列出 USB 目标；无副作用 shell 查询和 `bm get -u` 均成功。设备标识与 UDID 未写入文档或聊天。
- `LOGIN PROXY MITIGATION READY`：WinHTTP 为直连，npm/Git 未配置代理；DevEco CLI 使用标准代理环境变量。仅登录进程脚本已补全 `[::1]` 的 bypass，未修改系统代理或 TLS 安全配置。
- `DEVECOSTUDIO READY FOR AUTO SIGNING`：DevEco Studio 已安装于 `C:\Program Files\Huawei\DevEco Studio`，并被 preflight 和 DevEco CLI 识别。安装器的 Authenticode 签名已验证为 Huawei Technologies Co., Ltd.；本地 SHA-256 已记录。
- `SIGNING BLOCKED BY DEVICE`：受限直连环境中的 `devecocli auth status` 已返回已登录用户；执行 `devecocli signature generate --product default` 后，华为官方 CLI 返回“Unable to create the profile file due to missing devices”。未生成证书、Profile 或私钥，也未更改 `build-profile.json5`。
- `CLI DEVICE DETECTION READY`：`devecocli device list` 已列出 Mate 70 Pro（状态 `device`，类型 `phone`）。以账户默认 ID 和唯一开发团队 ID 各执行一次官方 `signature generate`，均在华为后台 Profile 创建阶段报告 `missing devices`；这不是 USB、HDC 或本地调试授权问题。
- `PREFLIGHT READY AFTER IDE INSTALL`：自动发现现在优先使用已验证的 `C:\HOS\command-line-tools` API 26 SDK、OHPM 和 Hvigor，不会被 Studio 自带的不同版本工具覆盖。
- `SIGNING READY / HAP SIGNED DEBUG GENERATED`：AppGallery Connect 设备登记后，官方 `devecocli signature generate --product default --team-id <redacted>` 已成功完成；Hvigor 的 `SignHap` 任务完成，并输出 `entry-default-signed.hap`。签名材料、团队标识和密码未写入本文档。
- `INSTALL SUCCESS`：真实 HDC 对已授权 Mate 70 Pro 安装 signed debug HAP 返回 `install bundle successfully`。设备标识未记录。
- `LAUNCH PARTIAL`：HDC 启动入口 Ability 返回成功，设备进程持续运行，应用日志确认 `Index loaded`；但 DevEco CLI UI 树没有可操作节点且截图未显示 Dashboard 内容。因此不声明 `LAUNCH SUCCESS` 或 `SMOKE TEST PASS`。
- `TESTS PASS 17/17 (POST-SIGNING)`：本轮签名构建和安装后重新执行 `tools/test.ps1`，移动端 8/8、Bridge/Sync 9/9 均通过。
- `DASHBOARD RENDER PASS`：以直接全尺寸 `Column` 承载 `DashboardPage` 的入口已在 Mate 70 Pro 截图中真实显示 THE ONE、Quick Capture、Inbox、Codex 与 Settings；官方 UI tree 也确认根 Column、Scroll、TextArea 与卡片的有效尺寸。
- `NAVIGATION DEFERRED`：将 API 26 `Navigation(this.pathStack)` 作为首页内容时，真机 UI tree 只保留空 Navigation 节点；目前保留已验证的直接 Dashboard 根，不宣称页面跳转、Inbox 详情、Codex Task 或 Settings 真机交互通过。
