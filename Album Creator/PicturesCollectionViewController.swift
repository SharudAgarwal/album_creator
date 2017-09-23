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

    fileprivate var databaseRef: DatabaseReference!
    fileprivate var storageRef: StorageReference!
    fileprivate var pictures: [DataSnapshot]! = []
    fileprivate let pictureReuseIdentifier = "pictureCell"
    fileprivate let addPicReuseIdentifier = "addPicturesCell"
    fileprivate let numberOfItemsPerRow = 3
    
    fileprivate var picturesRefHandle: DatabaseHandle!
    
    var album: Album!
//    var albumID: String?
//    var albumThumbnailSet = false

    
    @IBAction func addPicturesToAlbum(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            picker.allowsEditing = false
        } else {
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            picker.allowsEditing = false
        }
        
        present(picker, animated: true, completion:nil)
    }

/*
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
    }
*/
    
 
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion:nil)
        
        let referenceUrl = info[UIImagePickerControllerReferenceURL] as! URL
        let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl], options: nil)
        print("The number of assets fetched from Photos: \(assets.count)")
        let asset = assets.firstObject
        asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, editingInfo) in
            let imageFile = contentEditingInput?.fullSizeImageURL
            let imageID = self.databaseRef.child("pictures/\(self.album.id)").childByAutoId().key
            let filePath = "pictures/\(self.album.id)/\(imageID)"
            let filepathRef = self.storageRef.child(filePath)
            filepathRef.putFile(from: imageFile!, metadata: nil, completion: { (metadata, error) in
                if let error = error {
                    print("Error uploading: \(error.localizedDescription)")
                    return
                } else {
                    print("Upload Succeeded!")
                    updateDatabaseWithName(root: "pictures", name: imageID, databaseRef: self.databaseRef, id: self.album.id)
                    if (self.album.thumbnailURL == nil) {
                        let post = [Constants.AlbumFields.thumbnailURL:"pictures/\(self.album.id)/\(imageID)"]
                        updateDatabaseWithPost(root: "albums", post: post, databaseRef: self.databaseRef, id: self.album.id)
                        self.album.setThumbnail(thumbnailPath: "pictures/\(self.album.id)/\(imageID)")
                    }
                    self.collectionView!.reloadEmptyDataSet()
                }
            })

        })  //requestContentEditingInputWithOptions
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = Database.database().reference()
        storageRef = Storage.storage().reference()
        self.collectionView!.emptyDataSetSource = self
        self.collectionView!.emptyDataSetDelegate = self
/*        let tabBarController = self.tabBarController
        let tabBar = tabBarController?.tabBar
        
        let tabBarItem1 = UITabBarItem(title: "Pictures", image: UIImage(named: "tab_icon_normal"), selectedImage: UIImage(named: "tab_icon_seelcted"))
        let tabBarItem2 = UITabBarItem(title: "Settings", image: UIImage(named: "tab_icon_normal"), selectedImage: UIImage(named: "tab_icon_seelcted"))
        let tabBarItems: [UITabBarItem] = [tabBarItem1, tabBarItem2]
        
        tabBar?.setItems(tabBarItems, animated: false)
*/        //        self.collectionView.footer
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
    
    override func viewWillDisappear(_ animated: Bool) {
        print(#file + "::" + #function)
        self.databaseRef.child("pictures/\(album.id)").removeObserver(withHandle: picturesRefHandle)
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
        picturesRefHandle = self.databaseRef.child("pictures/\(album.id)").observe(.childAdded, with: { (snapshot) in
            print(snapshot.description)
            self.pictures.append(snapshot)
            self.collectionView?.insertItems(at: [NSIndexPath(row: self.pictures.count-1, section: 0) as IndexPath])
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

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pictures.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    /*    if (indexPath.row != numberOfItemsPerRow) {
            cell = CollectionView.dequeueReusableCellWithReuseIdentifier(addPicturesReuseIdentifier, forIndexPath: indexPath) as! AddPicturesCollectionViewCell
        }*/
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: pictureReuseIdentifier, for: indexPath) as! PicturesCollectionViewCell
        let pictureSnapshot = self.pictures[indexPath.row]
        let pictureJSON = JSON(pictureSnapshot.value!)
        print("\(#function):: pictures.count = \(pictures.count) & albumThumbnail = \(self.album.thumbnailURL as Optional)")
        if (pictureJSON[Constants.PictureFields.pathToImage].string != nil) {
            setCellImageView(cell: cell, snapshotJSON: pictureJSON, storageRef: storageRef)
        } else {
            fatalError("\(#function):: How did I get here??")
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // This will cancel all unfinished downloading task when the cell disappearing.
        // swiftlint:disable force_cast
        (cell as! PicturesCollectionViewCell).pictureImageView.kf.cancelDownloadTask()
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
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = album.name
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }

    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "You currently have no photos in this album."
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }

    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if (self.pictures.isEmpty) {
            return true
        } else {
            return false
        }
    }
}
