import Foundation

struct Voice: Identifiable, Hashable {
    let id: String
    let name: String
    let langCode: String
    let grade: String
}

struct VoiceLibrary {
    static let availableVoices: [Voice] = [
        // American English
        Voice(id: "af_heart", name: "Heart (US Female)", langCode: "a", grade: "A"),
        Voice(id: "af_bella", name: "Bella (US Female)", langCode: "a", grade: "A-"),
        Voice(id: "af_nicole", name: "Nicole (US Female)", langCode: "a", grade: "B-"),
        Voice(id: "af_aoede", name: "Aoede (US Female)", langCode: "a", grade: "C+"),
        Voice(id: "af_kore", name: "Kore (US Female)", langCode: "a", grade: "C+"),
        Voice(id: "af_sarah", name: "Sarah (US Female)", langCode: "a", grade: "C+"),
        Voice(id: "am_fenrir", name: "Fenrir (US Male)", langCode: "a", grade: "C+"),
        Voice(id: "am_michael", name: "Michael (US Male)", langCode: "a", grade: "C+"),
        Voice(id: "am_puck", name: "Puck (US Male)", langCode: "a", grade: "C+"),
        
        // British English
        Voice(id: "bf_emma", name: "Emma (UK Female)", langCode: "b", grade: "B-"),
        Voice(id: "bf_isabella", name: "Isabella (UK Female)", langCode: "b", grade: "C"),
        Voice(id: "bm_fable", name: "Fable (UK Male)", langCode: "b", grade: "C"),
        Voice(id: "bm_george", name: "George (UK Male)", langCode: "b", grade: "C")
    ]
}
