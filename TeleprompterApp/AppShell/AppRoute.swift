import Foundation

enum AppRoute: Hashable, Identifiable {
    case fullScreenPrompt
    case cameraPrompt
    case settings

    var id: String {
        switch self {
        case .fullScreenPrompt: "fullScreenPrompt"
        case .cameraPrompt: "cameraPrompt"
        case .settings: "settings"
        }
    }
}
