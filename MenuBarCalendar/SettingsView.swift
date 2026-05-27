import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject private var holidayStore = HolidayStore.shared
    @State private var selectedTab = 0
    @State private var settingsWindow: NSWindow?
    @State private var showCustomColorPopover = false

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                tabButton("通用", icon: "gearshape", tag: 0)
                tabButton("样式", icon: "paintpalette", tag: 1)
                tabButton("状态栏", icon: "menubar.rectangle", tag: 2)
                tabButton("背景", icon: "photo", tag: 3)
            }
            .padding(.horizontal, 12)

            Divider()
                .padding(.top, 8)

            // Tab content
            Group {
                switch selectedTab {
                case 0: generalTab
                case 1: styleTab
                case 2: statusBarTab
                case 3: backgroundTab
                default: EmptyView()
                }
            }
            .padding(16)
        }
        .frame(width: 420, height: 460)
        .background(Color(NSColor.windowBackgroundColor))
        .background(WindowReader(window: $settingsWindow))
    }

    // MARK: - Tab Button

    private func tabButton(_ title: String, icon: String, tag: Int) -> some View {
        Button(action: { selectedTab = tag }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 11))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundColor(selectedTab == tag ? settings.currentThemeColor : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTab == tag ? settings.currentThemeColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsSection("启动") {
                Toggle("开机自动启动", isOn: $settings.launchAtLogin)
            }

            settingsSection("日历") {
                Picker("一周开始于", selection: $settings.weekStartsOn) {
                    Text("周日").tag(0)
                    Text("周一").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            settingsSection("中国节假日") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("订阅地址", text: $settings.holidaySubscriptionURLTemplate)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 8) {
                        Button {
                            holidayStore.refreshYearsAroundToday()
                        } label: {
                            Label(holidayStore.status.isUpdating ? "更新中" : "立即更新", systemImage: "arrow.clockwise")
                        }
                        .disabled(holidayStore.status.isUpdating)

                        Button {
                            settings.holidaySubscriptionURLTemplate = HolidayStore.defaultSubscriptionURLTemplate
                        } label: {
                            Label("恢复默认", systemImage: "arrow.uturn.backward")
                        }
                    }

                    Text(holidayStatusText)
                        .font(.system(size: 11))
                        .foregroundColor(holidayStore.status.lastError == nil ? .secondary : .red)

                    Text("iCal 订阅地址：\(HolidayStore.icalSubscriptionURL)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }

            settingsSection("通知") {
                Toggle("推送通知", isOn: $settings.pushNotifications)
            }

            Spacer()
        }
    }

    // MARK: - Style Tab

    private var styleTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("主题颜色")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                ForEach(0 ..< AppSettings.themeColors.count, id: \.self) { index in
                    let theme = AppSettings.themeColors[index]
                    ZStack {
                        Circle()
                            .fill(theme.color)
                            .frame(width: 36, height: 36)

                        if settings.accentColorIndex == index {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .onTapGesture { settings.accentColorIndex = index }
                    .overlay(
                        Circle()
                            .stroke(settings.accentColorIndex == index ? theme.color : Color.clear, lineWidth: 2)
                            .frame(width: 42, height: 42)
                    )
                }
            }

            Text(AppSettings.themeColors[max(0, min(settings.accentColorIndex, AppSettings.themeColors.count - 1))].name)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
        }
    }

    // MARK: - Status Bar Tab

    private var statusBarTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsSection("图标") {
                    Toggle("显示图标", isOn: $settings.showIcon)
                }

                settingsSection("时间选项") {
                    Toggle("使用24小时格式", isOn: $settings.use24HourFormat)
                    if !settings.use24HourFormat {
                        Toggle("显示上午/下午", isOn: $settings.showAMPM)
                    }
                    Toggle("时间精确到秒", isOn: $settings.showSeconds)
                }

                settingsSection("日期选项") {
                    Toggle("显示农历", isOn: $settings.showLunarInStatusBar)
                    Toggle("显示阳历", isOn: $settings.showSolarInStatusBar)
                    Toggle("显示星期几", isOn: $settings.showWeekdayInStatusBar)
                }
            }
        }
    }

    // MARK: - Background Tab

    private var backgroundTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsSection("背景图片") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Button {
                                BackgroundImageStore.chooseImage(attachedTo: settingsWindow, for: settings)
                            } label: {
                                Label("选择图片", systemImage: "photo.on.rectangle")
                            }

                            Button {
                                BackgroundImageStore.removeImage(settings)
                            } label: {
                                Label("移除图片", systemImage: "trash")
                            }
                            .disabled(settings.backgroundImagePath.isEmpty)
                        }

                        Text(settings.backgroundImagePath.isEmpty ? "当前未设置背景图片" : "图片已复制到应用数据目录，删除原文件后仍可显示。")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                settingsSection("背景颜色") {
                    backgroundColorGrid
                }

                settingsSection("透明度") {
                    HStack {
                        Slider(value: $settings.backgroundOpacity, in: 0...1)
                        Text("\(Int(settings.backgroundOpacity * 100))%")
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundColor(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }

                settingsSection("显示区域") {
                    VStack(alignment: .leading, spacing: 10) {
                        percentSlider("水平偏移", value: $settings.backgroundOffsetX, range: 0...1)
                        percentSlider("垂直偏移", value: $settings.backgroundOffsetY, range: 0...1)
                        percentSlider("缩放", value: $settings.backgroundScale, range: 0...1)

                        Button {
                            settings.backgroundOffsetX = 0.5
                            settings.backgroundOffsetY = 0.5
                            settings.backgroundScale = 0.5
                        } label: {
                            Label("重置显示区域", systemImage: "crop.rotate")
                        }
                    }
                }
            }
        }
        .onAppear {
            BackgroundPreviewWindowController.shared.startObserving()
        }
        .onDisappear {
            BackgroundPreviewWindowController.shared.stopObserving()
        }
        .onChange(of: settings.backgroundImagePath) { _ in BackgroundPreviewWindowController.shared.showPreview() }
        .onChange(of: settings.backgroundColorIndex) { _ in BackgroundPreviewWindowController.shared.showPreview() }
        .onChange(of: settings.backgroundCustomARGB) { _ in BackgroundPreviewWindowController.shared.showPreview() }
        .onChange(of: settings.backgroundOpacity) { _ in BackgroundPreviewWindowController.shared.showPreview() }
        .onChange(of: settings.backgroundOffsetX) { _ in BackgroundPreviewWindowController.shared.showPreview() }
        .onChange(of: settings.backgroundOffsetY) { _ in BackgroundPreviewWindowController.shared.showPreview() }
        .onChange(of: settings.backgroundScale) { _ in BackgroundPreviewWindowController.shared.showPreview() }
    }

    // MARK: - Helper

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            content()
                .font(.system(size: 13))
        }
    }

    private var backgroundColorGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                ForEach(0 ..< AppSettings.backgroundColors.count, id: \.self) { index in
                    let background = AppSettings.backgroundColors[index]
                    let isCustom = index == AppSettings.customBackgroundColorIndex

                    if isCustom {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(
                                        AngularGradient(
                                            gradient: Gradient(colors: [
                                                .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red,
                                            ]),
                                            center: .center
                                        )
                                    )
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                                    )

                                if settings.backgroundColorIndex == index {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 1)
                                }
                            }

                            Text("自定义")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            settings.backgroundColorIndex = index
                            showCustomColorPopover = true
                        }
                        .popover(isPresented: $showCustomColorPopover, arrowEdge: .bottom) {
                            customColorPopoverContent
                        }
                    } else {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(background.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                                    )

                                if settings.backgroundColorIndex == index {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(index <= 1 ? .primary : .white)
                                }
                            }

                            Text(background.name)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { settings.backgroundColorIndex = index }
                    }
                }
            }
        }
    }

    private var customColorPopoverContent: some View {
        VStack(spacing: 14) {
            Text("自定义背景颜色")
                .font(.system(size: 13, weight: .medium))

            ColorPicker("颜色", selection: customColorBinding, supportsOpacity: false)
                .labelsHidden()
                .frame(height: 30)

            VStack(spacing: 6) {
                Text("透明度")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                HStack {
                    Slider(value: customAlphaBinding, in: 0...1)
                    Text("\(Int(customAlphaBinding.wrappedValue * 100))%")
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }

            RoundedRectangle(cornerRadius: 6)
                .fill(settings.currentCustomBackgroundColor)
                .frame(height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                )

            HStack(spacing: 8) {
                Text("ARGB")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))

                TextField("FFFFFFFF", text: customARGBBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12).monospaced())
                    .frame(width: 100)
            }
        }
        .padding(16)
        .frame(width: 240)
    }

    private var customColorBinding: Binding<Color> {
        Binding(
            get: {
                let argb = settings.backgroundCustomARGB
                guard argb.count == 8, let value = UInt32(argb, radix: 16) else {
                    return Color.white
                }
                let r = Double((value >> 16) & 0xFF) / 255
                let g = Double((value >> 8) & 0xFF) / 255
                let b = Double(value & 0xFF) / 255
                return Color(red: r, green: g, blue: b)
            },
            set: { newColor in
                let nsColor = NSColor(newColor).usingColorSpace(.deviceRGB) ?? NSColor.white
                let r = Int(nsColor.redComponent * 255)
                let g = Int(nsColor.greenComponent * 255)
                let b = Int(nsColor.blueComponent * 255)
                let currentARGB = settings.backgroundCustomARGB
                let a: Int
                if currentARGB.count == 8, let val = UInt32(currentARGB, radix: 16) {
                    a = Int((val >> 24) & 0xFF)
                } else {
                    a = 255
                }
                settings.backgroundCustomARGB = String(format: "%02X%02X%02X%02X", a, r, g, b)
                settings.backgroundColorIndex = AppSettings.customBackgroundColorIndex
            }
        )
    }

    private var customAlphaBinding: Binding<Double> {
        Binding(
            get: {
                let argb = settings.backgroundCustomARGB
                guard argb.count == 8, let value = UInt32(argb, radix: 16) else {
                    return 1.0
                }
                return Double((value >> 24) & 0xFF) / 255
            },
            set: { newAlpha in
                let currentARGB = settings.backgroundCustomARGB
                let a = Int(newAlpha * 255)
                if currentARGB.count == 8, let val = UInt32(currentARGB, radix: 16) {
                    let r = Int((val >> 16) & 0xFF)
                    let g = Int((val >> 8) & 0xFF)
                    let b = Int(val & 0xFF)
                    settings.backgroundCustomARGB = String(format: "%02X%02X%02X%02X", a, r, g, b)
                } else {
                    settings.backgroundCustomARGB = String(format: "%02XFFFFFF", a)
                }
                settings.backgroundColorIndex = AppSettings.customBackgroundColorIndex
            }
        )
    }

    private func percentSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 58, alignment: .leading)
            Slider(value: value, in: range)
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.system(size: 11).monospacedDigit())
                .foregroundColor(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
    }

    private var customARGBBinding: Binding<String> {
        Binding(
            get: { settings.backgroundCustomARGB },
            set: { newValue in
                let normalized = newValue
                    .uppercased()
                    .filter { $0.isNumber || ("A"..."F").contains(String($0)) }
                    .prefix(8)
                settings.backgroundCustomARGB = String(normalized)
                settings.backgroundColorIndex = AppSettings.customBackgroundColorIndex
            }
        )
    }

    private var holidayStatusText: String {
        if let error = holidayStore.status.lastError {
            return error
        }

        guard let lastUpdatedAt = holidayStore.status.lastUpdatedAt else {
            return "尚未更新，将在启动后自动获取近年数据。"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return "上次更新：\(formatter.string(from: lastUpdatedAt))"
    }
}

