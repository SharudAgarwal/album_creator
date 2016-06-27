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

class SignInViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    @IBOutlet weak var FBLoginButtonView: UIView!
    
    private let albumsSegue = "toAlbumsCollectionViewController"
    private var userLoggedIn = false
    
    var userID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            firebaseLogin()
            userLoggedIn = true
            print("\(#function):: Already logged in")
        }
        else {
            let loginView : FBSDKLoginButton = FBSDKLoginButton()
            
            
//            loginView.bounds = self.FBLoginButtonView.frame
//            self.FBLoginButtonView.addSubview(loginView)
//            loginView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
            self.view.addSubview(loginView)
            loginView.center = self.view.center
            loginView.readPermissions = ["public_profile", "email", "user_friends"]
            loginView.delegate = self
        }

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        if (userLoggedIn) {
            performSegueWithIdentifier(albumsSegue, sender: nil)
        }
    }

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
                userLoggedIn = true
                firebaseLogin()
                performSegueWithIdentifier(albumsSegue, sender: nil)
            }
        }
    }
    
    func firebaseLogin() {
        let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
        FIRAuth.auth()?.signInWithCredential(credential, completion: { (user, error) in
            if let error = error {
                print("\(#function):: error = \(error)")
            } else {
                User.name = user?.displayName
                User.profilePic = user?.photoURL
                print("\(#function):: User now initialized")
                //FIXME: Need to make this blocking. Put a loading progress circle and then segue from here
            }
        })
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
        userLoggedIn = false
    }

}
