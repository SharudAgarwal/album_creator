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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
//    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    fileprivate var databaseRef: DatabaseReference!
    fileprivate let albumsSegue = "toAlbumsCollectionViewController"
    fileprivate var userLoggedIn = false
    
    var userID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = Database.database().reference()
        
        if (FBSDKAccessToken.current() != nil) {
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
    
    override func viewWillAppear(_ animated: Bool) {
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

    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
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
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            if let error = error {
                print("\(#function):: error = \(error)")
            } else {
                let currentUser = User(username: user!.displayName!, id: user!.uid)
//                currentUser.name = user?.providerID //user?.displayName
                currentUser.profilePic = user?.photoURL as! NSURL as URL
                print("\(#function):: User now initialized with name \(currentUser.name) & id = \(currentUser.id)")
                updateDatabaseWithName(root: "users", name: currentUser.name, databaseRef: self.databaseRef, id: currentUser.id)
                self.performSegue(withIdentifier: self.albumsSegue, sender: currentUser)
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        print("\(#function)")
        let tabVC = segue.destination as! UITabBarController
        
        if (segue.identifier! == albumsSegue) {
//            let nav = tabVC.viewcon as! UINavigationController
            tabVC.selectedIndex = 0
            let nav = tabVC.selectedViewController as! UINavigationController
            if let destinationVC = nav.topViewController as? AlbumsCollectionViewController {
                print("\(#function):: sender = \(sender)")
                destinationVC.currentUser = sender as? User
            } else {
                fatalError("Could not segue to a AlbumsCollectionViewController from SignInViewController")
            }
            activityIndicator.stopAnimating()
//            HUD.hide()
        } else {
            print("\(#function):: Segue identifier didn't match. Identifier = \(segue.identifier)")
        }
    }

    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
        userLoggedIn = false
    }

}
