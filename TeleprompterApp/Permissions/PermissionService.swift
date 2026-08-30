import AVFoundation
import Observation
import Photos
import UIKit

enum PermissionStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
}

@Observable
@MainActor
final class PermissionService {
    var cameraStatus: PermissionStatus = .notDetermined
    var microphoneStatus: PermissionStatus = .notDetermined
    var photosAddStatus: PermissionStatus = .notDetermined

    init() {
        refresh()
    }

    func refresh() {
        cameraStatus = mapAVStatus(AVCaptureDevice.authorizationStatus(for: .video))
        microphoneStatus = mapAVStatus(AVCaptureDevice.authorizationStatus(for: .audio))
        photosAddStatus = mapPhotosStatus(PHPhotoLibrary.authorizationStatus(for: .addOnly))
    }

    func requestCamera() async -> PermissionStatus {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraStatus = granted ? .authorized : .denied
        return cameraStatus
    }

    func requestMicrophone() async -> PermissionStatus {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        microphoneStatus = granted ? .authorized : .denied
        return microphoneStatus
    }

    func requestPhotosAddOnly() async -> PermissionStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        photosAddStatus = mapPhotosStatus(status)
        return photosAddStatus
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func mapAVStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .denied: .denied
        case .restricted: .restricted
        @unknown default: .restricted
        }
    }

    private func mapPhotosStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized, .limited: .authorized
        case .denied: .denied
        case .restricted: .restricted
        @unknown default: .restricted
        }
    }
}
