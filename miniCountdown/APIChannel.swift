import Foundation

enum APIChannel: Int {
    case ollama = 0
    case aiHubMix = 1
    case openAI = 2
    
    var displayName: String {
        switch self {
        case .ollama:
            return "本地Ollama"
        case .aiHubMix:
            return "AiHubMix"
        case .openAI:
            return "OpenAI"
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
        default:
            return .ollama
        }
    }
}