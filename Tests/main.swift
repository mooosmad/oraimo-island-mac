import Foundation
func check(_ condition: @autoclosure () -> Bool, _ description: String) {
    guard condition() else { fatalError(description) }
}
check(BatteryValues().fields.isEmpty, "Unknown levels must be invisible")
check(BatteryValues(main: 100).fields.map { $0.0 } == ["BATTERIE"], "One aggregate must not invent two sides")
check(BatteryValues(main: 100, left: 80, right: 75).fields.map { $0.1 } == [80,75], "Separate levels should replace aggregate")
check(BatteryValues(left: 80).fields.count == 1, "Unknown right and case must stay hidden")
check(BatteryValues.percent("100\u{00A0}%") == 100, "French system report spacing")
check(BatteryValues.percent("0 %") == 0, "Explicit system zero is valid")
for invalid in ["-1", "255", "101 %", "n/a", "80.5 %"] { check(BatteryValues.percent(invalid) == nil, "Invalid level: \(invalid)") }
let fixture = #"{"SPBluetoothDataType":[{"device_connected":[{"oraimo SpaceBuds Lite 2":{"device_address":"AA:BB:CC:11:22:33","device_batteryLevelMain":"100 %","device_batteryLevelLeft":"90 %","device_batteryLevelRight":"80 %"}},{"oraimo BoomPop Pro":{"device_address":"AA-BB-CC-44-55-66","device_batteryLevelMain":"70 %"}}],"device_not_connected":[{"oraimo stale":{"device_address":"00:11:22:33:44:55","device_batteryLevelMain":"95 %"}}]}]}"#.data(using: .utf8)!
let parsed = BatteryValues.parseProfiler(fixture)
check(parsed.count == 2, "Disconnected cache must be ignored")
check(parsed["aabbcc112233"]?.left == 90 && parsed["aabbcc112233"]?.right == 80, "L/R parser")
check(parsed["aabbcc445566"]?.main == 70 && parsed["aabbcc445566"]?.left == nil, "No cross-device battery contamination")
check(BatteryValues.parseProfiler(Data("bad".utf8)).isEmpty, "Malformed report")
print("PASS: masking, aggregate versus left/right, French percentage, explicit zero, invalid values, disconnected records and device isolation")

check(OraimoProduct(name: "oraimo BoomPop Pro").symbol == "headphones", "BoomPop must use a headset icon")
check(OraimoProduct(name: "oraimo SpaceBuds Lite 2").symbol == "earbuds", "SpaceBuds icon")
check(OraimoProduct.boomPop.asset != OraimoProduct.spaceBuds.asset, "Product photos must be independent")
print("PASS: model-specific symbols and independent photo resources")

check(OraimoProduct(name: "oraimo Watch 6 Nano_ABCD") == .watch6Nano, "Watch advertised suffix")
check(OraimoProduct(name: "ORAIMO WATCH 6 NANO") == .watch6Nano, "Watch case-insensitive recognition")
check(OraimoProduct(name: "oraimo Watch 6 NanoPlus") == .unknown, "Do not recognize another watch variant")
check(OraimoProduct(name: "oraimo Watch 6") == .unknown, "Do not mislabel another watch as earbuds")
check(OraimoProduct(name: "AirPods Pro") == .unknown, "Non-Oraimo presentation stays generic")
check(OraimoProduct.watch6Nano.symbol == "applewatch", "Watch icon")
check(OraimoProduct.watch6Nano.asset != OraimoProduct.spaceBuds.asset, "Watch photo independent of earbuds")
check(OraimoProduct.watch6Nano.connectionHeadline == "Montre connectée", "Watch connection copy")
check(OraimoProduct.watch6Nano.disconnectionHeadline == "Montre déconnectée", "Watch disconnection copy")
let watchFixture = #"{"SPBluetoothDataType":[{"device_connected":[{"oraimo Watch 6 Nano_ABCD":{"device_address":"AA:BB:CC:00:00:01","device_minorType":"Watch","device_productID":"0x0220","device_vendorID":"0x0642"}},{"oraimo BoomPop Pro":{"device_address":"AA:BB:CC:00:00:02","device_batteryLevelMain":"70%"}},{"AirPods Pro":{"device_address":"AA:BB:CC:00:00:03","device_batteryLevelMain":"90%"}}],"device_not_connected":[{"oraimo Watch 6 Nano_EFGH":{"device_address":"AA:BB:CC:00:00:04","device_batteryLevelMain":"80%"}}]}]}"#.data(using: .utf8)!
let watchReport = BatteryValues.parseProfiler(watchFixture)
check(watchReport.count == 2, "Only connected Oraimo devices are included")
check(watchReport["aabbcc000001"]?.fields.isEmpty == true, "Missing watch battery stays hidden, not zero or borrowed")
check(watchReport["aabbcc000002"]?.main == 70, "Headset battery remains isolated")
let chargedWatchFixture = String(data: watchFixture, encoding: .utf8)!.replacingOccurrences(of: "\"device_minorType\":\"Watch\"", with: "\"device_batteryLevelMain\":\"0%\",\"device_minorType\":\"Watch\"")
check(BatteryValues.parseProfiler(Data(chargedWatchFixture.utf8))["aabbcc000001"]?.main == 0, "Explicit watch zero remains a valid measurement")
print("PASS: Watch 6 Nano recognition, presentation, missing battery and Oraimo-only isolation")

