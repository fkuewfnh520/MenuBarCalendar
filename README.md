# MenuBarCalendar 📅

macOS 菜单栏日历应用，支持中国法定节假日标注。

## 功能

- **菜单栏运行** — 在 macOS 菜单栏显示当前日期，点击弹出日历面板
- **月历视图** — 显示当前月份日历，支持前后月份切换，一键回到今天
- **法定节假日** — 标注中国法定节假日（绿色「休」标签）和调休工作日（橙色「班」标签）
- **节日详情** — 点击日期显示节假日名称和 emoji
- **周末高亮** — 周六/周日以红色显示

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

应用启动后会在菜单栏显示当前日期（如 `5月22日`），点击即可弹出日历面板。

> **提示**：应用设置了 `LSUIElement = YES`，不会在 Dock 中显示图标，仅在菜单栏运行。

## 项目结构

```
MenuBarCalendar/
├── MenuBarCalendarApp.swift   # 应用入口
├── AppDelegate.swift          # 菜单栏状态栏管理 (NSStatusItem + NSPopover)
├── CalendarView.swift         # SwiftUI 日历视图
├── CalendarViewModel.swift    # 日历数据逻辑
├── ChineseHolidays.swift      # 中国法定节假日数据 (2024-2026)
├── Assets.xcassets/           # 图标和颜色资源
├── Info.plist                 # 应用配置
└── MenuBarCalendar.entitlements
```

## 扩展节假日数据

如需添加更多年份的节假日，编辑 `ChineseHolidays.swift`：

- 在 `holidays` 字典中添加节假日日期和信息
- 在 `workdays` 集合中添加调休工作日日期

## 截图

应用在菜单栏显示当前日期，点击弹出日历面板：
- 今天以蓝色圆圈高亮显示
- 法定节假日标注绿色「休」
- 调休工作日标注橙色「班」
- 周末以红色文字显示

## 许可证

MIT License
