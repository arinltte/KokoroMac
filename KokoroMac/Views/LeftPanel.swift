import SwiftUI

struct LeftPanel: View {
    @Binding var textInput: String
    @EnvironmentObject var ttsManager: TTSManager
    @EnvironmentObject var appSettings: AppSettings
     
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Speech Text Area (Takes remaining space)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Speech Text")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button(action: { textInput = "" }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.regularMaterial)
                    
                    MacTextEditor(text: $textInput, insertSignal: appSettings.insertDirective, theme: appSettings.appTheme, appSettings: appSettings)
                        .padding(12)
                        .padding(.bottom, 20)
                     
                    Text("\(textInput.count) characters")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                        .padding(.trailing, 16)
                        .padding(.bottom, 8)
                }
            }
            .frame(maxHeight: .infinity)
            
            // Audio Preview Area (Fixed compact height)
            VStack(alignment: .leading, spacing: 8) {
                Text("Audio Preview")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.regularMaterial)
                    
                    if let url = ttsManager.currentOutputURL {
                        AudioPlayerView(audioURL: url)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "waveform")
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(.tertiary)
                            Text("Generated audio will appear here")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    }
                }
            }
            .frame(height: 140)
        }
        .padding(20)
    }
}
