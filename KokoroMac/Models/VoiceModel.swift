import Foundation

struct Voice: Identifiable, Hashable {
    let id: String
    let name: String
    let langCode: String
    let grade: String
    let category: String // "US" or "UK"
}

struct VoiceLibrary {
    static let availableVoices: [Voice] = [
        // American English
        Voice(id: "af_heart", name: "Heart (Female)", langCode: "a", grade: "A", category: "US"),
        Voice(id: "af_bella", name: "Bella (Female)", langCode: "a", grade: "A-", category: "US"),
        Voice(id: "af_nicole", name: "Nicole (Female)", langCode: "a", grade: "B-", category: "US"),
        Voice(id: "af_aoede", name: "Aoede (Female)", langCode: "a", grade: "C+", category: "US"),
        Voice(id: "af_kore", name: "Kore (Female)", langCode: "a", grade: "C+", category: "US"),
        Voice(id: "af_sarah", name: "Sarah (Female)", langCode: "a", grade: "C+", category: "US"),
        Voice(id: "am_fenrir", name: "Fenrir (Male)", langCode: "a", grade: "C+", category: "US"),
        Voice(id: "am_michael", name: "Michael (Male)", langCode: "a", grade: "C+", category: "US"),
        Voice(id: "am_puck", name: "Puck (Male)", langCode: "a", grade: "C+", category: "US"),
        
        // British English
        Voice(id: "bf_emma", name: "Emma (Female)", langCode: "b", grade: "B-", category: "UK"),
        Voice(id: "bf_isabella", name: "Isabella (Female)", langCode: "b", grade: "C", category: "UK"),
        Voice(id: "bm_fable", name: "Fable (Male)", langCode: "b", grade: "C", category: "UK"),
        Voice(id: "bm_george", name: "George (Male)", langCode: "b", grade: "C", category: "UK")
    ]
}
