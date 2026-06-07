import Foundation

struct AppVersion {
    static let current = "0.4.0"
    static let versionFileURL = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".KokoroMac")
        .appendingPathComponent("version.txt")
    
    static func getInstalledVersion() -> String? {
        try? String(contentsOf: versionFileURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func markInstalled() {
        let dir = versionFileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? current.write(to: versionFileURL, atomically: true, encoding: .utf8)
    }
    
    static func needsMigration() -> Bool {
        guard let installed = getInstalledVersion() else { return true } // First install
        // Compare semver: if installed < current, migrate
        return compareVersions(installed, current) < 0
    }
    
    private static func compareVersions(_ v1: String, _ v2: String) -> Int {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(parts1.count, parts2.count) {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 < p2 { return -1 }
            if p1 > p2 { return 1 }
        }
        return 0
    }
}
