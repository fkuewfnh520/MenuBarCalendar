# MenuBarCalendar 📅

macOS 菜单栏日历应用，支持中国法定节假日标注和农历显示。

## 功能

### 日历面板
- **顶部导航** — 年份下拉框（±50年）、月份切换箭头、「返回今天」按钮
- **周显示** — 周一至周日（可在设置中切换一周起始日）
- **日期方块** — 每天显示阳历日期 + 农历/节日/节气；固定阳历节日、传统农历节日和二十四节气会显示在农历日期位置，法定节假日绿色填充+左上角「休」标签，调休工作日橙色填充+「班」标签
- **底部信息栏** — 实时时间、星期、日期、农历月日与节日详情 + 退出按钮 + 设置按钮

### 菜单栏
- 可配置显示：时间（12/24小时制）、阳历日期、农历、星期
- 支持显示/隐藏图标、精确到秒、上午/下午
- 支持拖拽调整图标、星期、阳历、农历、时间的显示顺序

### 设置面板
- **通用** — 开机启动、一周开始于（周日/周一）、中国节假日订阅与更新、推送通知
- **色调** — 24 种主色调可选，包含常用色、马卡龙色和自定义 ARGB；日历文字强调、选中态和背景浅色会自动从主色调派生
- **状态栏** — 自定义菜单栏显示内容、时间格式、日期选项，并通过拖拽调整各元素顺序
- **背景** — 支持上传背景图片、移除图片、调整图片透明度与显示区域，并在设置面板中实时预览日历效果；背景底色来自「色调」页的主色调派生色

### 中国节假日

| 节日 | Emoji |
|------|-------|
| 元旦 | 🎍 |
| 春节 | 🧧 |
| 清明节 | 🌿 |
| 劳动节 | 👷 |
| 端午节 | 🐲 |
| 中秋节 | 🥮 |
| 国庆节 | 🇨🇳 |

应用内置 2024–2026 年节假日作为离线兜底；启动后会通过订阅地址获取中国节假日和调休数据，并按年份缓存到本地，查询历史年份时会自动补拉并保存对应年份数据。

默认 JSON 数据源：

```text
https://www.shuyz.com/githubfiles/china-holiday-calender/master/holidayAPI.json
```

iCal 订阅地址：

```text
https://www.shuyz.com/githubfiles/china-holiday-calender/master/holidayCal.ics
```

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Xcode 15.0 或更高版本

## 构建与运行

1. 克隆仓库：
   ```bash
   git clone https://github.com/fkuewfnh520/MenuBarCalendar.git
   ```

2. 用 Xcode 打开项目：
   ```bash
   cd MenuBarCalendar
   open MenuBarCalendar.xcodeproj
   ```

3. 在 Xcode 中按 `⌘R` 运行

应用启动后会在菜单栏显示时间和日期，点击即可弹出日历面板。

> **提示**：应用设置了 `LSUIElement = YES`，不会在 Dock 中显示图标，仅在菜单栏运行；如需关闭应用，可点击日历面板底部左侧的退出图标，并在确认弹窗中选择「退出」。

### 发布通用版

项目已配置为标准 macOS 通用架构，Release 构建会同时包含 Apple Silicon (`arm64`) 和 Intel (`x86_64`)。

发布给其他 Mac 使用时，建议在 Xcode 中使用 **Any Mac** / **Generic Mac** 或 **Archive** 方式构建；如果直接从当前机器的运行产物中取 `.app`，可能只包含当前机器的架构。

也可以用命令行构建并验证：

```bash
xcodebuild -scheme MenuBarCalendar -configuration Release -destination generic/platform=macOS build
lipo -info "path/to/万年历.app/Contents/MacOS/万年历"
```

验证结果应同时包含 `x86_64` 和 `arm64`。

## 项目结构

```
MenuBarCalendar/
├── MenuBarCalendarApp.swift   # 应用入口
├── AppDelegate.swift          # 菜单栏管理 (NSStatusItem + NSPopover)
├── CalendarView.swift         # SwiftUI 日历视图 + 日期方块
├── CalendarViewModel.swift    # 日历数据逻辑 + 底部栏数据
├── ChineseHolidays.swift      # 中国法定节假日订阅、缓存与离线兜底
├── LunarCalendar.swift        # 农历转换（天干地支、生肖、农历日期）
├── AppSettings.swift          # 应用设置（UserDefaults + 开机启动）
├── SettingsView.swift         # 设置面板（通用/色调/状态栏/背景）
├── Assets.xcassets/           # 图标和颜色资源
├── Info.plist                 # 应用配置
└── MenuBarCalendar.entitlements
```

## 扩展节假日数据

如需更换数据源，可在设置面板的「中国节假日」中修改订阅地址。应用支持 ShuYZ 聚合 JSON，也兼容包含 `%d` 的按年份 JSON 模板。

## 许可证

MIT License
