//
//  MatchDetails.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 1/24/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//

import Foundation
struct MatchDetails {
    var matchID : String?
    var creatorID : String?
    var creatorName : String?
    var isLocked : Bool?
    var creatorPhoto : String?
    var players : [PlayerData]?
}
extension MatchDetails{
    
    var dictionary: [String: Any] {
        return ["matchID": matchID ?? "noid",
                "creatorID": creatorID ?? "noid",
                "creatorName": creatorName ?? "no name",
                "isLocked": isLocked ?? false,
                "creatorPhoto": creatorPhoto ?? "no photo",
                "players":  players?.map({$0.dictionary}) ?? []]
    }
    init(value:[String:Any]) {
        matchID = value["matchID"] as? String
        creatorID = value["creatorID"] as? String
        creatorName = value["creatorName"] as? String
        isLocked = value["isLocked"] as? Bool

        let playersArray=value["players"] as! NSArray
        players=playersArray.map({PlayerData.init(value: $0 as! [String : Any])})
        creatorPhoto = value["creatorPhoto"] as? String
    }
}
