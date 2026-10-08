# The One Mobile V1 Release Report

更新时间：2026-09-03

## 已验证

- DevEco Studio、DevEco CLI 认证、HarmonyOS API 26 工具链均已真实可用。
- AppGallery Connect 调试设备登记后，官方自动调试签名完成。
- Hvigor `SignHap` 成功生成 signed debug HAP：`entry\\build\\default\\outputs\\default\\entry-default-signed.hap`，520,115 bytes，SHA-256 `23AC222FEA2FADDD92CFB762C67921EFACA35A1751237F9E4E029F18A9585A82`。
- Mate 70 Pro 通过 HDC 已连接、已授权；signed HAP 安装返回成功。
- 入口 Ability 启动返回成功，进程保持运行，设备日志确认 `Index loaded`。
- 构建、签名和安装后，自动测试仍为 17/17 PASS（Mobile 8/8，Bridge/Sync 9/9）。

## 未通过 / 未声明

- 真机 Dashboard 没有在截图或 DevEco CLI 界面树中呈现可交互节点，因此 Quick Capture、Inbox、Inbox Detail、状态切换、Codex Tasks 与 Settings 的真机冒烟均未通过。
- 因主界面可见性未验证，未改写手机 Bridge 设置，也未声明手机到 Bridge 的 health、Inbox 或 Task Queue 联调成功。

## 发布结论

`SOURCE READY`、`BUILD SUCCESS`、`SIGNING READY`、`HAP SIGNED DEBUG GENERATED`、`DEVICE CONNECTED`、`INSTALL SUCCESS` 和 `TESTS PASS` 已有真实证据。

本版本不具备“真机 UI 验收通过”或“Bridge 真机联调通过”的证据。下一项工作应仅定位并修复 API 26 真机页面渲染可见性，再重复部署与冒烟；不要扩展功能范围。

## 真机 UI 修复更新

- Dashboard 可见性已修复：真实 Mate 70 Pro 画面确认正式 Dashboard 可见，新的 signed HAP 已安装。
- 当前入口采用直接 `Column` → `DashboardPage` 根，以规避真机上的空 Navigation 内容。
- 页面导航、Quick Capture、Inbox、Codex Tasks、Settings 与持久化仍未有真机交互证据，不能视为 V1 UI 完整验收。
