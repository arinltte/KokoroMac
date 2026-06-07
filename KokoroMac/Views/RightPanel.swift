import SwiftUI
import UniformTypeIdentifiers
import Combine

struct ToolboxRow: View {
    let icon: String; let title: String; let theme: AppTheme; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundColor(theme.isTrueDark ? .white : .primary).frame(width: 20)
                Text(title).foregroundColor(theme.isTrueDark ? .white : .primary)
                Spacer()
            }
            .padding(.vertical, 10).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

struct RightPanel: View {
    @Binding var textInput: String
    @Binding var selectedVoice: Voice
    @Binding var speechSpeed: Double
    @EnvironmentObject var ttsManager: TTSManager
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var showPhonemeHelp = false
    @State private var showVoicePicker = false
    
    var primaryText: Color { appSettings.appTheme.isTrueDark ? .white : .primary }
    var secondaryText: Color { appSettings.appTheme.isTrueDark ? Color(red: 0.55, green: 0.55, blue: 0.58) : .secondary }
    var borderColor: Color { appSettings.appTheme.isTrueDark ? Color(red: 0.15, green: 0.15, blue: 0.15) : .white.opacity(0.1) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 1. Voice Selection Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Voice Selection")
                    .font(.headline)
                    .foregroundColor(primaryText)
                
                Button { showVoicePicker.toggle() } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.wave.2.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(appSettings.appTheme.accentColor)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedVoice.name).font(.body).fontWeight(.medium).foregroundStyle(.primary)
                            Text(selectedVoice.category == "US" ? "American English" : "British English")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(selectedVoice.grade)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.quaternary, in: Capsule())
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showVoicePicker, arrowEdge: .top) {
                    VoicePickerPopover(selectedVoice: $selectedVoice)
                }
            }
            
            // 2. Speech Toolbox Card
            VStack(alignment: .leading, spacing: 0) {
                Text("Speech Toolbox").font(.headline).foregroundColor(primaryText).padding(.bottom, 4)
                
                ToolboxRow(icon: "pause.rectangle", title: "Short Pause (0.5s)", theme: appSettings.appTheme) {
                    appSettings.insertDirective.send("PAUSE_CHIP_0.5")
                }
                Divider().background(borderColor)
                ToolboxRow(icon: "pause.rectangle", title: "Medium Pause (1.0s)", theme: appSettings.appTheme) {
                    appSettings.insertDirective.send("PAUSE_CHIP_1.0")
                }
                Divider().background(borderColor)
                ToolboxRow(icon: "pause.rectangle", title: "Long Pause (2.0s)", theme: appSettings.appTheme) {
                    appSettings.insertDirective.send("PAUSE_CHIP_2.0")
                }
                Divider().background(borderColor)
                
                HStack(spacing: 0) {
                    ToolboxRow(icon: "character.phonetic", title: "Phoneme Override", theme: appSettings.appTheme) { appSettings.insertDirective.send("PHONEME_OVERRIDE") }
                    Button(action: { showPhonemeHelp.toggle() }) { Image(systemName: "questionmark.circle").foregroundColor(secondaryText).padding(.trailing, 4) }
                        .buttonStyle(.plain).popover(isPresented: $showPhonemeHelp, arrowEdge: .leading) { phonemeHelpView }
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(appSettings.appTheme.isTrueDark ? Color(red: 0.10, green: 0.10, blue: 0.10) : .clear))
            .background { if !appSettings.appTheme.isTrueDark { RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial) } }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
            
            // 3. Speech Speed Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Speech Speed").font(.headline).foregroundColor(primaryText)
                    Spacer()
                    Text(String(format: "x%.1f", speechSpeed))
                        .foregroundColor(secondaryText).font(.caption).monospacedDigit()
                }
                Slider(value: $speechSpeed, in: 0.5...1.5, step: 0.1)
                    .tint(appSettings.appTheme.accentColor)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(appSettings.appTheme.isTrueDark ? Color(red: 0.10, green: 0.10, blue: 0.10) : .clear))
            .background { if !appSettings.appTheme.isTrueDark { RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial) } }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
            
            Spacer()
            
            // 4. Bottom Action Buttons
            Button {
                // Use ttsReadyText. Fallback to textInput just in case it hasn't populated yet.
                let textToGenerate = appSettings.ttsReadyText.isEmpty ? textInput : appSettings.ttsReadyText
                ttsManager.generateSpeech(text: textToGenerate, voice: selectedVoice, speed: speechSpeed)
            } label: {
                HStack {
                    if !ttsManager.isServerReady {
                        ProgressView().controlSize(.small).tint(.white)
                        Text("Starting Server...").fontWeight(.bold)
                    } else if ttsManager.isGenerating {
                        ProgressView().controlSize(.small).tint(.white)
                        Text("Generating...").fontWeight(.bold)
                    } else {
                        Image(systemName: "waveform.badge.mic")
                        Text("Generate Speech").fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(appSettings.appTheme.accentColor)
            .controlSize(.large)
            .disabled(!ttsManager.isServerReady || ttsManager.isGenerating || textInput.isEmpty)
            
            Button { exportAudio() } label: {
                Label("Export Audio...", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(ttsManager.currentOutputURL == nil)
        }
        .padding(20)
    }
    
    private var phonemeHelpView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phoneme Override").font(.headline)
            Text("Syntax: `[word](/ipa/)`").font(.system(.caption, design: .monospaced))
            Text("Example: `[Kokoro](/kˈOkəɹO/)`").font(.system(.caption, design: .monospaced))
        }.padding().frame(width: 250)
    }
    
    func exportAudio() {
        guard let url = ttsManager.currentOutputURL else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.wav]
        panel.nameFieldStringValue = "kokoro_export.wav"
        if panel.runModal() == .OK, let saveURL = panel.url { try? FileManager.default.copyItem(at: url, to: saveURL) }
    }
}
