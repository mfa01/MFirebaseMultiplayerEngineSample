//
//  MFirebaseMatchMessaging.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 2/7/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//

import UIKit
import FirebaseDatabase
protocol MFirebaseMatchMessagingDelegate:AnyObject {
    func gameStartedMessage(move:Move)
    func gameReceivedMessage(move:Move)
    func gameReceivedMove(move:Move)
    func moveSent(move:Move)
}

enum MessageType:Int {
    case gameStarted = 10
    case gameMessage = 11
    case gameMove = 12
    
}
class MFirebaseMatchMessaging {
    weak var delegate : MFirebaseMatchMessagingDelegate?
    var messagePath:String = ""
    var moves : [Move] = []
    var userID : String?
    init(messagePath:String) {
        self.messagePath=messagePath
    }
    func startMatch(creatorID:String){
        
        let startMatch = Database.database().reference(withPath: messagePath);
        let move = Move.init(playerID: creatorID, code: MessageType.gameStarted.rawValue, message: "\(MessageType.gameStarted)")
        userID=creatorID
        startMatch.childByAutoId().setValue(move.dictionary);
        matchStartedListenToMoves()
        
    }

    func sendMove(move:Move){
        let startMatch = Database.database().reference(withPath: messagePath);
        startMatch.childByAutoId().setValue(move.dictionary);
        userID=move.playerID
    }

    
    func matchStartedListenToMoves() {
        print("start listeners to moves")
        let startMatch = Database.database().reference(withPath: messagePath);
        startMatch.observe(DataEventType.childAdded, with: { (snap) in
            let value = snap.value as! [String:Any]
            print("move \(value)")
            let comingMove=Move.init(value: value)
            self.moves.append(comingMove)
            if comingMove.playerID == self.userID{
                self.delegate?.moveSent(move: comingMove)
                return
            }
            
            switch comingMove.code {
                case MessageType.gameStarted.rawValue:
                    self.delegate?.gameStartedMessage(move: comingMove)
                break
            case MessageType.gameMessage.rawValue:
                self.delegate?.gameReceivedMessage(move: comingMove)
                break
            case MessageType.gameMove.rawValue:
                self.delegate?.gameReceivedMove(move: comingMove)
                break
            default: break
            }
            
        })
    }
}
