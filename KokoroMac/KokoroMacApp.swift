import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var ttsManager: TTSManager?
    
    func applicationWillTerminate(_ aNotification: Notification) {
        ttsManager?.stopServer()
        // Failsafe: Ensure port 8080 is freed when app quits
        let killTask = Process()
        killTask.launchPath = "/bin/sh"
        killTask.arguments = ["-c", "lsof -ti:8080 | xargs kill -9 2>/dev/null || true"]
        try? killTask.run()
    }
}

@main
struct KokoroMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var setupManager = SetupManager()
    @StateObject var ttsManager = TTSManager()
    @StateObject var appSettings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            #if arch(arm64)
            if setupManager.isSetupComplete {
                MainView()
                    .environmentObject(ttsManager)
                    .environmentObject(appSettings)
                    .onAppear {
                        appDelegate.ttsManager = ttsManager
                        appSettings.cleanupTempFiles()
                        ttsManager.startServer()
                    }
            } else {
                SetupWizardView(setupManager: setupManager)
            }
            #else
            VStack {
                Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundColor(.red)
                Text("Unsupported Architecture").font(.title)
                Text("KokoroMac requires an Apple Silicon (M1+) processor.")
            }
            .frame(width: 400, height: 300)
            #endif
        }
        .windowResizability(.contentSize)
    }
}
