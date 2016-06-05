//
//  Constants.swift
//  Album Creator
//
//  Created by Sharud Agarwal on 6/4/16.
//  Copyright © 2016 agarwals. All rights reserved.
//

struct Constants {
    
    struct AlbumFields {
        static let name = "albumName"
        static let createdAtTimestamp = "createdAtTimestamp"
        static let lastModified = "lastModifiedAtTimestamp"
        static let numOfPics = "numOfPics"
        static let numOfUsers = "numOfUsers"
        static let thumbnailURL = "thumbnailURL"
    }
    
    struct UserFields {
        static let name = "username"
        static let profilePic = "profilePicture"
        static let numOfAlbums = "numOfAlbums"
        static let albums = "albums"
        static let createdAtTimestamp = "createdAtTimestamp"
    }
    
    struct PictureFields {
        static let name = "pictureName"
        static let addedTimestamp = "addedAtTimestamp"
        static let fileType = "fileType"
        static let url = "URL"
        static let caption = "caption"
    }
    
    struct FirebaseFields {
        static let urlPrefix = "gs://"
    }
}