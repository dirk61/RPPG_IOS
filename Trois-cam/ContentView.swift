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
            Button(action:{start = true; cameraSource.startRecord(); cameraSource.startRecord2()},label:{Text("Start Survey")})
            Toggle("Start Survey", isOn: $start)
            
            Spacer()
        }.onReceive(timer){time in
            if self.timeRemaining > 0 && self.start{
                self.timeRemaining -= 1
            }
            else if self.timeRemaining == 0{
                cameraSource.stopRecord()
                cameraSource.stopRecord2()
                self.timeRemaining -= 1
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
