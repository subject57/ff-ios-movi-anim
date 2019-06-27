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

var qx : QX? = nil

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if (qx == nil) { qx = QX() }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        localsTest()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if let qx = qx { qx.finish() }
    }
    
    // Example of QX 'parameter like' local value storage
    private func localsTest() {
        let PN = "PARAMETER_NAME"
        QX.Locals.setDefault(key: PN, val: 10, min: 5, max: 15)
        QX.Locals.changeAbsolute(PN,20)
        shouldBe(pn: PN, val: 15)
        QX.Locals.changeAbsolute(PN,0)
        shouldBe(pn: PN, val: 5)
        QX.Locals.changeRelative(PN, i: 1)
        shouldBe(pn: PN, val: 6)
        QX.Locals.changeRelative(PN, i: -2)
        shouldBe(pn: PN, val: 5)
        QX.Locals.changeRelative(PN, i: 200)
        shouldBe(pn: PN, val: 15)
    }
    
    private func shouldBe(pn : String, val : Float) {
        if(QX.Locals.get(pn) != val) {
            NSException(name:NSExceptionName(rawValue: "Unexpected Locals value"), reason:"", userInfo:nil).raise()
        }
    }
    
}



