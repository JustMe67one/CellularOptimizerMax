import Foundation
import NetworkExtension

@MainActor
final class DNSController: ObservableObject {
    @Published private(set) var active = false
    @Published private(set) var message = "Managed DNS is off"

    private let manager = NEDNSSettingsManager.shared()

    func load() async {
        await withCheckedContinuation { continuation in
            manager.loadFromPreferences { [weak self] error in
                Task { @MainActor in
                    if let error {
                        self?.message = error.localizedDescription
                    } else {
                        self?.active = self?.manager.isEnabled ?? false
                        self?.message = self?.active == true ? "Managed DNS is active" : "Managed DNS is off"
                    }
                    continuation.resume()
                }
            }
        }
    }

    func setCloudflare(_ enabled: Bool) async {
        await withCheckedContinuation { continuation in
            manager.loadFromPreferences { [weak self] error in
                guard let self else { continuation.resume(); return }
                if let error {
                    Task { @MainActor in
                        self.message = error.localizedDescription
                        continuation.resume()
                    }
                    return
                }

                if enabled {
                    let settings = NEDNSOverHTTPSSettings(
                        servers: ["1.1.1.1", "1.0.0.1"],
                        serverURL: URL(string: "https://cloudflare-dns.com/dns-query")!
                    )
                    settings.matchDomains = [""]
                    self.manager.localizedDescription = "Cellular Optimizer MAX"
                    self.manager.dnsSettings = settings
                    self.manager.isEnabled = true
                } else {
                    self.manager.isEnabled = false
                }

                self.manager.saveToPreferences { error in
                    Task { @MainActor in
                        if let error {
                            self.message = error.localizedDescription
                        } else {
                            self.active = enabled
                            self.message = enabled ? "Encrypted DNS active" : "Managed DNS is off"
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }
}
