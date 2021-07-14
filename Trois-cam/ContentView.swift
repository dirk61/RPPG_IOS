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



let motion = CMMotionManager()
let accName = "Accelerometer.csv"
let gyroName = "GyroScope.csv"
let magneName = "Magnenometer.csv"

let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String

let documentURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(accName)

let output = OutputStream.toMemory()
let csvWriter = CHCSVWriter(outputStream: output, encoding: String.Encoding.utf8.rawValue, delimiter: ",".utf16.first!)
let buffer = (output.property(forKey: .dataWrittenToMemoryStreamKey) as? Data)!

struct ContentView: View{
    @State private var timeRemaining = 65
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
            Button(action: {urlConnection(u: "http://192.168.1.103:5000")}, label: {
                Text("Request")
            })
            Button(action: {toggleTorch(on: true)},label:{Text("Flash")})
            Text("Time:\(timeRemaining)")
            Button(action:{start = true; cameraSource.startRecord(); toggleTorch(on: true); cameraSource.startRecord2(); urlConnection(u: "http://192.168.1.103:5000"); collectSensorData()},label:{Text("Start Survey")})
            //            Toggle("Start Survey", isOn: $start)
            
            Spacer()
        }.onReceive(timer){time in
            if self.timeRemaining > 0 && self.start{
                self.timeRemaining -= 1
                
            }
            else if self.timeRemaining == 0{
                cameraSource.stopRecord()
                cameraSource.stopRecord2()
                urlConnection(u: "http://192.168.1.103:5000/dirk")
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
    //    HTTP.GET("https://192.168.1.103:5000") { response in
    //        if let err = response.error {
    //            print("error: \(err.localizedDescription)")
    //            return //also notify app of failure as needed
    //        }
    //        print("opt finished: \(response.description)")
    //print("data is: \(response.data)") access the response of the data with response.data
    //    }
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
                
                csvWriter?.writeField(String(Int(Date().timeIntervalSince1970 * 1000)))
                csvWriter?.writeField(String(data.acceleration.x))
                csvWriter?.writeField(String(data.acceleration.y))
                csvWriter?.writeField(String(data.acceleration.z))
                csvWriter?.finishLine()
                
                //                csvWriter?.closeStream()
                
                
                
                
                //                print(data.acceleration.x as Any)
            }
            
            if let data = motion.gyroData{
                
            }
            
            if let data = motion.magnetometerData{
                
            }
            
        })
        
        RunLoop.current.add(timer, forMode: .default)
    }
}

func stopDataCollection() {
    do{
        try buffer.write(to: documentURL)
    }
    catch{
        
    }
    
    motion.stopGyroUpdates()
    motion.stopMagnetometerUpdates()
    motion.stopAccelerometerUpdates()
}

