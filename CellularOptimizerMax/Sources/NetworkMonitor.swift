import Foundation
import Network

final class NetworkMonitor: ObservableObject {
    @Published private(set) var path = PathSnapshot()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "CellularOptimizerMax.Path")

    init() {
        monitor.pathUpdateHandler = { [weak self] p in
            let interface: InterfaceKind
            if p.usesInterfaceType(.cellular) { interface = .cellular }
            else if p.usesInterfaceType(.wifi) { interface = .wifi }
            else if p.usesInterfaceType(.wiredEthernet) { interface = .ethernet }
            else if p.status == .satisfied { interface = .other }
            else { interface = .unavailable }

            DispatchQueue.main.async {
                self?.path = PathSnapshot(
                    status: p.status == .satisfied ? "satisfied" : "unsatisfied",
                    interface: interface,
                    expensive: p.isExpensive,
                    constrained: p.isConstrained
                )
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
