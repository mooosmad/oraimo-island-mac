import Foundation

struct DeviceSnapshot: Equatable {
    var name: String
    var connected: Bool
    var battery: Int?
    var caseBattery: Int? = nil
    var leftBattery: Int? = nil
    var rightBattery: Int? = nil
    var address: String = ""
    var levels: BatteryValues { BatteryValues(main: battery, left: leftBattery, right: rightBattery, caseLevel: caseBattery) }
    var lowestListeningLevel: Int? { [battery, leftBattery, rightBattery].compactMap { $0 }.min() }
}

enum DeviceSelection {
    static func current(in inventory: [DeviceSnapshot], selected: String?, route: String, previous: String?) -> DeviceSnapshot? {
        let connected = inventory.filter { $0.connected }
        if let device = connected.first(where: { $0.address == selected }) { return device }
        if let device = connected.first(where: { $0.name.caseInsensitiveCompare(route) == .orderedSame }) { return device }
        if let device = connected.first(where: { $0.address == previous }) { return device }
        if let device = connected.first { return device }
        if let device = inventory.first(where: { $0.address == previous }) { return device }
        if let device = inventory.first(where: { $0.address == selected }) { return device }
        return inventory.first
    }

    static func validSelection(_ selected: String?, in inventory: [DeviceSnapshot]) -> String? {
        guard let selected, inventory.contains(where: { $0.address == selected }) else { return nil }
        return selected
    }

    static func bleOwner(named name: String, in inventory: [DeviceSnapshot]) -> String? {
        let matches = inventory.filter { $0.connected && $0.name.caseInsensitiveCompare(name) == .orderedSame }
        return matches.count == 1 ? matches[0].address : nil
    }
}

struct LowBatteryAlert {
    static let threshold = 20
    private(set) var warned = false

    mutating func shouldWarn(level: Int?) -> Bool {
        guard let level else { return false }
        if level > Self.threshold { warned = false; return false }
        guard !warned else { return false }
        warned = true
        return true
    }

    mutating func reset() { warned = false }
}

/// Use the audio route, not an inferred in-ear sensor. Keep the initial photo visible briefly.
struct ConnectionPresentation {
    private var connectedAt: TimeInterval?
    mutating func connected(at time: TimeInterval) { connectedAt = time }
    func audioDelay(at time: TimeInterval) -> TimeInterval {
        guard let connectedAt else { return 0 }
        return max(0, connectedAt + 1.8 - time)
    }
}
