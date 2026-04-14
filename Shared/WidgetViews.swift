import SwiftUI
import WidgetKit

// MARK: - Shared Data Model

struct ClaudeUsageEntry: TimelineEntry {
    let date: Date
    let fiveHourUtil: Int?
    let fiveHourResetsAt: Date?
    let weeklyUtil: Int?
    let weeklyResetsAt: Date?
    let error: String?

    static var placeholder: ClaudeUsageEntry {
        ClaudeUsageEntry(
            date: Date(),
            fiveHourUtil: 42,
            fiveHourResetsAt: Date().addingTimeInterval(3 * 3600),
            weeklyUtil: 28,
            weeklyResetsAt: Date().addingTimeInterval(3 * 86400),
            error: nil
        )
    }
}

// MARK: - Color Helpers

extension Color {
    static func usageColor(for utilization: Int) -> Color {
        switch utilization {
        case 0..<30: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case 30..<50: return Color(red: 0.4, green: 0.8, blue: 0.3)
        case 50..<65: return Color(red: 0.9, green: 0.8, blue: 0.1)
        case 65..<80: return Color(red: 1.0, green: 0.6, blue: 0.1)
        case 80..<90: return Color(red: 1.0, green: 0.3, blue: 0.2)
        default:      return Color(red: 0.9, green: 0.1, blue: 0.1)
        }
    }

    static func progressGradient(for utilization: Int) -> LinearGradient {
        let color = usageColor(for: utilization)
        return LinearGradient(
            colors: [color.opacity(0.7), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Subviews

struct UsageProgressBar: View {
    let utilization: Int
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.white.opacity(0.1))

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.progressGradient(for: utilization))
                    .frame(width: max(0, geo.size.width * CGFloat(utilization) / 100.0))
            }
        }
        .frame(height: height)
    }
}

struct CountdownText: View {
    let resetsAt: Date?
    let label: String

    var body: some View {
        if let reset = resetsAt {
            let remaining = reset.timeIntervalSince(Date())
            if remaining > 0 {
                let hours = Int(remaining) / 3600
                let minutes = (Int(remaining) % 3600) / 60
                let h = String(localized: "time.hour")
                let m = String(localized: "time.minute")
                if hours > 0 {
                    Text("\(label) \(hours)\(h) \(minutes)\(m)")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(label) \(minutes)\(m)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("\(label) \(String(localized: "countdown.now"))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Small Widget View

struct ClaudeUsageSmallView: View {
    let entry: ClaudeUsageEntry

    var body: some View {
        if let error = entry.error {
            VStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text(error)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(12)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("Claude")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    if let util = entry.fiveHourUtil {
                        Text("\(util)%")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.usageColor(for: util))
                    }
                }

                if let util = entry.fiveHourUtil {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("label.fiveHourSession")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        UsageProgressBar(utilization: util, height: 6)
                    }
                }

                if let weekly = entry.weeklyUtil {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("label.weekly")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        UsageProgressBar(utilization: weekly, height: 5)
                    }
                }

                Spacer(minLength: 0)
                CountdownText(resetsAt: entry.fiveHourResetsAt,
                              label: String(localized: "countdown.reset"))
            }
            .padding(12)
        }
    }
}

// MARK: - Medium Widget View

struct ClaudeUsageMediumView: View {
    let entry: ClaudeUsageEntry

    var body: some View {
        if let error = entry.error {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            HStack(spacing: 16) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: CGFloat(entry.fiveHourUtil ?? 0) / 100.0)
                            .stroke(
                                Color.usageColor(for: entry.fiveHourUtil ?? 0),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(entry.fiveHourUtil ?? 0)%")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.usageColor(for: entry.fiveHourUtil ?? 0))
                        }
                    }
                    .frame(width: 70, height: 70)

