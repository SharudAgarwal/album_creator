//
//  AlbumLib.swift
//  Album Creator
//
//  Created by Sharud Agarwal on 6/4/16.
//  Copyright © 2016 agarwals. All rights reserved.
//

import UIKit
import FirebaseStorage
import Firebase
import Kingfisher
import SwiftyJSON

func updateDatabaseWithName(root: String, name: String, databaseRef: FIRDatabaseReference, id: String) {
    //        let key = databaseRef.child("pictures/\(self.albumID!)").childByAutoId().key
//    var childUpdates = [String : [String : String]]()
    var newDataRef = databaseRef.child("\(root)/\(id)")
    var post = [String: String]()
    
    if root == "pictures" {
        newDataRef = databaseRef.child("\(root)/\(id)/\(name)")
        post = [Constants.PictureFields.name: name,
                Constants.PictureFields.pathToImage: "\(root)/\(id)/\(name)"]
//        childUpdates = ["\(root)/\(id)/\(name)": post]
    } else if root == "albums" {
        post = [Constants.AlbumFields.name: name]
//        childUpdates = ["\(root)/\(id)": post]
    } else if root == "users" {
        post = [Constants.UserFields.name: name,
                Constants.UserFields.id: id]
//        childUpdates = ["\(root)/\(id)": post]
    }
    
    newDataRef.updateChildValues(post)
}

func updateDatabaseWithPost(root: String, post: [String:String], databaseRef: FIRDatabaseReference, id: String) {
    //        let key = databaseRef.child("pictures/\(self.albumID!)").childByAutoId().key
//    var childUpdates = [String : [String : String]]()
    let newDataRef = databaseRef.child("\(root)/\(id)")
    
    newDataRef.updateChildValues(post)
}

func updateDatabaseUserAndAlbum(userID userID: String, albumID: String, databaseRef: FIRDatabaseReference) {
    //        let key = databaseRef.child("pictures/\(self.albumID!)").childByAutoId().key
    // add album to user's list of albums
    var root = Constants.FIRDatabaseRoots.users
//    var childUpdates = [String : Bool]()
    var newDataRef = databaseRef.child("\(root)/\(userID)/albums")
    var childUpdates = [albumID: true]
    newDataRef.updateChildValues(childUpdates)
    
    
    // add user to album's list of users
    root = Constants.FIRDatabaseRoots.albums
    newDataRef = databaseRef.child("\(root)/\(albumID)/users")
    childUpdates = [userID: true]
    newDataRef.updateChildValues(childUpdates)
}


func setCellImageView(cell: UICollectionViewCell, snapshotJSON: JSON, storageRef: FIRStorageReference) {
    
    if let imageCell = cell as? AlbumsCollectionViewCell {
        imageCell.albumImageView.kf_showIndicatorWhenLoading = true
        let picturePath = snapshotJSON[Constants.AlbumFields.thumbnailURL].string
        if picturePath == nil {
            fatalError(#function)
        }
        let imageRef = storageRef.child(picturePath!)
        imageRef.downloadURLWithCompletion { (URL, error) -> Void in
            
            if let error = error {
                print("\(#function):: error = \(error.localizedDescription)")
            } else {
                print("\(#function):: successfully grabbed url = \(URL?.absoluteString)")
                imageCell.albumImageView.kf_setImageWithURL(URL!, placeholderImage: nil)
            }
        }
    } else if let imageCell = cell as? PicturesCollectionViewCell {
        imageCell.pictureImageView.kf_showIndicatorWhenLoading = true
        let picturePath = snapshotJSON[Constants.PictureFields.pathToImage].string
        let imageRef = storageRef.child(picturePath!)
        imageRef.downloadURLWithCompletion { (URL, error) -> Void in
            
            if let error = error {
                print("\(#function):: error = \(error.localizedDescription)")
            } else {
                print("\(#function):: successfully grabbed url = \(URL?.absoluteString)")
                imageCell.pictureImageView.kf_setImageWithURL(URL!, placeholderImage: nil)
            }
        }
    }

}


/// Takes an image URL and returns a UIImage?
func downloadImage(url: String) -> UIImage? {
    
    var downloadedImage: UIImage?
    
    if url.hasPrefix(Constants.FirebaseFields.urlPrefix) {
        let storageRef = FIRStorage.storage().reference()
        // Create a reference to the file you want to download
        let imageRef = storageRef.child(url)
        // Fetch the download URL
        imageRef.downloadURLWithCompletion({ (URL, error) in
            if (error != nil) {
                // Handle any errors
                print("\(#function):: Error downloading: \(error)")
            } else {
                print("\(#function):: downloading firebase storage image")
                
//                downloadedImage = kf_setImageWithURL(URL!, placeholderImage: nil)
//                if let downloadURL = NSURL(string: (URL?.absoluteString)!), data = NSURLSession NSData(contentsOfURL: downloadURL) {
//                    downloadedImage = UIImage.init(data: data)
//                }
            }
        })
    } else if let nonFirebaseURL = NSURL(string: url), data = NSData(contentsOfURL: nonFirebaseURL) {
        downloadedImage = UIImage.init(data: data)
    }
    
    return downloadedImage
}

func getDownloadURL (pathToImage: String, storageRef: FIRStorageReference) -> NSURL? {
    
    var downloadURL: NSURL?
    
    let imageRef = storageRef.child(pathToImage)
    imageRef.downloadURLWithCompletion { (URL, error) -> Void in
        
        if let error = error {
            print("\(#function):: error = \(error.localizedDescription)")
            downloadURL = nil
        } else {
            print("\(#function):: successfully grabbed url = \(URL?.absoluteString)")
            downloadURL = URL
        }
    }
//    while(!urlSet) {
////        print("waiting da heck..")
//        // wait for url to get set
//    }
    return downloadURL
}

func albumAddedToUser(snapshot: FIRDataSnapshot) {
    
}

func albumRemovedFromUser(snapshot: FIRDataSnapshot) {
    print("\(#function):: Album was removed from user - \(snapshot)")
}

func imageType(imgData : NSData) -> String
{
    var c = [UInt8](count: 1, repeatedValue: 0)
    imgData.getBytes(&c, length: 1)
    
    let ext : String
    
    switch (c[0]) {
    case 0xFF:
        
        ext = "jpg"
        
    case 0x89:
        
        ext = "png"
    case 0x47:
        
        ext = "gif"
    case 0x49, 0x4D :
        ext = "tiff"
    default:
        ext = "" //unknown
    }
    
    return ext
}

func stringUpToChar(origString: String, delimitingChar: Character) -> String {
    let chars = origString.characters
    if let idx = chars.indexOf(delimitingChar) {
        return String(chars.prefixUpTo(idx))
    }
    return origString
}

