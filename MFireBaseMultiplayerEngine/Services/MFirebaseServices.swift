//
//  MFirebaseServices.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 1/22/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//

import Foundation
import Firebase

class MFirebaseServices : NSObject {
    static let shared = MFirebaseServices()
    
    override init() {
        if FirebaseApp.allApps?.count==0 {
            FirebaseApp.configure()
        }
    }
    func uploadImage(data:Data?,completion:@escaping (URL?,Error?)->()) {
        // Get a non-default Storage bucket
        // Create a root reference
        guard let data = data else{
            completion(nil,nil)
            return
            
        }
        let storage = Storage.storage()

        let storageRef = storage.reference()


        /////////
        // Create a reference to the file you want to upload
        let uid=getCurrentUser()?.uid ?? "nouid"
        let riversRef = storageRef.child("UsersImages\(uid)/profileImage.jpg")
        
        // Upload the file to the path "images/rivers.jpg"
        _ = riversRef.putData(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            // Metadata contains file metadata such as size, content-type.
//            let size = metadata.size
            // You can also access to download URL after upload.
            riversRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    completion(nil,error)
                    return
                }
                completion(downloadURL,nil)
            }
        }
        
        
    }
    func downloadImage(from url: URL?,completion:@escaping (UIImage?,Error?)->()) {
        print("Download Started")
        guard url != nil else{return}
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil,error)
                return
            }
//            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                completion(UIImage(data: data),nil)
            }
        }.resume()
    }
    func getCurrentUser() -> User? {
        guard let user = Auth.auth().currentUser else{ return nil}
        return user
    }
    func loginAnonymously(completion:@escaping (User)->()) {
        Auth.auth().signInAnonymously() { (authResult, error) in
            guard let authResult = authResult else {return}
            let user = authResult.user
            completion(user)
        }
    }
    func updateUserName(name : String?,photoUrlString:String?,completion:@escaping (Bool?,Error?)->()) {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        if name != nil {
            changeRequest?.displayName = name
        }
        if photoUrlString != nil {
            let url = URL(string: photoUrlString!)
            guard url != nil else {return}
            changeRequest?.photoURL = url
        }
        changeRequest?.commitChanges { (error) in
            if (error != nil){
                completion(false,error)
                print("error \(String(describing: error?.localizedDescription))")
            }
            else {
                print("name change successfully")
                completion(true,error)
            }
        }
    }
}
