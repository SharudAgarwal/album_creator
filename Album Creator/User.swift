//
//  User.swift
//  Album Creator
//
//  Created by Sharud Agarwal on 6/27/16.
//  Copyright © 2016 agarwals. All rights reserved.
//

import Foundation

class User {
    var name: String
    var id: String
    var profilePic: NSURL?
    var numOfAlbums: Int = 0
    var albums = [String]()
    
    init(username: String, id: String) {
        self.name = username
        self.id = id
    }
    
    init(username: String, id: String, profilePic: NSURL?) {
        self.name = username
        self.id = id
        self.profilePic = profilePic
    }
    
    init(username: String, id: String, profilePic: NSURL?, albumName: String) {
        self.name = username
        self.id = id
        self.profilePic = profilePic
        self.albums.append(albumName)
        self.numOfAlbums += 1
    }
    
}
