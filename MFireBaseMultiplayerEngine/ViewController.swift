//
//  ViewController.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 1/22/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//
//MABED
import UIKit

class ViewController: UIViewController {
    
    let mFireServices=MFirebaseServices()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isKind(of: MProfileViewController.self){
            print("going to profile")
            let dest=segue.destination as! MProfileViewController
            let user = mFireServices.getCurrentUser()
            dest.setUserData(name: user?.displayName, url: user?.photoURL)
        }
        else if segue.destination.isKind(of: MCreateMatchViewController.self){
            print("going to profile")
            let dest=segue.destination as! MCreateMatchViewController
            dest.user = mFireServices.getCurrentUser()
//            dest.setUserData(name: user?.displayName, url: user?.photoURL)
        }
    }
}

