import Foundation

let defaultHolidaySubscriptionURLTemplate = "https://www.shuyz.com/githubfiles/china-holiday-calender/master/holidayAPI.json"

/// Represents a Chinese statutory holiday.
struct HolidayInfo: Codable, Equatable {
    let name: String
    let emoji: String
}

struct HolidayUpdateStatus: Equatable {
    var isUpdating: Bool = false
    var lastUpdatedAt: Date?
    var lastError: String?
}

/// Manages Chinese statutory holiday data.
///
/// The app keeps a bundled 2024-2026 fallback, then overlays data fetched from
/// the configured subscription URL and cached by year on disk.
@MainActor
final class HolidayStore: ObservableObject {
    static let shared = HolidayStore()

    static let defaultSubscriptionURLTemplate = defaultHolidaySubscriptionURLTemplate
    static let icalSubscriptionURL = "https://www.shuyz.com/githubfiles/china-holiday-calender/master/holidayCal.ics"

    @Published private(set) var status = HolidayUpdateStatus()

    private var remoteHolidays: [String: HolidayInfo] = [:]
    private var remoteWorkdays: Set<String> = []
    private var loadedYears: Set<Int> = []
    private var loadingYears: Set<Int> = []
    private var updateTimer: Timer?

    private let decoder = JSONDecoder()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private init() {
        loadCachedYearsAroundToday()
        startAutomaticUpdates()
    }

    // MARK: - Public API

    func holidayInfo(for date: Date) -> HolidayInfo? {
        let key = Self.dateFormatter.string(from: date)
        return remoteHolidays[key] ?? Self.bundledHolidays[key]
    }

    func isWorkday(_ date: Date) -> Bool {
        let key = Self.dateFormatter.string(from: date)
        guard !Self.nonWorkdayCorrections.contains(key) else { return false }
        return remoteWorkdays.contains(key) || Self.bundledWorkdays.contains(key)
    }

    func isHoliday(_ date: Date) -> Bool {
        holidayInfo(for: date) != nil
    }

    func ensureYearAvailable(_ year: Int) {
        guard !loadedYears.contains(year), !loadingYears.contains(year) else { return }

        if loadCachedYear(year) {
            return
        }

        Task {
            await refreshYear(year)
        }
    }

    func refreshYearsAroundToday() {
        let currentYear = Self.calendar.component(.year, from: Date())
        let years = Array((currentYear - 5)...(currentYear + 1))
        Task {
            await refreshYears(years, force: true)
        }
    }

    // MARK: - Refresh

