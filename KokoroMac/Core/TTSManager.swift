import Foundation
import Combine

class TTSManager: ObservableObject {
    @Published var isGenerating = false
    @Published var currentOutputURL: URL?
    @Published var errorMessage: String?
    @Published var isServerReady = false
    @Published var modelsLoaded = true
    
    private var serverProcess: Process?
    private var readinessTimer: Timer?
    let baseDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".KokoroMac")
    
    func startServer() {
        // NEW: Run migration before killing old processes
        performMigrationIfNeeded()
        
        // Kill zombie servers (existing code)
        let killTask = Process()
        killTask.launchPath = "/bin/sh"
        killTask.arguments = ["-c", "lsof -ti:8080 | xargs kill -9 2>/dev/null || true"]
        try? killTask.run()
        killTask.waitUntilExit()

        let pythonPath = baseDir.appendingPathComponent("Python/bin/python").path
        let scriptPath = baseDir.appendingPathComponent("server.py").path
        
        try? pythonServerScript.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        
        guard FileManager.default.fileExists(atPath: pythonPath) else { return }

        serverProcess = Process()
        serverProcess?.executableURL = URL(fileURLWithPath: pythonPath)
        serverProcess?.arguments = [scriptPath]
         
        var env = ProcessInfo.processInfo.environment
        env["HF_HOME"] = baseDir.appendingPathComponent("Cache").path
        
        // CRITICAL: Force offline mode to prevent HF Hub warnings and ensure offline functionality
        env["HF_HUB_OFFLINE"] = "1"
        env["TRANSFORMERS_OFFLINE"] = "1"
        
        env["PATH"] = "/opt/homebrew/bin:" + (env["PATH"] ?? "")
        serverProcess?.environment = env
        
        let pipe = Pipe()
        serverProcess?.standardOutput = pipe
        serverProcess?.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                print("🐍 [Server] \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
        
        do {
            try serverProcess?.run()
            startHealthCheck()
        } catch {
            print("❌ [TTSManager] Failed to start TTS server: \(error)")
        }
    }
    
    private func startHealthCheck() {
        isServerReady = false
        readinessTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            let url = URL(string: "http://127.0.0.1:8080/health")!
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.isServerReady = true
                        self.readinessTimer?.invalidate()
                        print("✅ [TTSManager] Server is ready.")
                    }
                }
            }.resume()
        }
    }
    
    func stopServer() {
        readinessTimer?.invalidate()
        serverProcess?.terminate()
    }
    
    func ensureModelsLoaded() {
        if !modelsLoaded {
            let url = URL(string: "http://127.0.0.1:8080/health")!
            URLSession.shared.dataTask(with: url) { _, _, _ in
                DispatchQueue.main.async { self.modelsLoaded = true }
            }.resume()
        }
    }
    
    func performMigrationIfNeeded() {
        guard AppVersion.needsMigration() else { return }
        
        print("🔄 [TTSManager] Detected version upgrade. Migrating server script...")
        
        let serverScriptURL = baseDir.appendingPathComponent("server.py")
        
        // Only rewrite server.py, preserve Cache/, Models/, Temp/
        do {
            if FileManager.default.fileExists(atPath: serverScriptURL.path) {
                try FileManager.default.removeItem(at: serverScriptURL)
                print("🗑️ [Migration] Removed outdated server.py")
            }
            try pythonServerScript.write(to: serverScriptURL, atomically: true, encoding: .utf8)
            print("✅ [Migration] Wrote updated server.py with exact-pause logic")
            AppVersion.markInstalled()
        } catch {
            print("⚠️ [Migration] Failed to update server.py: \(error.localizedDescription)")
            // Don't block app launch; let health check fail gracefully
        }
    }
     
    func generateSpeech(text: String, voice: Voice, speed: Double) {
        ensureModelsLoaded()
        DispatchQueue.main.async { self.isGenerating = true; self.errorMessage = nil }
        
        let fileId = UUID().uuidString
        
        let url = URL(string: "http://127.0.0.1:8080/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "text": text, // Send the pre-formatted ttsReadyText directly
            "voice": voice.id,
            "lang_code": voice.langCode,
            "file_id": fileId,
            "speed": speed
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { self.isGenerating = false }
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = "Network Error: \(error.localizedDescription)" }
                return
            }
            guard let data = data else { return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let filePath = json["file"] as? String {
                DispatchQueue.main.async { self.currentOutputURL = URL(fileURLWithPath: filePath) }
            }
        }.resume()
    }
}