private struct CalendarBackgroundPreviewOverlay: View {
    let themeColor: Color

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(yearTitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 76, height: 22)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.65))
                    .cornerRadius(5)

                Spacer()

                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(themeColor)

                Text(monthTitle)
                    .font(.system(size: 14, weight: .bold))
                    .frame(minWidth: 42)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(themeColor)

                Spacer()

                Text("返回今天")
                    .font(.system(size: 10))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(themeColor.opacity(0.12))
                    .foregroundColor(themeColor)
                    .cornerRadius(4)
            }
            .padding(.bottom, 8)

            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(weekday == "周六" || weekday == "周日" ? .red.opacity(0.7) : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 18)
                }
            }
            .padding(.bottom, 4)

            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(previewDays) { day in
                    PreviewDayCell(day: day, themeColor: themeColor)
                }
            }

            Divider()
                .padding(.top, 6)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(timeText)
                            .font(.system(size: 12, weight: .medium).monospacedDigit())
                        Text(weekdayText)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 6) {
                        Text(dateText)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(LunarCalendar.monthDayAndFestivalText(for: Date()))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "power")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)

                Image(systemName: "gearshape")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)
            }
            .padding(.top, 7)
        }
    }

    private var yearTitle: String {
        let year = calendar.component(.year, from: Date())
        return "\(year) 年"
    }

    private var monthTitle: String {
        "\(calendar.component(.month, from: Date()))月"
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    private var weekdayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: Date())
    }

    private var weekdaySymbols: [String] {
        ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        calendar.firstWeekday = 2
        return calendar
    }

    private var previewDays: [PreviewDay] {
        let today = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: today),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else {
            return []
        }

        let firstDayOffset = (firstWeekday + 5) % 7
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 31
        let visibleCount = ((firstDayOffset + daysInMonth + 6) / 7) * 7
        let currentMonth = calendar.component(.month, from: today)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)

        return (0 ..< visibleCount).compactMap { index in
            let offset = index - firstDayOffset
            guard let date = calendar.date(byAdding: .day, value: offset, to: monthInterval.start) else {
                return nil
            }

            let components = calendar.dateComponents([.year, .month, .day], from: date)
            let festival = LunarCalendar.festivalText(for: date)
            return PreviewDay(
                id: "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)",
                dayNumber: components.day ?? 1,
                subtitle: festival ?? LunarCalendar.shortText(for: date),
                isFestival: festival != nil,
                isCurrentMonth: components.month == currentMonth,
                isWeekend: components.weekday == 1 || components.weekday == 7,
                holidayInfo: ChineseHolidays.holidayInfo(for: date),
                isCompensatoryWorkday: ChineseHolidays.isWorkday(date),
                isToday: components.year == todayComponents.year
                    && components.month == todayComponents.month
                    && components.day == todayComponents.day
            )
        }
    }
}

