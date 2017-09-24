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
import DZNEmptyDataSet
import Photos

class AlbumsCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, UITabBarControllerDelegate {

    //    var myAlbums = Albums().albums
    var databaseRef: DatabaseReference!
    var albums: [DataSnapshot]! = []
    var tappedAlbumID: String?
    var currentUser: User?
    
    fileprivate var albumsRefHandle: DatabaseHandle!
    fileprivate var usersRefHandle: DatabaseHandle!
    fileprivate var storageRef: StorageReference!
    fileprivate var userAlbumNames = [String]()
    fileprivate let picturesSegue = "toPicturesCollectionViewController"
    fileprivate let createNewAlbumSegue = "toCreateNewAlbumViewController"
    fileprivate let reuseIdentifier = "albumCell"
    fileprivate let numberOfItemsPerRow = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(#function):: Albums Collection View did load")
        databaseRef = Database.database().reference()
        storageRef = Storage.storage().reference()
        self.collectionView!.emptyDataSetSource = self
        self.collectionView!.emptyDataSetDelegate = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
    }
    
    deinit {
        self.collectionView!.emptyDataSetSource = nil
        self.collectionView!.emptyDataSetDelegate = nil
    }

//    override func viewDidAppear(animated: Bool) {
//    }
    
    @IBAction func createNewAlbum(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "New Album", message:"Enter a name for this album.", preferredStyle: .alert)
        let addAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let albumName = alertController.textFields![0].text {
                if (self.albumNameExists(albumName: albumName)) {
                    let invalidNameAlertController = UIAlertController(title: "Invalid Album Name", message: "You already have an album titled \(albumName), please choose a unique name", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
                    invalidNameAlertController.addAction(cancelAction)
                    self.present(invalidNameAlertController, animated: true, completion: nil)
                } else {
                    let albumID = self.createAlbumDatabaseID()
                    updateDatabaseUserAndAlbum(userID: self.currentUser!.id, albumID: albumID, databaseRef: self.databaseRef)
                    updateDatabaseWithName(root: "albums", name: albumName, databaseRef: self.databaseRef, id: albumID)
                    let album = Album(albumName: albumName, id: albumID)
                    self.performSegue(withIdentifier: self.picturesSegue, sender: album)
                }
            } else {
                // user did not fill field
            }
        }
        alertController.addTextField { (textField) in
            textField.placeholder = ""
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func albumNameExists(albumName: String) -> Bool {
        return userAlbumNames.contains(albumName)
    }
    
    func createAlbumDatabaseID() -> String {
        let albumID = self.databaseRef.child("albums").childByAutoId().key
        return albumID
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albums.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumsCollectionViewCell
        // unpack album data from Firebase DataSnapshot
        let albumSnapshot: DataSnapshot! = self.albums[indexPath.row]
        let albumJSON = JSON(albumSnapshot.value!)
        let albumName = albumJSON[Constants.AlbumFields.name].string
        self.userAlbumNames.append(albumName!)
        cell.albumNameLabel.text = albumName
        if (albumJSON[Constants.AlbumFields.thumbnailURL].string != nil) {
            setCellImageView(cell: cell, snapshotJSON: albumJSON, storageRef: storageRef)
        } else {
            cell.albumImageView.image = nil
        }
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let albumSnapshot = self.albums[indexPath.row]
//        self.tappedAlbumID = albumSnapshot.key
        let albumJSON = JSON(albumSnapshot.value!)
        let thumbnail = albumJSON[Constants.AlbumFields.thumbnailURL].string
        let chosenAlbum = Album(albumName: albumJSON[Constants.AlbumFields.name].string!, id: albumSnapshot.key, thumbnailURL: thumbnail, username: currentUser!.id)
        performSegue(withIdentifier: picturesSegue, sender: chosenAlbum)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let tabVC = segue.destinationViewController as! UITabBarController
        if sender != nil && segue.identifier == picturesSegue {
            if let pictureVC = segue.destination as? PicturesCollectionViewController {
                pictureVC.album = sender as? Album
            }
/*            tabVC.selectedIndex = 0
            let pictureVC = tabVC.selectedViewController as! PicturesCollectionViewController
//            if let pictureVC = segue.destinationViewController as? PicturesCollectionViewController {
            pictureVC.album = sender as? Album
//            }
        } else {
            fatalError("Segue Identifier != picturesSegue")
        }
 */
/*        else if segue.identifier == picturesSegue {
            if let pictureVC = segue.destinationViewController as? PicturesCollectionViewController {
//                pictureVC.album = self.tappedAlbumID
//                pictureVC.albumThumbnailSet = true
            }
        }*/
        }
    }
    
    // Will update the table by calling updateTable()
    override func viewWillAppear(_ animated: Bool) {
        print(#file + "::" + #function)
        self.navigationItem.setHidesBackButton(true, animated: false)
        updateCollection()
        self.collectionView?.reloadEmptyDataSet()
        print("End of updateCollection")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print(#file + "::" + #function)
        self.databaseRef.child("users/\(currentUser!.id)/albums").removeObserver(withHandle: usersRefHandle)
    }
    
    /// Updates albums table view by refetching each image url and album name.
    func updateCollection() {
        self.albums.removeAll()
        self.collectionView?.reloadData()
        // Listen for new Albums from Firebase database
        print("\(#function):: username = \(currentUser!.id)")
        usersRefHandle = self.databaseRef.child("users/\(currentUser!.id)/albums").observe(.childAdded, with: { (snapshot) in
            // get list of albums the user belongs to from the snapshot
            print("\(#function):: This user is a member of the following albums: \(snapshot.key)")
            let albumUserIsIn = snapshot.key
            // observesingleeventtype for each album
            self.databaseRef.child("albums/\(albumUserIsIn)").observeSingleEvent(of: .value, with: { (snapshot) in
                // add album to table
                print(snapshot.description)
                self.albums.append(snapshot)
                self.collectionView?.insertItems(at: [IndexPath(row: self.albums.count-1, section: 0)])
                self.collectionView!.reloadEmptyDataSet()
            })
            //            albumAddedToUser(snapshot)
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left + flowLayout.sectionInset.right + (flowLayout.minimumInteritemSpacing * CGFloat(numberOfItemsPerRow - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(numberOfItemsPerRow))
        return CGSize(width: size, height: size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // Code here will execute before the rotation begins.
        // Equivalent to placing it in the deprecated method -[willRotateToInterfaceOrientation:duration:]
        coordinator.animate(alongsideTransition: { (nil) -> Void in
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

extension AlbumsCollectionViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Welcome!"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "You currently have no albums."
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if (self.albums.isEmpty) {
            return true
        } else {
            return false
        }
    }
}
