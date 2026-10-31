import Foundation

struct ReleaseVersion: Comparable {
    let parts: [Int]
    init?(_ text: String) {
        let value = text.hasPrefix("v") ? String(text.dropFirst()) : text
        let fields = value.split(separator: ".", omittingEmptySubsequences: false)
        guard fields.count == 3 else { return nil }
        var numbers: [Int] = []
        for field in fields {
            guard !field.isEmpty, field.allSatisfy({ $0.isASCII && $0.isNumber }), let number = Int(field) else { return nil }
            numbers.append(number)
        }
        parts = numbers
    }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.parts.lexicographicallyPrecedes(rhs.parts) }
}

struct ReleaseInfo: Decodable {
    let tag_name: String
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]
    struct Asset: Decodable { let name: String; let browser_download_url: String }
    var downloadURL: URL? {
        guard !draft, !prerelease, ReleaseVersion(tag_name) != nil,
              let asset = assets.first(where: { $0.name == "Oraimo-Island-macOS-universal.dmg" }),
              let url = URL(string: asset.browser_download_url), url.scheme == "https", url.host == "github.com",
              url.user == nil, url.password == nil, url.port == nil,
              url.path == "/mooosmad/oraimo-island-mac/releases/download/\(tag_name)/Oraimo-Island-macOS-universal.dmg" else { return nil }
        return url
    }
    func isNewer(than current: String) -> Bool {
        guard let latest = ReleaseVersion(tag_name), let installed = ReleaseVersion(current), downloadURL != nil else { return false }
        return latest > installed
    }
}
