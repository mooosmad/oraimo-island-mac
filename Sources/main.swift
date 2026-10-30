import AppKit
import SwiftUI
import IOBluetooth
import CoreBluetooth
import CoreAudio
import UniformTypeIdentifiers
import ObjectiveC.runtime

struct DeviceSnapshot: Equatable {
    var name: String
    var connected: Bool
    var battery: Int?
    var caseBattery: Int? = nil
    var leftBattery: Int? = nil
    var rightBattery: Int? = nil
    var address: String = ""
    var levels: BatteryValues { BatteryValues(main: battery, left: leftBattery, right: rightBattery, caseLevel: caseBattery) }
}

// Guarded read-only bridge. Selectors and ABI observed in this machine's framework.
// Zero is conservatively unknown here: these private getters can default to zero.
func privateBattery(_ device: IOBluetoothDevice, _ name: String) -> Int? {
    let sel = NSSelectorFromString(name)
    guard device.responds(to: sel), let method = class_getInstanceMethod(type(of: device), sel),
          method_getNumberOfArguments(method) == 2 else { return nil }
    let rawType = method_copyReturnType(method)
    defer { free(rawType) }
    guard String(cString: rawType) == "C" else { return nil }
    typealias Getter = @convention(c) (AnyObject, Selector) -> UInt8
    let fn = unsafeBitCast(method_getImplementation(method), to: Getter.self)
    let n = Int(fn(device, sel))
    return (1...100).contains(n) ? n : nil
}

// Prefer a fresh system cache reading; otherwise standard BLE Battery Service.
final class BluetoothMonitor: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var onChange: ((DeviceSnapshot?) -> Void)?
    var onRoute: ((String) -> Void)?
    var onInventoryChange: (([DeviceSnapshot]) -> Void)?
    var previousInventory: [DeviceSnapshot] = []
    var central: CBCentralManager!
    var timer: Timer?
    var peripherals: [UUID: CBPeripheral] = [:]
    var peripheralOwners: [UUID: String] = [:]
    var ble: [String: (Int, Date)] = [:]
    var last: DeviceSnapshot?
    var lastRoute = ""
    var lastBatteryRead = Date.distantPast
    var inventory: [DeviceSnapshot] = []
    var selectedAddress: String?
    var probeSummary = "BLE : pas encore exploré"
    var scanTask: DispatchWorkItem?
    let system = SystemBatteryReader()
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
        system.onUpdate = { [weak self] in self?.poll() }
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.poll() }
    }
    func poll() {
        let devices = (IOBluetoothDevice.pairedDevices() ?? []).compactMap { $0 as? IOBluetoothDevice }
            .filter { ($0.name ?? "").localizedCaseInsensitiveContains("oraimo") }
        inventory = devices.map { d in
            let id = BatteryValues.address(d.addressString ?? "")
            guard d.isConnected() else {
                ble[id] = nil
                return DeviceSnapshot(name: d.name ?? "Oraimo", connected: false, battery: nil, address: id)
            }
            let reported = system.value(for: id)
            let bleValue = ble[id].flatMap { Date().timeIntervalSince($0.1) < 90 ? $0.0 : nil }
            return DeviceSnapshot(name: d.name ?? "Oraimo", connected: true,
                battery: reported?.main ?? privateBattery(d, "batteryPercentSingle") ?? privateBattery(d, "batteryPercentCombined") ?? bleValue,
                caseBattery: reported?.caseLevel ?? privateBattery(d, "batteryPercentCase"),
                leftBattery: reported?.left ?? privateBattery(d, "batteryPercentLeft"),
                rightBattery: reported?.right ?? privateBattery(d, "batteryPercentRight"), address: id)
        }
        if inventory != previousInventory {
            previousInventory = inventory
            onInventoryChange?(inventory)
        }
        let route = Self.outputName()
        let current = inventory.first(where: { $0.address == selectedAddress })
            ?? inventory.first(where: { $0.connected && $0.name.caseInsensitiveCompare(route) == .orderedSame })
            ?? inventory.first(where: { $0.connected }) ?? inventory.first
        if current != last { last = current; onChange?(current) }
        system.refresh()
        if inventory.contains(where: { $0.connected }), central.state == .poweredOn,
           Date().timeIntervalSince(lastBatteryRead) > 60 {
            lastBatteryRead = Date()
            for p in central.retrieveConnectedPeripherals(withServices: [CBUUID(string: "180F")]) { inspect(p) }
        }
        if route != lastRoute {
            let previous = lastRoute; lastRoute = route
            if !previous.isEmpty { onRoute?(route) }
        }
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) { poll() }
    func explore() {
        guard central.state == .poweredOn else { probeSummary = "BLE : Bluetooth indisponible"; return }
        probeSummary = "BLE : exploration en cours (12 s)"
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        scanTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.central.stopScan()
            if self.probeSummary.contains("en cours") { self.probeSummary = "BLE : aucun service batterie Oraimo accessible observé pendant 12 s" }
        }
        scanTask = task; DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: task)
        for p in central.retrieveConnectedPeripherals(withServices: [CBUUID(string: "180F")]) { inspect(p) }
    }
    func centralManager(_ central: CBCentralManager, didDiscover p: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = p.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
        guard name.localizedCaseInsensitiveContains("oraimo") else { return }
        // Observe advertising only. No new BLE connection and no vendor commands.
        let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        probeSummary = "BLE : \(name), services annoncés : \(services.map { $0.uuidString }.joined(separator: ", "))"
        if p.state == .connected { inspect(p) }
    }
    func inspect(_ p: CBPeripheral) {
        guard let name = p.name,
              let owner = inventory.first(where: { $0.connected && $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { return }
        peripherals[p.identifier] = p; peripheralOwners[p.identifier] = owner.address
        p.delegate = self; p.discoverServices([CBUUID(string: "180F")])
    }
    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        for service in p.services ?? [] where service.uuid == CBUUID(string: "180F") {
            probeSummary = "BLE : service batterie standard trouvé sur \(p.name ?? "Oraimo")"
            p.discoverCharacteristics([CBUUID(string: "2A19")], for: service)
        }
    }
    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { return }
        for c in service.characteristics ?? [] where c.uuid == CBUUID(string: "2A19") {
            if c.properties.contains(.read) { p.readValue(for: c) }
        }
    }
    func peripheral(_ p: CBPeripheral, didUpdateValueFor c: CBCharacteristic, error: Error?) {
        guard error == nil, c.uuid == CBUUID(string: "2A19"), let n = c.value?.first, n <= 100,
              let owner = peripheralOwners[p.identifier], inventory.contains(where: { $0.address == owner && $0.connected }) else { return }
        // Do not label multiple service instances as left/right without a decoded descriptor.
        guard p.services?.filter({ $0.uuid == CBUUID(string: "180F") }).count == 1 else {
            probeSummary = "BLE : plusieurs batteries trouvées, côtés non identifiés"; return
        }
        ble[owner] = (Int(n), Date()); poll()
    }
    static func outputName() -> String {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var id = AudioDeviceID(0); var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &id) == noErr else { return "" }
        address.mSelector = kAudioObjectPropertyName
        var rawName: Unmanaged<CFString>?; size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &rawName) == noErr else { return "" }
        return rawName?.takeUnretainedValue() as String? ?? ""
    }
}

