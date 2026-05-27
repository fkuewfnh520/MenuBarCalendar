# MenuBarCalendar 📅

macOS 菜单栏日历应用，支持中国法定节假日标注和农历显示。

## 功能

### 日历面板
- **顶部导航** — 年份下拉框（±50年）、月份切换箭头、「返回今天」按钮
- **周显示** — 周一至周日（可在设置中切换一周起始日）
- **日期方块** — 每天显示阳历日期 + 农历；法定节假日绿色填充+左上角「休」标签，调休工作日橙色填充+「班」标签
- **底部信息栏** — 实时时间、星期、日期、农历月日 + 设置按钮

### 菜单栏
- 可配置显示：时间（12/24小时制）、阳历日期、农历、星期
- 支持显示/隐藏图标、精确到秒、上午/下午

### 设置面板
- **通用** — 开机启动、一周开始于（周日/周一）、推送通知
- **样式** — 12 种主题颜色可选
- **状态栏** — 自定义菜单栏显示内容（时间格式、日期选项等）

### 已收录节假日（2024–2026）

| 节日 | Emoji |
|------|-------|
| 元旦 | 🎍 |
| 春节 | 🧧 |
| 清明节 | 🌿 |
| 劳动节 | 👷 |
| 端午节 | 🐲 |
| 中秋节 | 🥮 |
| 国庆节 | 🇨🇳 |

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

> **提示**：应用设置了 `LSUIElement = YES`，不会在 Dock 中显示图标，仅在菜单栏运行。

## 项目结构

```
MenuBarCalendar/
├── MenuBarCalendarApp.swift   # 应用入口
├── AppDelegate.swift          # 菜单栏管理 (NSStatusItem + NSPopover)
├── CalendarView.swift         # SwiftUI 日历视图 + 日期方块
├── CalendarViewModel.swift    # 日历数据逻辑 + 底部栏数据
├── ChineseHolidays.swift      # 中国法定节假日数据 (2024-2026)
├── LunarCalendar.swift        # 农历转换（天干地支、生肖、农历日期）
├── AppSettings.swift          # 应用设置（UserDefaults + 开机启动）
├── SettingsView.swift         # 设置面板（通用/样式/状态栏）
├── Assets.xcassets/           # 图标和颜色资源
├── Info.plist                 # 应用配置
└── MenuBarCalendar.entitlements
```

## 扩展节假日数据

如需添加更多年份的节假日，编辑 `ChineseHolidays.swift`：

- 在 `holidays` 字典中添加节假日日期和信息
- 在 `workdays` 集合中添加调休工作日日期

## 许可证

MIT License
