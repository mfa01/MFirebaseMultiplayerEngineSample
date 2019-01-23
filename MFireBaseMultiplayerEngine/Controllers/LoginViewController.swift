//
//  LoginViewController.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 1/22/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//

import UIKit
import FirebaseAuth
class LoginViewController: UIViewController {
    let fireServices = MFirebaseServices()
    @IBAction func LoginAnonymously(_ sender: Any) {
        fireServices.loginAnonymously { (user) in
            let uid = user.uid
            print("user \(user)")
            print("display name \(String(describing: user.displayName))")
            print("uid  \(uid)")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        // Do any additional setup after loading the view.
    }
    
}
