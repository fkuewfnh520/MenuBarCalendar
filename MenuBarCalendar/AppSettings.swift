import AppKit
import SwiftUI
import Combine
import ServiceManagement

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - General

    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { updateLoginItem() }
    }

    /// 0 = Sunday, 1 = Monday
    @AppStorage("weekStartsOn") var weekStartsOn: Int = 1

    @AppStorage("pushNotifications") var pushNotifications: Bool = true

    @AppStorage("holidaySubscriptionURLTemplate") var holidaySubscriptionURLTemplate: String = defaultHolidaySubscriptionURLTemplate
    @AppStorage("holidayLastUpdatedAt") private var holidayLastUpdatedTimestamp: Double = 0

    var holidayLastUpdatedAt: Date? {
        get { holidayLastUpdatedTimestamp > 0 ? Date(timeIntervalSince1970: holidayLastUpdatedTimestamp) : nil }
        set { holidayLastUpdatedTimestamp = newValue?.timeIntervalSince1970 ?? 0 }
    }

    // MARK: - Style

    @AppStorage("accentColorIndex") var accentColorIndex: Int = 0
    @AppStorage("backgroundColorIndex") var backgroundColorIndex: Int = 0
    @AppStorage("backgroundCustomARGB") var backgroundCustomARGB: String = "FFFFFFFF"
    @AppStorage("backgroundImagePath") var backgroundImagePath: String = ""
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.18
    @AppStorage("backgroundOffsetX") var backgroundOffsetX: Double = 0.5
    @AppStorage("backgroundOffsetY") var backgroundOffsetY: Double = 0.5
    @AppStorage("backgroundScale") var backgroundScale: Double = 0.5

    static let themeColors: [(name: String, color: Color)] = [
        ("默认蓝", Color.blue),
        ("天空蓝", Color.cyan),
        ("薄荷绿", Color.mint),
        ("翡翠绿", Color.green),
        ("柠檬黄", Color(red: 0.95, green: 0.8, blue: 0.0)),
        ("落日橙", Color.orange),
        ("珊瑚红", Color(red: 0.94, green: 0.36, blue: 0.36)),
        ("玫瑰粉", Color.pink),
        ("薰衣紫", Color.purple),
        ("靛蓝", Color.indigo),
        ("石墨灰", Color.gray),
        ("棕褐色", Color.brown),
    ]

    static let backgroundColors: [(name: String, color: Color)] = [
        ("默认", Color(NSColor.windowBackgroundColor)),
        ("浅灰", Color(NSColor.controlBackgroundColor)),
        ("天空蓝", Color.cyan.opacity(0.16)),
        ("薄荷绿", Color.mint.opacity(0.16)),
        ("暖黄色", Color.yellow.opacity(0.16)),
        ("玫瑰粉", Color.pink.opacity(0.14)),
        ("薰衣紫", Color.purple.opacity(0.14)),
        ("石墨灰", Color.gray.opacity(0.18)),
        ("淡橙", Color.orange.opacity(0.14)),
        ("靛蓝", Color.indigo.opacity(0.14)),
        ("自定义", Color.clear),
    ]

    static let customBackgroundColorIndex = backgroundColors.count - 1

    var currentThemeColor: Color {
        let index = max(0, min(accentColorIndex, Self.themeColors.count - 1))
        return Self.themeColors[index].color
    }

    var currentBackgroundColor: Color {
        let index = max(0, min(backgroundColorIndex, Self.backgroundColors.count - 1))
        if index == Self.customBackgroundColorIndex {
            return currentCustomBackgroundColor
        }
        return Self.backgroundColors[index].color
    }

    var currentCustomBackgroundColor: Color {
        Self.color(fromARGB: backgroundCustomARGB) ?? Color.white
    }

    // MARK: - Status Bar

    @AppStorage("showIcon") var showIcon: Bool = true
    @AppStorage("use24HourFormat") var use24HourFormat: Bool = true
    @AppStorage("showAMPM") var showAMPM: Bool = false
    @AppStorage("showSeconds") var showSeconds: Bool = false
    @AppStorage("showLunarInStatusBar") var showLunarInStatusBar: Bool = false
    @AppStorage("showSolarInStatusBar") var showSolarInStatusBar: Bool = true
    @AppStorage("showWeekdayInStatusBar") var showWeekdayInStatusBar: Bool = false

    // MARK: - Login Item

    private func updateLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
        }
    }

    private init() {
        if holidaySubscriptionURLTemplate.contains("cdn.jsdelivr.net/npm/chinese-days") {
            holidaySubscriptionURLTemplate = defaultHolidaySubscriptionURLTemplate
            holidayLastUpdatedAt = nil
        }
    }

    static func color(fromARGB argb: String) -> Color? {
        let normalized = argb.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard normalized.count == 8,
              let value = UInt32(normalized, radix: 16)
        else {
            return nil
        }

        let alpha = CGFloat((value >> 24) & 0xFF) / 255
        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255

        return Color(NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha))
    }
}
