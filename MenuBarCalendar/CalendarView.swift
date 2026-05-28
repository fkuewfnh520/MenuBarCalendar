import AppKit
import SwiftUI

// MARK: - CalendarView

struct CalendarView: View {
    @StateObject private var vm = CalendarViewModel()
    @ObservedObject private var settings = AppSettings.shared

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            weekdayHeader
                .padding(.horizontal, 12)
                .padding(.bottom, 4)

            daysGrid
                .padding(.horizontal, 8)

            Divider()
                .padding(.top, 6)

            bottomBar
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 360)
        .background(calendarBackground)
        .environment(\.colorScheme, .light)
        .onChange(of: settings.weekStartsOn) { _ in vm.updateWeekStart(settings.weekStartsOn) }
    }

    private var calendarBackground: some View {
        ZStack {
            settings.currentBackgroundColor

            if let image = BackgroundImageStore.image(for: settings) {
                PositionedBackgroundImage(
                    image: image,
                    offsetX: settings.backgroundOffsetX,
                    offsetY: settings.backgroundOffsetY,
                    scale: settings.backgroundScale
                )
                .opacity(settings.backgroundOpacity)
                .allowsHitTesting(false)
            }

            settings.currentBackgroundColor
                .opacity(0.72)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 8) {
            // Year picker
            Picker("", selection: Binding(
                get: { vm.displayedYear },
                set: { vm.setYear($0) }
            )) {
                ForEach(vm.yearRange, id: \.self) { year in
                    Text("\(year)年").tag(year)
                }
            }
            .frame(width: 100)
            .labelsHidden()

            Spacer()

            // Month navigation
            Button(action: { vm.moveToPreviousMonth() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(settings.currentThemeColor)
            }
            .buttonStyle(.plain)

            Text(vm.monthTitle)
                .font(.system(size: 15, weight: .bold))
                .frame(minWidth: 50)

            Button(action: { vm.moveToNextMonth() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(settings.currentThemeColor)
            }
            .buttonStyle(.plain)

            Spacer()

            // Go to today
            Button(action: { vm.goToToday() }) {
                Text("返回今天")
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(settings.currentThemeColor.opacity(0.12))
                    .foregroundColor(settings.currentThemeColor)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(vm.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(symbol == "周六" || symbol == "周日" ? .red.opacity(0.7) : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
            }
        }
    }

    // MARK: - Days Grid

    private var daysGrid: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(vm.days) { day in
                DayCellView(
                    day: day,
                    isSelected: vm.selectedDate == day.date,
                    themeColor: settings.currentThemeColor
                )
                .onTapGesture { vm.select(day) }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(vm.currentTimeString)
                        .font(.system(size: 14, weight: .medium).monospacedDigit())
                    Text(vm.currentWeekdayString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    Text(vm.currentDateString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(vm.currentLunarString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: confirmQuit) {
                Image(systemName: "power")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("退出")

            Button(action: { SettingsWindowController.shared.showWindow(anchorWindow: NSApp.keyWindow) }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("设置")
        }
    }

    private func confirmQuit() {
        let alert = NSAlert()
        alert.messageText = "退出日历？"
        alert.informativeText = "确认后将关闭菜单栏日历。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "退出")
        alert.addButton(withTitle: "取消")

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        NSApp.terminate(nil)
    }
}

// MARK: - SettingsWindowController

final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    private init() {}

    func showWindow(anchorWindow: NSWindow? = nil) {
        if let existingWindow = window, existingWindow.isVisible {
            position(existingWindow, near: anchorWindow)
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.title = "设置"
        window.isReleasedWhenClosed = false
        position(window, near: anchorWindow)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { [weak self, weak window, weak anchorWindow] in
            guard let window else { return }
            self?.position(window, near: anchorWindow)
        }

        self.window = window
    }

    private func position(_ window: NSWindow, near anchorWindow: NSWindow?) {
        let fallbackPoint = NSEvent.mouseLocation
        let anchorFrame = anchorWindow?.frame
        let anchorPoint = anchorFrame.map { NSPoint(x: $0.midX, y: $0.midY) } ?? fallbackPoint
        let screen = anchorWindow?.screen
            ?? NSScreen.screens.first { $0.frame.contains(anchorPoint) }
            ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else {
            window.center()
            return
        }

        let margin: CGFloat = 10
        let windowSize = window.frame.size
        let preferredX = anchorPoint.x - windowSize.width / 2
        let preferredY = (anchorFrame?.maxY ?? visibleFrame.maxY) - windowSize.height - 8
        var proposedFrame = NSRect(origin: NSPoint(x: preferredX, y: preferredY), size: windowSize)
        proposedFrame = clamp(proposedFrame, to: visibleFrame.insetBy(dx: margin, dy: margin))

        window.setFrame(proposedFrame, display: true)
    }

    private func clamp(_ frame: NSRect, to bounds: NSRect) -> NSRect {
        var frame = frame

        if frame.width > bounds.width {
            frame.size.width = bounds.width
        }
        if frame.height > bounds.height {
            frame.size.height = bounds.height
        }

        if frame.maxX > bounds.maxX {
            frame.origin.x = bounds.maxX - frame.width
        }
        if frame.minX < bounds.minX {
            frame.origin.x = bounds.minX
        }
        if frame.maxY > bounds.maxY {
            frame.origin.y = bounds.maxY - frame.height
        }
        if frame.minY < bounds.minY {
            frame.origin.y = bounds.minY
        }

        return frame
    }
}

// MARK: - DayCellView

struct DayCellView: View {
    let day: DayItem
    let isSelected: Bool
    let themeColor: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background fill for holiday/workday
            if day.isCurrentMonth {
                if day.holidayInfo != nil {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.12))
                } else if day.isCompensatoryWorkday {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange.opacity(0.12))
                }
            }

            // Selection / today indicator
            if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(themeColor, lineWidth: 2)
            } else if day.isToday {
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(themeColor, lineWidth: 1.5)
                    )
            }

            // Content
            VStack(spacing: 1) {
                Text("\(day.dayNumber)")
                    .font(.system(size: 14, weight: day.isToday ? .bold : .regular))
                    .foregroundColor(dayTextColor)

                Text(day.lunarText)
                    .font(.system(size: day.festivalText == nil ? 9 : 8.5, weight: day.festivalText == nil ? .regular : .medium))
                    .foregroundColor(lunarTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Holiday/workday badge at top-left
            if day.isCurrentMonth {
                if day.holidayInfo != nil {
                    Text("休")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 14, height: 14)
                        .background(Color.green)
                        .cornerRadius(2)
                        .offset(x: 1, y: 1)
                } else if day.isCompensatoryWorkday {
                    Text("班")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 14, height: 14)
                        .background(Color.orange)
                        .cornerRadius(2)
                        .offset(x: 1, y: 1)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .contentShape(Rectangle())
    }

    private var dayTextColor: Color {
        if !day.isCurrentMonth { return .secondary.opacity(0.3) }
        if isSelected || day.isToday { return themeColor }
        if day.holidayInfo != nil { return .green }
        if day.isWeekend && !day.isCompensatoryWorkday { return .red.opacity(0.7) }
        return .primary
    }

    private var lunarTextColor: Color {
        if !day.isCurrentMonth { return .secondary.opacity(0.2) }
        if isSelected { return themeColor.opacity(0.85) }
        if day.festivalText != nil { return .red.opacity(0.75) }
        return .secondary.opacity(0.7)
    }
}

// MARK: - Preview

#if DEBUG
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
#endif
