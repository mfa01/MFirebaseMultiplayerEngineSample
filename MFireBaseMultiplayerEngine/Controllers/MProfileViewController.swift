//
//  MProfileViewController.swift
//  MFireBaseMultiplayerEngine
//
//  Created by MAbed on 1/23/19.
//  Copyright © 2019 Mohammad Abed. All rights reserved.
//

import UIKit

class MProfileViewController: UIViewController {
    let mFireServices = MFirebaseServices()
    var imagePicker = UIImagePickerController()
    var imageURL :URL?
    var userName:String?
    var imageData:Data?
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserDataView()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        userNameTextField.resignFirstResponder()
    }
    
    func updateUserDataView() {
        self.userNameTextField.text=userName
        mFireServices.downloadImage(from: imageURL) { (image, error) in
            if error != nil {
                print("cant download image")
            }
            else{
                print("Image Downloaded")
                
                self.userImageView.image=image
            }
        }
    }
    func setUserData(name:String?,url:URL?) {
        self.imageURL=url
        self.userName=name
    }
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var userNameTextField: UITextField!
    @IBAction func changeImage(_ sender: Any) {
        showImagePicker()
    }
    
    
    @IBAction func updateUserData(_ sender: Any) {
        mFireServices.uploadImage(data: imageData) { (url, err) in
            self.mFireServices.updateUserName(name: self.userNameTextField.text, photoUrlString: url?.absoluteString) { (ok, error) in
                self.navigationController?.popViewController(animated: true)
            }
        }
        
    }
}
extension MProfileViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextFieldDelegate{
    func showImagePicker() {
        //imagePicker.modalPresentationStyle = UIModalPresentationStyle.currentContext
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        //imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let tempImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
        self.userImageView.image=tempImage
        imageData = tempImage.jpegData(compressionQuality: 0.5)

        self.dismiss(animated: true) {}
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true) {}
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.userNameTextField.resignFirstResponder()
        return true
    }
}
