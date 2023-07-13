//
//  ViewController.swift
//  DasdApp
//
//  Created by Ethan Miller on 10/9/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class WelcomeScreen: CustomViewController {

    @IBOutlet weak var headerSubLabel: UILabel!
    
    @IBOutlet weak var loadingBar: UIView!
    
    @IBOutlet weak var headerLabel: UILabel!
    
    let loadingBarView = CAShapeLayer()
    
    let authRef = Auth.auth()
    let storeRef = Firestore.firestore()
    
    //MARK: VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewDidLayoutSubviews() {
        //run configuration of the loading bar
        addLoadingBar()
    }
    
    //MARK: VIEW DID APPEAR
    override func viewDidAppear(_ animated: Bool) {
        //read userdefaults to determine if sign in is required
        if UserDefaults.standard.value(forKey: "User/DidLogIn") as? Bool != true {
            //show screen to sign in the user
            self.performSegue(withIdentifier: "showSignIn", sender: self)
            //show that the user signed up for the latest version
            UserDefaults.standard.set(true, forKey: "1.0.1 (2)")
        } else if UserDefaults.standard.value(forKey: "User/DidAddClasses") as? Bool != true {
            //first determine if the person is a teacher waiting for sign in
            TeacherFunctions().determineInTeacherList(uid: Auth.auth().currentUser!.uid) { (list) in
                if list == .some(.toApprove) {
                    //show error message
                    presentMessageWithAction(sender: self, title: "Pending Approval", message: "Your Teacher Profile is pending approval. Please wait while we approve it.", actionTitle: "Refresh", action: self.runLoad)
                } else if list == .some(.denied) {
                    //show error message
                    presentMessageWithAction(sender: self, title: "Profile Denied", message: "Your request for a teacher profile has been denied. Please contact support if you think this is a mistake.", actionTitle: "Refresh", action: self.runLoad)
                } else {
                    //show screen to prompt the user to select a class
                    self.performSegue(withIdentifier: "showClassSelectionView", sender: self)
                }
            }
        } else {
            //fun if statement to determine if the user is using the latest version
            if UserDefaults.standard.value(forKey: "1.0.1 (2)") as? Bool == nil {
                UserDefaults.standard.set("Beta-Testing (Mr. Brown-Y1 Physics)", forKey: "UserInfo/School")
                //run update functions
                print("applying updates")
                runUpdates()
            } else {
                //run loading functions
                runLoad()
                print("loading")
            }
        }
    }
    
    //MARK: UPDATE FUNCTIONS
    //function to determine if the user is running on the latest version of the app, and update if needed
    func runUpdates() {
        headerSubLabel.text = "Updating..."
        moveLoadingBar(to: 1/100)
        
        //algorythm determining what updates need to be applied
        if UserDefaults.standard.value(forKey: "1.0.1") as? Bool == nil {
            print("updating to 1.0.1")
            
            //determine if the user was part of beta testing
            if Profile().getUserSchoolName() == "Beta-Testing (Mr. Brown-Y1 Physics)" {
                //run function to sign up the user for the new beta testing
                signUpUser(UID: Auth.auth().currentUser!.uid, school: "STEM Beta Testing", userEmail: Profile().getUserEmail(), userName: Profile().getUserName())
                
                //upload the user classes to the new profile
                Firestore.firestore().collection("STEM Beta Testing").document("Users").collection("UserCollection").document(Auth.auth().currentUser!.uid).updateData(["classes" : Profile().getArrayOfClasses()])
                
                var timerIndex: Int = 0
                //create a repeating function
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
                    timerIndex += 1
                    
                    print("timer: \(timerIndex)")
                    
                    self.moveLoadingBar(to: CGFloat(timerIndex)/10)
                    
                    if timerIndex == 10 {
                        timer.invalidate()
                        
                        UserDefaults.standard.set(true, forKey: "1.0.1")
                        
                        UserDefaults.standard.set(nil, forKey: "User/DidAddClasses")
                        
                        self.viewDidAppear(true)
                    }
                }
            }
        } else if UserDefaults.standard.value(forKey: "1.0.1 (2)") as? Bool == nil {
            //run functions to determine if the user is a teacher
            TeacherFunctions().determineIfTeacher(school: Profile().getUserSchoolName(), uid: Auth.auth().currentUser!.uid) { (isTeacher) in
                //set user default showing that the user is a teacher or not
                UserDefaults.standard.set(isTeacher, forKey: "UserInfo/isTeacher")
                
                //show that the user has updated
                UserDefaults.standard.set(true, forKey: "1.0.1 (2)")
                
                //run function to reload
                self.viewDidAppear(true)
            }
        } else {
            print("other update")
        }
    }
    
    
    //MARK: LOADING BAR
    func addLoadingBar() {
        print("adding loading bar")
        loadingBar.backgroundColor = UIColor.clear
        
        let trackView = CAShapeLayer()
        trackView.frame = CGRect(x: 0, y: 0, width: loadingBar.frame.width, height: loadingBar.frame.height)
        trackView.cornerRadius = 10
        trackView.backgroundColor = UIColor.lightGray.cgColor
        trackView.borderColor = UIColor.darkGray.cgColor
        trackView.borderWidth = 5
        
        loadingBarView.frame = CGRect(x: 5, y: 5, width: 0, height: loadingBar.frame.height - 10)
        loadingBarView.cornerRadius = 5
        loadingBarView.backgroundColor = UIColor.blue.cgColor
        
        loadingBar.layer.addSublayer(trackView)
        loadingBar.layer.addSublayer(loadingBarView)
    }
    
    //function to move loading par to a percentage of its width
    func moveLoadingBar(to: CGFloat) {
        print("moving loading bar")
        //find the full width the load view can extend to
        let fullWidth = loadingBar.frame.width - 10
        
        //change the frame of the load percent view
        loadingBarView.frame = CGRect(x: 5, y: 5, width: fullWidth * to, height: loadingBar.frame.height - 10)
    }
    
    //MARK: LOADING FUNCTIONS
    func runLoad() {
        //move loading bar to 1/4 the way
        moveLoadingBar(to: 1/6)
        
        //first check app permissions, get allowLaunch and class array
        storeRef.collection("AppInfo").document("MainInfo").getDocument { (document, error) in
            //run error check
            if error != nil {
                print(error!)
                presentMessageWithAction(sender: self, title: "Unexpected Error!", message: "Try checking your network connection.", actionTitle: "Refresh", action: self.runLoad)
            } else {
                //download allow launch and class array
                let allowLaunch: Bool = document?.data()?["allowLaunch"] as! Bool
                let classArray: [String] = document?.data()?["Schools"] as! [String]
                
                //check to see if emergency shut down is active
                if allowLaunch == false && classArray.isEmpty {
                    fatalError("//EMERGENCY SHUT DOWN ACTIVE//")
                } else if allowLaunch == false {
                    //show that app is currently inactive
                    presentMessageWithAction(sender: self, title: "App Closed!", message: "Sorry, we are currently working on the app. TAKT will be active again soon.", actionTitle: "Refresh", action: self.runLoad)
                } else {
                    //move loading bar
                    self.moveLoadingBar(to: 2/6)
                    
                    //continue with load
                    //determine if there is an update
                    //get the device version
                    let deviceVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                    
                    //download the firebase version
                    let firebaseVersion = document?.data()?["currentVersion"] as! String
                    let betaVersion = document?.data()?["betaVersion"] as! String
                    
                    //run if to see if the user needs to update
                    if deviceVersion! != firebaseVersion && deviceVersion! != betaVersion {
                        //show message prompting user ot update
                        presentMessageWithAction(sender: self, title: "Update Available!", message: "You need to update the app to continue!", actionTitle: "Refresh", action: self.runLoad)
                    } else {
                        //completed, move loading bar
                        self.moveLoadingBar(to: 3/6)
                        
                        //run function to determine if the user is a teacher
                        TeacherFunctions().determineInTeacherList(uid: Auth.auth().currentUser!.uid) { (list) in
                            switch list {
                            case .denied:
                                presentMessageWithAction(sender: self, title: "Teacher Request Denied", message: "Your request to obtain a teacher profile has been denied.", actionTitle: "Refresh") {
                                    self.runLoad()
                                }
                                
                            case .toApprove:
                                presentMessageWithAction(sender: self, title: "Pending Approval", message: "Your request to obtain a teacher profile if pending. Please wait.", actionTitle: "Refresh") {
                                    self.runLoad()
                                }
                                
                            case .approved, nil:
                                print("teacher profile granted, or doesnt exsist")
                                
                                self.moveLoadingBar(to: 4/6)
                                
                                //check to see if the user's school is allowed
                                //establish connection to get the permission for the school
                                self.storeRef.collection(Profile().getUserSchoolName()).document("MainInfo").getDocument { (secondDocument, secondError) in
                                    //run error check
                                    if error != nil {
                                        print(error! as NSError)
                                        presentMessageWithAction(sender: self, title: "Unexpected Error!", message: "Try checking your network connection", actionTitle: "Refresh", action: self.runLoad)
                                    } else {
                                        //get the permission value
                                        let classPermission = secondDocument?.data()?["allowLaunch"] as! Bool
                                        
                                        //run if to check the permission
                                        if classPermission == false {
                                            //show school is disabled
                                            presentMessageWithAction(sender: self, title: "School Disabled", message: "The school you are signed into is currently disabled.", actionTitle: "Refresh", action: self.runLoad)
                                        } else {
                                            //compelte, move loading bar
                                            self.moveLoadingBar(to: 5/6)
                                            
                                            //run function to check for user banishment
                                            Permissions().determineIfUserIsOnList(uid: Auth.auth().currentUser!.uid) { (list) in
                                                //enter a switch statement to determine what to move to
                                                switch list {
                                                case .permenant, .weekLong, .dayLong:
                                                    //run if statement to determine which message to send
                                                    if list == .some(.permenant) {
                                                        presentMessageWithAction(sender: self, title: "Banned", message: "You have been banned permenantly.", actionTitle: "Refresh", action: self.runLoad)
                                                    } else if list == .some(.weekLong) {
                                                        presentMessageWithAction(sender: self, title: "Week-Long Ban", message: "You have been banned for the remainder of the week", actionTitle: "Refresh", action: self.runLoad)
                                                    } else if list == .some(.dayLong) {
                                                        presentMessageWithAction(sender: self, title: "Day-Long", message: "You have been banned for the rest of the day", actionTitle: "Refresh", action: self.runLoad)
                                                    }
                                                case .firstOffense, .secondOffense, .thirdOffense:
                                                    //enter an if statement to determine which notification to send
                                                    print("found first offense: \(list!)")
                                                    
                                                    if list == .some(.firstOffense) {
                                                        notifyUser(title: "First Offense", body: "You have been reported. You have two more strikes before you will receive a ban", afterTime: 1)
                                                    } else if list == .some(.secondOffense) {
                                                        notifyUser(title: "Second Offense", body: "You have been reported for a second time. You have only one more strike.", afterTime: 1)
                                                    } else if list == .some(.thirdOffense) {
                                                        notifyUser(title: "Third Offense", body: "You have been reported for a third time. Being reported again will result in a ban.", afterTime: 1)
                                                    }
                                                    
                                                    //continue to enter the app
                                                    
                                                    self.moveLoadingBar(to: 1)
                                                    
                                                    //start repeating function
                                                    Permissions().initiateRepeatedCheck()
                                                    
                                                    //run seague, after delay
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                        self.showTabController()
                                                    }
                                                case .none:
                                                    self.moveLoadingBar(to: 1)
                                                    
                                                    //start repeating function
                                                    Permissions().initiateRepeatedCheck()
                                                    
                                                    //run seague, after delay
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                        self.showTabController()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //function to continue to tab controller
    @objc func showTabController() {
        performSegue(withIdentifier: "continueToTabController", sender: self)
    }
}

