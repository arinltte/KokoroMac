import SwiftUI

struct VoicePickerPopover: View {
    @Binding var selectedVoice: Voice
    @State private var searchQuery = ""
    @Environment(\.dismiss) var dismiss
    
    var filteredVoices: [Voice] {
        if searchQuery.isEmpty {
            return VoiceLibrary.availableVoices
        }
        return VoiceLibrary.availableVoices.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.grade.localizedCaseInsensitiveContains(searchQuery) ||
            $0.category.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var groupedVoices: [(String, [Voice])] {
        let usVoices = filteredVoices.filter { $0.category == "US" }
        let ukVoices = filteredVoices.filter { $0.category == "UK" }
        var result: [(String, [Voice])] = []
        if !usVoices.isEmpty { result.append(("American English", usVoices)) }
        if !ukVoices.isEmpty { result.append(("British English", ukVoices)) }
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Native-style Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                
                TextField("Search Voices...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.body)
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 10)
            
            Divider().opacity(0.5)
            
            // Grouped List
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(groupedVoices, id: \.0) { section in
                        VStack(alignment: .leading, spacing: 4) {
                            // Section Header
                            Text(section.0)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 14)
                                .padding(.top, 12)
                                .padding(.bottom, 4)
                            
                            // Rows
                            VStack(spacing: 2) {
                                ForEach(section.1) { voice in
                                    VoiceRow(voice: voice, isSelected: selectedVoice.id == voice.id) {
                                        selectedVoice = voice
                                        dismiss() // Close popover on selection
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .frame(width: 320, height: 420)
        // Note: macOS .popover automatically applies the native material background,
        // corner radius, and soft system shadow.
    }
}

// MARK: - Voice Row Component

struct VoiceRow: View {
    let voice: Voice
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection Indicator & Name
                HStack(spacing: 8) {
                    // FIX: Always use "checkmark" but hide it with opacity to prevent the "No symbol named ''" error
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.tint)
                        .frame(width: 12)
                        .opacity(isSelected ? 1 : 0)
                    
                    Text(voice.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // Grade Capsule
                Text(voice.grade)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }
}
