//
//  ContentView.swift
//  Trois-cam
//
//  Created by Joss Manger on 1/19/20.
//  Copyright © 2020 Joss Manger. All rights reserved.
//

import SwiftUI
import AVFoundation
import UIKit
import CoreLocation
import Photos
import CoreMotion
import SensorKit

let subNet = "100"

let motion = CMMotionManager()
var exp = ""
let ID2 = "01"
let ID = "01/Data"
let accName = "/Accelerometer.csv"
let gyroName = "/GyroScope.csv"
let magneName = "/Magnenometer.csv"
let waveName = "/Wave.csv"
let frontName = "/Front.mov"
let fingerName = "/PPG.mov"

let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    
var accURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + accName)
var gyroURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + gyroName)
var magneURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + magneName)
var waveURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + waveName)
var frontURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + frontName)
var fingerURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + fingerName)

var accOutput = OutputStream.toMemory()
var accCsvWriter = CHCSVWriter(outputStream: accOutput, encoding: String.Encoding.utf8.rawValue, delimiter: ",".utf16.first!)
var accBuffer = (accOutput.property(forKey: .dataWrittenToMemoryStreamKey) as? Data)!

var gyroOutput = OutputStream.toMemory()
var gyroCsvWriter = CHCSVWriter(outputStream: gyroOutput, encoding: String.Encoding.utf8.rawValue, delimiter: ",".utf16.first!)
var gyroBuffer = (gyroOutput.property(forKey: .dataWrittenToMemoryStreamKey) as? Data)!

var magneOutput = OutputStream.toMemory()
var magneCsvWriter = CHCSVWriter(outputStream: magneOutput, encoding: String.Encoding.utf8.rawValue, delimiter: ",".utf16.first!)
var magneBuffer = (magneOutput.property(forKey: .dataWrittenToMemoryStreamKey) as? Data)!

var waveOutput = OutputStream.toMemory()
var waveCsvWriter = CHCSVWriter(outputStream: waveOutput, encoding: String.Encoding.utf8.rawValue, delimiter: ",".utf16.first!)
var waveBuffer = (waveOutput.property(forKey: .dataWrittenToMemoryStreamKey) as? Data)!


struct MultiView: View{
    @State private var timeRemaining = 90
    @State private var start = false
    @State private var selectedMode = "Auto"
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let cameraSource = CameraController()
    
    @State var selectedIndex:Int? = nil
    
    var body: some View {
        VStack{
            
            Text("Selected:\(ExperimentStr)")
            Text("Selected:\(selectedMode)")
            HStack(spacing:0){
                
                ForEach(Array([Color.green, Color.red].enumerated()),id: \.offset){ (index,value) in
                    CameraView(color: value, session: self.cameraSource.captureSession, index: index,selectedIndex:self.selectedIndex).frame(width: 216, height: 384, alignment: .center)
                    
                }
                
            }
            
            Button(action: {toggleTorch(on: true);},label:{Text("Flash")})
            Text("Time:\(timeRemaining)")
            Button(action: {manualISO();selectedMode="Manual"},label:{Text("manual")})
            Button(action: {autoISO();selectedMode = "Auto"},label:{Text("auto")})
            
            Button(action:{start = true;manualISOBack();frontURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + ExperimentStr + frontName);fingerURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + ExperimentStr+fingerName);accURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + ExperimentStr + accName);gyroURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + ExperimentStr + gyroName);magneURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + ExperimentStr + magneName);waveURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(ID + ExperimentStr + waveName); cameraSource.startRecord(); toggleTorch(on: true); cameraSource.startRecord2(); urlConnection(u: "http://192.168.1." + subNet + ":5000"); urlConnection(u: "http://192.168.1." + subNet + ":5000/upload");collectSensorData()},label:{Text("Start Survey")})
            //            Toggle("Start Survey", isOn: $start)
            
            Spacer()
        }.onReceive(timer){time in
            if self.timeRemaining > 0 && self.start{
                self.timeRemaining -= 1
//                var dataqueue = DispatchQueue(label: "data" + String(self.timeRemaining))
//                dataqueue.async {
////                    writeDepth(data: cameraSource.getdpth())
//                    trueDepthCsvWriter?.writeField("1")
//                    trueDepthCsvWriter?.finishLine()
//                }
                
            }
            else if self.timeRemaining == 0{
                cameraSource.stopRecord()
                cameraSource.stopRecord2()
                urlConnection(u: "http://192.168.1." + subNet + ":5000/dirk")
                stopDataCollection()
                self.timeRemaining -= 1
                usleep(3000000)
                urlConnection(u: "http://192.168.1." + subNet + ":5000/get")
                
                
            }
        }
        
    }
}

struct MultiView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

