# Build Artifacts

更新时间：2026-09-03

## HarmonyOS HAP

### Signed debug HAP (latest)

#### UI-render fix rebuild

- 状态：`SIGNED DEBUG GENERATED / INSTALLED`
- HAP 路径：`C:\Users\The One\Documents\Codex\2026-09-01\the-one-mobile\entry\build\default\outputs\default\entry-default-signed.hap`
- 大小：233,443 bytes
- 修改时间（UTC）：2026-09-03T14:15:26.1772238Z
- SHA-256：`D9115500FCB86F63358DF1521B4B41E37108A3A4A917222ADB8483CC5C04C6EF`
- 真机结果：该 HAP 已由 HDC 安装并启动；Dashboard 画面已确认可见。

- 状态：`SIGNED DEBUG GENERATED`
- 官方签名方式：已登录的 DevEco CLI 自动调试签名；Hvigor 输出 `SignHap` 完成。
- HAP 路径：`C:\Users\The One\Documents\Codex\2026-09-01\the-one-mobile\entry\build\default\outputs\default\entry-default-signed.hap`
- 大小：520,115 bytes
- 修改时间（UTC）：2026-09-03T13:50:07.3603726Z
- SHA-256：`23AC222FEA2FADDD92CFB762C67921EFACA35A1751237F9E4E029F18A9585A82`
- 安装证据：真实 HDC 安装返回 `install bundle successfully`。

签名材料、团队标识及密码保持本地私有，未登记到 Git 或本文档。

- 状态：`GENERATED`
- 已执行：`tools/build.ps1 -CommandLineRoot 'C:\HOS\command-line-tools'`。
- 实际结果：Hvigor 6.26.1 完成 API 26 ArkTS 编译与 `assembleHap`，输出 `HAP_BUILD_OK`。
- HAP 路径：`C:\Users\The One\Documents\Codex\2026-09-01\the-one-mobile\entry\build\default\outputs\default\entry-default-unsigned.hap`
- 大小：471,467 bytes
- 构建时间：2026-09-03T16:43:56.6226734+08:00
- debug / release：debug
- 签名状态：unsigned（Hvigor 提示未配置 signingConfig）
- SHA-256：`6C9E80ACC93D9E0FB452F85679F48549F6A1E103F995077A359BA039B0C8697F`

该产物已真实生成，但必须配置调试签名后才可作为可安装 HAP 使用。

签名部署现状详见 `DEVICE_DEPLOYMENT_REPORT.md`：官方 CLI 当前未登录，尚未获得合法 debug 签名材料；没有设备连接，未执行安装。

## Bridge

- TypeScript 编译：成功
- 启动命令：`tools/start-bridge.ps1`
- 实测地址：`http://127.0.0.1:4319`（临时验证端口）
- 实测响应：`tools/check-bridge.ps1` 输出 `BRIDGE_HEALTH_PASS the-one-mobile-bridge protocol=1.0.0`
- Bridge 不是 HAP，不可安装到手机。