                    Text("label.fiveHourSession")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("label.claudeUsage")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("label.weekly")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(entry.weeklyUtil ?? 0)%")
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.usageColor(for: entry.weeklyUtil ?? 0))
                        }
                        UsageProgressBar(utilization: entry.weeklyUtil ?? 0, height: 5)
                    }

                    CountdownText(resetsAt: entry.fiveHourResetsAt,
                                  label: String(localized: "countdown.fiveHourReset"))
                    CountdownText(resetsAt: entry.weeklyResetsAt,
                                  label: String(localized: "countdown.weeklyReset"))

                    Spacer(minLength: 0)
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Large Widget View

struct ClaudeUsageLargeView: View {
    let entry: ClaudeUsageEntry

    var body: some View {
        if let error = entry.error {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("error.configPathLabel")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Text("~/.claude/claude-usage-widget.json")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding()
        } else {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.usageColor(for: entry.fiveHourUtil ?? 0))
                            .frame(width: 4, height: 18)
                        Text("label.claudeUsageMonitor")
                            .font(.system(size: 16, weight: .bold))
                    }
                    Spacer()
                    Text(entry.date, style: .time)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 14)

                UsageCard(
                    title: String(localized: "label.fiveHourTitle"),
                    utilization: entry.fiveHourUtil ?? 0,
                    resetsAt: entry.fiveHourResetsAt,
                    barHeight: 10
                )
                .padding(.bottom, 12)

                UsageCard(
                    title: String(localized: "label.weeklyUsage"),
                    utilization: entry.weeklyUtil ?? 0,
                    resetsAt: entry.weeklyResetsAt,
                    barHeight: 8
                )
                .padding(.bottom, 12)

                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    StatBox(label: String(localized: "label.fiveHour"),
                            value: "\(entry.fiveHourUtil ?? 0)%",
                            color: Color.usageColor(for: entry.fiveHourUtil ?? 0))
                    Divider().frame(height: 30).padding(.horizontal, 8)
                    StatBox(label: String(localized: "label.weekly"),
                            value: "\(entry.weeklyUtil ?? 0)%",
                            color: Color.usageColor(for: entry.weeklyUtil ?? 0))
                    Divider().frame(height: 30).padding(.horizontal, 8)
                    StatBox(label: String(localized: "label.status"),
                            value: statusText(for: entry.fiveHourUtil ?? 0),
                            color: Color.usageColor(for: entry.fiveHourUtil ?? 0))
                }
            }
            .padding(16)
        }
    }

    func statusText(for util: Int) -> String {
        switch util {
        case 0..<30: return String(localized: "status.low")
        case 30..<60: return String(localized: "status.normal")
        case 60..<80: return String(localized: "status.high")
        case 80..<95: return String(localized: "status.heavy")
        default: return String(localized: "status.limit")
        }
    }
}

struct UsageCard: View {
    let title: String
    let utilization: Int
    let resetsAt: Date?
    let barHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(utilization)%")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.usageColor(for: utilization))
            }
            UsageProgressBar(utilization: utilization, height: barHeight)
            CountdownText(resetsAt: resetsAt,
                          label: String(localized: "countdown.resetsIn"))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget View Dispatcher

struct ClaudeUsageWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: ClaudeUsageEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                ClaudeUsageSmallView(entry: entry)
            case .systemMedium:
                ClaudeUsageMediumView(entry: entry)
            case .systemLarge:
                ClaudeUsageLargeView(entry: entry)
            default:
                ClaudeUsageLargeView(entry: entry)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Previews (macOS widget sizes: Small 158x158, Medium 330x158, Large 330x345)

#Preview("Small") {
    ClaudeUsageSmallView(entry: .placeholder)
        .frame(width: 158, height: 158)
        .background(.fill.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
}

#Preview("Medium") {
    ClaudeUsageMediumView(entry: .placeholder)
        .frame(width: 330, height: 158)
        .background(.fill.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
}

#Preview("Large") {
    ClaudeUsageLargeView(entry: .placeholder)
        .frame(width: 330, height: 345)
        .background(.fill.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
}
