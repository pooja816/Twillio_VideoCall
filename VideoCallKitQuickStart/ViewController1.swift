//
//  ViewController1.swift
//  VideoCallKitQuickStart
//
//  Created by Pooja Gupta on 10/05/18.
//  Copyright © 2018 Twilio, Inc. All rights reserved.
//

import UIKit

class ViewController1: UIViewController {

    var roomViewController: ViewController2?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func continueCallAction(_ sender: Any) {
        
       navigateToVideoCall(isNewCall: false)
    }
    
    
    @IBAction func newCallAction(_ sender: Any) {
        navigateToVideoCall(isNewCall: true);
    }
    
    func navigateToVideoCall(isNewCall : Bool)  {
        
        CallManager.shared.isCallInProgress = !isNewCall;
        if (isNewCall) {
            roomViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController2") as? ViewController2;
            self.navigationController!.pushViewController(roomViewController!, animated: true);
        } else {
            self.navigationController?.pushViewController(self.roomViewController!, animated: true)
        }
    }
}
