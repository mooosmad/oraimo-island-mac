import AppKit

/// Checks public release metadata only; never downloads or replaces executable code.
final class UpdateChecker {
    private let defaults = UserDefaults.standard
    private var running = false
    private var timer: Timer?
    var enabled: Bool { defaults.object(forKey: "automaticUpdates") as? Bool ?? true }
    func start() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in self?.check() }
        timer = Timer.scheduledTimer(withTimeInterval: 6 * 3600, repeats: true) { [weak self] _ in self?.check() }
    }
    func toggleAutomatic() { defaults.set(!enabled, forKey: "automaticUpdates") }
    func check(manual: Bool = false) {
        guard !running else { return }
        if !manual {
            guard enabled else { return }
            if let date = defaults.object(forKey: "lastUpdateAttempt") as? Date, Date().timeIntervalSince(date) < 24 * 3600 { return }
        }
        running = true
        defaults.set(Date(), forKey: "lastUpdateAttempt")
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/mooosmad/oraimo-island-mac/releases/latest")!)
        request.timeoutInterval = 20
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("OraimoIsland", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let release: ReleaseInfo?
            if error == nil, (response as? HTTPURLResponse)?.statusCode == 200, let data {
                release = try? JSONDecoder().decode(ReleaseInfo.self, from: data)
            } else { release = nil }
            DispatchQueue.main.async {
                guard let self else { return }
                self.running = false
                if !manual && !self.enabled { return }
                guard let release, release.downloadURL != nil else {
                    if manual { self.message("Vérification impossible", "Vérifie ta connexion et réessaie plus tard.") }
                    return
                }
                let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
                guard release.isNewer(than: current) else {
                    if manual { self.message("Oraimo Island est à jour", "Version installée : \(current).") }
                    return
                }
                if !manual && (self.defaults.string(forKey: "notifiedRelease") == release.tag_name || self.defaults.string(forKey: "ignoredRelease") == release.tag_name) { return }
                self.defaults.set(release.tag_name, forKey: "notifiedRelease")
                NSApp.activate(ignoringOtherApps: true)
                let alert = NSAlert()
                alert.messageText = "Oraimo Island \(release.tag_name) est disponible"
                alert.informativeText = "Tu utilises la version \(current). Télécharge le nouveau DMG, quitte Oraimo Island puis remplace l’app dans Applications."
                alert.addButton(withTitle: "Télécharger")
                alert.addButton(withTitle: "Plus tard")
                alert.addButton(withTitle: "Ignorer cette version")
                let result = alert.runModal()
                if result == .alertFirstButtonReturn, let url = release.downloadURL { NSWorkspace.shared.open(url) }
                if result == .alertThirdButtonReturn { self.defaults.set(release.tag_name, forKey: "ignoredRelease") }
            }
        }.resume()
    }
    private func message(_ title: String, _ text: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert(); alert.messageText = title; alert.informativeText = text; alert.runModal()
    }
}
