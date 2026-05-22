import SwiftUI

// MARK: - CalendarView

struct CalendarView: View {
    @StateObject private var vm = CalendarViewModel()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 8) {
            headerView
            weekdayHeader
            daysGrid
            if let info = vm.selectedHolidayInfo {
                holidayBanner(info)
            }
        }
        .padding(12)
        .frame(width: 340, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button(action: { vm.moveToPreviousMonth() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(vm.monthYearTitle)
                .font(.system(size: 16, weight: .bold))

            Spacer()

            Button(action: { vm.goToToday() }) {
                Text("今天")
                    .font(.system(size: 12))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)

            Button(action: { vm.moveToNextMonth() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(day == "日" || day == "六" ? .red.opacity(0.7) : .secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Days Grid

    private var daysGrid: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(vm.days) { day in
                DayCellView(day: day, isSelected: vm.selectedDate == day.date)
                    .onTapGesture { vm.select(day) }
            }
        }
    }

    // MARK: - Holiday Banner

    private func holidayBanner(_ info: HolidayInfo) -> some View {
        HStack(spacing: 6) {
            Text(info.emoji)
                .font(.system(size: 16))
            Text(info.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            Spacer()
            Text("法定节假日")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.red.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - DayCellView

struct DayCellView: View {
    let day: DayItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                if day.isToday {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 30, height: 30)
                }
                if isSelected && !day.isToday {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 1.5)
                        .frame(width: 30, height: 30)
                }

                Text("\(day.dayNumber)")
                    .font(.system(size: 14, weight: day.isToday ? .bold : .regular))
                    .foregroundColor(dayTextColor)
            }

            // Holiday/workday indicator
            if day.isCurrentMonth {
                if day.holidayInfo != nil {
                    Text("休")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 14, height: 14)
                        .background(Color.green)
                        .cornerRadius(2)
                } else if day.isCompensatoryWorkday {
                    Text("班")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 14, height: 14)
                        .background(Color.orange)
                        .cornerRadius(2)
                } else {
                    Color.clear.frame(width: 14, height: 14)
                }
            } else {
                Color.clear.frame(width: 14, height: 14)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(Rectangle())
    }

    private var dayTextColor: Color {
        if day.isToday { return .white }
        if !day.isCurrentMonth { return .secondary.opacity(0.4) }
        if day.holidayInfo != nil { return .green }
        if day.isWeekend && !day.isCompensatoryWorkday { return .red.opacity(0.7) }
        return .primary
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
