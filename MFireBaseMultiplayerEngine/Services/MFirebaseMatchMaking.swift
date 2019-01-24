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
    var ref = Database.database().reference()
    let mFireHelper=MFirebaseServices()
    override init() {
        if FirebaseApp.allApps?.count==0 {
            print(tagTitle,"Please Initilize firebase and before start matchmaking!")
        }
    }
    
    func createMatch(completion:@escaping (Bool,Error?)->(),
                     playerJoined:@escaping (Bool)->()) {
        
       let user=mFireHelper.getCurrentUser()
        guard user != nil else {
            print(tagTitle,"Cant Create match becuase user is nil")
            return
        }
        
      
        
        let matchDetails=MatchDetails(matchID: user?.uid, creatorID: user?.uid, creatorName: user?.displayName,isLocked:false)
        
        
        self.ref.child("Matches").child("\(MatchType.WaitingMatches)").child(user!.uid).setValue(["matchID": matchDetails.matchID!,"creatorID":matchDetails.creatorID!,"creatorName":matchDetails.creatorName!,"isLocked":false]){ (error, database) in
            if (error != nil){
                DispatchQueue.main.async(){
                    completion(false,error)
                }
            }
            else {
                DispatchQueue.main.async(){
                    completion(true,nil)
                }
                
            }
        }
        ref.observe(DataEventType.value, with: { (snapshot) in
            print(snapshot.value ?? "value deleted")
            if snapshot.hasChildren() ==  false {
                print("val deleted")
                self.ref.removeAllObservers()
                DispatchQueue.main.async(){
                    playerJoined(true)
                }
            }
            
        })

            
//        ref.child("Matches").child("\(MatchType.WaitingMatches)").child(user!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
//            // Get user value
//            let value = snapshot.value as? NSDictionary
//            _ = value?["creatorName"] as? String ?? ""
//            _ = value?["matchID"] as? String ?? ""
//            print("isLocked \(String(describing: value?["isLocked"]))")
////            let matchDetails=MatchDetails(matchID: user?.uid, creatorID: user?.uid, creatorName: user?.displayName)
//            // ...
//        }) { (error) in
//            print(error.localizedDescription)
//        }
//        
//
//        ref = Database.database().reference()
//        ref = Database.database().reference(withPath: "WaitingMatches")
    }
    
}
