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

import Photos

class AlbumsCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {

    //    var myAlbums = Albums().albums
    var databaseRef: FIRDatabaseReference!
    var albums: [FIRDataSnapshot]! = []
    var tappedAlbumID: String?
    var currentUser: User?
    
    private var albumsRefHandle: FIRDatabaseHandle!
    private var usersRefHandle: FIRDatabaseHandle!
    private var storageRef: FIRStorageReference!
    private var usersAlbumNamesArr = [AnyObject?]()
    private let picturesSegue = "toPicturesCollectionViewController"
    private let createNewAlbumSegue = "toCreateNewAlbumViewController"
    private let reuseIdentifier = "albumCell"
    private let numberOfItemsPerRow = 3
    
    //FIXME: Add "add album" buttom
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(#function):: Albums Collection View did load")
        databaseRef = FIRDatabase.database().reference()
        storageRef = FIRStorage.storage().reference()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
    }

//    override func viewDidAppear(animated: Bool) {
//    }
    
    @IBAction func createNewAlbum(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "New Album", message:"Enter a name for this album.", preferredStyle: .Alert)
        let addAction = UIAlertAction(title: "Save", style: .Default) { _ in
            if let albumName = alertController.textFields![0].text {
                let albumID = self.createAlbumDatabaseID()
                updateDatabaseUserAndAlbum(userID: self.currentUser!.id, albumID: albumID, databaseRef: self.databaseRef)
                updateDatabaseWithName("albums", name: albumName, databaseRef: self.databaseRef, id: albumID)
                let album = Album(albumName: albumName, id: albumID)
                self.performSegueWithIdentifier(self.picturesSegue, sender: album)
            } else {
                // user did not fill field
            }
        }
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = ""
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func createAlbumDatabaseID() -> String {
        let albumID = self.databaseRef.child("albums").childByAutoId().key
        return albumID
    }

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
        cell.albumNameLabel.text = albumJSON[Constants.AlbumFields.name].string
        if (albumJSON[Constants.AlbumFields.thumbnailURL].string != nil) {
            setCellImageView(cell, snapshotJSON: albumJSON, storageRef: storageRef)
        }
        return cell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let albumSnapshot = self.albums[indexPath.row]
//        self.tappedAlbumID = albumSnapshot.key
        let albumJSON = JSON(albumSnapshot.value!)
        let chosenAlbum = Album(albumName: albumJSON[Constants.AlbumFields.name].string!, id: albumSnapshot.key, thumbnailURL: albumJSON[Constants.AlbumFields.thumbnailURL].string!, username: currentUser!.id)
/*        print("albumSnapshot value = \(albumSnapshot.value)")
        for child in albumSnapshot.children {
            print("albumSnapshot children are: \(child)")
        }
 */
        performSegueWithIdentifier(picturesSegue, sender: chosenAlbum)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if sender != nil && segue.identifier == picturesSegue {
            if let pictureVC = segue.destinationViewController as? PicturesCollectionViewController {
                pictureVC.album = sender as? Album
//                pictureVC.albumThumbnailSet = false
            }
        }
/*        else if segue.identifier == picturesSegue {
            if let pictureVC = segue.destinationViewController as? PicturesCollectionViewController {
//                pictureVC.album = self.tappedAlbumID
//                pictureVC.albumThumbnailSet = true
            }
        } */
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
        self.databaseRef.child("users/\(currentUser!.id)/albums").removeObserverWithHandle(usersRefHandle)
    }
    
    /// Updates albums table view by refetching each image url and album name.
    func updateCollection() {
        self.albums.removeAll()
        self.collectionView?.reloadData()
        // Listen for new Albums from Firebase database
        print("\(#function):: username = \(currentUser!.id)")
        usersRefHandle = self.databaseRef.child("users/\(currentUser!.id)/albums").observeEventType(.ChildAdded, withBlock: { (snapshot) in
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
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left + flowLayout.sectionInset.right + (flowLayout.minimumInteritemSpacing * CGFloat(numberOfItemsPerRow - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(numberOfItemsPerRow))
        return CGSize(width: size, height: size)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        // Code here will execute before the rotation begins.
        // Equivalent to placing it in the deprecated method -[willRotateToInterfaceOrientation:duration:]
        coordinator.animateAlongsideTransition({ (nil) -> Void in
            // Place code here to perform animations during the rotation.
            // You can pass nil for this closure if not necessary.
        },
        completion: { (context) -> Void in
            // Code here will execute after the rotation has finished.
            // Equivalent to placing it in the deprecated method -[didRotateFromInterfaceOrientation:]
            self.collectionViewLayout.invalidateLayout()
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
