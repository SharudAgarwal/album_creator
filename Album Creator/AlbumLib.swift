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

/// Takes an image URL and returns a UIImage?
func downloadImage(url: String) -> UIImage? {
    
    var downloadedImage: UIImage?
    
    if url.hasPrefix(Constants.FirebaseFields.urlPrefix) {
        FIRStorage.storage().referenceForURL(url).dataWithMaxSize(INT64_MAX, completion: { (data, error) in
            if (error != nil) {
                print("\(#function):: Error downloading: \(error)")
            }
            downloadedImage = UIImage.init(data: data!)
        })
    } else if let nonFirebaseURL = NSURL(string: url), data = NSData(contentsOfURL: nonFirebaseURL) {
        downloadedImage = UIImage.init(data: data)
    }
    
    return downloadedImage
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

