//
//  AlbumsCollectionViewController.swift
//  Album Creator
//
//  Created by Sharud Agarwal on 6/9/16.
//  Copyright © 2016 agarwals. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

import SwiftyJSON

private let reuseIdentifier = "albumCell"

class AlbumsCollectionViewController: UICollectionViewController {

    //    var myAlbums = Albums().albums
    var databaseRef: FIRDatabaseReference!
    var albums: [FIRDataSnapshot]! = []
    
    private var albumsRefHandle: FIRDatabaseHandle!
    private var usersRefHandle: FIRDatabaseHandle!
//    private let userID: String = "user1"
    private var usersAlbumNamesArr = [AnyObject?]()
    private let picturesSegue = "toPicturesCollectionViewController"
    
    var tappedAlbumID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(#function):: Albums Collection View did load")
        databaseRef = FIRDatabase.database().reference()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albums.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! AlbumsCollectionViewCell
        // unpack album data from Firebase DataSnapshot
        let albumSnapshot: FIRDataSnapshot! = self.albums[indexPath.row]
        let albumJSON = JSON(albumSnapshot.value!)
        cell.AlbumNameLabel.text = albumJSON[Constants.AlbumFields.name].string
        if let albumThumbnailURL = albumJSON[Constants.AlbumFields.thumbnailURL].string {
            cell.AlbumImageView.image = downloadImage(albumThumbnailURL)
        } else {
            // Todo: Need to implement nil image object class from github
        }
        return cell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let albumSnapshot = self.albums[indexPath.row]
        self.tappedAlbumID = albumSnapshot.key
        performSegueWithIdentifier(picturesSegue, sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == picturesSegue {
            if let pictureVC = segue.destinationViewController as? PicturesCollectionViewController {
                pictureVC.albumID = self.tappedAlbumID
            }
        }
    }
    
    // Will update the table by calling updateTable()
    override func viewWillAppear(animated: Bool) {
        print(#file + "::" + #function)
        self.navigationItem.setHidesBackButton(true, animated: false)
        updateCollection()
        print("End of updateCollection")
    }
    
    override func viewWillDisappear(animated: Bool) {
        print(#file + "::" + #function)
        self.databaseRef.child("users/\(User.name)/albums").removeObserverWithHandle(usersRefHandle)
    }
    
    /// Updates albums table view by refetching each image url and album name.
    func updateCollection() {
        self.albums.removeAll()
        self.collectionView?.reloadData()
        // Listen for new Albums from Firebase database
        print("\(#function):: username = \(User.name)")
        usersRefHandle = self.databaseRef.child("users/\(User.name)/albums").observeEventType(.ChildAdded, withBlock: { (snapshot) in
            // get list of albums the user belongs to from the snapshot
            print("\(#function):: This user is a member of the following albums: \(snapshot.key)")
            let albumUserIsIn = snapshot.key
            // observesingleeventtype for each album
            self.databaseRef.child("albums/\(albumUserIsIn)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                // add album to table
                print(snapshot.description)
                self.albums.append(snapshot)
                self.collectionView?.insertItemsAtIndexPaths([NSIndexPath(forRow: self.albums.count-1, inSection: 0)])
            })
            //            albumAddedToUser(snapshot)
        })
    }
    
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}
