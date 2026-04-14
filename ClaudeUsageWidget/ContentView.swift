import SwiftUI
import Darwin

private enum ConfigLocation {
    static var url: URL {
        if let passwd = getpwuid(getuid()) {
            return URL(fileURLWithPath: String(cString: passwd.pointee.pw_dir), isDirectory: true)
                .appendingPathComponent(".claude", isDirectory: true)
                .appendingPathComponent("claude-usage-widget.json", isDirectory: false)
        }

        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude", isDirectory: true)
            .appendingPathComponent("claude-usage-widget.json", isDirectory: false)
    }
}

struct ContentView: View {
    @State private var sessionKey = ""
    @State private var organizationId = ""
    @State private var oauthToken = ""
    @State private var statusMessage = ""
    @State private var isSuccess = false

    private let configURL = ConfigLocation.url

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .font(.title)
                    .foregroundStyle(.purple)
                VStack(alignment: .leading) {
                    Text("app.title")
                        .font(.title2.bold())
                    Text("app.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            // OAuth section
            GroupBox(label: Text("app.oauth.title")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("app.oauth.description")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    TextField(String(localized: "app.oauth.placeholder"), text: $oauthToken)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .monospaced))
                }
                .padding(8)
            }

            GroupBox(label: Text("app.session.title")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("app.session.description")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    TextField(String(localized: "app.session.keyPlaceholder"), text: $sessionKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .monospaced))
                    TextField(String(localized: "app.session.orgPlaceholder"), text: $organizationId)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .monospaced))
                }
                .padding(8)
            }

            // Status
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.callout)
                    .foregroundStyle(isSuccess ? .green : .red)
                    .padding(.horizontal)
            }

            HStack {
                Button(String(localized: "app.button.save")) {
                    saveConfig()
                }
                .buttonStyle(.borderedProminent)

                Button(String(localized: "app.button.load")) {
                    loadConfig()
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Text("app.configPath")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            loadConfig()
        }
    }

    func saveConfig() {
        let config: [String: String?] = [
            "sessionKey": sessionKey.isEmpty ? nil : sessionKey,
            "organizationId": organizationId.isEmpty ? nil : organizationId,
            "oauthToken": oauthToken.isEmpty ? nil : oauthToken
        ]

        do {
            let data = try JSONSerialization.data(
                withJSONObject: config.compactMapValues { $0 },
                options: [.prettyPrinted, .sortedKeys]
            )
            // Ensure .claude directory exists
            let dir = configURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: configURL)
            statusMessage = String(localized: "app.status.saved")
            isSuccess = true
        } catch {
            statusMessage = String(format: String(localized: "app.status.saveFailed"), error.localizedDescription)
            isSuccess = false
        }
    }

    func loadConfig() {
        guard let data = try? Data(contentsOf: configURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return
        }
        sessionKey = json["sessionKey"] ?? ""
        organizationId = json["organizationId"] ?? ""
        oauthToken = json["oauthToken"] ?? ""
    }
}

#Preview {
    ContentView()
}
