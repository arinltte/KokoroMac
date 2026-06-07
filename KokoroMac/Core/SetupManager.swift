import Foundation
import Combine

class SetupManager: ObservableObject {
    @Published var isSetupComplete = false
    @Published var isInstalling = false
    @Published var statusMessage = "Ready for setup."
    @Published var progress: Double = 0.0
    
    let baseDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".KokoroMac")
    
    init() {
        checkIfAlreadyInstalled()
    }
    
    private func checkIfAlreadyInstalled() {
        let pythonBin = baseDir.appendingPathComponent("Python/bin/python").path
        let serverScript = baseDir.appendingPathComponent("server.py").path
        let cacheDir = baseDir.appendingPathComponent("Cache").path
        
        if FileManager.default.fileExists(atPath: pythonBin) &&
           FileManager.default.fileExists(atPath: serverScript) &&
           FileManager.default.fileExists(atPath: cacheDir) {
            print("🚀 [SetupManager] Existing installation found. Skipping setup.")
            isSetupComplete = true
        }
    }
    
    private func isInternetAvailable() async -> Bool {
        let url = URL(string: "https://huggingface.co")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        request.httpMethod = "HEAD"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    private func ensureHomebrewInstalled() -> String? {
        let brewPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        for path in brewPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    func runSetup() {
        isInstalling = true
        print("🚀 [SetupManager] Starting setup process...")
        
        Task {
            if !(await isInternetAvailable()) {
                await updateStatus("⚠️ Internet connection required.\nPlease connect to Wi-Fi and tap 'Retry Setup'.", progress: 0.0)
                DispatchQueue.main.async { self.isInstalling = false }
                return
            }
            
            await updateStatus("Checking prerequisites...", progress: 0.05)
            guard let brewPath = ensureHomebrewInstalled() else {
                await updateStatus("⚠️ Homebrew not found.\n\nPlease install Homebrew first via Terminal:\n/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"\n\nThen restart KokoroMac.", progress: 0.0)
                DispatchQueue.main.async { self.isInstalling = false }
                return
            }
            
            do {
                await updateStatus("Preparing directories...", progress: 0.1)
                let subDirs = ["Python", "Models", "Cache", "Temp"]
                if !FileManager.default.fileExists(atPath: baseDir.path) {
                    try FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
                }
                for dir in subDirs {
                    let path = baseDir.appendingPathComponent(dir)
                    if !FileManager.default.fileExists(atPath: path.path) {
                        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
                    }
                }
                 
                await updateStatus("Installing Python 3.11 and espeak-ng...", progress: 0.2)
                try await runShellCommand("\(brewPath) install python@3.11 espeak-ng")
                
                await updateStatus("Setting up Python environment...", progress: 0.4)
                let pythonEnv = baseDir.appendingPathComponent("Python")
                let pythonBin = pythonEnv.appendingPathComponent("bin/python").path
                let brewPython311 = "/opt/homebrew/opt/python@3.11/bin/python3.11"
                let brewPython311Intel = "/usr/local/opt/python@3.11/bin/python3.11"
                let actualBrewPython = FileManager.default.fileExists(atPath: brewPython311) ? brewPython311 : brewPython311Intel
                
                if !FileManager.default.fileExists(atPath: pythonBin) {
                    try await runShellCommand("'\(actualBrewPython)' -m venv '\(pythonEnv.path)'")
                }
                
                await updateStatus("Installing AI dependencies (This may take a few minutes)...", progress: 0.5)
                let pipPath = pythonEnv.appendingPathComponent("bin/pip").path
                try await runShellCommand("'\(pipPath)' install --upgrade pip")
                
                // FIX: Added numpy explicitly to ensure it is available for audio silence generation
                try await runShellCommand("'\(pipPath)' install 'kokoro>=0.9.2' soundfile torch fastapi uvicorn pydantic huggingface_hub spacy numpy")
                
                await updateStatus("Downloading AI models for offline use...", progress: 0.7)
                let hfHome = baseDir.appendingPathComponent("Cache").path
                let downloadScript = """
                import os
                import sys
                
                cache_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser('~/.KokoroMac/Cache')
                os.environ['HF_HOME'] = cache_dir
                
                print("Downloading Kokoro-82M weights and voices...")
                from huggingface_hub import snapshot_download
                snapshot_download(repo_id='hexgrad/Kokoro-82M', repo_type='model')
                
                print("Downloading spaCy en_core_web_sm...")
                import spacy
                spacy.cli.download('en_core_web_sm')
                
                print("All models downloaded successfully.")
                """
                
                let tempScriptPath = baseDir.appendingPathComponent("download_models.py").path
                try downloadScript.write(toFile: tempScriptPath, atomically: true, encoding: .utf8)
                try await runShellCommand("'\(pythonBin)' '\(tempScriptPath)' '\(hfHome)'")
                try? FileManager.default.removeItem(atPath: tempScriptPath)
                
                await updateStatus("Configuring local server...", progress: 0.9)
                let scriptPath = baseDir.appendingPathComponent("server.py")
                try pythonServerScript.write(to: scriptPath, atomically: true, encoding: .utf8)
                
                await updateStatus("Setup Complete!", progress: 1.0)
                DispatchQueue.main.async {
                    self.isSetupComplete = true
                    self.isInstalling = false
                    AppVersion.markInstalled() // NEW: Mark version on fresh install too
                }
                 
            } catch {
                print("❌ [SetupManager] FATAL ERROR: \(error.localizedDescription)")
                await updateStatus("⚠️ Setup failed.\n\nPlease ensure you have a stable internet connection and try again.\n\nError: \(error.localizedDescription)", progress: 0.0)
                DispatchQueue.main.async { self.isInstalling = false }
            }
        }
    }
    
    private func updateStatus(_ msg: String, progress: Double) async {
        await MainActor.run {
            self.statusMessage = msg
            self.progress = progress
        }
    }
    
    private func runShellCommand(_ command: String) async throws {
        print("▶️ [EXEC] Running command: \(command)")
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = Process()
            task.launchPath = "/bin/zsh"
            task.arguments = ["-c", command]
            
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
            task.environment = env
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            task.standardOutput = outputPipe
            task.standardError = errorPipe
            
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                    print("   [STDOUT] \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
            
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                    print("   [STDERR] \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
            
            task.terminationHandler = { process in
                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                
                if process.terminationStatus == 0 {
                    print("✅ [EXEC] Command succeeded.")
                    continuation.resume()
                } else {
                    let errorMsg = "Command exited with status \(process.terminationStatus)."
                    print("❌ [EXEC] \(errorMsg)")
                    continuation.resume(throwing: NSError(domain: "SetupError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorMsg]))
                }
            }
            
            do { try task.run() } catch { continuation.resume(throwing: error) }
        }
    }
}