    private func startAutomaticUpdates() {
        refreshYearsAroundTodayIfNeeded()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 12 * 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshYearsAroundTodayIfNeeded()
            }
        }
    }

    private func refreshYearsAroundTodayIfNeeded() {
        guard shouldRefresh else { return }

        let currentYear = Self.calendar.component(.year, from: Date())
        let years = Array((currentYear - 5)...(currentYear + 1))
        Task {
            await refreshYears(years, force: false)
        }
    }

    private var shouldRefresh: Bool {
        guard let lastUpdatedAt = AppSettings.shared.holidayLastUpdatedAt else { return true }
        return Date().timeIntervalSince(lastUpdatedAt) >= 24 * 60 * 60
    }

    private func refreshYears(_ years: [Int], force: Bool) async {
        if !force, !shouldRefresh {
            return
        }

        status.isUpdating = true
        status.lastError = nil

        var refreshedAnyYear = false
        var lastFailure: Error?

        for year in years {
            do {
                try await fetchAndCacheYear(year)
                refreshedAnyYear = true
            } catch {
                lastFailure = error
            }
        }

        if refreshedAnyYear {
            let now = Date()
            AppSettings.shared.holidayLastUpdatedAt = now
            status.lastUpdatedAt = now
        }

        status.isUpdating = false
        status.lastError = lastFailure.map { "节假日更新失败：\($0.localizedDescription)" }
    }

    private func refreshYear(_ year: Int) async {
        do {
            loadingYears.insert(year)
            try await fetchAndCacheYear(year)
            loadingYears.remove(year)
            status.lastError = nil
        } catch {
            loadingYears.remove(year)
            status.lastError = "节假日更新失败：\(error.localizedDescription)"
        }
    }

    private func fetchAndCacheYear(_ year: Int) async throws {
        let template = AppSettings.shared.holidaySubscriptionURLTemplate
        let urlString = template.contains("%d") ? String(format: template, year) : template
        guard let url = URL(string: urlString) else {
            throw HolidayStoreError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.setValue("application/json,text/plain,*/*", forHTTPHeaderField: "Accept")
        request.setValue("MenuBarCalendar/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw HolidayStoreError.httpStatus(httpResponse.statusCode)
        }

        let yearData = try decodeYearData(from: data, year: year)
        merge(yearData, year: year)
        try cache(yearData, for: year)
    }

    // MARK: - Cache

    private func loadCachedYearsAroundToday() {
        let currentYear = Self.calendar.component(.year, from: Date())
        for year in (currentYear - 5)...(currentYear + 1) {
            _ = loadCachedYear(year)
        }

        status.lastUpdatedAt = AppSettings.shared.holidayLastUpdatedAt
    }

    @discardableResult
    private func loadCachedYear(_ year: Int) -> Bool {
        guard !loadedYears.contains(year),
              let data = try? Data(contentsOf: cacheURL(for: year)),
              let yearData = try? decoder.decode(HolidayYearData.self, from: data)
        else {
            return false
        }

        merge(yearData, year: year)
        return true
    }

    private func cache(_ yearData: HolidayYearData, for year: Int) throws {
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let data = try encoder.encode(yearData)
        try data.write(to: cacheURL(for: year), options: .atomic)
    }

    private var cacheDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("MenuBarCalendar/Holidays", isDirectory: true)
    }

    private func cacheURL(for year: Int) -> URL {
        cacheDirectory.appendingPathComponent("\(year).json")
    }

    // MARK: - Merge

    private func merge(_ yearData: HolidayYearData, year: Int) {
        for (date, name) in yearData.holidays {
            remoteHolidays[date] = HolidayInfo(name: name, emoji: Self.emoji(for: name))
            remoteWorkdays.remove(date)
        }

        for date in yearData.workdays {
            guard !Self.nonWorkdayCorrections.contains(date) else { continue }
            remoteWorkdays.insert(date)
            remoteHolidays.removeValue(forKey: date)
        }

        loadedYears.insert(year)
        objectWillChange.send()
    }

    private func decodeYearData(from data: Data, year: Int) throws -> HolidayYearData {
        if let shuyzData = try? decoder.decode(ShuYZHolidayData.self, from: data),
           let holidays = shuyzData.years["\(year)"] {
            return HolidayYearData(from: holidays)
        }

        if (try? decoder.decode(ShuYZHolidayData.self, from: data)) != nil {
            return HolidayYearData(holidays: [:], workdays: [])
        }

        if let chineseDaysData = try? decoder.decode(ChineseDaysYearData.self, from: data) {
            return HolidayYearData(from: chineseDaysData)
        }

        throw HolidayStoreError.unsupportedFormat
    }

    private static func emoji(for name: String) -> String {
        if name.contains("春节") { return "🧧" }
        if name.contains("清明") { return "🌿" }
        if name.contains("劳动") { return "👷" }
        if name.contains("端午") { return "🐲" }
        if name.contains("中秋") { return "🥮" }
        if name.contains("国庆") { return "🇨🇳" }
        if name.contains("元旦") { return "🎍" }
        return "🎌"
    }

    // MARK: - Formatters

    fileprivate static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }()

    fileprivate static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter
    }()

    // MARK: - Bundled fallback data

    private static let bundledHolidays: [String: HolidayInfo] = {
        var map = [String: HolidayInfo]()

        map["2024-01-01"] = HolidayInfo(name: "元旦", emoji: "🎍")
        for d in 10...17 { map["2024-02-\(String(format: "%02d", d))"] = HolidayInfo(name: "春节", emoji: "🧧") }
        for d in 4...6 { map["2024-04-\(String(format: "%02d", d))"] = HolidayInfo(name: "清明节", emoji: "🌿") }
        for d in 1...5 { map["2024-05-\(String(format: "%02d", d))"] = HolidayInfo(name: "劳动节", emoji: "👷") }
        for d in 8...10 { map["2024-06-\(String(format: "%02d", d))"] = HolidayInfo(name: "端午节", emoji: "🐲") }
        for d in 15...17 { map["2024-09-\(String(format: "%02d", d))"] = HolidayInfo(name: "中秋节", emoji: "🥮") }
        for d in 1...7 { map["2024-10-\(String(format: "%02d", d))"] = HolidayInfo(name: "国庆节", emoji: "🇨🇳") }

        map["2025-01-01"] = HolidayInfo(name: "元旦", emoji: "🎍")
        for d in 28...31 { map["2025-01-\(String(format: "%02d", d))"] = HolidayInfo(name: "春节", emoji: "🧧") }
        for d in 1...4 { map["2025-02-\(String(format: "%02d", d))"] = HolidayInfo(name: "春节", emoji: "🧧") }
        for d in 4...6 { map["2025-04-\(String(format: "%02d", d))"] = HolidayInfo(name: "清明节", emoji: "🌿") }
        for d in 1...5 { map["2025-05-\(String(format: "%02d", d))"] = HolidayInfo(name: "劳动节", emoji: "👷") }
        map["2025-05-31"] = HolidayInfo(name: "端午节", emoji: "🐲")
        for d in 1...2 { map["2025-06-\(String(format: "%02d", d))"] = HolidayInfo(name: "端午节", emoji: "🐲") }
        for d in 1...8 { map["2025-10-\(String(format: "%02d", d))"] = HolidayInfo(name: d <= 3 ? "中秋节·国庆节" : "国庆节", emoji: d <= 3 ? "🥮🇨🇳" : "🇨🇳") }

        map["2026-01-01"] = HolidayInfo(name: "元旦", emoji: "🎍")
        map["2026-01-02"] = HolidayInfo(name: "元旦", emoji: "🎍")
        map["2026-01-03"] = HolidayInfo(name: "元旦", emoji: "🎍")
        for d in 17...23 { map["2026-02-\(String(format: "%02d", d))"] = HolidayInfo(name: "春节", emoji: "🧧") }
        for d in 4...6 { map["2026-04-\(String(format: "%02d", d))"] = HolidayInfo(name: "清明节", emoji: "🌿") }
        for d in 1...5 { map["2026-05-\(String(format: "%02d", d))"] = HolidayInfo(name: "劳动节", emoji: "👷") }
        for d in 19...21 { map["2026-06-\(String(format: "%02d", d))"] = HolidayInfo(name: "端午节", emoji: "🐲") }
        for d in 25...27 { map["2026-09-\(String(format: "%02d", d))"] = HolidayInfo(name: "中秋节", emoji: "🥮") }
        for d in 1...7 { map["2026-10-\(String(format: "%02d", d))"] = HolidayInfo(name: "国庆节", emoji: "🇨🇳") }

        return map
    }()

    private static let bundledWorkdays: Set<String> = [
        "2024-02-04", "2024-02-18",
        "2024-04-07", "2024-04-28",
        "2024-05-11",
        "2024-09-14", "2024-09-29",
        "2024-10-12",
        "2025-01-26",
        "2025-02-08",
        "2025-04-27",
        "2025-09-28",
        "2025-10-11",
        "2026-01-04",
        "2026-02-14", "2026-02-28",
        "2026-05-09",
        "2026-10-10",
    ]

    private static let nonWorkdayCorrections: Set<String> = [
        "2026-06-28",
    ]
}

