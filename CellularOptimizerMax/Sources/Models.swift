import Foundation

enum InterfaceKind: String, Codable {
    case cellular, wifi, ethernet, other, unavailable
}

struct PathSnapshot: Codable, Equatable {
    var status: String = "unknown"
    var interface: InterfaceKind = .unavailable
    var expensive = false
    var constrained = false
}

struct ProbeSample: Identifiable, Codable {
    let id: UUID
    let date: Date
    let endpoint: String
    let latencyMs: Double?
    let jitterMs: Double?
    let success: Bool
    let bytes: Int
    let durationSeconds: Double?
    let protocolName: String?
    let dnsProtocol: String?
    let remoteAddress: String?
    let cellular: Bool
    let ipv6: Bool

    var mbps: Double? {
        guard let durationSeconds, durationSeconds > 0, bytes > 0 else { return nil }
        return Double(bytes * 8) / durationSeconds / 1_000_000
    }
}

struct OptimizerReport {
    let score: Int
    let packetLoss: Double
    let medianLatency: Double?
    let jitter: Double?
    let medianMbps: Double?
    let verdict: String
    let action: String
}
