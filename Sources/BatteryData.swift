import Foundation

struct BatteryValues: Equatable {
    var main: Int?
    var left: Int?
    var right: Int?
    var caseLevel: Int?
    var fields: [(String, Int)] {
        var result: [(String, Int)] = []
        if let left { result.append(("GAUCHE", left)) }
        if let right { result.append(("DROIT", right)) }
        if left == nil && right == nil, let main { result.append(("BATTERIE", main)) }
        if let caseLevel { result.append(("BOÎTIER", caseLevel)) }
        return result
    }
    static func percent(_ input: Any?) -> Int? {
        guard let input else { return nil }
        let text = String(describing: input).replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let n = Int(text), (0...100).contains(n) else { return nil }; return n
    }
    static func address(_ value: String) -> String {
        value.lowercased().filter { $0.isHexDigit }
    }
    static func parseProfiler(_ data: Data) -> [String: BatteryValues] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let controllers = root["SPBluetoothDataType"] as? [[String: Any]] else { return [:] }
        var result: [String: BatteryValues] = [:]
        for c in controllers {
            for row in c["device_connected"] as? [[String: Any]] ?? [] {
                for (name, raw) in row where name.localizedCaseInsensitiveContains("oraimo") {
                    guard let info = raw as? [String: Any], let id = info["device_address"] as? String else { continue }
                    result[address(id)] = BatteryValues(main: percent(info["device_batteryLevelMain"]),
                        left: percent(info["device_batteryLevelLeft"]), right: percent(info["device_batteryLevelRight"]),
                        caseLevel: percent(info["device_batteryLevelCase"]))
                }
            }
        }
        return result
    }
}

// Run the system report off the UI thread; expire it rather than retaining stale levels.
final class SystemBatteryReader {
    private var values: [String: BatteryValues] = [:]
    private var updated = Date.distantPast
    private var requested = Date.distantPast
    private var running = false
    var onUpdate: (() -> Void)?
    func value(for address: String) -> BatteryValues? {
        guard Date().timeIntervalSince(updated) < 45 else { return nil }
        return values[BatteryValues.address(address)]
    }
    func refresh() {
        guard !running, Date().timeIntervalSince(requested) >= 30 else { return }
        requested = Date(); running = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let process = Process(); let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
            process.arguments = ["SPBluetoothDataType", "-json", "-timeout", "8"]
            process.standardOutput = pipe; process.standardError = FileHandle.nullDevice
            var result: [String: BatteryValues] = [:]
            do {
                try process.run()
                let deadline = DispatchWorkItem { if process.isRunning { process.terminate() } }
                DispatchQueue.global().asyncAfter(deadline: .now() + 10, execute: deadline)
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit(); deadline.cancel()
                if process.terminationStatus == 0 { result = BatteryValues.parseProfiler(data) }
            } catch { }
            let captured = result
            DispatchQueue.main.async {
                guard let self else { return }
                self.values = captured; self.updated = Date(); self.running = false; self.onUpdate?()
            }
        }
    }
}
