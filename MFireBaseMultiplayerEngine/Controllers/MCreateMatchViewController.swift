//
//  MCreateMatchViewController.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 1/24/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//

import UIKit
import Firebase
class MCreateMatchViewController: UIViewController {
    @IBOutlet var player1Name: UILabel!
    @IBOutlet var player1Image: UIImageView!
    
    @IBOutlet var player2Name: UILabel!
    @IBOutlet var player2Image: UIImageView!
    
    @IBOutlet var btnCreateMatch: UIButton!
    @IBOutlet var lblState: UILabel!
    let matchMake = MFirebaseMatchMaking()
    let services = MFirebaseServices()
    var user : User?
    
    @IBAction func sendMove(_ sender: Any) {
        matchMake.sendMove(code: MessageType.gameMove.rawValue, message: "\(MessageType.gameMove)")
    }
    
    @IBAction func startGame(_ sender: Any) {
        matchMake.startMatch()
    }
    @IBAction func joinMatch(_ sender: Any) {
        matchMake.matchMaking(completion: { (joined, created, details, error) in
            if joined {
                DispatchQueue.main.async {
                self.lblState.text="Match Joined"
                self.player2Name.text=details?.players?.first?.name
                }
                let url = URL(string: details?.players?.first?.photo ?? "")
                
                self.services.downloadImage(from: url) { (image, error) in
                    if error == nil {
                        DispatchQueue.main.async {
                            self.player2Image.image = image
                        }
                        
                    }
                }
            }
            else if created {
                DispatchQueue.main.async {
                self.lblState.text="Match Created"
                }
                
            }
        }) { (joinedPlayer) in
            self.player2Name.text=joinedPlayer?.name
            let url = URL(string: joinedPlayer?.photo ?? "")
            self.services.downloadImage(from: url) { (image, error) in
                if error == nil {
                    DispatchQueue.main.async {
                        self.player2Image.image = image
                        self.lblState.text="other player join the match"
                    }
                    
                }
            }
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    func updateUI() {
        player1Name.text=user?.displayName
        services.downloadImage(from: user?.photoURL) { (image, error) in
            if error == nil {
                DispatchQueue.main.async {
                self.player1Image.image = image
                }
                
            }
        }
    }
}
