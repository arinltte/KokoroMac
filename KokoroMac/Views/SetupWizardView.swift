import SwiftUI
import AppKit

struct SetupWizardView: View {
    @ObservedObject var setupManager: SetupManager
    
    // Detects if the setup failed or requires user action (like connecting to Wi-Fi or installing Homebrew)
    private var hasError: Bool {
        let msg = setupManager.statusMessage.lowercased()
        return !setupManager.isInstalling && (msg.contains("failed") || msg.contains("required") || msg.contains("not found") || msg.contains("⚠️"))
    }
    
    // Dynamically changes button text based on state
    private var buttonText: String {
        return hasError ? "Retry Setup" : "Start Setup"
    }
    
    // Colors the status text red if it's an error/warning
    private var statusColor: Color {
        let msg = setupManager.statusMessage
        if msg.contains("⚠️") || msg.lowercased().contains("failed") || msg.lowercased().contains("not found") {
            return .red
        }
        return .secondary
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 1. App Logo
            if let nsImage = NSImage(named: "AppIcon") {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            } else {
                // Fallback if AppIcon is missing from Assets
                Image(systemName: "waveform.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.blue)
            }
            
            // 2. Welcome Text
            VStack(spacing: 12) {
                Text("Welcome to KokoroMac")
                    .font(.system(size: 36, weight: .bold))
                
                Text("To get started, we need to set up the local inference engine and dependencies. This happens entirely on your Mac and only needs to be done once.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .font(.title3)
                    .frame(maxWidth: 550)
            }
            
            Spacer()
            
            // 3. Status / Action Area
            VStack(spacing: 24) {
                if setupManager.isInstalling {
                    VStack(spacing: 16) {
                        ProgressView(value: setupManager.progress, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(width: 450)
                        
                        Text(setupManager.statusMessage)
                            .font(.callout)
                            .foregroundColor(statusColor)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 550, minHeight: 60)
                            .animation(.easeInOut(duration: 0.2), value: setupManager.statusMessage)
                    }
                } else {
                    VStack(spacing: 20) {
                        if hasError {
                            Text(setupManager.statusMessage)
                                .font(.callout)
                                .foregroundColor(statusColor)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 550, minHeight: 60)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .animation(.easeInOut(duration: 0.2), value: setupManager.statusMessage)
                        }
                        
                        Button(action: {
                            setupManager.runSetup()
                        }) {
                            Text(buttonText)
                                .font(.headline)
                                .frame(width: 220, height: 20)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .frame(minHeight: 140) // Prevents UI jumping when switching between button and progress
            
            Spacer()
        }
        .padding(60)
        .frame(minWidth: 900, minHeight: 600) // Matches MainView dimensions exactly to prevent shrinking
    }
}
