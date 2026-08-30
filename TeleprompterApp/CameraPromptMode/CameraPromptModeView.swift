import SwiftUI

struct CameraPromptModeView: View {
    let settings: AppSettings
    let initialScript: Script?

    init(settings: AppSettings, initialScript: Script? = nil) {
        self.settings = settings
        self.initialScript = initialScript
    }

    var body: some View {
        PromptModeView(settings: settings, initialScript: initialScript, initialMode: .camera)
    }
}
