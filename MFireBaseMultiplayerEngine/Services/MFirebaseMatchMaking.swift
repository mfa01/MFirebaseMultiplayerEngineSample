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
    
    func matchMaking(completion:@escaping (_ joined:Bool,_ created:Bool,_ matchDetails:MatchDetails?,Error?)->()) {
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
                }
                print("child added \(String(describing: matchDetails.matchID)) name: \(String(describing: matchDetails.creatorName))")
            }
            if self.waitingMatchesArray.count == 0 {
                completion(false)
            }
            else  {
                completion(true)
            }
        })
    }
    
    /*
     func joinMatch(matchID:String,completion:(_ joined:Bool)->()) {
     
     joinRef.observeSingleEvent(of: .value, with: { (snapshotParent) in
     for snapshot in snapshotParent.children {
     let value = (snapshot as! DataSnapshot).value as! [String:Any]
     var matchDetails=MatchDetails.init(value: value)
     matchDetails.matchID=(snapshot as! DataSnapshot).key
     self.waitingMatchesArray.append(matchDetails)
     print("child added \(String(describing: matchDetails.matchID)) name: \(String(describing: matchDetails.creatorName))")
     }
     if(self.waitingMatchesArray.count == 1 && self.matchStarted==false)
     {
     self.removeMatch(matchDetails: self.waitingMatchesArray[0])
     }
     //        })
     //waitingMatchesRef.observe(.childAdded, with: { (snapshot) -> Void in
     //            let value = snapshot.value as! [String:Any]
     //            var matchDetails=MatchDetails.init(value: value)
     //            matchDetails.matchID=snapshot.key
     //            self.waitingMatchesArray.append(matchDetails)
     //            print("child added \(String(describing: matchDetails.matchID)) name: \(String(describing: matchDetails.creatorName))")
     //
     //            if(self.waitingMatchesArray.count == 1 && self.matchStarted==false)
     //            {
     //                self.removeMatch(matchDetails: self.waitingMatchesArray[0])
     //            }
     })
     // Listen for deleted matches in the Firebase database
     waitingMatchesRef.observe(.childRemoved, with: { (snapshot) -> Void in
     let value = snapshot.value as! [String:Any]
     let matchDetails=MatchDetails.init(value: value)
     
     self.waitingMatchesArray.removeAll(where: { (details) -> Bool in
     if details.matchID == matchDetails.matchID{
     return true
     }
     return false
     })
     print("child removed \(String(describing: matchDetails.matchID))")
     })
     }
     */
    
    /*
    func joinMatch(matchID:String,completion:(_ joined:Bool)->()) {
     
        joinRef.observeSingleEvent(of: .value, with: { (snapshotParent) in
            for snapshot in snapshotParent.children {
                let value = (snapshot as! DataSnapshot).value as! [String:Any]
                var matchDetails=MatchDetails.init(value: value)
                matchDetails.matchID=(snapshot as! DataSnapshot).key
                self.waitingMatchesArray.append(matchDetails)
                print("child added \(String(describing: matchDetails.matchID)) name: \(String(describing: matchDetails.creatorName))")
            }
            if(self.waitingMatchesArray.count == 1 && self.matchStarted==false)
            {
                self.removeMatch(matchDetails: self.waitingMatchesArray[0])
            }
            //        })
            //waitingMatchesRef.observe(.childAdded, with: { (snapshot) -> Void in
            //            let value = snapshot.value as! [String:Any]
            //            var matchDetails=MatchDetails.init(value: value)
            //            matchDetails.matchID=snapshot.key
            //            self.waitingMatchesArray.append(matchDetails)
            //            print("child added \(String(describing: matchDetails.matchID)) name: \(String(describing: matchDetails.creatorName))")
            //
            //            if(self.waitingMatchesArray.count == 1 && self.matchStarted==false)
            //            {
            //                self.removeMatch(matchDetails: self.waitingMatchesArray[0])
            //            }
        })
        // Listen for deleted matches in the Firebase database
        waitingMatchesRef.observe(.childRemoved, with: { (snapshot) -> Void in
            let value = snapshot.value as! [String:Any]
            let matchDetails=MatchDetails.init(value: value)
     
            self.waitingMatchesArray.removeAll(where: { (details) -> Bool in
                if details.matchID == matchDetails.matchID{
                    return true
                }
                return false
            })
            print("child removed \(String(describing: matchDetails.matchID))")
        })
    }
 */
}
