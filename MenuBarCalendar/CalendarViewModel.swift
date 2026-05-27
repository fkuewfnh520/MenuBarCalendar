import Foundation
import SwiftUI
import Combine

// MARK: - DayItem

struct DayItem: Identifiable {
    let id: String
    let date: Date
    let dayNumber: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let isWeekend: Bool
    let holidayInfo: HolidayInfo?
    let isCompensatoryWorkday: Bool
    let lunarText: String
    let festivalText: String?
}

// MARK: - CalendarViewModel

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var days: [DayItem] = []
    @Published var monthTitle: String = ""
    @Published var displayedYear: Int = 2025
    @Published var yearRange: [Int] = []
    @Published var weekdaySymbols: [String] = []
    @Published var selectedDate: Date?
    @Published var selectedHolidayInfo: HolidayInfo?

    // Bottom bar
    @Published var currentTimeString: String = ""
    @Published var currentWeekdayString: String = ""
    @Published var currentDateString: String = ""
    @Published var currentLunarString: String = ""

    /// The date shown in the bottom bar; nil means "now" (live clock).
    private var bottomBarDate: Date?

    private var displayedMonth: Date
    private var calendar: Calendar
    private let today: Date
    private var timer: Timer?
    private var weekStartsOnMonday: Bool
    private var cancellables = Set<AnyCancellable>()

    init() {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "zh_CN")
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        self.calendar = cal
        self.today = Date()
        self.displayedMonth = today
        self.weekStartsOnMonday = AppSettings.shared.weekStartsOn == 1

        if weekStartsOnMonday {
            self.calendar.firstWeekday = 2
        }

        let currentYear = calendar.component(.year, from: today)
        self.displayedYear = currentYear
        self.yearRange = Array((currentYear - 50)...(currentYear + 50))

        updateWeekdaySymbols()
        bindHolidayUpdates()
        HolidayStore.shared.ensureYearAvailable(currentYear)
        buildMonth()
        updateBottomBar()
        startTimer()
    }

    private func bindHolidayUpdates() {
        HolidayStore.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.buildMonth()
            }
            .store(in: &cancellables)
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateBottomBar()
            }
        }
    }

    private func updateBottomBar() {
        let now = Date()
        let displayDate = bottomBarDate ?? now

        let settings = AppSettings.shared

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
        currentTimeString = timeFormatter.string(from: now)

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "zh_CN")
        weekdayFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        weekdayFormatter.dateFormat = "EEEE"
        currentWeekdayString = weekdayFormatter.string(from: displayDate)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        dateFormatter.dateFormat = "yyyy年M月d日"
        currentDateString = dateFormatter.string(from: displayDate)

        currentLunarString = LunarCalendar.monthDayAndFestivalText(for: displayDate)
    }

    // MARK: - Week Start

    func updateWeekStart(_ value: Int) {
        weekStartsOnMonday = value == 1
        calendar.firstWeekday = weekStartsOnMonday ? 2 : 1
        updateWeekdaySymbols()
        buildMonth()
    }

    private func updateWeekdaySymbols() {
        if weekStartsOnMonday {
            weekdaySymbols = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        } else {
            weekdaySymbols = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        }
    }

    // MARK: - Navigation

    func moveToNextMonth() {
        guard let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = next
        displayedYear = calendar.component(.year, from: displayedMonth)
        HolidayStore.shared.ensureYearAvailable(displayedYear)
        buildMonth()
    }

    func moveToPreviousMonth() {
        guard let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = prev
        displayedYear = calendar.component(.year, from: displayedMonth)
        HolidayStore.shared.ensureYearAvailable(displayedYear)
        buildMonth()
    }

    func setYear(_ year: Int) {
        let currentMonth = calendar.component(.month, from: displayedMonth)
        var comps = DateComponents()
        comps.year = year
        comps.month = currentMonth
        comps.day = 1
        if let newDate = calendar.date(from: comps) {
            displayedMonth = newDate
            displayedYear = year
            HolidayStore.shared.ensureYearAvailable(year)
            buildMonth()
        }
    }

    func goToToday() {
        displayedMonth = today
        displayedYear = calendar.component(.year, from: today)
        HolidayStore.shared.ensureYearAvailable(displayedYear)
        selectedDate = nil
        selectedHolidayInfo = nil
        bottomBarDate = nil
        buildMonth()
        updateBottomBar()
    }

    func select(_ day: DayItem) {
        selectedDate = day.date
        selectedHolidayInfo = day.holidayInfo
        bottomBarDate = day.date
        updateBottomBar()
    }

    // MARK: - Build Month Grid

    private func buildMonth() {
        let month = calendar.component(.month, from: displayedMonth)
        monthTitle = "\(month)月"

        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return }

        // Calculate leading empty days based on first weekday setting
        let firstDayOffset: Int
        if weekStartsOnMonday {
            // Monday=2 -> offset 0, Tuesday=3 -> offset 1, ..., Sunday=1 -> offset 6
            firstDayOffset = (firstWeekday + 5) % 7
        } else {
            // Sunday=1 -> offset 0, Monday=2 -> offset 1, ...
            firstDayOffset = firstWeekday - 1
        }

        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)!.count
        let totalCells = firstDayOffset + daysInMonth
        let rows = (totalCells + 6) / 7
        let gridSize = rows * 7

        var items: [DayItem] = []

        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)

        for i in 0 ..< gridSize {
            let offset = i - firstDayOffset
            guard let date = calendar.date(byAdding: .day, value: offset, to: monthInterval.start) else { continue }

            let comps = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
            let isCurrentMonth = offset >= 0 && offset < daysInMonth
            let isToday = comps.year == todayComponents.year
                && comps.month == todayComponents.month
                && comps.day == todayComponents.day
            let isWeekend = comps.weekday == 1 || comps.weekday == 7

            items.append(DayItem(
                id: "\(comps.year!)-\(comps.month!)-\(comps.day!)",
                date: date,
                dayNumber: comps.day!,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isWeekend: isWeekend,
                holidayInfo: ChineseHolidays.holidayInfo(for: date),
                isCompensatoryWorkday: ChineseHolidays.isWorkday(date),
                lunarText: LunarCalendar.dayCellText(for: date),
                festivalText: LunarCalendar.festivalText(for: date)
            ))
        }

        days = items
    }
}
