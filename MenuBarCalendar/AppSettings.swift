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

    // MARK: - Style

    @AppStorage("accentColorIndex") var accentColorIndex: Int = 0

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

    var currentThemeColor: Color {
        let index = max(0, min(accentColorIndex, Self.themeColors.count - 1))
        return Self.themeColors[index].color
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

    private init() {}
}
