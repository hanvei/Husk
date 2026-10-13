# 简体中文（zh-Hans）本地化

基于上游 `8e79a47b3f771eddd005bf338749e01a96443689`。上游权限为 READ，改动保存在个人 fork 的 `localization/zh-Hans` 分支。

## 修改范围

- 753 条中英文资源，795 处显式本地化表达式；设置、首次引导、游戏库、商店、导入安装、文件、存档、JIT 设置与配对、FAQ、诊断、更新说明、虚拟手柄、下载实时活动。
- `Shared/en.lproj/Localizable.strings` 和 `Shared/zh-Hans.lproj/Localizable.strings` 同时由主 App 与下载小组件引用。
- 主 App 的 `InfoPlist.strings` 翻译本地网络隐私权限说明。
- XcodeGen 显式使用 `developmentLanguage: en`；`Shared` 的现有 sources 引用自动加入 Swift 文件和本地化资源。无需手改生成的 pbxproj。
- `HuskL10n.render` 保留插值类型的字符串表示并转义百分号；`HuskL10n.text` 在显示边界翻译既有英文状态与错误，未知文案保持原文。
- 保持 `com.husk.app`、`.JITHelper`、`.Downloads` 标识关系、UserDefaults 键、文件目录、URL Scheme、原生 C/C++、JIT 协议和错误识别逻辑。

覆盖范围为 Husk 自身界面。Android 客体系统、游戏内部、外部网页、第三方软件源描述、原始调试日志及第三方错误中未识别的细节仍可能显示原文。部分低频开发者诊断尚未逐条汉化。没有新增强制语言设置；使用 iOS 系统/应用首选语言，其他语言回退英文。

## 验证

在 Windows 上运行 `node scripts/check_localization.cjs`：校验两种语言的键集合、重复/空翻译、格式占位符、所有 render 引用、主 App/小组件 Shared 引用、原有 Bundle ID 和权限说明。

已使用 Swift Tree-sitter 语法解析器与基准源码对比，33 个修改/新增 Swift 文件未出现新增解析错误；它不替代 Swift 类型检查或 iOS 构建。部分上游新语法不被该解析器支持。

`.github/workflows/localization.yml` 在 macOS 上编译共享 Foundation 辅助代码，验证英文、简体中文、未支持语言回退、旧英文诊断、插值与百分号；运行 Apple `plutil` 并生成 XcodeGen 工程。该流程不是完整 IPA 构建。

完整 App 构建仍需 macOS、相应 Xcode/iOS SDK，以及上游要求的 QEMU、ANGLE、MoltenVK、rppairing、客体映像和运行时资源。JITHelper 的现有部署目标为 iOS 26，源码包含上游 iOS 27 配对路径；SDK 不匹配的问题不属于本地化新增行为。依照仓库 README 的 Building 部分构建，已有构建环境可再运行 `./scripts/package_ipa.sh`。

## 保留 SideStore / AltStore 数据覆盖安装

1. 先在旧版各游戏页面选择 **Back Up Saves** 导出 ZIP；退出游戏并保存 Android 状态，再通过“文件”或 Finder 文件共享复制整个 Husk Documents。转译层数据在 `Documents/TranslationLayer`，另有 `Shared Storage`、Android 磁盘及 StikJIT 配对文件。游戏 ZIP 备份不等于整个 Android 磁盘备份；Documents 复制也不包含所有系统保存的应用偏好设置。
2. 从此分支构建 IPA，保留项目中现有 Bundle ID，不为“中文版”改名成另一个应用标识。保留 JITHelper 和 Downloads 扩展；侧载工具询问是否移除扩展时选择保留。
3. 使用安装旧版的同一个 SideStore 或 AltStore、同一个 Apple ID/开发团队导入新 IPA。侧载后实际 Bundle ID（可能由侧载工具加后缀）及签名应用身份必须与旧版匹配。
4. **不要先删除或卸载旧版。** 让侧载工具替换原有 Husk。若出现第二个 Husk 图标、不同应用身份或要求先删除旧版，停止并核对标识及签名；不要删除旧版来绕过此问题。
5. 覆盖完成后检查游戏库及存档，再在系统设置中为 Husk 选择简体中文（不同 iOS 版本可能位于“设置 › App › Husk › 语言”），或将简体中文设为首选系统语言。重新启动 Husk；JIT 可能需要重新启用。

仅保持源码中的 Bundle ID 不能保证跨 Apple ID、跨团队或跨侧载工具保留数据。本次没有连接 iPhone、检查旧 IPA 的实际签名身份，也没有执行设备上的覆盖安装，不能保证具体设备的数据保留结果。
