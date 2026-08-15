# AGENTS.md

本文件供 AI 编码代理阅读。读者对本项目一无所知，请先完整阅读本文件再动手。

## 项目概览

这是一个 **HarmonyOS（鸿蒙）第三方网易云音乐（NCM）客户端**，使用 ArkTS + ArkUI 开发，Stage 模型（`apiType: "stageMode"`）。

- 包名：`com.example.ncm`（见 `AppScope/app.json5`），当前为模板默认值，版本 `1.0.0`
- SDK：`targetSdkVersion` / `compatibleSdkVersion` 均为 `6.1.1(24)`（API 24），`runtimeOS: HarmonyOS`
- 设备类型：仅 `phone`
- 界面语言：中文；代码注释主要使用中文，新增注释请保持一致
- 只有一个模块：`entry`（`build-profile.json5`）

应用功能：发现（Banner、日推入口、热门歌单）、搜索、日推（每日推荐歌曲）、"我的"歌单、歌单/专辑详情、扫码/账号登录、完整播放器（封面模糊沉浸背景、歌词滚动、循环模式、迷你播放器）、主题设置（浅色/深色/跟随系统）。音频播放声明了 `backgroundModes: audioPlayback` 与 `KEEP_BACKGROUND_RUNNING` 权限，支持后台播放。

## 技术栈

- 语言 / UI：ArkTS + ArkUI，**状态管理 V2**（`@ComponentV2`、`@ObservedV2`、`@Trace`、`@Local`、`@Provider`、`@Monitor`、`AppStorageV2`、`PersistenceV2`）。不要引入 V1 装饰器（`@State`、`@Observed` 等）。
- 网络：`@kit.NetworkKit` 的 `http`，统一封装在 `NcmHttp`（weapi / eapi 双通道，AES 加密在 `crypto.ets`）
- 媒体：`@kit.MediaKit` 的 `AVPlayer` + AVSession（媒体会话）
- 设计组件：`@kit.UIDesignKit`（`HdsTabs` 等）
- 包管理：ohpm；锁文件 `oh-package-lock.json5`，依赖目录 `oh_modules/`（已 gitignore）。运行时无第三方依赖，仅 devDependencies：`@ohos/hypium`（单元测试框架）、`@ohos/hamock`（mock）

## 构建与运行

本项目**不含 hvigorw 命令行包装脚本**，通常通过 DevEco Studio 构建。若使用命令行（需 DevEco Studio 自带的 hvigor/ohpm 环境）：

- 安装依赖：`ohpm install`
- 构建 HAP：`hvigorw assembleHap --mode module -p product=default`（或 `assembleApp` 打 APP 包）
- 构建模式：`debug` / `release`（见根 `build-profile.json5` 的 `buildModeSet`）；release 混淆默认关闭（`entry/build-profile.json5`，规则文件 `entry/obfuscation-rules.txt`）
- 签名：`signingConfigs` 为空，真机运行需在 DevEco Studio 中配置自动签名
- 运行 / 调试：DevEco Studio 连接真机或模拟器（API 24+）

## 代码结构（`entry/src/main/ets/`）

分层为 MVVM，单向依赖：`view → viewmodel → model(repository) → model(source)`，全局状态在 `store`，播放服务在 `service`。

