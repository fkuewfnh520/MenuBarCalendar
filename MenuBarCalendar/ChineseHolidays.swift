import Foundation

/// Represents a Chinese statutory holiday.
struct HolidayInfo {
    let name: String
    let emoji: String
}

/// Manages Chinese statutory holiday data.
///
/// Includes official holidays and compensatory workdays (调休).
/// Data covers 2024–2026; extend `holidays` and `workdays` for future years.
enum ChineseHolidays {
    // MARK: - Holiday dates (放假)

    private static let holidays: [String: HolidayInfo] = {
        var map = [String: HolidayInfo]()

        // ── 2024 ──────────────────────────────────────────────
        // 元旦
        map["2024-01-01"] = HolidayInfo(name: "元旦", emoji: "🎍")
        // 春节
        for d in 10...17 { map["2024-02-\(String(format: "%02d", d))"] = HolidayInfo(name: "春节", emoji: "🧧") }
        // 清明节
        for d in 4...6 { map["2024-04-\(String(format: "%02d", d))"] = HolidayInfo(name: "清明节", emoji: "🌿") }
        // 劳动节
        for d in 1...5 { map["2024-05-\(String(format: "%02d", d))"] = HolidayInfo(name: "劳动节", emoji: "👷") }
        // 端午节
        for d in 8...10 { map["2024-06-\(String(format: "%02d", d))"] = HolidayInfo(name: "端午节", emoji: "🐲") }
        // 中秋节
        for d in 15...17 { map["2024-09-\(String(format: "%02d", d))"] = HolidayInfo(name: "中秋节", emoji: "🥮") }
        // 国庆节
        for d in 1...7 { map["2024-10-\(String(format: "%02d", d))"] = HolidayInfo(name: "国庆节", emoji: "🇨🇳") }

        // ── 2025 ──────────────────────────────────────────────
        // 元旦
        map["2025-01-01"] = HolidayInfo(name: "元旦", emoji: "🎍")
        // 春节
        for d in 28...31 { map["2025-01-\(String(format: "%02d", d))"] = HolidayInfo(name: "春节", emoji: "🧧") }
        for d in 1...4 { map["2025-02-\(String(format: "%02d", d))"] = HolidayInfo(name: "春节", emoji: "🧧") }
        // 清明节
        for d in 4...6 { map["2025-04-\(String(format: "%02d", d))"] = HolidayInfo(name: "清明节", emoji: "🌿") }
        // 劳动节
        for d in 1...5 { map["2025-05-\(String(format: "%02d", d))"] = HolidayInfo(name: "劳动节", emoji: "👷") }
        // 端午节
        for d in 31 ... 31 { map["2025-05-\(String(format: "%02d", d))"] = HolidayInfo(name: "端午节", emoji: "🐲") }
        for d in 1...2 { map["2025-06-\(String(format: "%02d", d))"] = HolidayInfo(name: "端午节", emoji: "🐲") }
        // 中秋节 + 国庆节
        for d in 1...8 { map["2025-10-\(String(format: "%02d", d))"] = HolidayInfo(name: d <= 3 ? "中秋节·国庆节" : "国庆节", emoji: d <= 3 ? "🥮🇨🇳" : "🇨🇳") }

        // ── 2026 ──────────────────────────────────────────────
        // 元旦
        map["2026-01-01"] = HolidayInfo(name: "元旦", emoji: "🎍")
        map["2026-01-02"] = HolidayInfo(name: "元旦", emoji: "🎍")
        map["2026-01-03"] = HolidayInfo(name: "元旦", emoji: "🎍")
        // 春节
        for d in 17...23 { map["2026-02-\(String(format: "%02d", d))"] = HolidayInfo(name: "春节", emoji: "🧧") }
        // 清明节
        for d in 4...6 { map["2026-04-\(String(format: "%02d", d))"] = HolidayInfo(name: "清明节", emoji: "🌿") }
        // 劳动节
        for d in 1...5 { map["2026-05-\(String(format: "%02d", d))"] = HolidayInfo(name: "劳动节", emoji: "👷") }
        // 端午节
        for d in 19...21 { map["2026-06-\(String(format: "%02d", d))"] = HolidayInfo(name: "端午节", emoji: "🐲") }
        // 中秋节
        for d in 25...27 { map["2026-09-\(String(format: "%02d", d))"] = HolidayInfo(name: "中秋节", emoji: "🥮") }
        // 国庆节
        for d in 1...7 { map["2026-10-\(String(format: "%02d", d))"] = HolidayInfo(name: "国庆节", emoji: "🇨🇳") }

        return map
    }()

    // MARK: - Compensatory workdays (调休上班)

    private static let workdays: Set<String> = [
        // 2024
        "2024-02-04", "2024-02-18",
        "2024-04-07", "2024-04-28",
        "2024-05-11",
        "2024-09-14", "2024-09-29",
        "2024-10-12",
        // 2025
        "2025-01-26",
        "2025-02-08",
        "2025-04-27",
        "2025-09-28",
        "2025-10-11",
        // 2026
        "2026-01-04",
        "2026-02-14", "2026-02-28",
        "2026-05-09",
        "2026-06-28",
        "2026-10-10",
    ]

    // MARK: - Public API

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return f
    }()

    /// Returns the holiday info for the given date, or `nil` if not a holiday.
    static func holidayInfo(for date: Date) -> HolidayInfo? {
        holidays[keyFormatter.string(from: date)]
    }

    /// Returns `true` if the date is a compensatory workday (调休).
    static func isWorkday(_ date: Date) -> Bool {
        workdays.contains(keyFormatter.string(from: date))
    }

    /// Returns `true` if the date is a statutory holiday.
    static func isHoliday(_ date: Date) -> Bool {
        holidays[keyFormatter.string(from: date)] != nil
    }
}
