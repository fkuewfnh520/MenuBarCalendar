import Foundation

enum LunarCalendar {
    private static let chineseCalendar: Calendar = {
        var cal = Calendar(identifier: .chinese)
        cal.locale = Locale(identifier: "zh_CN")
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return cal
    }()

    private static let gregorianCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "zh_CN")
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return cal
    }()

    private static let lunarMonths = [
        "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "冬月", "腊月"
    ]

    private static let lunarDays = [
        "初一", "初二", "初三", "初四", "初五",
        "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五",
        "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五",
        "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    private static let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    private static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    private static let zodiacAnimals = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]

    private static let solarFestivals = [
        101: "元旦",
        214: "情人节",
        308: "妇女节",
        312: "植树节",
        501: "劳动节",
        504: "青年节",
        601: "儿童节",
        701: "建党节",
        801: "建军节",
        910: "教师节",
        1001: "国庆节",
        1224: "平安夜",
        1225: "圣诞节",
    ]

    private static let lunarFestivals = [
        101: "春节",
        115: "元宵节",
        202: "龙抬头",
        505: "端午节",
        707: "七夕节",
        715: "中元节",
        815: "中秋节",
        909: "重阳节",
        1208: "腊八节",
    ]

    private struct SolarTerm {
        let name: String
        let month: Int
        let twentiethCenturyConstant: Double
        let twentyFirstCenturyConstant: Double
    }

    private static let solarTerms: [SolarTerm] = [
        SolarTerm(name: "小寒", month: 1, twentiethCenturyConstant: 6.11, twentyFirstCenturyConstant: 5.4055),
        SolarTerm(name: "大寒", month: 1, twentiethCenturyConstant: 20.84, twentyFirstCenturyConstant: 20.12),
        SolarTerm(name: "立春", month: 2, twentiethCenturyConstant: 4.6295, twentyFirstCenturyConstant: 3.87),
        SolarTerm(name: "雨水", month: 2, twentiethCenturyConstant: 19.4599, twentyFirstCenturyConstant: 18.73),
        SolarTerm(name: "惊蛰", month: 3, twentiethCenturyConstant: 6.3826, twentyFirstCenturyConstant: 5.63),
        SolarTerm(name: "春分", month: 3, twentiethCenturyConstant: 21.4155, twentyFirstCenturyConstant: 20.646),
        SolarTerm(name: "清明", month: 4, twentiethCenturyConstant: 5.59, twentyFirstCenturyConstant: 4.81),
        SolarTerm(name: "谷雨", month: 4, twentiethCenturyConstant: 20.888, twentyFirstCenturyConstant: 20.1),
        SolarTerm(name: "立夏", month: 5, twentiethCenturyConstant: 6.318, twentyFirstCenturyConstant: 5.52),
        SolarTerm(name: "小满", month: 5, twentiethCenturyConstant: 21.86, twentyFirstCenturyConstant: 21.04),
        SolarTerm(name: "芒种", month: 6, twentiethCenturyConstant: 6.5, twentyFirstCenturyConstant: 5.678),
        SolarTerm(name: "夏至", month: 6, twentiethCenturyConstant: 22.2, twentyFirstCenturyConstant: 21.37),
        SolarTerm(name: "小暑", month: 7, twentiethCenturyConstant: 7.928, twentyFirstCenturyConstant: 7.108),
        SolarTerm(name: "大暑", month: 7, twentiethCenturyConstant: 23.65, twentyFirstCenturyConstant: 22.83),
        SolarTerm(name: "立秋", month: 8, twentiethCenturyConstant: 8.35, twentyFirstCenturyConstant: 7.5),
        SolarTerm(name: "处暑", month: 8, twentiethCenturyConstant: 23.95, twentyFirstCenturyConstant: 23.13),
        SolarTerm(name: "白露", month: 9, twentiethCenturyConstant: 8.44, twentyFirstCenturyConstant: 7.646),
        SolarTerm(name: "秋分", month: 9, twentiethCenturyConstant: 23.822, twentyFirstCenturyConstant: 23.042),
        SolarTerm(name: "寒露", month: 10, twentiethCenturyConstant: 9.098, twentyFirstCenturyConstant: 8.318),
        SolarTerm(name: "霜降", month: 10, twentiethCenturyConstant: 24.218, twentyFirstCenturyConstant: 23.438),
        SolarTerm(name: "立冬", month: 11, twentiethCenturyConstant: 8.218, twentyFirstCenturyConstant: 7.438),
        SolarTerm(name: "小雪", month: 11, twentiethCenturyConstant: 23.08, twentyFirstCenturyConstant: 22.36),
        SolarTerm(name: "大雪", month: 12, twentiethCenturyConstant: 7.9, twentyFirstCenturyConstant: 7.18),
        SolarTerm(name: "冬至", month: 12, twentiethCenturyConstant: 22.6, twentyFirstCenturyConstant: 21.94),
    ]

    struct LunarDate {
        let month: Int
        let day: Int
        let isLeapMonth: Bool
        let monthName: String
        let dayName: String
        let yearStemBranch: String
        let zodiac: String
    }

    static func lunarDate(from date: Date) -> LunarDate {
        let comps = chineseCalendar.dateComponents([.year, .month, .day], from: date)
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        let year = comps.year ?? 1
        let isLeapMonth = comps.isLeapMonth ?? false

        let monthIndex = max(0, min(month - 1, lunarMonths.count - 1))
        let dayIndex = max(0, min(day - 1, lunarDays.count - 1))

        let stemIndex = (year - 1) % 10
        let branchIndex = (year - 1) % 12
        let stem = heavenlyStems[max(0, min(stemIndex, 9))]
        let branch = earthlyBranches[max(0, min(branchIndex, 11))]
        let zodiac = zodiacAnimals[max(0, min(branchIndex, 11))]

        return LunarDate(
            month: month,
            day: day,
            isLeapMonth: isLeapMonth,
            monthName: (isLeapMonth ? "闰" : "") + lunarMonths[monthIndex],
            dayName: lunarDays[dayIndex],
            yearStemBranch: "\(stem)\(branch)年",
            zodiac: zodiac
        )
    }

    /// Short display text for a day cell: shows month name on 初一, otherwise day name.
    static func shortText(for date: Date) -> String {
        let lunar = lunarDate(from: date)
        return lunar.day == 1 ? lunar.monthName : lunar.dayName
    }

    /// Festival name for fixed Gregorian dates and traditional lunar dates.
    static func festivalText(for date: Date) -> String? {
        var festivals: [String] = []

        let solarComponents = gregorianCalendar.dateComponents([.month, .day], from: date)
        if let month = solarComponents.month,
           let day = solarComponents.day,
           let festival = solarFestivals[month * 100 + day] {
            festivals.append(festival)
        }

        let lunar = lunarDate(from: date)
        if !lunar.isLeapMonth,
           let festival = lunarFestivals[lunar.month * 100 + lunar.day] {
            festivals.append(festival)
        }

        if let solarTerm = solarTermText(for: date) {
            festivals.append(solarTerm)
        }

        if isLunarNewYearEve(date) {
            festivals.append("除夕")
        }

        guard !festivals.isEmpty else { return nil }
        return festivals.joined(separator: "·")
    }

    /// Day-cell text prefers the festival name over the lunar date.
    static func dayCellText(for date: Date) -> String {
        festivalText(for: date) ?? shortText(for: date)
    }

    /// Full lunar date string, e.g. "甲辰年 腊月初八"
    static func fullText(for date: Date) -> String {
        let lunar = lunarDate(from: date)
        return "\(lunar.yearStemBranch) \(lunar.monthName)\(lunar.dayName)"
    }

    /// Month and day only, e.g. "腊月初八"
    static func monthDayText(for date: Date) -> String {
        let lunar = lunarDate(from: date)
        return "\(lunar.monthName)\(lunar.dayName)"
    }

    static func monthDayAndFestivalText(for date: Date) -> String {
        let monthDay = monthDayText(for: date)
        guard let festival = festivalText(for: date) else { return monthDay }
        return "\(monthDay) · \(festival)"
    }

    private static func isLunarNewYearEve(_ date: Date) -> Bool {
        guard let nextDate = gregorianCalendar.date(byAdding: .day, value: 1, to: date) else {
            return false
        }

        let lunar = lunarDate(from: date)
        let nextLunar = lunarDate(from: nextDate)
        return !lunar.isLeapMonth && nextLunar.month == 1 && nextLunar.day == 1
    }

    private static func solarTermText(for date: Date) -> String? {
        let components = gregorianCalendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day
        else {
            return nil
        }

        return solarTerms.first { term in
            term.month == month && solarTermDay(for: term, year: year) == day
        }?.name
    }

    private static func solarTermDay(for term: SolarTerm, year: Int) -> Int {
        let yearInCentury = year % 100
        let constant = year < 2000 ? term.twentiethCenturyConstant : term.twentyFirstCenturyConstant
        return Int(floor(Double(yearInCentury) * 0.2422 + constant)) - Int(floor(Double(yearInCentury - 1) / 4.0))
    }
}