private struct PreviewDay: Identifiable {
    let id: String
    let dayNumber: Int
    let subtitle: String
    let isFestival: Bool
    let isCurrentMonth: Bool
    let isWeekend: Bool
    let holidayInfo: HolidayInfo?
    let isCompensatoryWorkday: Bool
    let isToday: Bool
}

private struct PreviewDayCell: View {
    let day: PreviewDay
    let themeColor: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            if day.isCurrentMonth {
                if day.holidayInfo != nil {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.12))
                } else if day.isCompensatoryWorkday {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange.opacity(0.12))
                }
            }

            if day.isToday {
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(themeColor, lineWidth: 1.2)
                    )
            }

            VStack(spacing: 1) {
                Text("\(day.dayNumber)")
                    .font(.system(size: 13, weight: day.isToday ? .bold : .regular))
                    .foregroundColor(dayTextColor)

                Text(day.subtitle)
                    .font(.system(size: day.isFestival ? 7.5 : 8.5, weight: day.isFestival ? .medium : .regular))
                    .foregroundColor(subtitleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if day.isCurrentMonth {
                if day.holidayInfo != nil {
                    badge("休", color: .green)
                } else if day.isCompensatoryWorkday {
                    badge("班", color: .orange)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 7, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 12, height: 12)
            .background(color)
            .cornerRadius(2)
            .offset(x: 1, y: 1)
    }

    private var dayTextColor: Color {
        if !day.isCurrentMonth { return .secondary.opacity(0.3) }
        if day.isToday { return themeColor }
        if day.holidayInfo != nil { return .green }
        if day.isWeekend && !day.isCompensatoryWorkday { return .red.opacity(0.7) }
        return .primary
    }

    private var subtitleColor: Color {
        if !day.isCurrentMonth { return .secondary.opacity(0.2) }
        if day.isFestival { return .red.opacity(0.75) }
        return .secondary.opacity(0.7)
    }
}

private struct WindowReader: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.window = nsView.window
        }
    }
}
