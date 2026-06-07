import SwiftUI

struct MainView: View {
    @EnvironmentObject var ttsManager: TTSManager
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var textInput: String = """
        Welcome to KokoroMac, your local, open-weight text-to-speech studio. \u{FFFC}
        
        Kokoro is an efficient AI model with 82 million parameters. It delivers quality comparable to larger models while being significantly faster. Because it runs entirely on your Apple Silicon Mac, you never worry about internet connectivity or data privacy. Your words stay on your machine. \u{FFFC}
        
        Let's explore how to direct your speech generation. First, control the pacing. By inserting a pause block, you give the listener a moment to absorb the information. \u{FFFC} This is perfect for audiobooks or presentations.
        
        Second, override pronunciation using the Phoneme Override tool. For example, force the exact pronunciation using the International Phonetic Alphabet like this: [Kokoro](/kˈOkəɹO/). The word is Japanese, translating to "heart" or "spirit". \u{FFFC}
        
        Adjust the speech speed using the slider on the right. A speed of 1.0 is natural, 0.8 is great for technical docs, and 1.2 is perfect for skimming. \u{FFFC}
        
        Start typing or paste your favorite articles. The voice is yours.
        """
    
    @State private var selectedVoice: Voice = VoiceLibrary.availableVoices[0]
    @State private var speechSpeed: Double = 1.0
    @State private var showAbout = false
    
    @State private var updateStatus = "Check for Updates"
    @State private var updateURL: String? = nil
    
    var body: some View {
        ZStack {
            AmbientThemeBackground(theme: appSettings.appTheme)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                HStack(alignment: .top, spacing: 0) {
                    LeftPanel(textInput: $textInput)
                        .frame(width: geometry.size.width * 0.70, height: geometry.size.height)
                    
                    Divider()
                    
                    RightPanel(textInput: $textInput, selectedVoice: $selectedVoice, speechSpeed: $speechSpeed)
                        .frame(width: geometry.size.width * 0.30, height: geometry.size.height)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // FIX: Removed duplicate Trash icon. Kept only the Info icon.
                Button {
                    showAbout.toggle()
                } label: {
                    Image(systemName: "info.circle")
                }
                .help("About KokoroMac")
                .popover(isPresented: $showAbout, arrowEdge: .bottom) { aboutContent }
            }
        }
    }
    
    private var aboutContent: some View {
        VStack(spacing: 12) {
            Text("About")
                .font(.system(size: 14, weight: .semibold))

            VStack(spacing: 3) {
                if let nsImage = NSImage(named: "AppIcon") {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 56, height: 56)
                        .cornerRadius(12)
                }
                Text("KokoroMac")
                    .font(.system(size: 13, weight: .bold))
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Button(action: checkForUpdates) {
                Text(updateStatus)
                    .font(.system(size: 11))
                    .foregroundColor(updateURL != nil ? .white : nil)
                    .padding(.horizontal, updateURL != nil ? 8 : 0)
                    .padding(.vertical, updateURL != nil ? 3 : 0)
                    .background(updateURL != nil ? appSettings.appTheme.accentColor : Color.clear)
                    .cornerRadius(4)
            }
            .controlSize(.small)
            .disabled(updateStatus == "Checking…" || updateStatus == "Up to Date")
            
            Divider().opacity(0.5)

            HStack {
                Text("Theme")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("", selection: $appSettings.appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            VStack(spacing: 1) {
                Text("2026 Developed by [arinltte](https://github.com/arinltte)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .tint(appSettings.appTheme.accentColor)
                Text("cjshen00@gmail.com")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .tint(appSettings.appTheme.accentColor)
            }
            .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(width: 250, height: 320)
    }

    private func checkForUpdates() {
        if let url = updateURL {
            NSWorkspace.shared.open(URL(string: url)!)
            return
        }
        updateStatus = "Checking…"
        Task {
            do {
                let reqURL = URL(string: "https://github.com/arinltte/KokoroMac/releases/latest")!
                var request = URLRequest(url: reqURL)
                request.httpMethod = "HEAD"
                let (_, response) = try await URLSession.shared.data(for: request)
                let tag = (response.url?.lastPathComponent ?? "")
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "v"))

                let current = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0.1.0"
                let isNewer = tag.compare(current, options: .numeric) == .orderedDescending

                if !tag.isEmpty && isNewer {
                    updateStatus = "New Version (v\(tag))"
                    updateURL = "https://github.com/arinltte/KokoroMac/releases/latest"
                } else {
                    updateStatus = "Up to Date"
                }
            } catch {
                updateStatus = "Check for Updates"
            }
        }
    }
}
