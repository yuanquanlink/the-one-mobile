# Build Errors

更新时间：2026-09-03

## 已解决：真机 Dashboard 空白

- 真机日志显示 `Index loaded`，但原始首页将 `Navigation(this.pathStack)` 直接作为入口内容时，官方 UI tree 只显示空 `Navigation` 节点，页面不可见。
- 最小 `Column` + Text/Button 探针已在 Mate 70 Pro 真机显示，排除了 Ability、`main_pages.json`、资源、颜色、窗口尺寸与基础 ArkUI 渲染链路。
- 直接全尺寸 `Column` 承载 `DashboardPage` 后，正式 Dashboard 已在真机截图和 UI tree 中显示。当前采用此已验证根路径。
- 尝试将状态化 `NavPathStack` 注入 `Navigation` 后，设备被系统视觉浮层遮挡，未获得 Navigation 内容可见的证据；因此 Navigation 和下游页面交互保持 deferred。
- 一次中间实验真实编译错误：`@Entry` 的 `build` 根节点不能直接为自定义 `DashboardPage`，必须由容器组件承载；已改为 `Column`，最终构建成功。

## 已解决：真实 API 26 构建错误

- 工具链已在 `C:\HOS\command-line-tools` 完整发现并通过版本探测。
- OHPM 访问官方 registry 两次得到 HTTP 502 / `Fetch Pkg Info Failed`。这不是源码错误；`tools/build.ps1` 仅在恢复失败时使用同版本官方 Command Line Tools 内置 Hvigor 插件，最终 Hvigor 6.26.1 成功完成构建。
- 首次 Hvigor 真实根错误：`module.skillProfiles[0].version` 违反 API 26 schema。编译器允许字段为 `name`、`abilityName`、`srcEntries`、`permissions`。已删除不支持的 `version` 字段。
- 重建结果：`TYPE CHECK SUCCESSFUL`、`BUILD SUCCESSFUL`、`HAP_BUILD_OK`。ArkTS 对异常处理和过时 `AlertDialog` 给出 warnings，但没有 compilation error。
- 尚存构建警告：无 `signingConfig`，因此产物是 unsigned HAP；OHPM registry 仍不稳定。

## 历史记录：工具链缺失阶段（已解决）

`tools/build.ps1` 已真实执行。结构验证返回 `PROJECT_VALIDATION_OK`，随后因以下官方工具缺失而停止：

- HarmonyOS API 26 SDK
- OHPM
- Hvigor / hvigorw
- HDC
- codelinter

项目根目录已有官方格式的 `code-linter.json5`；`tools/lint.ps1` 已执行，实际停止原因是未发现官方 `codelinter`，没有产生代码告警结果。

官方 DevEco CLI `devecocli check lint` 也已执行，实际错误为：

```text
Error: DevEco Studio installation not found in default locations.
```

华为官方 Command Line Tools 下载页可访问，但下载服务要求华为账号登录，并可能要求协议确认或实名认证。无人值守条件下没有绕过，因此没有获得安装包。

2026-09-02 的官方页面显示 `Command Line Tools 26.0.0 Release`。按页面自身请求格式读取下载信息时，官方服务返回：

```text
returnCode: 90910011
description: request header X-HD-CSRF is not exist or null
```

这表明下载地址受登录会话保护；当前根阻塞应标为 `TOOLCHAIN BLOCKED BY USER AUTHORIZATION`，不是未知下载失败。

## 历史记录：安装未检测到（已解决）

用户确认华为授权步骤已完成后，重新执行预检，并只读核对用户 PATH、卸载注册表、常用 Huawei/HarmonyOS/DevEco 安装目录、下载目录、运行进程和可执行文件。结果仍未发现 `hvigorw`、`ohpm`、`hdc`、`codelinter`、API 26 SDK 或 Command Line Tools 根目录。

`tools/lint.ps1` 和 `tools/build.ps1` 均重新执行并在工具链门禁停止；这不是 ArkTS 源码错误。当前根阻塞更新为 `TOOLCHAIN BLOCKED: INSTALLATION NOT DETECTED`。下一步只需要已解压工具的真实完整路径。

2026-09-03 在用户指定范围内只读搜索后，确认 `devecocli` 1.3.0-stable 存在，但没有 `ohpm`、`hvigorw`、`hdc`、`codelinter` 或 API 26 SDK。这是“只安装 DevEco CLI，未安装 HarmonyOS Command Line Tools/SDK”的状态；仍没有 ArkTS 编译错误可修。

## 尚未获得的错误类别

由于 Hvigor 未启动，本轮没有真实 ArkTSCheck、ArkUI、Navigation、Resource、Module、Preferences、Packaging 或 Signing 编译错误日志。首次获得工具链后，必须执行真实 build，再根据新日志更新本文件；不能把当前主机契约测试通过当作 ArkTS 编译通过。
