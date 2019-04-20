//
//  GamePlayController.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 4/15/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//
import Foundation
import UIKit
class GamePlayController: UIViewController {
    var matchMake:MFirebaseMatchMaking?
    let tagTitle = "GamePlayController:"
    var p1s = 0 {
        didSet {
            self.matchMake?.updatePlayerScore(score: p1s)
            self.updateScore(label: p1Score, score: p1s)
        }
    }
    var p2s = 0 {
        didSet{
            self.matchMake?.updatePlayerScore(score: p2s)
            self.updateScore(label: p2Score, score: p2s)
        }
    }
    
    @IBOutlet var p1Image: UIImageView!
    @IBOutlet var p1Name: UILabel!
    @IBOutlet var p1Score: UILabel!
    @IBOutlet var p2Image: UIImageView!
    @IBOutlet var p2Name: UILabel!
    @IBOutlet var p2Score: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.matchMake?.delegate = self
        
        p1Image.image=self.matchMake?.currentPlayerData?.image
        p2Image.image=self.matchMake?.oppenentData?.image
    }
    @IBAction func sendMove(_ sender: Any) {
        self.matchMake?.sendMove(code: MessageType.gameMove.rawValue, message: "\(MessageType.gameMove)")
        p1s = p1s+1
        //self.matchMake?.updatePlayerScore(score: p1s)
    }
    func updateScore(label : UILabel!,score : Int!) {
        label.text="\(score!)"
    }
    @IBAction func leaveMatch(_ sender: Any) {
        self.matchMake?.leaveMatch()
        self.navigationController?.popToRootViewController(animated: false)
    }
}


extension GamePlayController:MFirebaseMatchMakingDelegate{
    func moveSent(move: Move){
        print("\(self.tagTitle)MoveSent")
    }
    func gameReceivedMessage(move: Move){
        print("\(self.tagTitle)GameStartedMessageDelegate \(String(describing: move.message))")
    }
    func gameReceivedMove(move: Move){
        print("\(self.tagTitle)GameReceivedMove \(String(describing: move.message))")
        p2s = p2s+1
    }
    func gameReceivedPlayerLeftMatch(move: Move){
        print("\(self.tagTitle)GameReceivedPlayerLeftMatch \(String(describing: move.message))")
    }
}