- `entryability/EntryAbility.ets`：入口 Ability。`onWindowStageCreate` 中初始化 `NcmHttp`、`PlayerService`，启动时若已登录则校验登录态
- `pages/Index.ets`：唯一 `@Entry` 页面（路由见 `resources/base/profile/main_pages.json`）。底部 `HdsTabs`（发现 / 搜索 / 我的）+ `Navigation`/`NavPathStack` 栈式导航 + 全局 `MiniPlayer` 悬浮层
- `common/router/`：路由常量（`RouteName`）与参数类型（`RouteParams`），新增页面路由在此登记并在 `Index.ets` 的 `PageMap` 中映射
- `common/utils/format.ets`：格式化与公共 UI 常量/设计 token（颜色如 `PAGE_BG`、`ACCENT_SOFT`，圆角 `RADIUS_*`、间距 `SPACE_*`、页面边距 `PAGE_PAD`、`NAV_INDICATOR_PAD`）
- `model/source/`：网络底层——`NcmHttp.ets`（统一 POST 入口、Cookie/csrf 管理）、`crypto.ets`（weapi/eapi 加密）、`cookiejar.ets`（Cookie 持久化）、`NcmParsers.ets`、`json.ets`
- `model/repository/`：业务接口层——`AuthRepository`（登录）、`CatalogRepository`（歌单/专辑）、`MediaRepository`（歌曲 URL/歌词）、`SearchRepository`（搜索）。均为单例（`XxxRepository.get()`）
- `model/entity/models.ets`：数据模型与歌词解析。DTO 是普通 class，**不加** `@ObservedV2`，UI 通过整引用替换刷新
- `store/`：全局状态。`StoreHub` 统一入口：`player()` / `session()` 用 `AppStorageV2.connect`，`theme()` 用 `PersistenceV2.connect`（持久化）。`PlayerSnapshot`、`SessionSnapshot`、`ThemeSettings` 为 `@ObservedV2` 快照类
- `service/player/`：`PlayerService`（AVPlayer 封装 + 播放队列 + 循环模式 + 失败跳转保护）、`AvSessionManager`（媒体会话/控制中心）
- `view/pages/`：各页面组件（`DiscoverPage`（首页：Banner + 日推 Hero + 热门歌单）、`SearchPage`（纯搜索）、`MinePage`（用户卡 + 歌单货架）、`DailySongsPage`、`PlaylistDetailPage`、`PlayerPage`、`SettingsPage`）
- `view/components/`：复用组件（`MiniPlayer`、`SongRow`、`PlaylistShelf`（歌单横滑货架）、`LoginPanel`）
- `viewmodel/`：每页一个 ViewModel（`@ObservedV2` + `@Trace`），页面持有的状态与业务调用都在这一层

## 编码约定

- 文件头与模块级注释使用中文块注释说明职责（如 `PlayerService.ets`、`models.ets` 开头），沿用现有风格
- 单例服务统一 `private static instance` + `static get()`
- 错误处理：异步调用用 try/catch 或 `.catch`，日志用 `console.error` 带 `[类名]` 前缀；Ability 层用 `hilog`
- 命名：常量 `UPPER_SNAKE_CASE`，类 `PascalCase`，方法/变量 `camelCase`
- 代码检查：`code-linter.json5`，规则集 `@performance/recommended` + `@typescript-eslint/recommended`，并强制一批 `@security/*` 加密安全规则（如禁用不安全 AES/哈希/RSA——注意 `crypto.ets` 是网易云协议要求的历史算法，改动时注意 lint 影响）
- `build-profile.json5` 开启了 `strictMode`（`caseSensitiveCheck`、`useNormalizedOHMUrl`），import 路径大小写必须与实际文件一致
- **记忆（用户偏好）**：界面与新增代码遵循鸿蒙现代化设计风格——优先使用 `@kit.UIDesignKit`（HDS）组件与 ArkUI 规范，遵循鸿蒙设计语言（充足留白、统一圆角、分层模糊/材质感、一致的间距与自然动效），不要引入与系统风格冲突的自绘样式

## 测试

- 已配置测试基建但**尚无测试代码**：`entry/build-profile.json5` 声明了 `ohosTest` target，`@ohos/hypium` / `@ohos/hamock` 已在 devDependencies。新增单元/仪器测试放在 `entry/src/ohosTest/`（框架为 Hypium，风格为 `describe/it/expect`）
- `code-linter.json5` 的 ignore 已排除 `ohosTest`、`test`、`mock` 目录
- 当前验证主要靠构建通过 + 真机/模拟器运行

## 安全与注意事项

- Cookie 与登录态（`MUSIC_U` 等）由 `cookiejar.ets` 持久化在应用沙箱，**不要**把真实 Cookie、账号信息写入日志或提交到仓库
- 请求全部发往 `music.163.com` / `interface.music.163.com`，UA 伪装为 iPhone 客户端；改动网络层需保持 weapi/eapi 加密协议与 header 伪装一致，否则接口会被拒
- 权限仅 `INTERNET` 与 `KEEP_BACKGROUND_RUNNING`（`module.json5`），新增权限需同步更新该文件
- `oh_modules/`、`build/`、`.hvigor/` 等目录已 gitignore，不要提交
- 本目录尚未初始化为 git 仓库；若日后初始化，提交信息建议用中文、简明描述改动
