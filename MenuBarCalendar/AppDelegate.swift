import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private let statusTitleFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = CalendarView()

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.autosaveName = "MenuBarCalendarStatusItem"
        if let button = statusItem?.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
            updateStatusBarDisplay()
        }

        // Update every second to keep time accurate
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateStatusBarDisplay()
        }

        // Observe settings changes
        let settings = AppSettings.shared
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusBarDisplay()
                }
            }
            .store(in: &cancellables)
    }

    private func updateStatusBarDisplay() {
        guard let button = statusItem?.button else { return }
        let settings = AppSettings.shared
        let now = Date()

        // Icon
        if settings.showIcon {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "日历")
        } else {
            button.image = nil
        }

        let title = " " + statusTitle(for: now, settings: settings)
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: statusTitleFont,
                .foregroundColor: NSColor.labelColor,
            ]
        )
        statusItem?.length = reservedStatusItemLength(for: now, settings: settings)
    }

    private func statusTitle(for date: Date, settings: AppSettings) -> String {
        var parts: [String] = []

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "zh_CN")
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

        if settings.showWeekdayInStatusBar {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
            formatter.dateFormat = "EEE"
            parts.append(formatter.string(from: date))
        }

        if settings.showSolarInStatusBar {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
            formatter.dateFormat = "yyyy年M月d日"
            parts.append(formatter.string(from: date))
        }

        if settings.showLunarInStatusBar {
            parts.append(LunarCalendar.monthDayText(for: date))
        }
        
        if settings.use24HourFormat {
            timeFormatter.dateFormat = settings.showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            if settings.showAMPM {
                timeFormatter.dateFormat = settings.showSeconds ? "a h:mm:ss" : "a h:mm"
            } else {
                timeFormatter.dateFormat = settings.showSeconds ? "h:mm:ss" : "h:mm"
            }
        }
        parts.append(timeFormatter.string(from: date))

        return parts.joined(separator: " ")
    }

    private func reservedStatusItemLength(for date: Date, settings: AppSettings) -> CGFloat {
        let actualTitle = " " + statusTitle(for: date, settings: settings)
        var candidates = [actualTitle]

        if settings.use24HourFormat {
            candidates.append(settings.showSeconds ? " 00:00:00" : " 00:00")
        } else if settings.showAMPM {
            candidates.append(settings.showSeconds ? " 下午 00:00:00" : " 下午 00:00")
        } else {
            candidates.append(settings.showSeconds ? " 00:00:00" : " 00:00")
        }

        let titleWidth = candidates
            .map { ($0 as NSString).size(withAttributes: [.font: statusTitleFont]).width }
            .max() ?? 0
        let iconWidth: CGFloat = settings.showIcon ? 22 : 0
        let horizontalPadding: CGFloat = settings.showIcon ? 14 : 10
        return ceil(titleWidth + iconWidth + horizontalPadding)
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }
        if let popover = popover {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}
