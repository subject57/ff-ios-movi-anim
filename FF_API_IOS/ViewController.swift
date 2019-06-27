/*-----------------------------------------------------------------
 MIT License
 
 Copyright (c) 2018 Freefly Systems
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 -----------------------------------------------------------------*/

import UIKit

class 	ViewController: UIViewController {
    
    var timer : Timer?
    
    private let AUTO_STOP = "Stop"
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.QXR(_:)), name: QX.E_KEY, object: nil)
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(ViewController.TimerAction), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
    }
    
    //
    // QX Reciever processes QX events.  Add an observer using E_KEY, and construct the event class from the notification
    //
    @objc func QXR(_ notification: NSNotification) {
        let e = QX.Event.init(notification)
        print(e.toString())
        
        if (e.getFlavor() == QX.Event.Flavor.CONNECTED) {
            statusText.text = "Connected to \(BTLE.getLastSelected())"
        }
        
        if (e.getFlavor() == QX.Event.Flavor.LOGGED_ON) {
            QX_RequestAttr(455); // Request Tuning setting
            QX_RequestAttr(109); // Request Tuning progress
            statusText.text = "Logged on with SN \(QX.sn) Comms \(QX.comms) HW \(QX.hw) Name \(BTLE.getLastSelected())"
        }
        
        if (e.getFlavor() == QX.Event.Flavor.DISCONNECTED) {
            statusText.text = "DISCONNECTED"
        }
        
        // Highlight buttons to show the current tuning state
        if(e.isAttribute(455)) {
            tuningLowButtenOutlet.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            tuningHighButtonOutlet.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            if (e.value("Tuning Active Method Status") == 0) {
                tuningLowButtenOutlet.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            } else if (e.value("Tuning Active Method Status") == 2) {
                tuningHighButtonOutlet.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            }
        }
        
        // Update Autotune information
        if(e.isAttribute(109)) {
            tuningIncrDecrText.text = e.valueString("Autotune Percentage", "%0.f")
            tuningProgressText.text = e.valueString("Autotune Progress", "%0.f")
            let running = (e.value("Autotune Start") == 1);
            tuningAutoButtonOutlet.setTitle(running ? AUTO_STOP : "Auto",for: .normal)
        }
        
        // Display Movi button presses
        setButton(e,  QX.BTN_TOP, buttonTopText)
        setButton(e,  QX.BTN_TRIGGER, buttonTriggerText)
        setButton(e,  QX.BTN_CENTER, buttonCenterText)
        setButton(e,  QX.BTN_LEFT, buttonLeftText)
        setButton(e,  QX.BTN_RIGHT, buttonRightText)
        setButton(e,  QX.BTN_DOWN, buttonDownText)
        setButton(e,  QX.BTN_UP, buttonUpText)
        
        // Update status text to indicate current selection
        if(e.isAttribute(454)) {
            statusText.text = "Method changed to #\(e.valueString("Active Method top level", "%0.f"))"
        }
        
        // Update status text to indicate timelapse progress
        if(e.isAttribute(34)) {
            statusText.text = "Timelapse Progress \(e.valueString("Timelapse Progress", "%0.f"))%"
        }
    }
    
    // ------------------- SHARED
    
    @IBOutlet weak var statusText: UILabel!
    
    // ------------------- TUNING
    
    @IBOutlet weak var tuningAutoButtonOutlet: UIButton!
    
    @IBOutlet weak var tuningProgressText: UILabel!
    
    @IBOutlet weak var tuningIncrDecrText: UILabel!
    
    @IBOutlet weak var tuningLowButtenOutlet: UIButton!
    
    @IBOutlet weak var tuningHighButtonOutlet: UIButton!
    
    @IBAction func tuningLowButton(_ sender: Any) {
        QX_ChangeValue(109, strdup("Autotune Start"), -1); // ensure autotune is not running
        QX_ChangeValueAbsolute(455, strdup("Tuning Active Method Status"), 0)
    }
    
    @IBAction func tuningHighButton(_ sender: Any) {
        QX_ChangeValue(109, strdup("Autotune Start"), -1); // ensure autotune is not running
        QX_ChangeValueAbsolute(455, strdup("Tuning Active Method Status"), 2)
    }
    
    @IBAction func tuningAutoButton(_ sender: Any) {
        QX_ChangeValueAbsolute(455, strdup("Tuning Active Method Status"), 3)
        let running = (tuningAutoButtonOutlet.titleLabel?.text == AUTO_STOP)
        QX_ChangeValue(109, strdup("Autotune Start"), running ? -1 : 1);
    }
    
    @IBAction func tuningIncrButton(_ sender: Any) {
        QX_ChangeValue(109, strdup("Autotune Percentage"), +1);
    }
    
    @IBAction func tuningDecrButton(_ sender: Any) {
        QX_ChangeValue(109, strdup("Autotune Percentage"), -1);
    }
    
    // Simple streaming for autotune progress
    @objc func TimerAction() {
        QX_RequestAttr(109);
    }
    
    // ------------------- BUTTONS
    
    private func setButton(_ e : QX.Event,_ key : String ,_ label : UILabel) {
        if (e.isButtonEvent(key, QX.BTN.PRESS)) { label.textColor = UIColor.green }
        if (e.isButtonEvent(key, QX.BTN.RELEASE)) { label.textColor = UIColor.black }
        if (e.isButtonEvent(key, QX.BTN.LONG_PRESS)) { label.textColor = UIColor.red }
    }
    
    @IBOutlet weak var buttonTopText: UILabel!
    
    @IBOutlet weak var buttonTriggerText: UILabel!
    
    @IBOutlet weak var buttonCenterText: UILabel!
    
    @IBOutlet weak var buttonLeftText: UILabel!
    
    @IBOutlet weak var buttonRightText: UILabel!
    
    @IBOutlet weak var buttonDownText: UILabel!
    
    @IBOutlet weak var buttonUpText: UILabel!
    
    // ------------------- System
    @IBOutlet weak var connectButtonOutlet: UIButton!
    
    @IBOutlet weak var disconnectButtonOutlet: UIButton!
    
    @IBAction func connectButton(_ sender: Any) {
        
        // disconnect and wait for scan results
        qx?.btle.resetConnect("")
        sleep(1) // should be background thread
        
        // try connecting to strongest signal
        var anyDevice = ""
        var rssi = -100
        for d in BTLE.getAvailableDevices() {
            print("Found device [\(d.key)] with rssi \(d.value.rssiValue) ")
            if (d.value.rssiValue > rssi)  {
                anyDevice = d.key
                rssi = d.value.rssiValue
            }
        }
        if (anyDevice != "") {
            statusText.text = "Connecting to closest device [\(anyDevice)] with rssi \(rssi)"
            qx?.btle.resetConnect(anyDevice)
        } else {
            statusText.text = "No devices found, please try again."
        }
    }
    @IBAction func disconnectButton(_ sender: Any) {
        qx?.btle.resetConnect("")
    }
    @IBAction func defaultButton(_ sender: Any) {
        QX_ChangeValueAbsolute(81, strdup("FLASH"), 2);
        QX_RequestAttr(109);
    }
    
    // ------------------- 277 control
    
    @IBAction func panRightButton(_ sender: Any) {
        QX.Control277.set(roll: 3000, tilt: 0, pan: 3000, gimbalFlags: Float( QX.Control277.INPUT_CONTROL_RZ_RATE))
    }
    @IBAction func panLeftButton(_ sender: Any) {
        QX.Control277.set(roll: -3000, tilt: 0, pan: -3000, gimbalFlags: Float( QX.Control277.INPUT_CONTROL_RZ_RATE))
    }
    @IBAction func panUpButton(_ sender: Any) {
        QX.Control277.set(roll: 0, tilt: -3000, pan: 0, gimbalFlags: Float( QX.Control277.INPUT_CONTROL_RY_RATE))
    }
    @IBAction func panDownButton(_ sender: Any) {
        QX.Control277.set(roll: 0, tilt: 3000, pan: 0, gimbalFlags: Float( QX.Control277.INPUT_CONTROL_RY_RATE))
    }
    @IBAction func panStopButton(_ sender: Any) {
        QX.Control277.deferr()
    }
    
    // ------------------- Methods
    
    @IBAction func majesticButton(_ sender: Any) {
        QX_ChangeValueAbsolute(454, strdup("Active Method top level"), 0);
    }
    @IBAction func moviLapseButton(_ sender: Any) {
        QX_ChangeValueAbsolute(454, strdup("Active Method top level"), 2);
    }
    @IBAction func podButton(_ sender: Any) {
        QX_ChangeValueAbsolute(454, strdup("Active Method top level"), 6);
    }
    
    // ------------------- Echo/Timelapse
    
    // NOTE: This is a rough example.
    // It is recommended to verify reciept of instructions, particularly if many are sent in a short duration
    
    private func clearAll() {
        QX.stream34 = true
        QX.sendControl1126(pCmd: "NOTHING", aCmd: "CANCEL", index: 0, panDegs: 0, panRevs: 0, tiltDegs: 0, rollDegs: 0, kfSeconds: 0, sharedDiff: 0, sharedWeight: 0);
        QX.sendControl1126(pCmd: "DEL_ALL_KFs", aCmd: "NOTHING", index: 0, panDegs: 0, panRevs: 0, tiltDegs: 0, rollDegs: 0, kfSeconds: 0, sharedDiff: 0, sharedWeight: 0);
    }
    
    @IBAction func buttonPath1(_ sender: Any) {
        clearAll()
        QX.sendControl1126(pCmd: "ADD_KF", aCmd: "NOTHING", index: 0, panDegs: -45, panRevs: 0, tiltDegs: -30, rollDegs: -20, kfSeconds: 5, sharedDiff: 0.4, sharedWeight: 0.4);
        QX.sendControl1126(pCmd: "ADD_KF", aCmd: "START_TL", index: 0, panDegs: 45, panRevs: 0, tiltDegs: 30, rollDegs: 20, kfSeconds: 0, sharedDiff: 0.4, sharedWeight: 0.4);
    }
    @IBAction func buttonExitTimelapse(_ sender: Any) {
        clearAll()
        QX.stream34 = false
    }
    @IBAction func buttonPath2(_ sender: Any) {
        clearAll()
        QX.sendControl1126(pCmd: "ADD_KF", aCmd: "NOTHING", index: 0, panDegs: -45, panRevs: 0, tiltDegs: -30, rollDegs: 0, kfSeconds: 1, sharedDiff: 0.4, sharedWeight: 0.4);
        QX.sendControl1126(pCmd: "ADD_KF", aCmd: "NOTHING", index: 0, panDegs: -45, panRevs: 0, tiltDegs: 30, rollDegs: 0, kfSeconds: 1, sharedDiff: 0.4, sharedWeight: 0.4);
        QX.sendControl1126(pCmd: "ADD_KF", aCmd: "NOTHING", index: 0, panDegs:  45, panRevs: 0, tiltDegs: 30, rollDegs: 0, kfSeconds: 1, sharedDiff: 0.4, sharedWeight: 0.4);
        QX.sendControl1126(pCmd: "ADD_KF", aCmd: "NOTHING", index: 0, panDegs:  45, panRevs: 0, tiltDegs: -30, rollDegs: 0, kfSeconds: 1, sharedDiff: 0.4, sharedWeight: 0.4);
        QX.sendControl1126(pCmd: "ADD_KF", aCmd: "START_TL", index: 0, panDegs:-45, panRevs: 0, tiltDegs: -30, rollDegs: 0, kfSeconds: 1, sharedDiff: 0.4, sharedWeight: 0.4);
    }
}

