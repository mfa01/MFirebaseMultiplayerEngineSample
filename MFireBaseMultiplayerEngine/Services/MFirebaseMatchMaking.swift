//
//  MFirebaseMatchMaking.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 1/24/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

enum MatchType {
    case WaitingMatches
    case StartedMatches
    case PlayingMatches
}
enum MatchStatus {
    //case waitingMatches
    //case startedMatches
}
class MFirebaseMatchMaking: NSObject {
    
    
    
    let tagTitle="MFirebaseMatchMaking_"
    //    var ref = Database.database().reference()
    var joinRef = Database.database().reference(withPath: "Matches/\(MatchType.WaitingMatches)")
    var createdRef = Database.database().reference(withPath: "Matches/\(MatchType.StartedMatches)")
    let mFireHelper=MFirebaseServices()
    var waitingMatchesArray = [MatchDetails]()
    var matchStarted = false
    var removingMatchStarted = false
    var currentMatch = MatchDetails()
    var matchMessaging : MFirebaseMatchMessaging?
    func resetVars(){
        self.removingMatchStarted=false;
    }
    override init() {
        if FirebaseApp.allApps?.count==0 {
            print(tagTitle,"Please Initilize firebase and before start matchmaking!")
        }
    }
    func createMatch(completion:@escaping (Bool,Error?)->()) {
        
        let user=mFireHelper.getCurrentUser()
        guard user != nil else {
            print(tagTitle,"Cant Create match becuase user is nil")
            completion(false,nil)
            return
        }
        let players = [PlayerData.init(id: user?.uid, photo: user?.photoURL?.absoluteString,name:user?.displayName)]
        let matchDetails=MatchDetails.init(matchID: nil, creatorID: user?.uid, creatorName: user?.displayName,isLocked:false, creatorPhoto: user?.photoURL?.absoluteString,players: players)
        self.currentMatch=matchDetails
        
        self.joinRef.childByAutoId().setValue(matchDetails.dictionary){ (error, database) in
            if (error != nil){
                completion(false,error)
            }
            else {
                self.currentMatch.matchID=database.key!
                completion(true,nil)
            }
        }
    }
    
    func createJoinedMatch(completion:@escaping (_ ready:Bool,Error?)->()) {
        self.createdRef.child((currentMatch.matchID)!).setValue(currentMatch.dictionary){ (error, database) in
            if (error != nil){
                completion(false,error)
            }
            else {
                completion(true,error)
            }
        }
    }
    
    func matchMaking(completion:@escaping (_ joined:Bool,_ created:Bool,_ matchDetails:MatchDetails?,Error?)->(),playerJoinedCompletion:@escaping (_ player:PlayerData?)->()) {
        listMatches { (ready) in
            if ready {
                //join match
                self.removeMatch(matchDetails: self.waitingMatchesArray.first, completion: { (removed) in
                    if removed {
                        //join
                        self.createJoinedMatch(completion: { (ready, error) in
                            if error == nil {
                                print("match started!")
                                completion(true,false,self.currentMatch,nil)
                                self.initMatchMessage()
                                self.matchMessaging?.matchStartedListenToMoves()
                            }
                            else {
                                //error in create joind match again
                                //join another match
                                self.waitingMatchesArray.remove(at: 0)
                                
                                print("error : \(String(describing: error?.localizedDescription))")
                                print("error in create joined match again, try to join another")
                                completion(false,false,nil,nil)
                                //restartMatchMaking()
                            }
                        })
                    }
                    else {
                        //error in join
                        //join another
                        print("error in joining match, try to join another")
                        completion(false,false,nil,nil)
                    }
                    
                })
            }
            else {
                //create new match
                self.createMatch(completion: { (created, error) in
                    if error == nil {
                        completion(false,true,self.currentMatch,error)
                        self.waitOtherPlayersToJoinTheMatch(completion: { (player) in
                            playerJoinedCompletion(player)
                        })
                    }
                    else {
                        //error in create match
                        //try again
                        completion(false,false,self.currentMatch,error)
                       
                    }
                })
            }
        }
     
    }
    func waitOtherPlayersToJoinTheMatch(completion:@escaping (_ playerJoined:PlayerData?)->()){
        let createdMatch = Database.database().reference(withPath: "Matches/\(MatchType.StartedMatches)");
        createdMatch.observe(DataEventType.childAdded, with: { (snap) in
            let value = snap.value as! [String:Any]
//            print("snap.key  \(snap.key)")
            if snap.key == self.currentMatch.matchID {
            let matchDetails=MatchDetails.init(value: value)

                if matchDetails.creatorID == self.mFireHelper.getCurrentUser()?.uid{
                    completion(matchDetails.players?.last)
                    self.currentMatch=matchDetails
                    createdMatch.removeAllObservers()
                    
                }
            }
        })
        
    }
    func removeMatch(matchDetails:MatchDetails?,completion:@escaping (_ matchRemoved:Bool)->()){
        if self.matchStarted || self.removingMatchStarted {return}
        self.removingMatchStarted=true
        self.joinRef.child((matchDetails?.matchID)!).removeValue(completionBlock: { (error, database) in
            if (error != nil) {
                print("match already gone please try other one")
                completion(false)
                return
            }
            print("match should start soon")
            self.matchStarted=true
            self.joinRef.removeAllObservers()
            self.currentMatch=matchDetails!
            let user=self.mFireHelper.getCurrentUser()
            let player = PlayerData.init(id: user?.uid, photo: user?.photoURL?.absoluteString,name:user?.displayName)
            var matchDetails = matchDetails
            matchDetails?.players?.append(player)
            self.currentMatch=matchDetails!
            completion(true)
        })
    }
    func listMatches(completion:@escaping (_ thereMatches:Bool)->()) {
        joinRef.observeSingleEvent(of: .value, with: { (snapshotParent) in
            for snapshot in snapshotParent.children {
                let value = (snapshot as! DataSnapshot).value as! [String:Any]
                var matchDetails=MatchDetails.init(value: value)
                matchDetails.matchID=(snapshot as! DataSnapshot).key
                if matchDetails.creatorID != self.mFireHelper.getCurrentUser()?.uid {
                    self.waitingMatchesArray.append(matchDetails)
                    print("child added \(String(describing: matchDetails.matchID)) name: \(String(describing: matchDetails.creatorName))")

                }
            }
            if self.waitingMatchesArray.count == 0 {
                completion(false)
            }
            else  {
                completion(true)
            }
        })
    }
    
    func initMatchMessage() {
        guard let matchID = self.currentMatch.matchID  else {
            return
        }
        self.matchMessaging=MFirebaseMatchMessaging.init(messagePath: "Matches/\(MatchType.StartedMatches)/\(matchID)/moves")
        self.matchMessaging?.delegate=self
    }
    func startMatch(){
        initMatchMessage()
        matchMessaging?.startMatch(creatorID: self.mFireHelper.getCurrentUser()?.uid ?? "")
    }
    
    
    
    
}

extension MFirebaseMatchMaking:MFirebaseMatchMessagingDelegate{
    func sendMove(code:Int?,message:String?) {
        let move = Move.init(playerID: mFireHelper.getCurrentUser()?.uid, code: code, message: message)
        matchMessaging?.sendMove(move: move)
    }
    func moveSent(move: Move) {
        print("moveSent")
    }
    func gameStartedMessage(move: Move) {
        print("gameStartedMessageDelegate")
    }
    func gameReceivedMessage(move: Move) {
        print("gameStartedMessageDelegate \(String(describing: move.message))")
    }
    func gameReceivedMove(move: Move) {
        print("gameReceivedMove \(String(describing: move.message))")
    }
}
