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
}
