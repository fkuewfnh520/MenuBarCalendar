import AppKit
import SwiftUI
import Combine
import ServiceManagement

enum StatusBarItemKind: String, CaseIterable, Identifiable {
    case icon
    case weekday
    case solar
    case lunar
    case time

    var id: String { rawValue }

    var title: String {
        switch self {
        case .icon: return "图标"
        case .weekday: return "星期"
        case .solar: return "阳历"
        case .lunar: return "农历"
        case .time: return "时间"
        }
    }

    var systemImage: String {
        switch self {
        case .icon: return "calendar"
        case .weekday: return "calendar.day.timeline.left"
        case .solar: return "sun.max"
        case .lunar: return "moon"
        case .time: return "clock"
        }
    }
}

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
    @AppStorage("backgroundCustomARGB") var backgroundCustomARGB: String = "FFFFFFFF"
    @AppStorage("backgroundImagePath") var backgroundImagePath: String = ""
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.18
    @AppStorage("backgroundOffsetX") var backgroundOffsetX: Double = 0.5
    @AppStorage("backgroundOffsetY") var backgroundOffsetY: Double = 0.5
    @AppStorage("backgroundScale") var backgroundScale: Double = 0.5

    static let themeColors: [(name: String, argb: String)] = [
        ("默认蓝", "FF2F80ED"),
        ("天空蓝", "FF16A8E8"),
        ("薄荷绿", "FF23B77E"),
        ("翡翠绿", "FF2EAD4F"),
        ("柠檬黄", "FFE5B800"),
        ("落日橙", "FFF27A1A"),
        ("珊瑚红", "FFE85656"),
        ("玫瑰粉", "FFE84C8B"),
        ("薰衣紫", "FF8B5CF6"),
        ("靛蓝", "FF5865D9"),
        ("石墨灰", "FF667085"),
        ("奶油杏", "FFF2C6A0"),
        ("蜜桃粉", "FFFFA8B5"),
        ("樱花粉", "FFFFC7D9"),
        ("雾紫", "FFCDB4DB"),
        ("云朵蓝", "FFA7D8F0"),
        ("冰川蓝", "FFB8E7F2"),
        ("海盐青", "FFA8E6CF"),
        ("鼠尾草", "FFB7D7B2"),
        ("开心果", "FFD6EBA7"),
        ("香草黄", "FFFFE1A8"),
        ("奶茶棕", "FFD7B899"),
        ("雾霾灰", "FFAEB8C2"),
        ("自定义", "FFFFFFFF"),
    ]

    static let customThemeColorIndex = themeColors.count - 1

    var currentThemeColor: Color {
        let index = max(0, min(accentColorIndex, Self.themeColors.count - 1))
        if index == Self.customThemeColorIndex {
            return currentCustomBackgroundColor
        }
        return Self.color(fromARGB: Self.themeColors[index].argb) ?? Color.blue
    }

    var currentBackgroundColor: Color {
        Self.derivedBackgroundColor(from: currentThemeColor)
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
    @AppStorage("statusBarItemOrder") private var statusBarItemOrderRaw: String = ""

    var statusBarItemOrder: [StatusBarItemKind] {
        get {
            let saved = statusBarItemOrderRaw
                .split(separator: ",")
                .compactMap { StatusBarItemKind(rawValue: String($0)) }
            let missing = StatusBarItemKind.allCases.filter { !saved.contains($0) }
            let ordered = saved + missing
            return ordered.isEmpty ? Self.defaultStatusBarItemOrder : ordered
        }
        set {
            let unique = newValue.reduce(into: [StatusBarItemKind]()) { result, item in
                if !result.contains(item) {
                    result.append(item)
                }
            }
            let completed = unique + StatusBarItemKind.allCases.filter { !unique.contains($0) }
            statusBarItemOrderRaw = completed.map(\.rawValue).joined(separator: ",")
        }
    }

    static let defaultStatusBarItemOrder: [StatusBarItemKind] = [.icon, .weekday, .solar, .lunar, .time]

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

    static func derivedBackgroundColor(from color: Color) -> Color {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor.white
        let whiteMix: CGFloat = 0.88
        let red = nsColor.redComponent * (1 - whiteMix) + whiteMix
        let green = nsColor.greenComponent * (1 - whiteMix) + whiteMix
        let blue = nsColor.blueComponent * (1 - whiteMix) + whiteMix
        return Color(NSColor(calibratedRed: red, green: green, blue: blue, alpha: nsColor.alphaComponent))
    }
}
