//
//  PlayerData.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 1/27/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//

import UIKit
struct PlayerData {
    var id : String?
    var photo : String?
    var image : UIImage?
    var score : Int?
    var name : String?
}

extension PlayerData{
    var dictionary: [String: Any] {
        return ["id": id ?? "noid",
                "photo": photo ?? "no photo",
                "name": name ?? "no name"]
    }
    init(value:[String:Any]) {
        id = value["id"] as? String
        photo = value["photo"] as? String
        name = value["name"] as? String
    }
}
