//
//  CustomAnimationViewController.swift
//  FF_API_IOS
//
//  Created by Josh Ruoff on 6/23/19.
//  Copyright © 2019 Freefly. All rights reserved.
//

import Foundation
import UIKit

class CustomAnimationViewController: UIViewController, UITextFieldDelegate, CameraAnimationDelegate {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var keyFrameSwitch: UISwitch!
    @IBOutlet weak var panSlider: UISlider!
    @IBOutlet weak var tiltSlider: UISlider!
    @IBOutlet weak var rollSlider: UISlider!
    @IBOutlet weak var totalFrameCount: UILabel!
    
    @IBOutlet weak var diffInput: UITextField!
    @IBOutlet weak var weightInput: UITextField!
    @IBOutlet weak var durationInput: UITextField!
    
    @IBOutlet weak var keyFrameLabel: UILabel!
    @IBOutlet weak var panLabel: UILabel!
    @IBOutlet weak var tiltLabel: UILabel!
    @IBOutlet weak var rollLabel: UILabel!
    @IBOutlet weak var contentConstraintHeight: NSLayoutConstraint!
    
    var framesQueue: Queue<AnimationFrame>!
    var currentKeyframeIndex: Float!
    var isRunningAnimation: Bool!
    var cameraAnimator: CameraAnimator?
    var activeField: UITextField?
    var lastOffset: CGPoint!
    var keyboardHeight: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //cameraAnimator = CameraAnimator()
        //cameraAnimator?.delegate = self
        durationInput.delegate = self
        weightInput.delegate = self
        diffInput.delegate = self
        // Add touch gesture for contentView
        self.mainView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mainViewTap(gesture:))))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initialize()
        if cameraAnimator == nil {
            cameraAnimator = CameraAnimator()
            cameraAnimator?.delegate = self
        }
        // Observe keyboard change
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }
    
    func initialize() {
        framesQueue = Queue<AnimationFrame>()
        currentKeyframeIndex = -1.0
        isRunningAnimation = false
        panSlider.setValue(0.0, animated: true)
        tiltSlider.setValue(0.0, animated: true)
        rollSlider.setValue(0.0, animated: true)
        panLabel.text = "0"
        tiltLabel.text = "0"
        rollLabel.text = "0"
        diffInput.text = "0.4"
        weightInput.text = "0.4"
        durationInput.text = "0.5"
        updateFrameCountLabels()
    }
    
    @objc func mainViewTap(gesture: UIGestureRecognizer) {
        guard activeField != nil else {
            return
        }
        
        activeField?.resignFirstResponder()
        activeField = nil
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeField = textField
        lastOffset = self.scrollView.contentOffset
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        activeField?.resignFirstResponder()
        activeField = nil
        return true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if keyboardHeight != nil {
            return
        }
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            // so increase contentView's height by keyboard height
            UIView.animate(withDuration: 0.3, animations: {
                self.contentConstraintHeight.constant += self.keyboardHeight
            })
            // move if keyboard hide input field
            let distanceToBottom = self.scrollView.frame.size.height - (activeField?.frame.origin.y)! - (activeField?.frame.size.height)!
            let collapseSpace = keyboardHeight - distanceToBottom
            if collapseSpace > 0 {
                // no collapse
                return
            }
            // set new offset for scroll view
            UIView.animate(withDuration: 0.3, animations: {
                // scroll to the position above keyboard 10 points
                self.scrollView.contentOffset = CGPoint(x: self.lastOffset.x, y: collapseSpace - 10)
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.contentConstraintHeight.constant -= self.keyboardHeight
            self.scrollView.contentOffset = self.lastOffset ?? CGPoint(x: 0,y: 0)
        }
        keyboardHeight = nil
    }
    
    func animationStarted() {
        print("***Delegate call animation started")
    }
    func animationProgress(percent: Float) {
        print("***Delegate call progress \(percent)")
    }
    
    func animationComplete() {
        print("***Delegate call complete")
    }
    
    func updateFrameCountLabels() {
        totalFrameCount.text = "Frame Count:  \(framesQueue.count)"
        keyFrameLabel.text = "Current Key Frame: \(Int(currentKeyframeIndex))"
    }
    
    // MARK: Actions
    
    @IBAction func newAnimationTouchUpInside(_ sender: Any) {
        initialize();
    }
    
    @IBAction func rollSliderValueChanged(_ sender: Any) {
        rollLabel.text = "\(Int(rollSlider.value))"
    }
    
    @IBAction func tiltSliderValueChanged(_ sender: Any) {
        tiltLabel.text = "\(Int(tiltSlider.value))"
    }
    
    @IBAction func panSliderValueChanged(_ sender: Any) {
        panLabel.text = "\(Int(panSlider.value))"
    }
    
    @IBAction func addTouchUpInside(_ sender: Any) {
        if keyFrameSwitch.isOn || currentKeyframeIndex < 0 {
            currentKeyframeIndex += 1
        }
        
        framesQueue.enqueue(AnimationFrame(
            keyIndex: currentKeyframeIndex,
            tilt: Float(tiltSlider!.value),
            pan: Float(panSlider!.value),
            roll: Float(rollSlider!.value),
            durationSeconds: Float(durationInput.text!) ?? 0.0,
            weight: Float(weightInput.text!) ?? 0.0,
            diff: Float(diffInput.text!) ?? 0.0
        ))
        
        updateFrameCountLabels()
    }
    
    @IBAction func previewTouchUpInside(_ sender: Any) {
        cameraAnimator?.executeAnimationSequence(sequence: framesQueue)
    }
}

struct AnimationFrame {
    let keyIndex: Float
    let tilt: Float
    let pan: Float
    let roll: Float
    let durationSeconds: Float
    let weight: Float
    let diff: Float
}
