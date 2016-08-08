//
//  SignInViewController.swift
//  Album Creator
//
//  Created by Sharud Agarwal on 6/22/16.
//  Copyright © 2016 agarwals. All rights reserved.
//

import UIKit

import Firebase
import FirebaseAuth

import FBSDKLoginKit

//import PKHUD

class SignInViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    @IBOutlet weak var FBLoginButtonView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
//    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    private var databaseRef: FIRDatabaseReference!
    private let albumsSegue = "toAlbumsCollectionViewController"
    private var userLoggedIn = false
    
    var userID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = FIRDatabase.database().reference()
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            print("\(#function):: Already logged in")
            firebaseLogin()
        }
        else {
            userLoggedIn = false
            let loginView : FBSDKLoginButton = FBSDKLoginButton()
            
            
//            loginView.bounds = self.FBLoginButtonView.frame
//            self.FBLoginButtonView.addSubview(loginView)
//            loginView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
            self.view.addSubview(loginView)
            loginView.center = self.view.center
            loginView.readPermissions = ["public_profile", "email", "user_friends"]
            loginView.delegate = self
        }
        activityIndicator.hidesWhenStopped = true
//        activityIndicator.activityIndicatorViewStyle  = UIActivityIndicatorViewStyle.Gray
//        activityIndicator.center = view.center
//        self.view.addSubview(activityIndicator)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
//        CGRect activityIndicatorFrame = acitvity
/*        var activityIndicatorFrame = activityIndicator.frame
        activityIndicatorFrame.origin.x = 0.5*self.view.frame.width
        activityIndicatorFrame.origin.y = 0.25*self.view.frame.height
        activityIndicator.frame = activityIndicatorFrame
        self.activityIndicator.startAnimating()
*/
//        frame.origin.y=10;//pass the cordinate which you want
//        frame.origin.x= 12;//pass the cordinate which you want
//        myLabel.frame= frame;
    }
//    override func viewDidAppear(animated: Bool) {
//        if (userLoggedIn) {
//            print("\(#function):: How did this happen?!")
//            performSegueWithIdentifier(albumsSegue, sender: nil)
//        }
//    }

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User clicked login")
        
        if ((error) != nil) {
            // Process error
            userLoggedIn = false
            print("\(#function):: error = \(error.localizedDescription)")
        } else if result.isCancelled {
            // Handle cancellations
            print("\(#function):: Login cancelled")
            userLoggedIn = false
        } else {
            print("No error in login and login was not cancelled")
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if (result.grantedPermissions.contains("user_friends") && result.grantedPermissions.contains("email") && result.grantedPermissions.contains("public_profile")) {
                firebaseLogin()
                
            }
        }
    }
    
    func firebaseLogin() {
        userLoggedIn = true
        self.activityIndicator.startAnimating()
//        showProgressBar()
        let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
        FIRAuth.auth()?.signInWithCredential(credential, completion: { (user, error) in
            if let error = error {
                print("\(#function):: error = \(error)")
            } else {
                let currentUser = User(username: user!.displayName!, id: user!.uid)
//                currentUser.name = user?.providerID //user?.displayName
                currentUser.profilePic = user?.photoURL
                print("\(#function):: User now initialized with name \(currentUser.name) & id = \(currentUser.id)")
                updateDatabaseWithName("users", name: currentUser.name, databaseRef: self.databaseRef, id: currentUser.id)
                self.performSegueWithIdentifier(self.albumsSegue, sender: currentUser)
            }
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        print("\(#function)")

        if (segue.identifier! == albumsSegue) {
            let nav = segue.destinationViewController as! UINavigationController
            if let destinationVC = nav.topViewController as? AlbumsCollectionViewController {
                print("\(#function):: sender = \(sender)")
                destinationVC.currentUser = sender as? User
            }
            activityIndicator.stopAnimating()
//            HUD.hide()
        } else {
            print("\(#function):: Segue identifier didn't match. Identifier = \(segue.identifier)")
        }
    }
/*
    func showProgressBar() {
        PKHUD.sharedHUD.dimsBackground = true
        PKHUD.sharedHUD.userInteractionOnUnderlyingViewsEnabled = false
        HUD.show(.Progress)
    }
*/
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
        userLoggedIn = false
    }

}
