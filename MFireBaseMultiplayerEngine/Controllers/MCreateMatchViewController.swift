//
//  MCreateMatchViewController.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 1/24/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//

import UIKit

class MCreateMatchViewController: UIViewController {
    @IBOutlet var btnCreateMatch: UIButton!
    @IBOutlet var lblState: UILabel!
    let matchMake = MFirebaseMatchMaking()
    @IBAction func createMatch(_ sender: Any) {
        matchMake.createMatch(completion: { (done, error) in
            if done==true{
                self.lblState.text="waiting for opponent"
            }
            else{
                self.lblState.text="error in creating match \(String(describing: error?.localizedDescription))"
                
                self.enableCreateMatchBtn(enable: true)
            }
        }) { (ready) in
            self.lblState.text="other player joined you"
        }
            
    
        enableCreateMatchBtn(enable: false)
    }
    func enableCreateMatchBtn(enable : Bool)  {
        self.btnCreateMatch.isUserInteractionEnabled=enable
        if enable == false {
            btnCreateMatch.setTitleColor(UIColor.gray, for: .normal)
        }
        else{
            btnCreateMatch.setTitleColor(UIColor.blue, for: .normal)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        enableCreateMatchBtn(enable: true)
        // Do any additional setup after loading the view.
    }
}
