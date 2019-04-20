//
//  Move.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 2/6/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//

import UIKit
struct Move {
    var playerID:String?
    var code:Int?
    var message:String?
}
extension Move{
    var dictionary: [String: Any] {
        return ["playerID": playerID ?? "noid",
                "code": code ?? 0,
                "message": message ?? "no message"]
    }
    init(value:[String:Any]) {
        playerID = value["playerID"] as? String
        code = value["code"] as? Int
        message = value["message"] as? String
    }
}
