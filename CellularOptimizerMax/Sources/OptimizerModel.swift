import Foundation
import SwiftUI

@MainActor
final class OptimizerModel: ObservableObject {
    @Published var running = false
    @Published var status = "Ready"
    @Published var samples: [ProbeSample] = []
    @Published var report = OptimizerReport(score: 0, packetLoss: 100,
                                             medianLatency: nil, jitter: nil,
                                             medianMbps: nil,
                                             verdict: "No measurement",
                                             action: "Run optimizer.")
    @Published var autoDNS = false
    @Published var dnsTested = false

    let network = NetworkMonitor()
    let dns = DNSController()
    private let engine = ProbeEngine()

    init() {
        Task { await dns.load() }
    }

    func optimize() async {
        guard !running else { return }
        running = true
        status = "Baseline: repeated cellular measurements…"
        samples.removeAll()

        let endpoints = [
            URL(string: "https://www.apple.com/library/test/success.html")!,
            URL(string: "https://www.cloudflare.com/cdn-cgi/trace")!,
            URL(string: "https://speed.cloudflare.com/__down?bytes=750000")!
        ]

        for _ in 0..<3 {
            for url in endpoints {
                let s = await engine.probe(url: url)
                samples.append(s)
            }
        }

        report = OptimizerEngine.analyze(samples)
        status = "Baseline complete"

        // Conservative: never silently change DNS on the first pass.
        // Auto mode only becomes eligible after a stable baseline.
        if autoDNS && report.score < 75 && report.packetLoss < 5 {
            status = "Baseline suggests a configuration test may be useful."
        }

        running = false
    }

    func clear() {
        samples.removeAll()
        report = OptimizerEngine.analyze([])
        status = "Ready"
    }
}
