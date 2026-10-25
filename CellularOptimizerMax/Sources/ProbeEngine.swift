import Foundation

final class ProbeEngine: NSObject, URLSessionTaskDelegate {
    private var metricsByTask: [Int: URLSessionTaskMetrics] = [:]
    private let lock = NSLock()

    private func session() -> URLSession {
        let c = URLSessionConfiguration.ephemeral
        c.waitsForConnectivity = true
        c.timeoutIntervalForRequest = 12
        c.timeoutIntervalForResource = 20
        c.allowsCellularAccess = true
        c.allowsExpensiveNetworkAccess = true
        c.allowsConstrainedNetworkAccess = true
        return URLSession(configuration: c, delegate: self, delegateQueue: nil)
    }

    func probe(url: URL, bytes: Int = 750_000) async -> ProbeSample {
        let s = session()
        let started = ContinuousClock.now

        do {
            let request: URLRequest
            if url.host == "speed.cloudflare.com" {
                request = URLRequest(url: URL(string: "https://speed.cloudflare.com/__down?bytes=\(bytes)")!)
            } else {
                request = URLRequest(url: url)
            }

            let (data, response) = try await s.data(for: request)
            let elapsed = started.duration(to: .now)
            let seconds = max(0.001, Double(elapsed.components.seconds) +
                              Double(elapsed.components.attoseconds) / 1e18)

            var protocolName: String?
            var dns: String?
            var remote: String?
            var cellular = false
            var ipv6 = false

            if let http = response as? HTTPURLResponse {
                _ = http.statusCode
            }

            lock.lock()
            let m = metricsByTask.values.last
            lock.unlock()

            if let t = m?.transactionMetrics.last {
                protocolName = t.networkProtocolName
                dns = t.domainResolutionProtocol.rawValue
                remote = t.remoteAddress
                cellular = t.isCellular
                ipv6 = t.remoteAddress?.contains(":") == true
            }

            return ProbeSample(
                id: UUID(), date: Date(), endpoint: url.host ?? "unknown",
                latencyMs: seconds * 1000,
                jitterMs: nil, success: true, bytes: data.count,
                durationSeconds: seconds, protocolName: protocolName,
                dnsProtocol: dns, remoteAddress: remote,
                cellular: cellular, ipv6: ipv6
            )
        } catch {
            return ProbeSample(
                id: UUID(), date: Date(), endpoint: url.host ?? "unknown",
                latencyMs: nil, jitterMs: nil, success: false, bytes: 0,
                durationSeconds: nil, protocolName: nil, dnsProtocol: nil,
                remoteAddress: nil, cellular: false, ipv6: false
            )
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didFinishCollecting metrics: URLSessionTaskMetrics) {
        lock.lock()
        metricsByTask[task.taskIdentifier] = metrics
        if metricsByTask.count > 30 {
            metricsByTask.removeValue(forKey: metricsByTask.keys.first!)
        }
        lock.unlock()
    }
}
