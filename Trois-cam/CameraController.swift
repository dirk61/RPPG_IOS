//
//  CameraController.swift
//  Trois-cam
//
//  Created by Joss Manger on 1/19/20.
//  Copyright © 2020 Joss Manger. All rights reserved.
//

import UIKit
import AVFoundation
import Combine
import Photos

class CameraController:NSObject, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("finishrecording")
//        // Check the authorization status.
//        PHPhotoLibrary.requestAuthorization { status in
//            if status == .authorized {
//                // Save the movie file to the photo library and cleanup.
//                PHPhotoLibrary.shared().performChanges({
//                    let options = PHAssetResourceCreationOptions()
//                    options.shouldMoveFile = true
//                    let creationRequest = PHAssetCreationRequest.forAsset()
//                    creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
//
//                }
//                )
//            }
//        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("StartRecording")
    }
    
    
    private var session: AVCaptureMultiCamSession!
    var startRecording = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    var captureSession: AVCaptureMultiCamSession? {
        return self.session
    }
    
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var movieFileOutput2: AVCaptureMovieFileOutput?
    
    static func addConnection(session: AVCaptureMultiCamSession,layer: AVCaptureVideoPreviewLayer, index: Int){
        
        layer.videoGravity = .resizeAspectFill
        layer.setSessionWithNoConnection(session)
        
        let videoPort = session.inputs[index].ports.first!
        
        let connection = MyConnection(inputPort: videoPort, videoPreviewLayer: layer)
        
        session.addConnection(connection)
        
    }
    
    var anyCan:AnyCancellable!
    
    func startRecord(){
        sessionQueue.async {
            
            
            //        print(movieFileOutput?.isRecording)
            
            if self.movieFileOutput?.isRecording == false{
                let lowerbound = String.Index(encodedOffset: 1)
                let outputFileName = ExperimentStr[lowerbound...] +  "_Front"
//                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)

                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let fileUrl = paths[0].appendingPathComponent(outputFileName + ".mov")
                print(fileUrl.absoluteString)
                self.movieFileOutput?.startRecording(to: frontURL, recordingDelegate: self)
                
                //            print(movieFileOutput?.isRecording)
            }}}
    
    func stopRecord(){
        sessionQueue.async {
            
            //        print(movieFileOutput?.isRecording)
            self.movieFileOutput?.stopRecording()
            //        print(movieFileOutput?.isRecording)
        }
    }
    
    func startRecord2(){
        sessionQueue.async {
            

            if self.movieFileOutput2?.isRecording == false{
                let lowerbound = String.Index(encodedOffset: 1)
                let outputFileName = ExperimentStr[lowerbound...] + "_finger"
//                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let fileUrl = paths[0].appendingPathComponent(outputFileName + ".mov")
                
                self.movieFileOutput2?.startRecording(to: fingerURL, recordingDelegate: self)

            }}}
    
    func stopRecord2(){
        sessionQueue.async {

            self.movieFileOutput2?.stopRecording()
        }
    }
    
    override init() {
        
        #if !targetEnvironment(simulator)
        
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("unsupported")
            return
        }
        
        
        session = AVCaptureMultiCamSession()
        session.beginConfiguration()
        //
        let device2 = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)!
        
        let input2 = try! AVCaptureDeviceInput(device: device2)
        session.addInputWithNoConnections(input2)
        
        let device1 = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
        let input1 = try! AVCaptureDeviceInput(device: device1)
        session.addInputWithNoConnections(input1)
        
        
        
        let output = AVCaptureMovieFileOutput()
        self.movieFileOutput = output
        
        let output2 = AVCaptureMovieFileOutput()
        self.movieFileOutput2 = output2
        //        session.sessionPreset = .high
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        session.addOutput(output)
        session.addOutput(output2)
        session.commitConfiguration()
        
        session.startRunning()
        
        
        //      func angleOffsetFromPortraitOrientation(at position: AVCaptureDevice.Position) -> Double {
        //        switch self {
        //        case .portrait:
        //          return position == .front ? .pi : 0
        //        case .portraitUpsideDown:
        //          return position == .front ? 0 : .pi
        //        case .landscapeRight:
        //          return -.pi / 2.0
        //        case .landscapeLeft:
        //          return .pi / 2.0
        //        default:
        //          return 0
        //        }
        //      }
        
        
        #endif
        
    }
    
    
    
}


class MyConnection : AVCaptureConnection {
    
    override var videoMaxScaleAndCropFactor: CGFloat {
        return 2.0
    }
    
}


