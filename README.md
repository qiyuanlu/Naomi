# Naomi · 糯米桌面伙伴

轻量原生 macOS 桌面宠物，使用 Swift + AppKit。当前版本 **0.2.0（构建 3）**，Apple Silicon，macOS 13 或以上。

## 打开与使用

从 GitHub Releases 下载 `Naomi-macOS-arm64.zip`，解压后双击 `Nuomi.app`。也可以自行构建后打开 `build/Nuomi.app`。本地已创建桌面「糯米」替身的用户，可继续使用该入口。

- 默认坐着，偶尔眨眼；点击猫的左半边向右跑，右半边向左跑，**每次 1 秒**。
- 无人互动 **120 秒**后侧躺休息，**180 秒**后侧躺歪头睡觉，带轻微呼吸、睡泡和飘动 Zzz；点击或拖动可唤醒。
- 拖动时切换为后颈被轻轻拎住、四肢放松下垂的姿态；可移到另一屏，松开后坐回对应屏幕底边。
- 菜单栏「糯米 🐾」或右键菜单：暂停/继续、大小、穿透点击、移到鼠标屏幕、回到底边、退出。
- 开启穿透点击后需从菜单栏关闭，才能再次点击和拖动猫。

没有网络聊天、开机自启或登录项。不会请求辅助功能、屏幕录制权限，也不会主动抢键盘焦点。暂停或显示器休眠不累计无人互动时间。

## 构建与测试

安装 Apple Command Line Tools（本项目使用 Swift 6 验证），无第三方依赖。在项目目录执行：

```sh
./build.sh
./test.sh
codesign --verify --deep build/Nuomi.app
```

构建先在 `/tmp` 临时目录生成并验证 ad-hoc 签名，再放入稳定路径 `build/Nuomi.app`，以避免云盘目录自动附加的 Finder 元数据影响签名。项目没有发行公证；遇到 macOS 安全提示，应由用户处理，本项目不绕过系统保护。

## 目录

```text
Sources/                 AppKit 窗口、点击/休息状态机、屏幕几何
Tests/main.swift         状态和边界测试
Tools/make-icons.swift   图标等比缩放与透明留边工具
Tools/desktop-alias.swift 创建或安全更新桌面替身
assets/                  精灵图、透明图标母图、icns、图标提示词
Info.plist               应用元数据
build.sh / test.sh       构建与测试入口
TEST-RESULTS.md           验证记录和实际限制
build/Nuomi.app           构建产物（不纳入 Git）
```

## 素材和图标

桌面动画使用原始透明精灵图 `spritesheet-extended.png`，1536×2288、8 列×11 行，每格192×208；SHA-256 为 `60f570e0c9830f1c4f5fa85782f73da2bb0eed776b0654deee42ef4a42d705ed`。

新增睡姿和提起姿态为 `assets/sleeping.png` 与 `assets/carried.png`，提示词见 `assets/pose-prompts.txt`。

图标按用户最终选择使用最初坐姿白猫，内置 imagegen 去除粉色背景；提示词保存在 `assets/icon-prompt.txt`，透明母图为 `assets/Nuomi-icon-source.png`。不使用此前生成的直立新稿。macOS 可能为图标添加自己的圆角底板。

需要重新生成图标时：

```sh
mkdir -p build/module-cache assets/Nuomi.iconset
swiftc -module-cache-path build/module-cache Tools/make-icons.swift -o build/make-icons
build/make-icons
iconutil -c icns assets/Nuomi.iconset -o assets/Nuomi.icns
./build.sh
```

## 桌面替身

「糯米」是 Finder alias，指向本项目 `build/Nuomi.app`，不复制一份可能过期的应用。保持项目位置不变即可通过同一个入口使用后续构建。

新建替身：编译 `Tools/desktop-alias.swift` 后传入应用路径和替身路径。若替身已存在，工具默认拒绝覆盖；只有显式传入旧目标路径且实际匹配时才允许更新。无需运行应用或重启 Finder。

## 运行限制

依据 `NSScreen.visibleFrame` 避开 Dock 保留区域，不追踪单个 Dock 图标的真实轮廓。自动隐藏 Dock 弹出时可能短暂遮挡猫。多屏一次只有一只猫，断开屏幕后会移回可用显示器。

睡觉和拖动使用依据原有糯米形象生成的独立透明姿态。睡眠特效以 8 Hz 更新，暂停及显示器休眠时停止。拖动姿态随鼠标事件更新。

## 项目与分享

GitHub 仓库名为 Naomi。源代码、必要素材与文档纳入版本记录；构建缓存和产物不纳入 Git，可运行应用以 Releases 附件提供。当前下载包适用于 Apple Silicon Mac。
