import SwiftUI

@main
struct CellularOptimizerMaxApp: App {
    @StateObject private var model = OptimizerModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