check(OraimoProduct(name: "oraimo SpaceBuds Neo") == .spaceBudsNeo, "SpaceBuds Neo recognition")
check(OraimoProduct(name: "ORAIMO SPACEBUDS NEO_1A2B") == .spaceBudsNeo, "SpaceBuds Neo suffix and case")
check(OraimoProduct(name: "oraimo SpaceBuds Neoplus") != .spaceBudsNeo, "Do not recognize another Neo variant")
check(OraimoProduct(name: "oraimo SpaceBuds Lite 2") == .spaceBuds, "Lite 2 is not mistaken for Neo")
check(OraimoProduct.spaceBudsNeo.symbol == "earbuds" && OraimoProduct.spaceBudsNeo.isEarbuds, "SpaceBuds Neo earbuds presentation")
check(OraimoProduct.spaceBudsNeo.asset != OraimoProduct.spaceBuds.asset, "Neo photo independent of Lite 2")
check(!OraimoProduct.boomPop.isEarbuds && !OraimoProduct.watch6Nano.isEarbuds, "Only earbuds use the case illustration")
let neoFixture = #"{"SPBluetoothDataType":[{"device_connected":[{"oraimo SpaceBuds Neo":{"device_address":"AA:BB:CC:00:00:10","device_batteryLevelMain":"100 %","device_minorType":"Headset","device_productID":"0x000A","device_vendorID":"0x05D6"}}],"device_not_connected":[{"oraimo BoomPop Pro":{"device_address":"AA:BB:CC:00:00:11","device_productID":"0x000A","device_vendorID":"0x05D6"}}]}]}"#.data(using: .utf8)!
check(BatteryValues.parseProfiler(neoFixture) == ["aabbcc000010": BatteryValues(main: 100)], "SpaceBuds Neo system battery, BoomPop sharing its IDs ignored")
print("PASS: SpaceBuds Neo recognition, presentation and system battery")

let buds = DeviceSnapshot(name: "oraimo SpaceBuds Neo", connected: true, battery: 80, address: "a1")
let watch = DeviceSnapshot(name: "oraimo Watch 6 Nano", connected: true, battery: nil, address: "b2")
let oldHeadset = DeviceSnapshot(name: "oraimo BoomPop Pro", connected: false, battery: nil, address: "c3")
check(DeviceSelection.current(in: [oldHeadset, buds, watch], selected: "b2", route: "oraimo SpaceBuds Neo", previous: nil)?.address == "b2", "Manual selection wins while connected")
check(DeviceSelection.current(in: [oldHeadset, buds, watch], selected: nil, route: "oraimo SpaceBuds Neo", previous: "b2")?.address == "a1", "Audio route wins in automatic mode")
check(DeviceSelection.current(in: [oldHeadset, buds, watch], selected: nil, route: "MacBook Speakers", previous: "b2")?.address == "b2", "Automatic choice stays stable")
var watchOff = watch; watchOff.connected = false
check(DeviceSelection.current(in: [oldHeadset, buds, watchOff], selected: "b2", route: "", previous: "b2")?.address == "a1", "Disconnected selection does not hide a connected device")
var budsOff = buds; budsOff.connected = false; budsOff.battery = nil
check(DeviceSelection.current(in: [oldHeadset, budsOff], selected: nil, route: "", previous: "a1")?.address == "a1", "Disconnection message names the device that left")
check(DeviceSelection.validSelection("zz", in: [buds]) == nil && DeviceSelection.validSelection("a1", in: [budsOff]) == "a1", "Unpaired selection falls back to automatic")
print("PASS: device selection, audio route, stability and disconnection identity")

