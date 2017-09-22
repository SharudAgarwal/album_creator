//
//  Album.swift
//  Album Creator
//
//  Created by Sharud Agarwal on 7/19/16.
//  Copyright © 2016 agarwals. All rights reserved.
//

import Foundation

class Album {
    fileprivate(set) var name: String
    fileprivate(set) var id: String
    fileprivate(set) var thumbnailURL: String?
    fileprivate(set) var numOfPics: Int = 0
    fileprivate(set) var numOfUsers: Int = 0
    fileprivate(set) var users = [String]()
    fileprivate(set) var pictures = [String]()
    
    init(albumName: String, id: String) {
        self.name = albumName
        self.id = id
    }

// Cant create a new album with a thumbnail without passing a picture also
/*
    init(albumName: String, id: String, thumbnailURL: String?) {
        self.name = albumName
        self.id = id
        self.thumbnailURL = thumbnailURL
    }
*/
    
    init(albumName: String, id: String, thumbnailURL: String?, username: String) {
        self.name = albumName
        self.id = id
        self.thumbnailURL = thumbnailURL
        self.users.append(username)
        self.numOfUsers += 1
    }
    
    init(albumName: String, id: String, thumbnailURL: String?, username: String, picturePath: String) {
        self.name = albumName
        self.id = id
        self.thumbnailURL = thumbnailURL
        self.users.append(username)
        self.numOfUsers += 1
        self.pictures.append(picturePath)
        self.numOfPics += 1
    }
    
    func setThumbnail(thumbnailPath: String?) {
        self.thumbnailURL = thumbnailPath
    }
    
    func setThumbnailWithNewPicture(thumbnailPath: String?, picturePath: String) {
        self.thumbnailURL = thumbnailPath
        self.pictures.append(picturePath)
        self.numOfPics += 1
    }
    
    func addPicture(picturePath: String) {
        self.pictures.append(picturePath)
        self.numOfPics += 1
    }
    
    func addUser(username: String) {
        self.users.append(username)
        self.numOfUsers += 1
    }
    
}
