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
//    var user : User?
    
    @IBAction func exitGame(_ sender: Any) {
        matchMake.leaveMatch()
        self.navigationController?.popViewController(animated: true)
    }
    func matchJoined(details:MatchDetails?){
        self.lblState.text="Match Joined"
        self.player2Name.text=details?.players?.first?.name
        
        let url = URL(string: details?.players?.first?.photo ?? "")
//        self.services.downloadImage(from: url) { (image, error) in
//            if error == nil {
//                self.player2Image.image = image
//            }
//        }
        self.player2Image.downloadImage(from: url) { (img, err) in
            self.matchMake.updateOpponentImage(image: img)
            self.performSegue(withIdentifier: "GamePlay", sender: nil)

        }
    }
    func opponentJoined(joinedPlayer:PlayerData?){
        self.lblState.text="Opponent joined"
        self.player2Name.text=joinedPlayer?.name
        
        let url = URL(string: joinedPlayer?.photo ?? "")
        self.player2Image.downloadImage(from: url) { (img, err) in
            self.matchMake.updateOpponentImage(image: img)
            self.matchMake.startMatch()
            self.performSegue(withIdentifier: "GamePlay", sender: nil)
        }
        
        
//        self.services.downloadImage(from: url) { (image, error) in
//            if error == nil {
//                self.player2Image.image = image
//            }
//            self.matchMake.startMatch()
//            self.performSegue(withIdentifier: "GamePlay", sender: nil)
//        }
    }
    @IBAction func joinMatch(_ sender: Any) {
        matchMake.matchMaking(completion: { (joined, created, details, error) in
            if joined {
                //When player joined random match
                self.matchJoined(details: details)
            }
            else if created {
                //When player create new game
                self.lblState.text="Match Created"
            }
        }) { (joinedPlayer) in
            //When opponent is joined created match game
            self.opponentJoined(joinedPlayer: joinedPlayer)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GamePlay" {
            let vc = segue.destination as! GamePlayController
            vc.matchMake=self.matchMake
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        setCurrentPlayerUI()
    }
    func setCurrentPlayerUI() {
        //player1Name.text=user?.displayName
        player1Name.text=self.matchMake.currentPlayerData?.name
        self.player1Image.downloadImage(from: URL(string: (self.matchMake.currentPlayerData?.photo)!)) { (img, err) in
            self.matchMake.updatePlayerImage(image: img)
        }
    }
}
