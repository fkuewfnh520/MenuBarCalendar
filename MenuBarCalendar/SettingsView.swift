import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                tabButton("通用", icon: "gearshape", tag: 0)
                tabButton("样式", icon: "paintpalette", tag: 1)
                tabButton("状态栏", icon: "menubar.rectangle", tag: 2)
            }
            .padding(.horizontal, 12)

            Divider()
                .padding(.top, 8)

            // Tab content
            Group {
                switch selectedTab {
                case 0: generalTab
                case 1: styleTab
                case 2: statusBarTab
                default: EmptyView()
                }
            }
            .padding(16)
        }
        .frame(width: 360, height: 380)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Tab Button

    private func tabButton(_ title: String, icon: String, tag: Int) -> some View {
        Button(action: { selectedTab = tag }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 11))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundColor(selectedTab == tag ? settings.currentThemeColor : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTab == tag ? settings.currentThemeColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsSection("启动") {
                Toggle("开机自动启动", isOn: $settings.launchAtLogin)
            }

            settingsSection("日历") {
                Picker("一周开始于", selection: $settings.weekStartsOn) {
                    Text("周日").tag(0)
                    Text("周一").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            settingsSection("通知") {
                Toggle("推送通知", isOn: $settings.pushNotifications)
            }

            Spacer()
        }
    }

    // MARK: - Style Tab

    private var styleTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("主题颜色")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                ForEach(0 ..< AppSettings.themeColors.count, id: \.self) { index in
                    let theme = AppSettings.themeColors[index]
                    ZStack {
                        Circle()
                            .fill(theme.color)
                            .frame(width: 36, height: 36)

                        if settings.accentColorIndex == index {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .onTapGesture { settings.accentColorIndex = index }
                    .overlay(
                        Circle()
                            .stroke(settings.accentColorIndex == index ? theme.color : Color.clear, lineWidth: 2)
                            .frame(width: 42, height: 42)
                    )
                }
            }

            Text(AppSettings.themeColors[max(0, min(settings.accentColorIndex, AppSettings.themeColors.count - 1))].name)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
        }
    }

    // MARK: - Status Bar Tab

    private var statusBarTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsSection("图标") {
                    Toggle("显示图标", isOn: $settings.showIcon)
                }

                settingsSection("时间选项") {
                    Toggle("使用24小时格式", isOn: $settings.use24HourFormat)
                    if !settings.use24HourFormat {
                        Toggle("显示上午/下午", isOn: $settings.showAMPM)
                    }
                    Toggle("时间精确到秒", isOn: $settings.showSeconds)
                }

                settingsSection("日期选项") {
                    Toggle("显示农历", isOn: $settings.showLunarInStatusBar)
                    Toggle("显示阳历", isOn: $settings.showSolarInStatusBar)
                    Toggle("显示星期几", isOn: $settings.showWeekdayInStatusBar)
                }
            }
        }
    }

    // MARK: - Helper

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            content()
                .font(.system(size: 13))
        }
    }
}
