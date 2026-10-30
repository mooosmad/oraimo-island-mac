import Foundation

/// Model presentation is independent of Bluetooth battery sources.
enum OraimoProduct: String, Equatable {
    case spaceBuds = "spacebuds-lite-2"
    case boomPop = "boompop-pro"
    case watch6Nano = "watch-6-nano"
    case unknown = "oraimo-generic"

    init(name: String) {
        let name = name.lowercased()
        guard name.contains("oraimo") else { self = .unknown; return }
        if name.range(of: #"\bwatch\s+6\s+nano(?:$|[^a-z0-9])"#, options: .regularExpression) != nil {
            self = .watch6Nano
        } else if name.contains("boompop") {
            self = .boomPop
        } else if name.contains("spacebuds") {
            self = .spaceBuds
        } else {
            self = .unknown
        }
    }

    var symbol: String {
        switch self {
        case .spaceBuds: return "earbuds"
        case .boomPop: return "headphones"
        case .watch6Nano: return "applewatch"
        case .unknown: return "antenna.radiowaves.left.and.right"
        }
    }
    var asset: String { rawValue }
    var photoDescription: String {
        switch self {
        case .spaceBuds: return "oraimo SpaceBuds Lite 2 et leur boîtier"
        case .boomPop: return "Casque oraimo BoomPop Pro"
        case .watch6Nano: return "Montre oraimo Watch 6 Nano"
        case .unknown: return "Appareil Oraimo"
        }
    }
    var connectionHeadline: String {
        self == .watch6Nano ? "Montre connectée" : "Oraimo connectés"
    }
    var disconnectionHeadline: String {
        self == .watch6Nano ? "Montre déconnectée" : "Oraimo déconnectés"
    }
    var connectedDescription: String {
        self == .watch6Nano ? "Connectée à ton Mac" : "Connectés à ton Mac"
    }
    var connectionPrompt: String {
        self == .watch6Nano ? "Connecte ta montre en Bluetooth" : "Connecte ton appareil Oraimo en Bluetooth"
    }
}
