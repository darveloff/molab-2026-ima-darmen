//
//  CameraModel.swift
//  week8
//
//  Runs the camera, applies filters, records video and takes photos.
//

import SwiftUI
import AVFoundation
import Photos
import CoreImage

@Observable
class CameraModel: NSObject {
  // things the screen shows
  var previewImage: CGImage?
  var selectedEffect: VideoEffect = .normal
  var strength: Double = 0.5
  var isRecording = false
  var message: String?

  // used on the camera queue, so SwiftUI does not watch them
  @ObservationIgnored var currentEffect: VideoEffect = .normal
  @ObservationIgnored var currentStrength: Double = 0.5
  @ObservationIgnored let context = CIContext()

  @ObservationIgnored private let session = AVCaptureSession()
  @ObservationIgnored private var videoDevice: AVCaptureDevice?
  @ObservationIgnored private var isSetUp = false

  // recording
  @ObservationIgnored private var assetWriter: AVAssetWriter?
  @ObservationIgnored private var writerInput: AVAssetWriterInput?
  @ObservationIgnored private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
  @ObservationIgnored private var isWriting = false
  @ObservationIgnored private var startTime: CMTime?
  @ObservationIgnored private var videoURL: URL?

  // photo
  @ObservationIgnored private var wantsPhoto = false

  // MARK: - Setup

  func start() {
    PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in }

    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      setupSession()
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted { self.setupSession() }
      }
    default:
      DispatchQueue.main.async { self.message = "Camera access denied" }
    }
  }

  private func setupSession() {
    guard !isSetUp else { return }
    isSetUp = true

    session.beginConfiguration()

    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
          let input = try? AVCaptureDeviceInput(device: device),
          session.canAddInput(input)
    else {
      session.commitConfiguration()
      return
    }
    videoDevice = device
    session.addInput(input)

    let output = AVCaptureVideoDataOutput()
    output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
    if session.canAddOutput(output) {
      session.addOutput(output)
      output.connection(with: .video)?.videoRotationAngle = 90
    }

    session.commitConfiguration()

    DispatchQueue.global(qos: .userInitiated).async {
      self.session.startRunning()
    }
  }

  // MARK: - Controls

  func changeEffect(to effect: VideoEffect) {
    selectedEffect = effect
    currentEffect = effect
  }

  func changeStrength(to value: Double) {
    currentStrength = value
  }

  func takePhoto() {
    wantsPhoto = true
  }

  func toggleRecording() {
    if isRecording {
      stopRecording()
    } else {
      startRecording()
    }
  }

  // MARK: - Recording

  private func startRecording() {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("week8.mp4")
    try? FileManager.default.removeItem(at: url)
    videoURL = url

    // camera gives landscape size, swap for portrait
    var width = 1080
    var height = 1920
    if let device = videoDevice {
      let dims = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
      width = Int(dims.height)
      height = Int(dims.width)
    }

    do {
      let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
      let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: width,
        AVVideoHeightKey: height
      ])
      input.expectsMediaDataInRealTime = true
      // the preview is mirrored, so mirror the saved video too
      input.transform = CGAffineTransform(scaleX: -1, y: 1)

      adaptor = AVAssetWriterInputPixelBufferAdaptor(
        assetWriterInput: input,
        sourcePixelBufferAttributes: [
          kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ])

      if writer.canAdd(input) { writer.add(input) }
      writer.startWriting()
      writer.startSession(atSourceTime: .zero)

      assetWriter = writer
      writerInput = input
      startTime = nil
      isWriting = true
      isRecording = true
    } catch {
      message = "Could not start recording"
    }
  }

  private func stopRecording() {
    isWriting = false
    isRecording = false
    writerInput?.markAsFinished()
    assetWriter?.finishWriting { [weak self] in
      guard let self, let url = self.videoURL else { return }
      self.save("Video saved") {
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      }
      self.assetWriter = nil
      self.writerInput = nil
      self.adaptor = nil
    }
  }

  // MARK: - Saving

  private func savePhoto(_ image: CIImage) {
    guard let cgImage = context.createCGImage(image, from: image.extent) else { return }
    let photo = UIImage(cgImage: cgImage, scale: 1, orientation: .upMirrored)
    save("Photo saved") {
      PHAssetChangeRequest.creationRequestForAsset(from: photo)
    }
  }

  private func save(_ text: String, change: @escaping () -> Void) {
    PHPhotoLibrary.shared().performChanges(change) { saved, _ in
      DispatchQueue.main.async {
        self.message = saved ? text : "Could not save to Photos"
      }
    }
  }

  private func writeFrame(_ buffer: CVPixelBuffer, image: CIImage, changed: Bool, time: CMTime) {
    guard let writerInput, writerInput.isReadyForMoreMediaData, let adaptor else { return }

    if startTime == nil { startTime = time }
    let frameTime = CMTimeSubtract(time, startTime ?? .zero)

    var output = buffer
    if changed {
      var newBuffer: CVPixelBuffer?
      CVPixelBufferCreate(kCFAllocatorDefault,
                          CVPixelBufferGetWidth(buffer),
                          CVPixelBufferGetHeight(buffer),
                          kCVPixelFormatType_32BGRA, nil, &newBuffer)
      if let newBuffer {
        context.render(image, to: newBuffer)
        output = newBuffer
      }
    }
    adaptor.append(output, withPresentationTime: frameTime)
  }
}

// MARK: - Camera frames

extension CameraModel: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

    let (image, changed) = filterImage(buffer)

    if wantsPhoto {
      wantsPhoto = false
      savePhoto(image)
    }

    if isWriting {
      let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
      writeFrame(buffer, image: image, changed: changed, time: time)
    }
  }
}