@MainActor
enum ChineseHolidays {
    static func holidayInfo(for date: Date) -> HolidayInfo? {
        HolidayStore.shared.holidayInfo(for: date)
    }

    static func isWorkday(_ date: Date) -> Bool {
        HolidayStore.shared.isWorkday(date)
    }

    static func isHoliday(_ date: Date) -> Bool {
        HolidayStore.shared.isHoliday(date)
    }
}

private struct ChineseDaysYearData: Decodable {
    let holidays: [String: String]
    let workdays: [String: String]
}

private struct HolidayYearData: Codable {
    let holidays: [String: String]
    let workdays: Set<String>

    init(holidays: [String: String], workdays: Set<String>) {
        self.holidays = holidays
        self.workdays = workdays
    }

    init(from source: ChineseDaysYearData) {
        var holidays = [String: String]()
        for (date, rawValue) in source.holidays {
            if let day = ChineseDaysEntry(rawValue: rawValue) {
                holidays[date] = day.name
            }
        }

        self.holidays = holidays
        self.workdays = Set(source.workdays.keys)
    }

    init(from source: [ShuYZHoliday]) {
        var holidays = [String: String]()
        var workdays = Set<String>()

        for holiday in source {
            for date in Self.dates(from: holiday.startDate, through: holiday.endDate) {
                holidays[date] = holiday.name
            }
            workdays.formUnion(holiday.compDays)
        }

        self.holidays = holidays
        self.workdays = workdays
    }

    private static func dates(from start: String, through end: String) -> [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

        guard let startDate = formatter.date(from: start),
              let endDate = formatter.date(from: end)
        else {
            return []
        }

        var dates: [String] = []
        var current = startDate
        while current <= endDate {
            dates.append(formatter.string(from: current))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }
}

private struct ShuYZHolidayData: Decodable {
    let years: [String: [ShuYZHoliday]]

    private enum CodingKeys: String, CodingKey {
        case years = "Years"
    }
}

private struct ShuYZHoliday: Decodable {
    let name: String
    let startDate: String
    let endDate: String
    let compDays: [String]

    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case startDate = "StartDate"
        case endDate = "EndDate"
        case compDays = "CompDays"
    }
}

private struct ChineseDaysEntry {
    let name: String

    init?(rawValue: String) {
        let parts = rawValue.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 2 else { return nil }
        self.name = parts[1]
    }
}

private enum HolidayStoreError: LocalizedError {
    case invalidURL(String)
    case httpStatus(Int)
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "无效订阅地址：\(url)"
        case .httpStatus(let statusCode):
            return "服务器返回状态码 \(statusCode)"
        case .unsupportedFormat:
            return "订阅数据格式不受支持"
        }
    }
}
