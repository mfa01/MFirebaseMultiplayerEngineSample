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
enum PlayerStatus {
    case PlayerIsWaitingForOpponent
    case PlayerIsPlaying
    case PlayerIsIdle
}
enum MatchStatus {
    //case waitingMatches
    //case startedMatches
}

protocol MFirebaseMatchMakingDelegate:AnyObject {
    func moveSent(move: Move);
    func gameReceivedMessage(move: Move);
    func gameReceivedMove(move: Move);
    func gameReceivedPlayerLeftMatch(move: Move);
}

class MFirebaseMatchMaking: NSObject {
    weak var delegate : MFirebaseMatchMakingDelegate?
    var playerStatus=PlayerStatus.PlayerIsIdle
    
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
    var clock : Timer?
    var clockCounter = 0
    
    var currentPlayerData : PlayerData?
    var oppenentData : PlayerData?

   
    
    func leaveMatch() {
        self.sendMove(code: MessageType.leaveMatch.rawValue, message: "\(MessageType.gameMove)")
        self.resetVars()
    }
    func setConnectivityClock(){
        self.clock = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.clockFunc), userInfo: nil, repeats: true)
    }
    @objc func clockFunc(){
        clockCounter += 1
        print("clock \(clockCounter)")
        if clockCounter%5 == 0 {
            NetworkManager.isUnreachable { _ in
                print("\(self.tagTitle)I am not connected")
                return
            }
            NetworkManager.isReachable { _ in
                
            print("\(self.tagTitle)I am connected, check other player if he can listen to my hello message")
                //if he can hear hello.
            //, then reset this timer
                self.sendMove(code: MessageType.hello.rawValue, message: "hello")
            }
        }
        else if clockCounter%10 == 0 {
            print("\(self.tagTitle)Other player is not connected!")
        }
    }
    let network: NetworkManager = NetworkManager.sharedInstance
    func updateDatabaseInfo() {
        
    }
    
    func resetVars(){
        clock?.invalidate()
        self.removingMatchStarted=false;
        self.playerStatus=PlayerStatus.PlayerIsIdle
        createdRef.removeAllObservers()
        joinRef.removeAllObservers()
        waitingMatchesArray.removeAll()
        matchStarted=false
        removingMatchStarted=false
        currentMatch = MatchDetails()
        matchMessaging = nil
    }
    override init() {
        super.init()
        
        if FirebaseApp.allApps?.count==0 {
            print(self.tagTitle,"\(self.tagTitle)Please Initilize firebase and before start matchmaking!")
        }
//        NetworkManager.isUnreachable { _ in
//        }
//        NetworkManager.isReachable { _ in
//        }
        network.reachability.whenUnreachable = { reachability in
            print("Not connected")
        }
        network.reachability.whenReachable = { reachability in
            print("Connected")
        }
        
        self.getCurrentPlayerData()
        
        
        
    }
    
    
    //This function to list all available matches and create one if there are no
    //available match to join
    //1-Get all available matches
    //2.1-If no matches, create new match, and observe created match
    //2.2-If there available matches do following
    //      2.2.0-Select first match in the returned matches
    //      2.2.1-Remove joined match from Waitng list from FIrebase
    //      2.2.2-Create joined match in the Started matches list in Firebase
    //      2.2.3-Create message room in joined match
    //      2.2.4-Observe created match
    //          2.2.5-Creator will be able to start the match
    func matchMaking(completion:@escaping (_ joined:Bool,_ created:Bool,_ matchDetails:MatchDetails?,Error?)->(),playerJoinedCompletion:@escaping (_ player:PlayerData?)->()) {
        
        //make sure that player is not in a started match
        guard playerStatus==PlayerStatus.PlayerIsIdle else{
            print("\(self.tagTitle)error, Player is currently \(playerStatus)")
            return
        }
        setConnectivityClock()
        listMatches { (ready) in
            if ready {
                //join match
                self.removeMatch(matchDetails: self.waitingMatchesArray.first, completion: { (removed) in
                    self.oppenentData = self.waitingMatchesArray.first?.players?.last

                    if removed {
                        //join
                        self.playerStatus=PlayerStatus.PlayerIsPlaying
                        self.reCreateJoinedMatch(completion: { (ready, error) in
                            if error == nil {
                                print("\(self.tagTitle)match started!")
                                DispatchQueue.main.async{
                                completion(true,false,self.currentMatch,nil)
                                }
                                self.initMatchMessage()
                                self.matchMessaging?.matchStartedListenToMoves()
                            }
                            else {
                                //error in create joind match again
                                //join another match
                                self.waitingMatchesArray.remove(at: 0)
                                
                                print("\(self.tagTitle)error : \(String(describing: error?.localizedDescription))")
                                print("\(self.tagTitle)error in create joined match again, try to join another")
                                DispatchQueue.main.async{
                                completion(false,false,nil,nil)
                                }
                                //restartMatchMaking()
                            }
                        })
                    }
                    else {
                        //error in join
                        //join another
                        print("\(self.tagTitle)error in joining match, try to join another")
                        DispatchQueue.main.async{
                        completion(false,false,nil,nil)
                        }
                    }
                    
                })
            }
            else {
                //create new match
                self.createFreshMatch(completion: { (created, error) in
                    if error == nil {
                        DispatchQueue.main.async{
                        completion(false,true,self.currentMatch,error)
                        }
                        
                        //Add observer to catch joined players
                        self.addObserverToWaitOtherPlayersWhenJoinTheMatch(completion: { (player) in
                            playerJoinedCompletion(player)
                        })
                        self.playerStatus=PlayerStatus.PlayerIsWaitingForOpponent
                    }
                    else {
                        //error in create match,try again
                        DispatchQueue.main.async{
                        completion(false,false,self.currentMatch,error)
                        }
                        
                    }
                })
            }
        }
        
    }
    
    
    
    
    
    
    func getCurrentPlayerData(){
        let user=mFireHelper.getCurrentUser()
        let players = [PlayerData.init(id: user?.uid, photo: user?.photoURL?.absoluteString, image: nil, score: 0, name:user?.displayName )]
        currentPlayerData=players.last
    }
    
    func createFreshMatch(completion:@escaping (Bool,Error?)->()) {
        if currentPlayerData == nil {
            getCurrentPlayerData()
        }
        guard currentPlayerData != nil else {
            print(self.tagTitle,"Cant Create match becuase user is nil")
            completion(false,nil)
            return
        }
        let matchDetails=MatchDetails.init(matchID: nil, creatorID: currentPlayerData?.id, creatorName: currentPlayerData?.name,isLocked:false, creatorPhoto: currentPlayerData?.photo,players: [currentPlayerData!])
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
    
    func reCreateJoinedMatch(completion:@escaping (_ ready:Bool,Error?)->()) {
        self.createdRef.child((currentMatch.matchID)!).setValue(currentMatch.dictionary){ (error, database) in
            if (error != nil){
                completion(false,error)
            }
            else {
                completion(true,error)
            }
        }
    }
    
    
    func addObserverToWaitOtherPlayersWhenJoinTheMatch(completion:@escaping (_ playerJoined:PlayerData?)->()){
        
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
                    self.oppenentData = matchDetails.players?.last
                }
            }
        })
        
    }
    func removeMatch(matchDetails:MatchDetails?,completion:@escaping (_ matchRemoved:Bool)->()){
        
        if currentPlayerData == nil {
            getCurrentPlayerData()
        }
        
        if self.matchStarted || self.removingMatchStarted {return}
        self.removingMatchStarted=true
        self.joinRef.child((matchDetails?.matchID)!).removeValue(completionBlock: { (error, database) in
            if (error != nil) {
                print("\(self.tagTitle)match already gone please try other one")
                completion(false)
                return
            }
            print("\(self.tagTitle)match should start soon")
            self.matchStarted=true
            self.joinRef.removeAllObservers()
            self.currentMatch=matchDetails!
            
            let user=self.currentPlayerData
            let player = PlayerData.init(id: user?.id, photo:user?.photo, image: nil, score: 0, name:user?.name )
            
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
                    print("\(self.tagTitle)child added \(String(describing: matchDetails.matchID)) name: \(String(describing: matchDetails.creatorName))")

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
        guard self.currentMatch.matchID != nil  else {
            print("\(self.tagTitle)Create Match Before")
            return
        }
        if self.currentMatch.creatorID != self.mFireHelper.getCurrentUser()?.uid {
            print("\(self.tagTitle)You can't start the match, just the creator can start it")
            return
        }
        if self.currentMatch.players?.count == 1 {
            print("\(self.tagTitle)You can't start the match, No one joined yet")
            return
        }
        initMatchMessage()
        matchMessaging?.startMatch(creatorID: self.mFireHelper.getCurrentUser()?.uid ?? "")
    }
}

extension MFirebaseMatchMaking{
    func updateOpponentScore(score:Int?){
        if score != nil {
            self.oppenentData?.score=score
        }
    }
    func updateOpponentImage(image:UIImage?){
        if image != nil {
            self.oppenentData?.image=image
        }
    }
    func updatePlayerScore(score:Int?){
        if score != nil {
            self.currentPlayerData?.score=score
        }
    }
    func updatePlayerImage(image:UIImage?){
        if image != nil {
            self.currentPlayerData?.image=image
        }
    }
}


extension MFirebaseMatchMaking:MFirebaseMatchMessagingDelegate{
    func sendMove(code:Int?,message:String?) {
        guard self.currentMatch.matchID != nil  else {
            print("\(self.tagTitle)Create Match Before")
            return
        }
        let move = Move.init(playerID: mFireHelper.getCurrentUser()?.uid, code: code, message: message)
        matchMessaging?.sendMove(move: move)
    }
    func moveSent(move: Move) {
//        print("\(self.tagTitle)moveSent")
        self.delegate?.moveSent(move: move)
    }
    func gameStartedMessage(move: Move) {
        print("\(self.tagTitle)gameStartedMessageDelegate")
    }
    func gameReceivedMessage(move: Move) {
//        print("\(self.tagTitle)gameReceivedMessage \(String(describing: move.message))")
        clockCounter=0;
        self.delegate?.gameReceivedMessage(move: move)
    }
    func gameReceivedHelloCheck(move: Move) {
        print(self.tagTitle,"Other Player want to make sure that iam connected, send hello back")
        self.sendMove(code: MessageType.helloBack.rawValue, message: "hello")
        clockCounter=0;
    }
    func gameReceivedHelloBack(move: Move) {
        print(self.tagTitle,"Other player confirm that he is here")
        clockCounter=0;
    }
    func gameReceivedMove(move: Move) {
//        print("\(self.tagTitle)gameReceivedMove \(String(describing: move.message))")
        clockCounter=0;
        self.delegate?.gameReceivedMove(move: move)
    }
    func gameReceivedPlayerLeftMatch(move: Move) {
//        print("\(self.tagTitle)gameReceivedPlayerLeftMatch \(String(describing: move.message))")
        self.delegate?.gameReceivedPlayerLeftMatch(move: move)
        //self.leaveMatch()
    }
}