let twin = DeviceSnapshot(name: "OraIMO SpaceBuds Neo", connected: true, battery: nil, address: "d4")
check(DeviceSelection.bleOwner(named: "oraimo SpaceBuds Neo", in: [buds, watch]) == "a1", "Unique BLE name maps to its device")
check(DeviceSelection.bleOwner(named: "oraimo SpaceBuds Neo", in: [buds, twin]) == nil, "Homonyms never share a BLE reading")
check(DeviceSelection.bleOwner(named: "oraimo SpaceBuds Neo", in: [budsOff]) == nil, "Disconnected device cannot own a BLE reading")
print("PASS: BLE ownership with homonyms")

check(DeviceSnapshot(name: "x", connected: true, battery: 60, caseBattery: 3, leftBattery: 15, rightBattery: 40).lowestListeningLevel == 15, "Low battery uses the lowest earbud, not the case")
check(DeviceSnapshot(name: "x", connected: true, battery: nil, caseBattery: 5).lowestListeningLevel == nil, "Case alone does not trigger a warning")
var alert = LowBatteryAlert()
check(!alert.shouldWarn(level: nil) && !alert.shouldWarn(level: 21), "No warning above threshold or without level")
check(alert.shouldWarn(level: 20) && !alert.shouldWarn(level: 18), "Warn once at threshold")
check(!alert.shouldWarn(level: 50) && alert.shouldWarn(level: 10), "Warn again after recharge")
alert.reset()
check(alert.shouldWarn(level: 10), "Reset re-arms the warning")
print("PASS: low battery threshold, earbuds minimum and re-arming")

check(ReleaseVersion("v0.10.0")! > ReleaseVersion("0.2.0")!, "Versions compare numerically")
check(ReleaseVersion("1.0.0")! > ReleaseVersion("0.99.9")!, "Major version wins")
check(ReleaseVersion("0.2.0")! == ReleaseVersion("v0.2.0")!, "Optional v prefix")
check(ReleaseVersion("0.3.0-beta") == nil && ReleaseVersion("junk") == nil, "Reject malformed and prerelease tags")
let releaseJSON = #"{"tag_name":"v0.3.0","draft":false,"prerelease":false,"assets":[{"name":"Oraimo-Island-macOS-universal.dmg","browser_download_url":"https://github.com/mooosmad/oraimo-island-mac/releases/download/v0.3.0/Oraimo-Island-macOS-universal.dmg"}]}"#
let release = try! JSONDecoder().decode(ReleaseInfo.self, from: Data(releaseJSON.utf8))
check(release.isNewer(than: "0.2.0") && !release.isNewer(than: "0.3.0") && !release.isNewer(than: "0.4.0"), "Only offer newer releases")
for changedJSON in [releaseJSON.replacingOccurrences(of: "github.com", with: "evil.example"), releaseJSON.replacingOccurrences(of: "\"prerelease\":false", with: "\"prerelease\":true"), releaseJSON.replacingOccurrences(of: "\"draft\":false", with: "\"draft\":true"), releaseJSON.replacingOccurrences(of: "https:", with: "http:")] {
    let invalid = try! JSONDecoder().decode(ReleaseInfo.self, from: Data(changedJSON.utf8))
    check(invalid.downloadURL == nil && !invalid.isNewer(than: "0.2.0"), "Reject unsafe or unpublished release")
}
print("PASS: release version ordering and trusted stable DMG metadata")
