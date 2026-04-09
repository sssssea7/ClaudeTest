import SwiftUI

@main
struct PikachuPetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The real window is created by AppDelegate as a borderless NSPanel.
        // Settings scene keeps SwiftUI happy without opening a default window.
        Settings { EmptyView() }
    }
}
