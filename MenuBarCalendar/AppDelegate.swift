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

        button.image = nil
        button.attributedTitle = statusAttributedTitle(for: now, settings: settings)
        statusItem?.length = reservedStatusItemLength(for: now, settings: settings)
    }

    private func statusAttributedTitle(for date: Date, settings: AppSettings) -> NSAttributedString {
        let title = NSMutableAttributedString()
        let parts = statusParts(for: date, settings: settings)

        for (index, part) in parts.enumerated() {
            if index > 0 {
                title.append(NSAttributedString(string: " ", attributes: statusTextAttributes))
            }

            switch part {
            case .icon:
                let attachment = NSTextAttachment()
                let image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "日历")
                image?.size = NSSize(width: 15, height: 15)
                attachment.image = image
                attachment.bounds = NSRect(x: 0, y: -2, width: 15, height: 15)
                title.append(NSAttributedString(attachment: attachment))
            case .text(let value):
                title.append(NSAttributedString(string: value, attributes: statusTextAttributes))
            }
        }

        return title
    }

    private var statusTextAttributes: [NSAttributedString.Key: Any] {
        [
            .font: statusTitleFont,
            .foregroundColor: NSColor.labelColor,
        ]
    }

    private enum StatusPart {
        case icon
        case text(String)
    }

    private func statusParts(for date: Date, settings: AppSettings) -> [StatusPart] {
        settings.statusBarItemOrder.compactMap { item in
            switch item {
            case .icon:
                return settings.showIcon ? .icon : nil
            case .weekday:
                guard settings.showWeekdayInStatusBar else { return nil }
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "zh_CN")
                formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
                formatter.dateFormat = "EEE"
                return .text(formatter.string(from: date))
            case .solar:
                guard settings.showSolarInStatusBar else { return nil }
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "zh_CN")
                formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
                formatter.dateFormat = "yyyy年M月d日"
                return .text(formatter.string(from: date))
            case .lunar:
                guard settings.showLunarInStatusBar else { return nil }
                return .text(LunarCalendar.monthDayText(for: date))
            case .time:
                return .text(statusTimeText(for: date, settings: settings))
            }
        }
    }

    private func statusTitle(for date: Date, settings: AppSettings) -> String {
        statusParts(for: date, settings: settings).compactMap { part in
            switch part {
            case .icon: return settings.showIcon ? "□" : nil
            case .text(let value): return value
            }
        }
        .joined(separator: " ")
    }

    private func statusTimeText(for date: Date, settings: AppSettings) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "zh_CN")
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        
        if settings.use24HourFormat {
            timeFormatter.dateFormat = settings.showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            if settings.showAMPM {
                timeFormatter.dateFormat = settings.showSeconds ? "a h:mm:ss" : "a h:mm"
            } else {
                timeFormatter.dateFormat = settings.showSeconds ? "h:mm:ss" : "h:mm"
            }
        }
        return timeFormatter.string(from: date)
    }

    private func reservedStatusItemLength(for date: Date, settings: AppSettings) -> CGFloat {
        let actualTitle = statusTitle(for: date, settings: settings)
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
        let horizontalPadding: CGFloat = 18
        return ceil(titleWidth + horizontalPadding)
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

    func keepCalendarOpenForSettingsPreview() {
        guard let button = statusItem?.button, let popover else { return }
        popover.behavior = .applicationDefined
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func closeSettingsPreviewCalendar() {
        guard let popover else { return }
        popover.behavior = .transient
        if popover.isShown {
            popover.performClose(nil)
        }
    }
}
