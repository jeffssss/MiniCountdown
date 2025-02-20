import Foundation

enum APIChannel: Int, CaseIterable {
    case ollama = 0
    case aiHubMix = 1
    case openAI = 2
    case grok = 3
    
    var displayName: String {
        switch self {
        case .ollama:
            return "本地Ollama"
        case .aiHubMix:
            return "AiHubMix"
        case .openAI:
            return "OpenAI"
        case .grok:
            return "Grok"
        }
    }
    
    static func fromString(_ string: String) -> APIChannel {
        switch string {
        case "本地Ollama":
            return .ollama
        case "AiHubMix":
            return .aiHubMix
        case "OpenAI":
            return .openAI
        case "Grok":
            return .grok
        default:
            return .ollama
        }
    }
}
