//
//  PicturesCollectionViewController.swift
//  Album Creator
//
//  Created by Sharud Agarwal on 6/6/16.
//  Copyright © 2016 agarwals. All rights reserved.
//

import UIKit
import Photos

import Firebase
import FirebaseDatabase
import FirebaseStorage

import SwiftyJSON
import DZNEmptyDataSet
import Kingfisher

//import CryptoSwift

class PicturesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var picturesViewTitleBar: UINavigationItem!

    private var databaseRef: FIRDatabaseReference!
    private var storageRef: FIRStorageReference!
    private var pictures: [FIRDataSnapshot]! = []
    private let reuseIdentifier = "pictureCell"
    private let numberOfItemsPerRow = 3
    
    private var picturesRefHandle: FIRDatabaseHandle!
    
    var album: Album!
//    var albumID: String?
//    var albumThumbnailSet = false

    
    @IBAction func addPicturesToAlbum(sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            picker.allowsEditing = false
        } else {
            picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            picker.allowsEditing = false
        }
        
        presentViewController(picker, animated: true, completion:nil)
    }

/*
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
    }
*/
    
 
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion:nil)
        
        let referenceUrl = info[UIImagePickerControllerReferenceURL] as! NSURL
        let assets = PHAsset.fetchAssetsWithALAssetURLs([referenceUrl], options: nil)
        print("The number of assets fetched from Photos: \(assets.count)")
        let asset = assets.firstObject
        asset?.requestContentEditingInputWithOptions(nil, completionHandler: { (contentEditingInput, editingInfo) in
            let imageFile = contentEditingInput?.fullSizeImageURL
            let imageID = self.databaseRef.child("pictures/\(self.album.id)").childByAutoId().key
            let filePath = "pictures/\(self.album.id)/\(imageID)"
            let filepathRef = self.storageRef.child(filePath)
            filepathRef.putFile(imageFile!, metadata: nil, completion: { (metadata, error) in
                if let error = error {
                    print("Error uploading: \(error.description)")
                    return
                } else {
                    print("Upload Succeeded!")
                    updateDatabaseWithName("pictures", name: imageID, databaseRef: self.databaseRef, id: self.album.id)
                    if (self.album.thumbnailURL == nil) {
                        let post = [Constants.AlbumFields.thumbnailURL:"pictures/\(self.album.id)/\(imageID)"]
                        updateDatabaseWithPost("albums", post: post, databaseRef: self.databaseRef, id: self.album.id)
                        self.album.setThumbnail("pictures/\(self.album.id)/\(imageID)")
                    }
                    self.collectionView!.reloadEmptyDataSet()
                }
            })

        })  //requestContentEditingInputWithOptions
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = FIRDatabase.database().reference()
        storageRef = FIRStorage.storage().reference()
        self.collectionView!.emptyDataSetSource = self
        self.collectionView!.emptyDataSetDelegate = self
//        self.collectionView.footer
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    deinit {
        self.collectionView!.emptyDataSetSource = nil
        self.collectionView!.emptyDataSetDelegate = nil
    }
    
    override func viewWillDisappear(animated: Bool) {
        print(#file + "::" + #function)
        self.databaseRef.child("pictures/\(album.id)").removeObserverWithHandle(picturesRefHandle)
    }
    
    override func viewWillAppear(animated: Bool) {
        print(#file + "::" + #function)
        picturesViewTitleBar.title = self.album.name
        updatePicturesCollection()
        self.collectionView!.reloadEmptyDataSet()
        print("End of updatePicturesCollection")
    }
    
    func updatePicturesCollection() {
        self.pictures.removeAll()
        self.collectionView?.reloadData()
        
        // Listen for new Pictures from Firebase database
        picturesRefHandle = self.databaseRef.child("pictures/\(album.id)").observeEventType(.ChildAdded, withBlock: { (snapshot) in
            print(snapshot.description)
            self.pictures.append(snapshot)
            self.collectionView?.insertItemsAtIndexPaths([NSIndexPath(forRow: self.pictures.count-1, inSection: 0)])
            self.collectionView!.reloadEmptyDataSet()
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
        print("\(#function):: pictures.count = \(pictures.count) & albumThumbnail = \(self.album.thumbnailURL)")
        if (pictureJSON[Constants.PictureFields.pathToImage].string != nil) {
            setCellImageView(cell, snapshotJSON: pictureJSON, storageRef: storageRef)
        } else {
            fatalError("\(#function):: How did I get here??")
        }
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        // This will cancel all unfinished downloading task when the cell disappearing.
        // swiftlint:disable force_cast
        (cell as! PicturesCollectionViewCell).pictureImageView.kf_cancelDownloadTask()
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
    
//    override func collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
//        // move your data order
//    }
    

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

extension PicturesCollectionViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = album.name
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        return NSAttributedString(string: str, attributes: attrs)
    }

    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "You currently have no photos in this album."
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: str, attributes: attrs)
    }

    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        if (self.pictures.isEmpty) {
            return true
        } else {
            return false
        }
    }
}