//
//  UIImageView+Download.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 4/20/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//

import Foundation
import UIKit
extension UIImageView {
    func downloadImage(from url: URL?,completion:@escaping (UIImage?,Error?)->()) {
        guard url != nil else{return}
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            guard let data = data, error == nil else {
                DispatchQueue.main.async{
                    completion(nil,error)
                }
                return
            }
            DispatchQueue.main.async() {
                completion(UIImage(data: data),nil)
                self.image=UIImage(data: data)
            }
            }.resume()
    }
}
