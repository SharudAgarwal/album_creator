//
//  AlbumsTableViewController.swift
//  Album Creator
//
//  Created by Sharud Agarwal on 5/30/16.
//  Copyright © 2016 agarwals. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

import SwiftyJSON

private let reuseIdentifier = "albumCell"

class AlbumsTableViewController: UITableViewController {
    
//    var myAlbums = Albums().albums
    var databaseRef: DatabaseReference!
    var albums: [DataSnapshot]! = []
    
    fileprivate var albumsRefHandle: DatabaseHandle!
    fileprivate var usersRefHandle: DatabaseHandle!
    fileprivate let userID: String = "user1"
    fileprivate var usersAlbumNamesArr = [AnyObject?]()
    fileprivate let picturesSegue = "toPicturesCollectionViewController"
    
    var tappedAlbumID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        print(#function)
        databaseRef = Database.database().reference()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//         self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! AlbumsTableViewCell
        // unpack album data from Firebase DataSnapshot
        let albumSnapshot: DataSnapshot! = self.albums[indexPath.row]
        let albumJSON = JSON(albumSnapshot.value!)
        cell.AlbumNameLabel.text = albumJSON[Constants.AlbumFields.name].string
        if let albumThumbnailURL = albumJSON[Constants.AlbumFields.thumbnailURL].string {
            cell.AlbumImageView.image = downloadImage(url: albumThumbnailURL)
        } else {
            // Todo: Need to implement nil image object class from github
        }
        return cell
            
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let albumSnapshot = self.albums[indexPath.row]
        self.tappedAlbumID = albumSnapshot.key
        performSegue(withIdentifier: picturesSegue, sender: nil)
    }
/*
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == picturesSegue {
            if let pictureVC = segue.destinationViewController as? PicturesCollectionViewController {
                pictureVC.albumID = self.tappedAlbumID
            }
        }
    }
*/
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // Will update the table by calling updateTable()
    override func viewWillAppear(_ animated: Bool) {
        print(#function)
        updateTable()
        print("End of updateTable")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.databaseRef.child("users/\(userID)/albums").removeObserver(withHandle: usersRefHandle)
    }
    
    /// Updates albums table view by refetching each image url and album name.
    func updateTable() {
        self.albums.removeAll()
        self.tableView.reloadData()
        // Listen for new Albums from Firebase database
        usersRefHandle = self.databaseRef.child("users/\(userID)/albums").observe(.childAdded, with: { (snapshot) in
            // get list of albums the user belongs to from the snapshot
            print("\(#function):: This user is a member of the following albums: \(snapshot.key)")
            let albumUserIsIn = snapshot.key
            // observesingleeventtype for each album
            self.databaseRef.child("albums/\(albumUserIsIn)").observeSingleEvent(of: .value, with: { (snapshot) in
                // add album to table
                print(snapshot.description)
                self.albums.append(snapshot)
                self.tableView.insertRows(at: [IndexPath(row: self.albums.count-1, section: 0)], with: .automatic)
            })
//            albumAddedToUser(snapshot)
        })
//        albumsRefHandle = self.databaseRef.child("users/$uid").observeEventType(.ChildRemoved, withBlock: { (FIRDataSnapshot) in
//            albumRemovedFromUser(FIRDataSnapshot)
//        })
    }

}
