import SwiftUI
import Combine

class AppSettings: ObservableObject {
    @AppStorage("appTheme") var appTheme: AppTheme = .default
    @AppStorage("menuBarIcon") var menuBarIcon: String = "play.circle.fill" // For the About panel
    
    // UI Event Bus for cursor-aware text insertion
    let insertDirective = PassthroughSubject<String, Never>()
    
    // TTS-ready text with <PAUSE:X> markers built from the AttributedString
    @Published var ttsReadyText: String = ""
    
    // Call this to trigger temp file cleanup
    func cleanupTempFiles() {
        let tempDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".KokoroMac")
            .appendingPathComponent("Temp")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            print("🗑️ [Cleanup] Temp audio files deleted.")
        } catch {
            print("⚠️ [Cleanup] Could not clean temp files: \(error.localizedDescription)")
        }
    }
}
