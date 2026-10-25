import Foundation

struct OptimizerEngine {
    static func analyze(_ samples: [ProbeSample]) -> OptimizerReport {
        guard !samples.isEmpty else {
            return OptimizerReport(score: 0, packetLoss: 100, medianLatency: nil,
                                   jitter: nil, medianMbps: nil,
                                   verdict: "No data yet.",
                                   action: "Run a measurement.")
        }

        let successful = samples.filter(\.success)
        let loss = 100 * Double(samples.count - successful.count) / Double(samples.count)

        let latencies = successful.compactMap(\.latencyMs).sorted()
        let speeds = successful.compactMap(\.mbps).sorted()

        let medianLatency = median(latencies)
        let medianMbps = median(speeds)

        var jitters: [Double] = []
        for i in 1..<latencies.count {
            jitters.append(abs(latencies[i] - latencies[i-1]))
        }
        let jitter = median(jitters)

        let latencyScore = medianLatency.map { max(0, min(100, 100 - $0 / 2.0)) } ?? 0
        let jitterScore = jitter.map { max(0, min(100, 100 - $0 * 1.5)) } ?? 0
        let lossScore = max(0, 100 - loss * 10)
        let speedScore = medianMbps.map { min(100, sqrt(max(0, $0)) * 10) } ?? 0

        let score = Int((latencyScore * 0.30 +
                         jitterScore * 0.20 +
                         lossScore * 0.25 +
                         speedScore * 0.25).rounded())

        let verdict: String
        let action: String

        if score >= 82 {
            verdict = "Healthy connection"
            action = "Do not modify the network."
        } else if loss >= 8 {
            verdict = "Unstable path"
            action = "Do not blame DNS; packet loss points toward radio/carrier/path instability."
        } else if let l = medianLatency, l >= 120 {
            verdict = "Latency dominated"
            action = "DNS changes are unlikely to solve the main problem."
        } else if let s = medianMbps, s < 8 {
            verdict = "Throughput dominated"
            action = "Repeat at another time before changing configuration."
        } else {
            verdict = "Mixed degradation"
            action = "Compare DNS/routing samples before applying a change."
        }

        return OptimizerReport(score: score, packetLoss: loss,
                               medianLatency: medianLatency, jitter: jitter,
                               medianMbps: medianMbps, verdict: verdict, action: action)
    }

    private static func median(_ a: [Double]) -> Double? {
        guard !a.isEmpty else { return nil }
        let n = a.count
        return n % 2 == 0 ? (a[n/2-1] + a[n/2]) / 2 : a[n/2]
    }
}
