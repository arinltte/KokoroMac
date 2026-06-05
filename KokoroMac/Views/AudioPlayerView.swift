import SwiftUI
import AVFoundation
import Combine

class AudioPlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var waveformPoints: [CGFloat] = []
    
    func play(url: URL, from time: TimeInterval = 0) {
        do {
            if audioPlayer?.url != url {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.delegate = self
            }
            audioPlayer?.currentTime = time
            audioPlayer?.play()
            isPlaying = true
        } catch { print("Playback failed: \(error.localizedDescription)") }
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.isPlaying = false }
    }
    
    func generateWaveform(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 0.2)
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            do {
                let file = try AVAudioFile(forReading: url)
                let frameCount = AVAudioFrameCount(file.length)
                guard frameCount > 0, let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount) else { return }
                try file.read(into: buffer)
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)
                let samplesCount = 80
                let samplesPerPoint = max(1, frameLength / samplesCount)
                var points: [CGFloat] = []
                for i in 0..<samplesCount {
                    let start = i * samplesPerPoint
                    let end = start + samplesPerPoint
                    var maxSample: Float = 0.0
                    for j in start..<end where j < frameLength { maxSample = max(maxSample, abs(channelData[j])) }
                    points.append(CGFloat(maxSample))
                }
                DispatchQueue.main.async { self.waveformPoints = points }
            } catch { print("❌ [Waveform] Error: \(error)") }
        }
    }
}

struct AudioPlayerView: View {
    let audioURL: URL
    @StateObject private var viewModel = AudioPlayerViewModel()
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var hoverLocation: CGPoint? = nil
    @State private var hoverTime: TimeInterval? = nil
    @State private var lastHoverTime: TimeInterval = 0

    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                if viewModel.isPlaying { viewModel.stop() } else { viewModel.play(url: audioURL, from: 0) }
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable().scaledToFit().frame(width: 44, height: 44)
                    .foregroundColor(appSettings.appTheme.accentColor)
            }
            .buttonStyle(.plain)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(appSettings.appTheme.isTrueDark ? Color(red: 0.12, green: 0.12, blue: 0.12) : Color.clear)
                    .background { if !appSettings.appTheme.isTrueDark { RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial) } }
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(appSettings.appTheme.isTrueDark ? Color(red: 0.15, green: 0.15, blue: 0.15) : .white.opacity(0.1), lineWidth: 1))
                
                TimelineView(.animation) { context in
                    let duration = viewModel.audioPlayer?.duration ?? 1.0
                    let currentTime = viewModel.audioPlayer?.currentTime ?? 0.0
                    let progress = duration > 0 ? CGFloat(currentTime / duration) : 0
                    let playedIndex = Int(progress * CGFloat(viewModel.waveformPoints.count))
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .topLeading) {
                            HStack(alignment: .center, spacing: 3) {
                                if viewModel.waveformPoints.isEmpty {
                                    Text("Processing...").foregroundColor(appSettings.appTheme.isTrueDark ? .white.opacity(0.5) : .secondary).font(.caption)
                                } else {
                                    let count = CGFloat(viewModel.waveformPoints.count)
                                    let spacing: CGFloat = 3
                                    let totalSpacing = spacing * max(0, count - 1)
                                    let barWidth = max(1, (geometry.size.width - 24 - totalSpacing) / count)
                                    
                                    ForEach(0..<viewModel.waveformPoints.count, id: \.self) { index in
                                        let normalized = viewModel.waveformPoints[index]
                                        let barHeight = max(4, geometry.size.height * normalized)
                                        
                                        let isPlayed = index <= playedIndex
                                        let color = isPlayed ? appSettings.appTheme.accentColor : (appSettings.appTheme.isTrueDark ? Color.white.opacity(0.3) : Color.secondary.opacity(0.4))
                                        
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(color)
                                            .frame(width: barWidth, height: barHeight)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .padding(.horizontal, 12)
                            
                            if let loc = hoverLocation {
                                Rectangle().fill(appSettings.appTheme.accentColor.opacity(0.8)).frame(width: 1.5, height: geometry.size.height).offset(x: loc.x - 0.75).allowsHitTesting(false)
                            }
                            if let time = hoverTime, let loc = hoverLocation {
                                Text(String(format: "%02d:%02d.%01d", Int(time) / 60, Int(time) % 60, Int((time * 10).truncatingRemainder(dividingBy: 10))))
                                    .font(.caption2.monospacedDigit()).padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(.ultraThickMaterial).cornerRadius(4).shadow(radius: 2)
                                    .offset(x: min(max(loc.x - 25, 0), geometry.size.width - 50), y: -25).allowsHitTesting(false)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                hoverLocation = location
                                let duration = viewModel.audioPlayer?.duration ?? 0
                                if duration > 0 {
                                    let percentage = max(0, min(1, location.x / geometry.size.width))
                                    hoverTime = duration * percentage
                                    lastHoverTime = hoverTime!
                                }
                            case .ended: hoverLocation = nil; hoverTime = nil
                            }
                        }
                        .onTapGesture { location in
                            let duration = viewModel.audioPlayer?.duration ?? 0
                            if duration > 0 {
                                let percentage = max(0, min(1, location.x / geometry.size.width))
                                viewModel.play(url: audioURL, from: duration * percentage)
                            }
                        }
                    }
                }
            }
            .frame(height: 100)
        }
        .onAppear { viewModel.generateWaveform(from: audioURL) }
        .onChange(of: audioURL) { oldValue, newValue in
            viewModel.stop()
            viewModel.waveformPoints = []
            viewModel.generateWaveform(from: newValue)
        }
    }
}