final class IslandModel: ObservableObject {
    @Published var device: DeviceSnapshot?
    @Published var expanded = true
    @Published var headline = "En attente de tes Oraimo"
    @Published var route = ""
    @Published var photo: NSImage?
    @Published var preview = false
    var product: OraimoProduct { OraimoProduct(name: device?.name ?? "") }
    var batteryLabel: String { device?.battery.map { "\($0) %" } ?? "Non disponible" }
    var connected: Bool { device?.connected == true }
}

// Original vector illustration, not an official product photograph.
struct CaseArt: View {
    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.5)).frame(width: 170, height: 20).blur(radius: 12).offset(y: 72)
            RoundedRectangle(cornerRadius: 44).fill(LinearGradient(colors: [Color(white: 0.32), Color(white: 0.09)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 184, height: 94).rotationEffect(.degrees(-10)).offset(y: -25)
                .overlay(RoundedRectangle(cornerRadius: 38).stroke(.white.opacity(0.12), lineWidth: 1).frame(width: 165, height: 72).rotationEffect(.degrees(-10)).offset(y: -25))
            HStack(spacing: 34) {
                bud(angle: -14); bud(angle: 14)
            }.offset(y: -17)
            RoundedRectangle(cornerRadius: 38).fill(LinearGradient(colors: [Color(white: 0.32), Color(white: 0.14), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 194, height: 91).overlay(RoundedRectangle(cornerRadius: 38).stroke(.white.opacity(0.18), lineWidth: 1)).offset(y: 33)
            VStack(spacing: 11) {
                Text("oraimo").font(.system(size: 17, weight: .medium, design: .rounded)).foregroundStyle(Color(white: 0.65))
                Capsule().fill(Color.green).frame(width: 15, height: 3).shadow(color: .green.opacity(0.6), radius: 5)
            }.offset(y: 37)
        }.frame(width: 250, height: 185).accessibilityLabel("Illustration d’un boîtier Oraimo ouvert")
    }
    func bud(angle: Double) -> some View {
        ZStack {
            Capsule().fill(LinearGradient(colors: [.gray, Color(white: 0.12)], startPoint: .leading, endPoint: .trailing)).frame(width: 18, height: 65).offset(y: 12)
            Ellipse().fill(Color(white: 0.2)).frame(width: 37, height: 30).overlay(Ellipse().stroke(.white.opacity(0.25), lineWidth: 1))
            Ellipse().fill(.black).frame(width: 14, height: 18).offset(x: -11, y: -2)
        }.rotationEffect(.degrees(angle))
    }
}

struct BatteryRing: View {
    var value: Int?
    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.15), lineWidth: 3)
            if let n = value {
                Circle().trim(from: 0, to: CGFloat(n) / 100).stroke(n <= 20 ? Color.red : Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round)).rotationEffect(.degrees(-90))
                Text("\(n)").font(.system(size: 10, weight: .semibold, design: .rounded))
            } else { Image(systemName: "battery.0percent").font(.system(size: 13)) }
        }.frame(width: 33, height: 33).accessibilityLabel(value.map { "Batterie : \($0) pour cent" } ?? "Batterie indisponible")
    }
}

