// Views/RightPanel.swift
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
    
    var primaryText: Color { appSettings.appTheme.isTrueDark ? .white : .primary }
    var secondaryText: Color { appSettings.appTheme.isTrueDark ? Color(red: 0.55, green: 0.55, blue: 0.58) : .secondary }
    var borderColor: Color { appSettings.appTheme.isTrueDark ? Color(red: 0.15, green: 0.15, blue: 0.15) : .white.opacity(0.1) }
    
    var body: some View {
        // Flat structure matches LeftPanel exactly
        VStack(spacing: 16) {
            // Voice Selection Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Voice Selection").font(.headline).foregroundColor(primaryText)
                Picker("", selection: $selectedVoice) {
                    ForEach(VoiceLibrary.availableVoices) { voice in Text("\(voice.name) [\(voice.grade)]").tag(voice) }
                }
                .labelsHidden().pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(appSettings.appTheme.isTrueDark ? Color(red: 0.10, green: 0.10, blue: 0.10) : .clear))
                .background { if !appSettings.appTheme.isTrueDark { RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial) } }
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1))
            }
            
            // Speech Toolbox Card
            VStack(alignment: .leading, spacing: 0) {
                Text("Speech Toolbox").font(.headline).foregroundColor(primaryText).padding(.bottom, 4)
                ToolboxRow(icon: "pause.rectangle", title: "Insert Pause", theme: appSettings.appTheme) { appSettings.insertDirective.send("PAUSE_CHIP") }
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
            
            VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Speech Speed").font(.headline).foregroundColor(primaryText)
                        Spacer()
                        Text(String(format: "x%.1f", speechSpeed))
                            .foregroundColor(secondaryText)
                            .font(.caption)
                            .monospacedDigit()
                    }
                    Slider(value: $speechSpeed, in: 0.5...1.5, step: 0.1)
                        .tint(appSettings.appTheme.accentColor)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(appSettings.appTheme.isTrueDark ? Color(red: 0.10, green: 0.10, blue: 0.10) : .clear))
                .background { if !appSettings.appTheme.isTrueDark { RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial) } }
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
            
            Spacer() // Pushes bottom section down
            
            // Bottom Section (Fixed Height for Alignment)
            VStack(spacing: 12) {
                //Spacer()
                Button(action: { ttsManager.generateSpeech(text: textInput, voice: selectedVoice, speed: speechSpeed) }) {                    HStack {
                        if !ttsManager.isServerReady {
                            ProgressView().controlSize(.small).tint(.white)
                            Text("Starting Server...").fontWeight(.bold)
                        } else if ttsManager.isGenerating {
                            ProgressView().controlSize(.small).tint(.white)
                            Text("Generating...").fontWeight(.bold)
                        } else {
                            Image(systemName: "waveform.circle.fill")
                            Text("Generate Speech").fontWeight(.bold)
                        }
                    }
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(LinearGradient(colors: [appSettings.appTheme.accentColor.opacity(0.9), appSettings.appTheme.accentColor.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                    .cornerRadius(10).shadow(color: appSettings.appTheme.accentColor.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain).disabled(!ttsManager.isServerReady || ttsManager.isGenerating || textInput.isEmpty)
                
                Button(action: exportAudio) {
                    Label("Export Audio...", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity).padding(.vertical, 10)
                        .foregroundColor(primaryText)
                        .background(RoundedRectangle(cornerRadius: 10).fill(appSettings.appTheme.isTrueDark ? Color(red: 0.10, green: 0.10, blue: 0.10) : .clear))
                        .background { if !appSettings.appTheme.isTrueDark { RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial) } }
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1))
                }
                .buttonStyle(.plain).disabled(ttsManager.currentOutputURL == nil)
            }
            .frame(height: 160)
        }
        .padding(20) // Exact match to LeftPanel
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