func toggleTorch(on: Bool) {
    guard let device = AVCaptureDevice.default(for: .video) else { return }
    
    if device.hasTorch {
        do {
            try device.lockForConfiguration()
            
            if on == true {
                device.torchMode = .on
            } else {
                device.torchMode = .off
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    } else {
        print("Torch is not available")
    }
}

func manualISO()
{
    
    guard let device = AVCaptureDevice.default(.builtInTrueDepthCamera,for: .video, position: .front) else { return }
    
    
    do {
        try device.lockForConfiguration()
        device.exposureMode = .custom
        device.setExposureModeCustom(duration: CMTimeMake(value: 1, timescale: 50), iso: 100, completionHandler: nil)
        device.whiteBalanceMode = .locked
        
        device.unlockForConfiguration()
    } catch {
        print("Torch could not be used")
    }
}

func autoISO()
{
    guard let device = AVCaptureDevice.default(.builtInTrueDepthCamera,for: .video, position: .front) else { return }
    
    
    do {
        try device.lockForConfiguration()
        
        device.exposureMode = .autoExpose
        device.whiteBalanceMode = .autoWhiteBalance
        
        device.unlockForConfiguration()
    } catch {
        print("Torch could not be used")
    }
    
}
func manualISOBack()
{
    
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
    
    
    do {
        try device.lockForConfiguration()
        device.exposureMode = .locked
        device.whiteBalanceMode = .locked
        device.focusMode = .locked
        device.unlockForConfiguration()
    } catch {
        print("Torch could not be used")
    }
}


func autoISOBack()
{
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
    
    
    do {
        try device.lockForConfiguration()
        
        device.exposureMode = .autoExpose
        
        device.unlockForConfiguration()
    } catch {
        print("Torch could not be used")
    }
    
}
func urlConnection(u: String)
{
    let lowerBounds = String.Index(encodedOffset: 1)
    if (u == "http://192.168.1." + subNet + ":5000/upload"){
        var ex:String = String(ExperimentStr[lowerBounds...])
        let params = ["timestamp": String(Int(Date().timeIntervalSince1970 * 1000)), "nameagegender":"Yuki", "experiment": ex]
        
        HTTP.POST(u, parameters: params) { response in
            
            //            print(response)
        }
        
    }
    else if(u == "http://192.168.1." + subNet + ":5000/get")
    {
        HTTP.GET(u){
            response in
            let responseArr = response.text!.components(separatedBy: "\n")
            print(responseArr)
            for row in responseArr{
                print(row)
                if row == ""{
                    print(1)
                }
                else{
                    print(0)
                    let timestamp = row.components(separatedBy: ",")[0]
                    let value = row.components(separatedBy: ",")[1]
                    waveCsvWriter?.writeField(timestamp)
                    waveCsvWriter?.writeField(value)
                    
                    waveCsvWriter?.finishLine()
                }
                
            }
            do{
                try waveBuffer.write(to: waveURL)
            }
            catch{
                
            }
            
        }
        
    }
    else{
        
        
        let url = URL(string: u)!
        
        var request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                
            } else if let error = error {
                print("HTTP Request Failed \(error)")
            }
        }
        //
        task.resume()
        
    }
}
func collectAmbientLight(){
    if #available(iOS 14.0, *) {
        let ambient = SRSensor(rawValue: "ambientLightSensor")
        let reader = SRSensorReader(sensor: ambient)
        reader.startRecording()
        
    } else {
        // Fallback on earlier versions
    }
    
}

func collectSensorData(){
    if motion.isAccelerometerAvailable && motion.isGyroAvailable && motion.isMagnetometerAvailable{
        motion.accelerometerUpdateInterval = 1.0 / 60.0
        motion.gyroUpdateInterval = 1.0 / 60.0
        motion.magnetometerUpdateInterval = 1.0 / 60.0
        
        motion.startAccelerometerUpdates()
        motion.startGyroUpdates()
        motion.startMagnetometerUpdates()
        
        var timer = Timer(fire: Date(), interval: (1.0/30.0), repeats: true, block: {(timer) in
            if let data = motion.accelerometerData{
                
                accCsvWriter?.writeField(String(Int(Date().timeIntervalSince1970 * 1000)))
                accCsvWriter?.writeField(String(data.acceleration.x))
                accCsvWriter?.writeField(String(data.acceleration.y))
                accCsvWriter?.writeField(String(data.acceleration.z))
                accCsvWriter?.finishLine()
            }
            
            if let data = motion.gyroData{
                gyroCsvWriter?.writeField(String(Int(Date().timeIntervalSince1970 * 1000)))
                gyroCsvWriter?.writeField(String(data.rotationRate.x))
                gyroCsvWriter?.writeField(String(data.rotationRate.y))
                gyroCsvWriter?.writeField(String(data.rotationRate.z))
                gyroCsvWriter?.finishLine()
            }
            
            if let data = motion.magnetometerData{
                magneCsvWriter?.writeField(String(Int(Date().timeIntervalSince1970 * 1000)))
                magneCsvWriter?.writeField(String(data.magneticField.x))
                magneCsvWriter?.writeField(String(data.magneticField.y))
                magneCsvWriter?.writeField(String(data.magneticField.z))
                magneCsvWriter?.finishLine()
            }
            
        })
        
        RunLoop.current.add(timer, forMode: .default)
    }
}

func enum2String(e: Experiments) -> String{
    switch e {
    case Experiments.Natural_Stationary:
        return "/Natural Stationary"
    case Experiments.LED_Stationary:
        return "/Led Stationary"
    case Experiments.Playground:
        return "/Playground"
    case Experiments.Randomly:
        return "/Randomly"
    case Experiments.Left_Right:
        return "/Left Right"
    case Experiments.Talking:
        return "/Talking"
    case Experiments.Running:
        return "/Running"
    case Experiments.Incandescent_Stationary:
        return "/Incandescent Stationary"
    default:
        break
    }
}

func stopDataCollection() {
    do{
        
        try accBuffer.write(to: accURL)
        try gyroBuffer.write(to: gyroURL)
        try magneBuffer.write(to: magneURL)
    }
    catch{
        
    }
    
   
    motion.stopGyroUpdates()
    motion.stopMagnetometerUpdates()
    motion.stopAccelerometerUpdates()
}

