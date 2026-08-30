@preconcurrency import AVFoundation
import Combine
import Photos
import UIKit

enum CameraPosition {
    case front
    case back

    var avPosition: AVCaptureDevice.Position {
        switch self {
        case .front: .front
        case .back: .back
        }
    }
}

@MainActor
final class CameraRecordingService: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var isRecording = false
    @Published var isRecordingPaused = false
    @Published var cameraPosition: CameraPosition
    @Published var lastErrorMessage: String?

    let session = AVCaptureSession()

    private let movieOutput = AVCaptureMovieFileOutput()
    private var activeVideoDevice: AVCaptureDevice?
    private var pendingRecordingURL: URL?
    private var recordingSegmentURLs: [URL] = []
    private var finishAction: RecordingFinishAction = .final
    private var saveContinuation: CheckedContinuation<Void, Error>?

    init(defaultPosition: CameraPosition = .front) {
        self.cameraPosition = defaultPosition
        super.init()
    }

    func configure() async {
        session.beginConfiguration()
        session.sessionPreset = .high
        session.inputs.forEach { session.removeInput($0) }

        do {
            if let videoInput = try videoInput(position: cameraPosition.avPosition), session.canAddInput(videoInput) {
                session.addInput(videoInput)
                activeVideoDevice = videoInput.device
            }
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                }
            }
            if !session.outputs.contains(movieOutput), session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
            }
        } catch {
            lastErrorMessage = "相机配置失败：\(error.localizedDescription)"
        }

        session.commitConfiguration()
    }

    func startSession() {
        guard !session.isRunning else { return }
        session.startRunning()
        isSessionRunning = true
    }

    func stopSession() {
        guard session.isRunning else {
            isSessionRunning = false
            return
        }
        session.stopRunning()
        isSessionRunning = false
    }

    func switchCamera() async {
        cameraPosition = cameraPosition == .front ? .back : .front
        await configure()
        startSession()
    }

    func setZoomFactor(_ factor: CGFloat) {
        guard let activeVideoDevice else { return }
        do {
            try activeVideoDevice.lockForConfiguration()
            activeVideoDevice.videoZoomFactor = min(max(factor, activeVideoDevice.minAvailableVideoZoomFactor), activeVideoDevice.maxAvailableVideoZoomFactor)
            activeVideoDevice.unlockForConfiguration()
        } catch {
            lastErrorMessage = "焦段切换失败：\(error.localizedDescription)"
        }
    }

    func startRecording() async {
        guard !movieOutput.isRecording, !isRecording else { return }
        recordingSegmentURLs = []
        startRecordingSegment()
        isRecording = true
        isRecordingPaused = false
    }

    private func startRecordingSegment() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("teleprompter-\(UUID().uuidString)")
            .appendingPathExtension("mov")
        pendingRecordingURL = url
        finishAction = .final
        movieOutput.startRecording(to: url, recordingDelegate: self)
    }

    func pauseRecording() {
        guard movieOutput.isRecording, !isRecordingPaused else { return }
        finishAction = .pause
        movieOutput.stopRecording()
        isRecordingPaused = true
    }

    func resumeRecording() {
        guard isRecording, isRecordingPaused, !movieOutput.isRecording else { return }
        startRecordingSegment()
        isRecordingPaused = false
    }

    func stopRecordingAndSaveToPhotos() async {
        guard isRecording else { return }
        if isRecordingPaused, !movieOutput.isRecording {
            isRecording = false
            isRecordingPaused = false
            await saveCollectedSegments()
            return
        }
        guard movieOutput.isRecording else { return }
        finishAction = .final
        await withCheckedContinuation { continuation in
            movieOutput.stopRecording()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                continuation.resume()
            }
        }
    }

    private func saveCollectedSegments() async {
        do {
            let outputURL = try await finalRecordingURL()
            try await saveToPhotos(outputURL)
            cleanupSegments(keeping: outputURL)
            lastErrorMessage = "已保存到系统相册"
        } catch {
            lastErrorMessage = "保存到相册失败：\(error.localizedDescription)"
        }
    }

    private func finalRecordingURL() async throws -> URL {
        guard !recordingSegmentURLs.isEmpty else {
            throw NSError(domain: "TeleprompterSave", code: -2, userInfo: [NSLocalizedDescriptionKey: "没有可保存的视频片段"])
        }
        guard recordingSegmentURLs.count > 1 else {
            return recordingSegmentURLs[0]
        }
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("teleprompter-merged-\(UUID().uuidString)")
            .appendingPathExtension("mov")
        try await mergeSegments(recordingSegmentURLs, outputURL: outputURL)
        return outputURL
    }

    private func mergeSegments(_ urls: [URL], outputURL: URL) async throws {
        let composition = AVMutableComposition()
        guard
            let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
            let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            throw NSError(domain: "TeleprompterMerge", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建视频合成轨道"])
        }

        var currentTime = CMTime.zero
        for url in urls {
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            let range = CMTimeRange(start: .zero, duration: duration)
            if let sourceVideo = try await asset.loadTracks(withMediaType: .video).first {
                try videoTrack.insertTimeRange(range, of: sourceVideo, at: currentTime)
                videoTrack.preferredTransform = try await sourceVideo.load(.preferredTransform)
            }
            if let sourceAudio = try await asset.loadTracks(withMediaType: .audio).first {
                try audioTrack.insertTimeRange(range, of: sourceAudio, at: currentTime)
            }
            currentTime = currentTime + duration
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "TeleprompterMerge", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法创建视频导出任务"])
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        let exportBox = ExportSessionBox(exportSession)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exportBox.session.exportAsynchronously {
                Task { @MainActor in
                    self.finishExport(exportBox.session, continuation: continuation)
                }
            }
        }
    }

    private func finishExport(_ exportSession: AVAssetExportSession, continuation: CheckedContinuation<Void, Error>) {
        if let error = exportSession.error {
            continuation.resume(throwing: error)
        } else if exportSession.status == .completed {
            continuation.resume()
        } else {
            continuation.resume(throwing: NSError(domain: "TeleprompterMerge", code: -3, userInfo: [NSLocalizedDescriptionKey: "视频合并未完成"]))
        }
    }

    private func cleanupSegments(keeping keptURL: URL) {
        for url in recordingSegmentURLs where url != keptURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingSegmentURLs = []
    }

    private func saveToPhotos(_ url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "TeleprompterSave", code: -1, userInfo: [NSLocalizedDescriptionKey: "保存到相册失败"]))
                }
            }
        }
    }

    private func videoInput(position: AVCaptureDevice.Position) throws -> AVCaptureDeviceInput? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        guard let device = discovery.devices.first else { return nil }
        return try AVCaptureDeviceInput(device: device)
    }
}

extension CameraRecordingService: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                self.isRecording = false
                self.isRecordingPaused = false
                self.lastErrorMessage = "录制失败：\(error.localizedDescription)"
                return
            }

            self.recordingSegmentURLs.append(outputFileURL)
            switch self.finishAction {
            case .pause:
                return
            case .final:
                self.isRecording = false
                self.isRecordingPaused = false
                await self.saveCollectedSegments()
            }
        }
    }
}

private enum RecordingFinishAction {
    case pause
    case final
}

private struct ExportSessionBox: @unchecked Sendable {
    let session: AVAssetExportSession

    init(_ session: AVAssetExportSession) {
        self.session = session
    }
}
