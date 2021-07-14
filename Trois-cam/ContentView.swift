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

let subNet = "103"

let motion = CMMotionManager()
let accName = "Accelerometer.csv"
let gyroName = "GyroScope.csv"
let magneName = "Magnenometer.csv"
let waveName = "Wave.csv"
let frontName = "Front.mov"

let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String

let accURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(accName)
let gyroURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(gyroName)
let magneURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(magneName)
let waveURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(waveName)
let frontURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(frontName)

let accOutput = OutputStream.toMemory()
let accCsvWriter = CHCSVWriter(outputStream: accOutput, encoding: String.Encoding.utf8.rawValue, delimiter: ",".utf16.first!)
let accBuffer = (accOutput.property(forKey: .dataWrittenToMemoryStreamKey) as? Data)!

let gyroOutput = OutputStream.toMemory()
let gyroCsvWriter = CHCSVWriter(outputStream: gyroOutput, encoding: String.Encoding.utf8.rawValue, delimiter: ",".utf16.first!)
let gyroBuffer = (gyroOutput.property(forKey: .dataWrittenToMemoryStreamKey) as? Data)!

let magneOutput = OutputStream.toMemory()
let magneCsvWriter = CHCSVWriter(outputStream: magneOutput, encoding: String.Encoding.utf8.rawValue, delimiter: ",".utf16.first!)
let magneBuffer = (magneOutput.property(forKey: .dataWrittenToMemoryStreamKey) as? Data)!

let waveOutput = OutputStream.toMemory()
let waveCsvWriter = CHCSVWriter(outputStream: waveOutput, encoding: String.Encoding.utf8.rawValue, delimiter: ",".utf16.first!)
let waveBuffer = (waveOutput.property(forKey: .dataWrittenToMemoryStreamKey) as? Data)!

struct ContentView: View{
    @State private var timeRemaining = 10
    @State private var start = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let cameraSource = CameraController()
    
    @State var selectedIndex:Int? = nil
    
    var body: some View {
        VStack{
            HStack(spacing:0){
                ForEach(Array([Color.green, Color.red].enumerated()),id: \.offset){ (index,value) in
                    CameraView(color: value, session: self.cameraSource.captureSession, index: index,selectedIndex:self.selectedIndex).frame(width: 216, height: 384, alignment: .center)
                    
                }
                
            }
            
            Button(action: {toggleTorch(on: true)},label:{Text("Flash")})
            Text("Time:\(timeRemaining)")
            Button(action:{start = true; cameraSource.startRecord(); toggleTorch(on: true); cameraSource.startRecord2(); urlConnection(u: "http://192.168.1." + subNet + ":5000"); urlConnection(u: "http://192.168.1." + subNet + ":5000/upload");collectSensorData()},label:{Text("Start Survey")})
            //            Toggle("Start Survey", isOn: $start)
            
            Spacer()
        }.onReceive(timer){time in
            if self.timeRemaining > 0 && self.start{
                self.timeRemaining -= 1
                
            }
            else if self.timeRemaining == 0{
                cameraSource.stopRecord()
                cameraSource.stopRecord2()
                urlConnection(u: "http://192.168.1." + subNet + ":5000/dirk")
                sleep(1)
                urlConnection(u: "http://192.168.1." + subNet + ":5000/get")
                self.timeRemaining -= 1
                stopDataCollection()
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
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

func urlConnection(u: String)
{
    
    if (u == "http://192.168.1." + subNet + ":5000/upload"){
        let params = ["timestamp": String(Int(Date().timeIntervalSince1970 * 1000)), "nameagegender":"Yuki", "experiment": "Playground"]
        
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

