import WidgetKit
import SwiftUI
import Darwin

private enum ConfigLocation {
    static var url: URL {
        let homeURL: URL
        if let passwd = getpwuid(getuid()) {
            homeURL = URL(fileURLWithPath: String(cString: passwd.pointee.pw_dir), isDirectory: true)
        } else {
            homeURL = FileManager.default.homeDirectoryForCurrentUser
        }

        return homeURL
            .appendingPathComponent(".claude", isDirectory: true)
            .appendingPathComponent("claude-usage-widget.json", isDirectory: false)
    }
}

// MARK: - API Data Models

struct UsageWindow: Codable {
    let utilization: Int
    let resets_at: String?
}

struct ClaudeUsageResponse: Codable {
    let five_hour: UsageWindow?
    let seven_day: UsageWindow?
    let seven_day_sonnet: UsageWindow?
    let seven_day_opus: UsageWindow?
}

struct ClaudeOrganization: Codable {
    let uuid: String
    let name: String?
}

// MARK: - Config Model

struct WidgetConfig: Codable {
    let sessionKey: String?
    let organizationId: String?
    let oauthToken: String?
}

// MARK: - API Fetcher

struct ClaudeAPIFetcher {
    static func fetchUsage() async -> ClaudeUsageEntry {
        let configPath = ConfigLocation.url

        guard let configData = try? Data(contentsOf: configPath),
              let config = try? JSONDecoder().decode(WidgetConfig.self, from: configData) else {
            return ClaudeUsageEntry(date: Date(), fiveHourUtil: nil, fiveHourResetsAt: nil,
                                    weeklyUtil: nil, weeklyResetsAt: nil,
                                    error: String(localized: "error.noConfig"))
        }

        if let oauthToken = config.oauthToken {
            if let result = await fetchViaOAuth(token: oauthToken) {
                return result
            }
        }

        if let sessionKey = config.sessionKey, let orgId = config.organizationId {
            if let result = await fetchViaSessionKey(sessionKey: sessionKey, orgId: orgId) {
                return result
            }
        }

        return ClaudeUsageEntry(date: Date(), fiveHourUtil: nil, fiveHourResetsAt: nil,
                                weeklyUtil: nil, weeklyResetsAt: nil,
                                error: String(localized: "error.fetchFailed"))
    }

    static func fetchViaOAuth(token: String) async -> ClaudeUsageEntry? {
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        return await performFetch(request: request)
    }

    static func fetchViaSessionKey(sessionKey: String, orgId: String) async -> ClaudeUsageEntry? {
        guard !orgId.contains(".."), !orgId.contains("/"),
              let url = URL(string: "https://claude.ai/api/organizations/\(orgId)/usage") else { return nil }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return await performFetch(request: request)
    }

    static func performFetch(request: URLRequest) async -> ClaudeUsageEntry? {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

            let usage = try JSONDecoder().decode(ClaudeUsageResponse.self, from: data)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let fiveHourReset: Date? = usage.five_hour?.resets_at.flatMap { formatter.date(from: $0) }
            let weeklyReset: Date? = usage.seven_day?.resets_at.flatMap { formatter.date(from: $0) }

            return ClaudeUsageEntry(
                date: Date(),
                fiveHourUtil: usage.five_hour?.utilization,
                fiveHourResetsAt: fiveHourReset,
                weeklyUtil: usage.seven_day?.utilization,
                weeklyResetsAt: weeklyReset,
                error: nil
            )
        } catch {
            return nil
        }
    }
}

// MARK: - Timeline Provider

struct ClaudeUsageProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClaudeUsageEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ClaudeUsageEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        Task {
            let entry = await ClaudeAPIFetcher.fetchUsage()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClaudeUsageEntry>) -> Void) {
        Task {
            let entry = await ClaudeAPIFetcher.fetchUsage()
            let next = Date().addingTimeInterval(5 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

// MARK: - Widget Definition

struct ClaudeUsageWidget: Widget {
    let kind = "ClaudeUsageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClaudeUsageProvider()) { entry in
            ClaudeUsageWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("widget.displayName"))
        .description(Text("widget.description"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
