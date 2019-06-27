//
//  CameraAnimation.swift
//  FF_API_IOS
//
//  Created by Josh Ruoff on 6/23/19.
//  Copyright © 2019 Freefly. All rights reserved.
//

import Foundation

internal protocol CameraAnimationDelegate: AnyObject {
    func animationProgress(percent: Float)
    func animationComplete()
    func animationStarted()
}

internal class CameraAnimator {
    
    internal weak var delegate: CameraAnimationDelegate?
    var commandQueue: Queue<AnimationFrame>?
    var isProgramming: Bool
    var isRunning: Bool
    
    init() {
        isProgramming = false
        isRunning = false
        commandQueue = Queue<AnimationFrame>()
        NotificationCenter.default.addObserver(self, selector: #selector(self.QXR(_:)), name: QX.E_KEY, object: nil)
    }

    deinit {
        print("***DEINIT CAMERA ANIMATOR***")
        delegate = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    //
    // QX Reciever processes QX events.  Add an observer using E_KEY, and construct the event class from the notification
    //
    @objc func QXR(_ notification: NSNotification) {
        let e = QX.Event.init(notification)
        print(e.toString())
        
        // get programming command verifications
        if e.isAttribute(1126) {
             let progCmd = e.value("KF Programming Cmd")
             if Int(progCmd) != 0 {
                print("KF Programming Cmd received: \(progCmd)")
                sendNextAddFrameCommand()
            }
            
            let actCmd = e.value("KF Action Cmd")
            if Int(actCmd) != 0 {
                print("KF Action Cmd: \(actCmd)")
            }
        }
        
        // Update status text to indicate timelapse progress
        if(e.isAttribute(34)) {
            print("Timelapse Progress \(e.valueString("Timelapse Progress", "%0.f"))%")
            delegate?.animationProgress(percent: e.value("Timelapse Progress"))
            
            if let timelapseState = e.valueNull("Timelapse state") {
                print("Timelapse state \(timelapseState)")
                if timelapseState == 1.0 && self.isRunning {
                    animationComplete()
                } else {
                    self.isRunning = true
                }
            }
        }
    }
    
    func animationComplete() {
        print("***Animation Complete***")
        self.isRunning = false
        stopTimelapse()
        delegate?.animationComplete()
    }
    
    func stopTimelapse() {
        clearAll()
        QX.stream34 = false
    }
    
    func clearAll() {
        QX.stream34 = true
        QX.sendControl1126(pCmd: "NOTHING", aCmd: "CANCEL", index: 0, panDegs: 0, panRevs: 0, tiltDegs: 0, rollDegs: 0, kfSeconds: 0, sharedDiff: 0, sharedWeight: 0)
        QX.sendControl1126(pCmd: "DEL_ALL_KFs", aCmd: "NOTHING", index: 0, panDegs: 0, panRevs: 0, tiltDegs: 0, rollDegs: 0, kfSeconds: 0, sharedDiff: 0, sharedWeight: 0)
    }
    
    func executeAnimationSequence(sequence: Queue<AnimationFrame>) {
        self.commandQueue = sequence
        self.isProgramming = true;
        clearAll();
    }
    
    // Called by QX notification observer after receiving a programming command
    func sendNextAddFrameCommand() {
        
        if let frame = self.commandQueue?.dequeue() {
            QX.sendControl1126(pCmd: "ADD_KF",
                               aCmd: "NOTHING",
                               index: frame.keyIndex,
                               panDegs: frame.pan,
                               panRevs: 0,
                               tiltDegs: frame.tilt,
                               rollDegs: frame.roll,
                               kfSeconds: frame.durationSeconds,
                               sharedDiff: frame.diff,
                               sharedWeight: frame.weight)
        }
        
        if self.commandQueue!.isEmpty && self.isProgramming {
            // All animation commands have been sent, start the animation
            self.isProgramming = false
            QX.sendControl1126(pCmd: "ADD_KF", aCmd: "START_TL", index: 0, panDegs: 0, panRevs: 0, tiltDegs: 0, rollDegs: 0, kfSeconds: 0.2, sharedDiff: 0.4, sharedWeight: 0.4)
        }
    }
}
