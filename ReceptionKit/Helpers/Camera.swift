//
//  Camera.swift
//  ReceptionKit
//
//  Created by Andy Cho on 2016-06-12.
//  Copyright © 2016 Andy Cho. All rights reserved.
//

import AVFoundation

class Camera: NSObject {
    /// The last image captured from the camera
    fileprivate var cameraImage: UIImage?
    /// Keep a reference to the session so it doesn't get deallocated
    fileprivate var captureSession: AVCaptureSession?

    /**
     Create a Camera instance and start streaming from the front facing camera
     */
    override init() {
        super.init()
        setupCamera()
    }

    /**
     Get a snapshot from the front facing camera

     - returns: The most recent image from the camera, if one exists
     */
    func takePhoto() -> UIImage? {
        return cameraImage
    }

    // MARK: - Private methods

    /**
     Start streaming from the front facing camera
     */
    fileprivate func setupCamera() {
        guard let camera = getFrontFacingCamera() else {
            Logger.error("Front facing camera not found")
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            Logger.error("Could not get the input stream for the camera")
            return
        }
        let output = createCameraOutputStream()
        captureSession = createCaptureSession(input, output: output)
        captureSession?.startRunning()
    }

    /**
     Get the front facing camera, if one exists

     - returns: The front facing camera, an AVCaptureDevice, or `nil` if none exists.
     */
    fileprivate func getFrontFacingCamera() -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        for device in devices! {
            if (device as AnyObject).position == AVCaptureDevicePosition.front {
                return device as? AVCaptureDevice
            }
        }
        return nil
    }

    /**
     Create a stream for the camera output

     - returns: A camera output stream
     */
    fileprivate func createCameraOutputStream() -> AVCaptureVideoDataOutput {
        let queue = DispatchQueue(label: "cameraQueue", attributes: [])
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)

        let key = kCVPixelBufferPixelFormatTypeKey as NSString
        let value = NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)
        output.videoSettings = [key: value]

        return output
    }

    /**
     Create a photo capture session from the camera input and output streams

     - parameter input:  A camera input stream
     - parameter output: A camera output stream

     - returns: An AVCaptureSession that has not yet been started
     */
    fileprivate func createCaptureSession(_ input: AVCaptureDeviceInput, output: AVCaptureVideoDataOutput) -> AVCaptureSession {
        let captureSession = AVCaptureSession()
        captureSession.addInput(input)
        captureSession.addOutput(output)
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        captureSession.startRunning()
        return captureSession
    }

}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        cameraImage = createImageFromBuffer(imageBuffer)
    }

    /**
     Create a UIImage instance from a CVImageBuffer

     - parameter buffer: An instance of a CVImageBuffer

     - returns: An UIImage instance if one could be created, nil otherwise
     */
    fileprivate func createImageFromBuffer(_ buffer: CVImageBuffer) -> UIImage? {
        let noOption = CVPixelBufferLockFlags(rawValue: CVOptionFlags(0))

        CVPixelBufferLockBaseAddress(buffer, noOption)
        defer {
            CVPixelBufferUnlockBaseAddress(buffer, noOption)
        }

        let baseAddress = CVPixelBufferGetBaseAddress(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let newContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        guard let newImage = newContext!.makeImage() else {
            return nil
        }

        return UIImage(cgImage: newImage, scale: 1.0, orientation: getPhotoOrientation())
    }

    fileprivate func getPhotoOrientation() -> UIImageOrientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .downMirrored
        case .landscapeRight:
            return .upMirrored
        case .portrait:
            return .leftMirrored
        case .portraitUpsideDown:
            return .rightMirrored
        default:
            return .rightMirrored
        }
    }

}
