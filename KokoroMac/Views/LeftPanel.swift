// Views/LeftPanel.swift
import SwiftUI

struct LeftPanel: View {
    @Binding var textInput: String
    @EnvironmentObject var ttsManager: TTSManager
    @EnvironmentObject var appSettings: AppSettings
    
    var primaryText: Color { appSettings.appTheme.isTrueDark ? .white : .primary }
    var secondaryText: Color { appSettings.appTheme.isTrueDark ? Color(red: 0.55, green: 0.55, blue: 0.58) : .secondary }
    
    var body: some View {
        // Flat structure matches RightPanel exactly
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Speech Text").font(.headline).foregroundColor(primaryText)
                    Spacer()
                    Button(action: { textInput = "" }) { Image(systemName: "trash").foregroundColor(secondaryText) }.buttonStyle(.plain)
                }
                
                CardContainer(theme: appSettings.appTheme) {
                    MacTextEditor(text: $textInput, insertSignal: appSettings.insertDirective, theme: appSettings.appTheme)
                        .padding(12)
                        .frame(minHeight: 150, maxHeight: .infinity)
                }
                Text("\(textInput.count) characters").font(.caption2).foregroundColor(secondaryText)
            }
            .frame(maxHeight: .infinity)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Audio Preview").font(.headline).foregroundColor(primaryText)
                if let url = ttsManager.currentOutputURL {
                    AudioPlayerView(audioURL: url)
                } else {
                    CardContainer(theme: appSettings.appTheme) {
                        VStack(spacing: 8) {
                            Image(systemName: "waveform").font(.largeTitle).foregroundColor(secondaryText)
                            Text("Generated audio will appear here.").font(.caption).foregroundColor(secondaryText)
                        }
                    }.frame(height: 100)
                }
            }
            .frame(height: 160)
        }
        .padding(20) // Exact match to RightPanel
    }
}