struct IslandView: View {
    @ObservedObject var model: IslandModel
    var toggle: () -> Void
    var dismiss: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: model.product.symbol).font(.system(size: 23)).foregroundStyle(model.connected ? .white : .gray)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.headline).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    if model.expanded { Text(model.preview ? "APERÇU · aucune connexion simulée" : "ORAIMO ISLAND").font(.system(size: 9, weight: .medium)).tracking(1.6).foregroundStyle(.gray) }
                }
                Spacer(minLength: 0)
                if let battery = model.device?.battery { BatteryRing(value: battery) }
            }.padding(.horizontal, 22).frame(height: 60).contentShape(Rectangle()).onTapGesture(perform: toggle)
            if model.expanded {
                VStack(spacing: 7) {
                    if let photo = model.photo {
                        Image(nsImage: photo).resizable().scaledToFit().frame(width: 270, height: 220).accessibilityLabel(model.product.photoDescription)
                    } else if model.product == .spaceBuds {
                        CaseArt()
                    } else {
                        Image(systemName: model.product.symbol)
                            .font(.system(size: 105, weight: .light)).foregroundStyle(.gray)
                            .frame(width: 270, height: 220)
                            .accessibilityLabel(model.product.photoDescription)
                    }
                    Text(model.device?.name ?? "Appareil Oraimo").font(.system(size: 21, weight: .semibold))
                    Text(model.connected ? model.product.connectedDescription : model.product.connectionPrompt)
                        .font(.system(size: 13)).foregroundStyle(.gray)
                    if let levels = model.device?.levels, !levels.fields.isEmpty {
                        HStack(spacing: 0) {
                            ForEach(Array(levels.fields.enumerated()), id: \.offset) { index, entry in
                                if index > 0 { Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 28) }
                                metric(entry.0, "\(entry.1) %")
                            }
                        }.padding(.top, 17).padding(.bottom, 14)
                    }
                    if !model.route.isEmpty {
                        Label(model.route, systemImage: "speaker.wave.2").font(.system(size: 11)).foregroundStyle(.gray).lineLimit(1).padding(.bottom, 8)
                    }
                    Button("Fermer", action: dismiss).buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(.gray).padding(.bottom, 16)
                }.transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .foregroundStyle(.white).frame(width: 390)
        .background(.black, in: RoundedRectangle(cornerRadius: model.expanded ? 34 : 30))
        .overlay(RoundedRectangle(cornerRadius: model.expanded ? 34 : 30).stroke(.white.opacity(0.1), lineWidth: 1))
        .environment(\.colorScheme, .dark)
    }
    func metric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 7) {
            Text(title).font(.system(size: 9, weight: .medium)).tracking(1.5).foregroundStyle(.gray)
            Text(value).font(.system(size: 14, weight: .medium, design: .rounded))
        }.frame(maxWidth: .infinity)
    }
}

