import AppKit
import Sparkle

/// Sparkle owns download progress, signature verification, replacement and relaunch.
final class UpdateChecker: NSObject, SPUStandardUserDriverDelegate {
    private lazy var controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: self)
    private var started = false
    private(set) var hasUpdate = false
    var onAvailabilityChange: (() -> Void)?
    var enabled: Bool { controller.updater.automaticallyChecksForUpdates }
    var supportsGentleScheduledUpdateReminders: Bool { true }

    func start() {
        guard !started else { return }
        started = true
        controller.startUpdater()
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "sparkleSettingsMigrated") {
            if let previous = defaults.object(forKey: "automaticUpdates") as? Bool {
                controller.updater.automaticallyChecksForUpdates = previous
            }
            defaults.set(true, forKey: "sparkleSettingsMigrated")
        }
        // Force one check at startup; Sparkle manages the hourly schedule afterward.
        if enabled { controller.updater.checkForUpdatesInBackground() }
    }
    func toggleAutomatic() { controller.updater.automaticallyChecksForUpdates = !enabled }
    func deviceConnected() {
        guard started, enabled else { return }
        // Re-evaluate Sparkle's schedule without bypassing its interval or in-progress session.
        controller.updater.resetUpdateCycle()
    }
    func check(manual: Bool = false) {
        guard started else { return }
        if manual {
            NSApp.activate(ignoringOtherApps: true)
            controller.checkForUpdates(nil)
        } else if enabled {
            controller.updater.resetUpdateCycle()
        }
    }
    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        hasUpdate = true
        // An accessory app otherwise leaves a background update window behind other apps.
        NSApp.setActivationPolicy(.regular)
        NSApp.dockTile.badgeLabel = state.userInitiated ? nil : "1"
        onAvailabilityChange?()
    }
    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        NSApp.dockTile.badgeLabel = nil
    }
    func standardUserDriverWillFinishUpdateSession() {
        hasUpdate = false
        NSApp.dockTile.badgeLabel = nil
        NSApp.setActivationPolicy(.accessory)
        onAvailabilityChange?()
    }
}
