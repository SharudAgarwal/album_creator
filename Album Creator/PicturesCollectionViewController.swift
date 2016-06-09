//
//  PicturesCollectionViewController.swift
//  Album Creator
//
//  Created by Sharud Agarwal on 6/6/16.
//  Copyright © 2016 agarwals. All rights reserved.
//

import UIKit

import Firebase
import FirebaseDatabase
import FirebaseStorage

import SwiftyJSON

class PicturesCollectionViewController: UICollectionViewController {

    private var databaseRef: FIRDatabaseReference!
    private var pictures: [FIRDataSnapshot]! = []
    private let reuseIdentifier = "pictureCell"
    
    private var picturesRefHandle: FIRDatabaseHandle!
    
    var albumID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = FIRDatabase.database().reference()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.databaseRef.child("pictures/\(albumID!)").removeObserverWithHandle(picturesRefHandle)
    }
    
    override func viewWillAppear(animated: Bool) {
        print(#function)
        updatePicturesCollection()
        print("End of updatePicturesCollection")
    }
    
    func updatePicturesCollection() {
        self.pictures.removeAll()
        self.collectionView?.reloadData()
        
        // Listen for new Pictures from Firebase database
        picturesRefHandle = self.databaseRef.child("pictures/\(albumID!)").observeEventType(.ChildAdded, withBlock: { (snapshot) in
            print(snapshot.description)
            self.pictures.append(snapshot)
            self.collectionView?.insertItemsAtIndexPaths([NSIndexPath(forRow: self.pictures.count-1, inSection: 0)])
        })
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
        return pictures.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PicturesCollectionViewCell
        let pictureSnapshot = self.pictures[indexPath.row]
        let pictureJSON = JSON(pictureSnapshot.value!)
        if let pictureURL = pictureJSON[Constants.PictureFields.url].string {
            cell.pictureImageView.image = downloadImage(pictureURL)
        } else {
            // handle error
        }
        // Configure the cell
//        cell.pictureImageView
        return cell
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
