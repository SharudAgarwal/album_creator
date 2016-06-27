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

import Kingfisher

//import CryptoSwift

class PicturesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var databaseRef: FIRDatabaseReference!
    private var storageRef: FIRStorageReference!
    private var pictures: [FIRDataSnapshot]! = []
    private let reuseIdentifier = "pictureCell"
    
    private var picturesRefHandle: FIRDatabaseHandle!
    
    var albumID: String?
    
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
//        print(hash?.toHexString())
        let assets = PHAsset.fetchAssetsWithALAssetURLs([referenceUrl], options: nil)
        print("The number of assets fetched from Photos: \(assets.count)")
        let asset = assets.firstObject
        asset?.requestContentEditingInputWithOptions(nil, completionHandler: { (contentEditingInput, editingInfo) in
            let imageFile = contentEditingInput?.fullSizeImageURL
//            let filePath = "\(FIRAuth.auth()?.currentUser?.uid)/\(Int(NSDate.timeIntervalSinceReferenceDate() * 1000))/\(referenceUrl.lastPathComponent!)"
//            let imageID = stringUpToChar((asset?.localIdentifier)!, delimitingChar: "/")
            let imageID = self.databaseRef.child("pictures/\(self.albumID!)").childByAutoId().key
/*            let imageFileName = referenceUrl.lastPathComponent
            var imageData: NSData?
            if (((imageFileName?.lowercaseString.containsString("jpg") != nil) || (imageFileName?.lowercaseString.containsString("jpeg")) != nil)) {
                imageData = UIImageJPEGRepresentation(info[UIImagePickerControllerOriginalImage] as! UIImage, 1.0)
            } else if (imageFileName?.lowercaseString.containsString("png") != nil) {
                imageData = UIImagePNGRepresentation(info[UIImagePickerControllerOriginalImage] as! UIImage)
            } else {
                fatalError("\(#function):: ERROR: Trying to hash an image of type \(imageFileName!)")
            }
//            let imageHash = imageData?.sha256()?.toHexString()
*/
            let filePath = "pictures/\(self.albumID!)/\(imageID)"
//            let metadata = FIRStorageMetadata()
//            metadata.contentType = "image/jpeg"
            let filepathRef = self.storageRef.child(filePath)
//            filepathRef.putFile(imageFile!)
            filepathRef.putFile(imageFile!, metadata: nil, completion: { (metadata, error) in
                if let error = error {
                    print("Error uploading: \(error.description)")
                    return
                } else {
                    print("Upload Succeeded!")
//                    let downloadURL = metadata!.downloadURL()
//                    self.updateDatabaseWithImage(imageID, url: "\(Constants.FirebaseFields.storageURL)/pictures/\(self.albumID!)/\(imageID)")
//                    self.updateDatabaseWithImage(imageID, url: downloadURL!.absoluteString)
                    self.updateDatabaseWithImage(imageID)
                }
            })

        })  //requestContentEditingInputWithOptions
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = FIRDatabase.database().reference()
        storageRef = FIRStorage.storage().reference()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(animated: Bool) {
        print(#file + "::" + #function)
        self.databaseRef.child("pictures/\(albumID!)").removeObserverWithHandle(picturesRefHandle)
    }
    
    override func viewWillAppear(animated: Bool) {
        print(#file + "::" + #function)
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
        
        cell.pictureImageView.kf_showIndicatorWhenLoading = true
        if let picturePath = pictureJSON[Constants.PictureFields.pathToImage].string {
            print("DEBUG: picturePath = \(picturePath)")
            
            let imageRef = storageRef.child(picturePath)
            imageRef.downloadURLWithCompletion { (URL, error) -> Void in
                
                if let error = error {
                    print("\(#function):: error = \(error.localizedDescription)")
                } else {
                    print("\(#function):: successfully grabbed url = \(URL?.absoluteString)")
                    cell.pictureImageView.kf_setImageWithURL(URL!, placeholderImage: nil)
                }
            }
            
        } else {
            print("\(#function):: picturePath does not exist for current snapshot")
        }
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        // This will cancel all unfinished downloading task when the cell disappearing.
        // swiftlint:disable force_cast
        (cell as! PicturesCollectionViewCell).pictureImageView.kf_cancelDownloadTask()
    }
    
//    override func collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
//        // move your data order
//    }
    
    func updateDatabaseWithImage(name: String) {
//        let key = databaseRef.child("pictures/\(self.albumID!)").childByAutoId().key
        let post = [Constants.PictureFields.name: name,
                    Constants.PictureFields.pathToImage: "pictures/\(self.albumID!)/\(name)"]
        let childUpdates = ["pictures/\(self.albumID!)/\(name)": post]
        databaseRef.updateChildValues(childUpdates)
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
