import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: OptimizerModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    top
                    path
                    score
                    action
                    controls
                    diagnostics
                    samples
                }
                .padding()
            }
            .navigationTitle("Cellular Optimizer MAX")
        }
    }

    var top: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("CELLULAR OPTIMIZER MAX")
                .font(.caption.bold()).tracking(1.7)
            Text("Evidence before optimization.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var path: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Network path").font(.headline)
                    Text(model.network.path.interface.rawValue.capitalized)
                        .font(.title2.bold())
                    Text(model.network.path.status)
                        .foregroundStyle(model.network.path.status == "satisfied" ? .green : .red)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 34))
            }
        }
    }

    var icon: String {
        switch model.network.path.interface {
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .wifi: return "wifi"
        default: return "network"
        }
    }

    var score: some View {
        Card {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text("Connection score").font(.headline)
                    Text("\(model.report.score)/100")
                        .font(.system(size: 45, weight: .bold, design: .rounded))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(model.report.verdict).bold()
                    if let l = model.report.medianLatency {
                        Text("Median latency: \(Int(l)) ms")
                    }
                    if let s = model.report.medianMbps {
                        Text(String(format: "Median throughput: %.1f Mbps", s))
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }

    var action: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Optimizer decision").font(.headline)
                Text(model.report.action)
            }
        }
    }

    var controls: some View {
        Card {
            VStack(spacing: 12) {
                Button {
                    Task { await model.optimize() }
                } label: {
                    HStack {
                        if model.running { ProgressView() }
                        Text(model.running ? "Measuring…" : "RUN FULL OPTIMIZATION")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.running)

                Toggle("Allow automatic DNS testing", isOn: $model.autoDNS)

                HStack {
                    Text(model.dns.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(model.dns.active ? "Remove DNS" : "Test encrypted DNS") {
                        Task { await model.dns.setCloudflare(!model.dns.active) }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    var diagnostics: some View {
        Card {
            VStack(alignment: .leading, spacing: 7) {
                Text("Diagnostics").font(.headline)
                row("Packet loss", String(format: "%.1f%%", model.report.packetLoss))
                row("Jitter", model.report.jitter.map { "\(Int($0)) ms" } ?? "—")
                row("DNS", model.samples.compactMap(\.dnsProtocol).last ?? "—")
                row("Protocol", model.samples.compactMap(\.protocolName).last ?? "—")
                row("IPv6 observations", "\(model.samples.filter(\.ipv6).count)")
            }
        }
    }

    var samples: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Recent samples").font(.headline)
                    Spacer()
                    Button("Clear") { model.clear() }
                        .buttonStyle(.borderless)
                }

                ForEach(model.samples.suffix(12).reversed()) { s in
                    HStack {
                        Image(systemName: s.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(s.endpoint).lineLimit(1)
                        Spacer()
                        Text(s.mbps.map { String(format: "%.1f Mbps", $0) } ?? "failed")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
    }

    func row(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).foregroundStyle(.secondary)
            Spacer()
            Text(b).bold()
        }
        .font(.footnote)
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}
