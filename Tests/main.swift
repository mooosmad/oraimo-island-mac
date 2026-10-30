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
