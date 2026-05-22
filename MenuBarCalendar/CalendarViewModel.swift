import Foundation
import SwiftUI

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
}

// MARK: - CalendarViewModel

final class CalendarViewModel: ObservableObject {
    @Published var days: [DayItem] = []
    @Published var monthYearTitle: String = ""
    @Published var selectedDate: Date?
    @Published var selectedHolidayInfo: HolidayInfo?

    private var displayedMonth: Date
    private let calendar: Calendar
    private let today: Date

    init() {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "zh_CN")
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        self.calendar = cal
        self.today = Date()
        self.displayedMonth = today
        buildMonth()
    }

    // MARK: - Navigation

    func moveToNextMonth() {
        guard let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = next
        buildMonth()
    }

    func moveToPreviousMonth() {
        guard let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = prev
        buildMonth()
    }

    func goToToday() {
        displayedMonth = today
        selectedDate = nil
        selectedHolidayInfo = nil
        buildMonth()
    }

    func select(_ day: DayItem) {
        selectedDate = day.date
        selectedHolidayInfo = day.holidayInfo
    }

    // MARK: - Build Month Grid

    private func buildMonth() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        monthYearTitle = formatter.string(from: displayedMonth)

        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return }

        // Sunday = 1 in Gregorian; our grid starts on Sunday
        let leadingEmptyDays = firstWeekday - 1

        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)!.count
        let totalCells = leadingEmptyDays + daysInMonth
        let rows = (totalCells + 6) / 7
        let gridSize = rows * 7

        var items: [DayItem] = []

        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)

        for i in 0 ..< gridSize {
            let offset = i - leadingEmptyDays
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
                isCompensatoryWorkday: ChineseHolidays.isWorkday(date)
            ))
        }

        days = items
    }
}
