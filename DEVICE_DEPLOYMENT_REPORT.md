# The One Mobile Device Deployment Report

更新时间：2026-09-03

## 2026-09-03 final deployment attempt (takes precedence over older sections)

## 2026-09-03 true-device UI render fix (takes precedence over older sections)

### ROOT CAUSE / FIX

- 原入口中 `Navigation(this.pathStack)` 在该 API 26 真机上产生空内容节点；不是 Index 生命周期、资源、颜色或基础 ArkUI 渲染失败。
- 已将入口改为全尺寸 `Column` 容器承载正式 `DashboardPage`，并保留 API 26 当前签名配置。

### DEVICE UI RESULT

- 真机截图和官方 UI tree 实测显示 THE ONE、Quick Capture、Inbox、Codex、Settings 及正式 Dashboard 卡片。
- 状态：`DASHBOARD RENDER PASS`。

### NAVIGATION / PERSISTENCE

- Navigation 容器在真机仍无可验证内容；因此 Quick Capture、Inbox、Codex Tasks、Settings 点击、数据创建和持久化未声明通过。
- 状态：`NAVIGATION AND PAGE FLOWS DEFERRED`。

### SIGNING

- AppGallery Connect 登记完成后，官方 DevEco CLI 自动签名命令成功完成，并将本机签名配置写入项目的本地 `build-profile.json5`。
- Hvigor `SignHap` 已真实完成，生成 `entry-default-signed.hap`；其大小为 520,115 bytes，SHA-256 为 `23AC222FEA2FADDD92CFB762C67921EFACA35A1751237F9E4E029F18A9585A82`。
- 状态：`SIGNING READY / HAP SIGNED DEBUG GENERATED`。

### DEVICE / INSTALL

- 真实 HDC 仍检测到一个已授权 USB 目标；标识已脱敏且未记录。
- 对 signed debug HAP 执行官方 HDC 安装，返回 `install bundle successfully`。
- 状态：`DEVICE CONNECTED / INSTALL SUCCESS`。

### LAUNCH / SMOKE TEST

- 官方 HDC 启动入口 Ability 返回成功；进程持续运行，设备端日志确认 `Index loaded`。
- 随后的 DevEco CLI 界面树没有可操作节点，设备截图未出现可见 Dashboard 内容。故无法可靠点击 Quick Capture、Inbox、Inbox Detail、pending/processed、Codex Tasks 或 Settings。
- 状态：`LAUNCH PARTIAL / SMOKE TEST NOT PASS`。

### BRIDGE DEVICE TEST

- 为保护已签名、已安装的主应用基线，未在界面未渲染时修改手机 Bridge 设置或进行网络写入。
- 状态：`DEFERRED (main UI render blocker)`。

### FINAL BLOCKER

1. 真机 ArkUI 页面可见性：入口脚本已加载，但 Dashboard 在该设备上没有渲染可验证内容。修复并复测该问题后，才能声明 UI 冒烟与 Bridge 真机联调通过。

## SIGNING

- 当前产物：`entry-default-unsigned.hap`，471,467 bytes，SHA-256 `6C9E80ACC93D9E0FB452F85679F48549F6A1E103F995077A359BA039B0C8697F`。
- 项目 `build-profile.json5` 的 `signingConfigs` 为空；Hvigor 已明确提示没有 `signingConfig`。
- 本机项目和标准 HarmonyOS 本地配置目录未发现 `.p12`、`.cer` 或 `.p7b` 签名材料。
- 官方 Command Line Tools SDK 含 `hap-sign-tool.jar`、`binary-sign-tool.jar` 和打包工具；不会用它们伪造证书或绕过 Profile。
- 官方 DevEco CLI 提供 `devecocli signature generate`，可自动生成签名材料并写入项目配置。华为账号登录已完成；在仅对该子进程清空代理变量的直连环境中，`devecocli auth status` 实测返回已登录用户（已脱敏）。普通代理环境会误报未登录，不改变系统代理或 TLS 设置。
- DevEco Studio 已实装于 `C:\Program Files\Huawei\DevEco Studio`，preflight 已确认可识别。安装器 Windows Authenticode 签名为 Huawei Technologies Co., Ltd.，状态 `Valid`；安装器 SHA-256 为 `DFA06146C7FC4DEE61D7BA6565B25E0F85420E0C7B715C35230AC2B4C6B2A88B`。
- 已实际执行 `devecocli signature generate --product default`。CLI 返回：缺少设备，无法创建 Profile；因此没有生成签名材料，也没有修改工程签名配置。
- DevEco CLI 本地实现会将 global-agent 配置为读取标准 `HTTP_PROXY`、`HTTPS_PROXY`、`NO_PROXY`。当前环境把代理指向 loopback。首次仅补全 IPv6 bypass 后，真实登录仍收到华为域名证书却校验 localhost，证明回调仍被本地代理拦截。`tools/deveco-auth-login.ps1` 现仅在登录子进程清空 HTTP/HTTPS/ALL proxy 变量并补全 loopback bypass；在相同临时直连环境下已验证华为官方站点 HTTP 200。
- 完整 DevEco Studio 是自动签名的硬要求：CLI 本地实现对 Command Line Tools 模式的签名操作执行 `assertStudio()`。Command Line Tools 能构建 HAP，但不能单独完成自动签名。

## DEVICE

- 官方 HDC 3.2.0e 已用真实命令检查：USB 目标已列出且不再处于 `Unauthorized` 状态。
- 无副作用 shell 查询和官方 `bm get -u` 命令均执行成功；设备标识、IMEI、序列号与 UDID 均未记录。
- `devecocli device list` 已将该目标识别为 phone。
- 状态：`DEVICE CONNECTED / DEBUG AUTHORIZED`。

## INSTALL

- 未执行安装：当前 HAP 未签名，且不存在已授权目标设备。
- 状态：`BLOCKED BY USER ACTION`。

## LAUNCH

- 未执行：前置安装条件未满足。
- 状态：`NOT VERIFIED`。

## SMOKE TEST

- Dashboard、Quick Capture、Inbox、Inbox Detail、状态切换、Codex Tasks、Settings 和 Bridge Health 均未在真机上声明通过。
- 状态：`NOT VERIFIED`。

## BRIDGE DEVICE TEST

- Bridge 的主机端与 phone-mock 集成测试为 9/9 通过；真机局域网路径未执行。
- 状态：`NOT VERIFIED`。

## FINAL BLOCKERS

1. 在 AppGallery Connect 的调试设备管理中登记当前 Mate 70 Pro。官方 CLI 已识别本机设备且已读取其调试 UDID，但后台 Profile 创建两次返回 `missing devices`；不通过手工伪造 Profile 或证书绕过此限制。
2. 后台设备登记完成后重新运行官方 `devecocli signature generate --product default`，由 CLI 自动写入调试签名材料和工程配置。

不需要向本项目或聊天提供账号密码、验证码、证书私钥或完整设备序列号。
