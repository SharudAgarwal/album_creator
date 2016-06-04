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

class AlbumsTableViewController: UITableViewController {
    
//    var myAlbums = Albums().albums
    var albumsRef: FIRDatabaseReference!
    var albums: [FIRDataSnapshot]! = []
    
    private var albumsRefHandle: FIRDatabaseHandle!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        albumsRef = FIRDatabase.database().reference()
        
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

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("albumCell", forIndexPath: indexPath) as! AlbumsTableViewCell
        // unpack album data from Firebase DataSnapshot
        let albumSnapshot: FIRDataSnapshot! = self.albums[indexPath.row]
        let albumJSON = JSON(albumSnapshot)
//        let album = albumJSON
//        let album = albumSnapshot.value as! Dictionary<String, String>
        cell.AlbumNameLabel.text = albumJSON[Constants.AlbumFields.name].string
        if let albumThumbnailURL = albumJSON[Constants.AlbumFields.thumbnailURL].string {
            cell.AlbumImageView.image = downloadImage(albumThumbnailURL)
        } else {
            // Todo: Need to implement nil image object class from github
        }
        return cell
            
    }
    
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
    override func viewWillAppear(animated: Bool) {
        updateTable()
    }
    
    /// Updates albums tablue view by refetching each image url and album name. 
    func updateTable() {
        self.albums.removeAll()
        self.tableView.reloadData()
        // Listen for new Albums from Firebase database
//        albumsRefHandle = self.albumsRef.child("album/photos/").observeSingleEventOfType(.Value, withBlock: { (FIRDataSnapshot) in
//            code
//        })
    }

}