final class IslandPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = IslandModel()
    var monitor: BluetoothMonitor!
    var panel: IslandPanel!
    var status: NSStatusItem!
    let devicesMenu = NSMenu()
    var collapseTask: DispatchWorkItem?
    var lowBatteryWarned = false
    var screenObserver: NSObjectProtocol?
    var presentationGeneration = 0
    var customPhotoURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("OraimoIsland/\(model.product.asset)-image.png")
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        panel = IslandPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
        panel.level = .statusBar; panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false; panel.hidesOnDeactivate = false
        panel.contentView = NSHostingView(rootView: IslandView(model: model, toggle: { [weak self] in self?.toggle() }, dismiss: { [weak self] in self?.collapse() }))
        loadPhoto()
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.isVisible = false
        status.button?.image = NSImage(systemSymbolName: "earbuds", accessibilityDescription: "Oraimo Island")
        let menu = NSMenu()
        item(menu, "Afficher Oraimo Island", #selector(show))
        item(menu, "Aperçu de la popup", #selector(preview))
        menu.addItem(.separator())
        item(menu, "Choisir une photo de cet appareil…", #selector(importPhoto))
        item(menu, "Rétablir la photo de cet appareil", #selector(resetPhoto))
        item(menu, "État des appareils et batteries…", #selector(diagnostics))
        item(menu, "Explorer les batteries BLE (12 s)", #selector(exploreBattery))
        let devicesItem = NSMenuItem(title: "Appareils Oraimo", action: nil, keyEquivalent: "")
        devicesItem.submenu = devicesMenu
        menu.addItem(devicesItem)
        menu.addItem(.separator())
        item(menu, "Quitter Oraimo Island", #selector(quit), key: "q")
        status.menu = menu
        screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in self?.position() }
        monitor = BluetoothMonitor()
        monitor.onInventoryChange = { [weak self] inventory in
            self?.refreshStatus(inventory)
        }
        monitor.onChange = { [weak self] snapshot in self?.update(snapshot) }
        monitor.onRoute = { [weak self] route in
            guard let self, self.model.connected else { return }
            self.model.route = route
            self.model.headline = route.localizedCaseInsensitiveContains("oraimo") ? "Audio sur tes Oraimo" : "Sortie audio modifiée"
            if !self.panel.isVisible {
                self.present(expanded: false); self.scheduleDismiss(after: 3)
            }
        }
        monitor.poll()
        if CommandLine.arguments.contains("--preview") { preview() }
        if CommandLine.arguments.contains("--explore-battery") { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.monitor.explore() } }
    }
    func item(_ menu: NSMenu, _ title: String, _ action: Selector, key: String = "") {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key); i.target = self; menu.addItem(i)
    }
    func update(_ snapshot: DeviceSnapshot?) {
        let wasConnected = model.connected
        let previousProduct = model.product
        let changedIdentity = model.device?.address != snapshot?.address
        if changedIdentity { lowBatteryWarned = false }
        model.device = snapshot
        if changedIdentity || previousProduct != model.product { loadPhoto() }
        refreshStatus(monitor.inventory)
        if panel.isVisible { position() }; model.preview = false; model.route = BluetoothMonitor.outputName()
        model.headline = snapshot?.connected == true ? model.product.connectionHeadline : model.product.disconnectionHeadline
        if model.connected && (!wasConnected || changedIdentity) { present(expanded: true); scheduleDismiss(after: 6) }
        else if !model.connected && wasConnected {
            lowBatteryWarned = false; present(expanded: false)
            scheduleDismiss(after: 4)
        }
        if let battery = snapshot?.battery {
            if battery > 20 { lowBatteryWarned = false }
            if battery <= 20 && !lowBatteryWarned {
                lowBatteryWarned = true; model.headline = "Batterie faible · \(battery) %"; present(expanded: false); scheduleDismiss(after: 4)
            }
        }
    }
    func position() {
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main else { return }
        let hasLevels = !(model.device?.levels.fields.isEmpty ?? true)
        let height: CGFloat = model.expanded ? (hasLevels ? 485 : 420) : 60
        // Below the physical notch so no text or controls are obscured by the camera.
        let top = screen.frame.maxY - max(screen.safeAreaInsets.top, 8) - 5
        let frame = NSRect(x: screen.frame.midX - 195, y: top - height, width: 390, height: height)
        panel.setFrame(frame, display: true, animate: panel.isVisible)
    }
    func present(expanded: Bool) {
        collapseTask?.cancel(); presentationGeneration += 1
        panel.alphaValue = 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { model.expanded = expanded }
        position(); panel.orderFrontRegardless()
    }
    func scheduleDismiss(after seconds: TimeInterval) {
        collapseTask?.cancel()
        let task = DispatchWorkItem { [weak self] in self?.collapse() }
        collapseTask = task; DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: task)
    }
    func collapse() {
        collapseTask?.cancel(); presentationGeneration += 1
        let generation = presentationGeneration
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            guard let self, self.presentationGeneration == generation else { return }
            self.panel.orderOut(nil)
        })
    }
    func toggle() { present(expanded: !model.expanded); scheduleDismiss(after: 6) }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        show(); return false
    }
    @objc func show() {
        model.preview = false
        model.headline = model.connected ? model.product.connectionHeadline : "En attente de tes Oraimo"
        present(expanded: true); scheduleDismiss(after: 6)
    }
    @objc func preview() {
        model.preview = true; model.headline = "Aperçu de la connexion"
        present(expanded: true); scheduleDismiss(after: 6)
    }
    @objc func importPhoto() {
        let picker = NSOpenPanel(); picker.allowedContentTypes = [.png, .jpeg, .heic]; picker.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        guard picker.runModal() == .OK, let url = picker.url, let image = NSImage(contentsOf: url),
              let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else { return }
        do {
            try FileManager.default.createDirectory(at: customPhotoURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: customPhotoURL, options: .atomic); model.photo = image; show()
        } catch { alert("Photo non enregistrée", error.localizedDescription) }
    }
    func refreshStatus(_ inventory: [DeviceSnapshot]) {
        refreshDevicesMenu(inventory)
        let connected = inventory.filter { $0.connected }
        status.isVisible = !connected.isEmpty
        let active = connected.first(where: { $0.address == model.device?.address })
            ?? connected.first(where: { $0.name.caseInsensitiveCompare(BluetoothMonitor.outputName()) == .orderedSame })
            ?? connected.first
        guard let active else { return }
        status.button?.image = NSImage(systemSymbolName: OraimoProduct(name: active.name).symbol, accessibilityDescription: active.name)
        status.button?.toolTip = active.name + (active.battery.map { " · \($0) %" } ?? "")
    }
    func loadPhoto() {
        model.photo = NSImage(contentsOf: customPhotoURL) ?? bundledPhoto()
    }
    func bundledPhoto() -> NSImage? {
        guard let url = Bundle.main.url(forResource: model.product.asset, withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }
    @objc func resetPhoto() { try? FileManager.default.removeItem(at: customPhotoURL); model.photo = bundledPhoto(); show() }
    func refreshDevicesMenu(_ inventory: [DeviceSnapshot]) {
        devicesMenu.removeAllItems()
        let automatic = NSMenuItem(title: "Sélection automatique", action: #selector(selectDevice(_:)), keyEquivalent: "")
        automatic.target = self
        automatic.state = monitor.selectedAddress == nil ? .on : .off
        devicesMenu.addItem(automatic)
        for device in inventory {
            let homonyms = inventory.filter { $0.name.caseInsensitiveCompare(device.name) == .orderedSame }
            let suffix = homonyms.count > 1 ? " · …" + device.address.suffix(4) : ""
            let title = device.name + suffix + (device.connected ? " · connecté" : " · déconnecté")
            let entry = NSMenuItem(title: title, action: #selector(selectDevice(_:)), keyEquivalent: "")
            entry.target = self
            entry.representedObject = device.address
            entry.state = monitor.selectedAddress == device.address ? .on : .off
            devicesMenu.addItem(entry)
        }
    }
    @objc func selectDevice(_ sender: NSMenuItem) {
        monitor.selectedAddress = sender.representedObject as? String
        monitor.poll()
        refreshDevicesMenu(monitor.inventory)
        show()
    }
    @objc func exploreBattery() { monitor.explore() }
    @objc func diagnostics() {
        let rows = monitor.inventory.map { d in
            let fields = d.levels.fields.map { "\($0.0) : \($0.1) %" }.joined(separator: " · ")
            return "\(d.name) — \(d.connected ? "connecté" : "déconnecté")\n\(fields.isEmpty ? "Aucun niveau reçu" : fields)"
        }.joined(separator: "\n\n")
        alert("Oraimo Island · Batteries", rows + "\n\n" + monitor.probeSummary + "\n\nLes niveaux absents sont masqués. Un niveau global ne permet pas de déduire gauche/droite. Aucune commande propriétaire n’est envoyée.")
    }
    func alert(_ title: String, _ message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert(); a.messageText = title; a.informativeText = message; a.runModal()
    }
    @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
if let identifier = Bundle.main.bundleIdentifier,
   NSRunningApplication.runningApplications(withBundleIdentifier: identifier).contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
    exit(0)
}
let delegate = AppDelegate()
app.delegate = delegate
app.run()
