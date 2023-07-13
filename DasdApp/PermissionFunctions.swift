//
//  PermissionFunctions.swift
//  DasdApp
//
//  Created by Ethan Miller on 1/1/20.
//  Copyright © 2020 Ethan Miller. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore

struct Permissions {
    //create private variable representing the firestore
    private var storeRef = Firestore.firestore()
    
    //function to see if the app is allowed to launch
    func checkLaunchPermission(complete: @escaping (Bool) -> Void) {
        //initiate connection to the app's main info
        storeRef.collection("AppInfo").document("MainInfo").getDocument { (document, error) in
            //run an error check
            if error != nil {
                //error ocurred, treat as disabled
                print(error! as NSError)
                
                complete(false)
            } else {
                //download the permission
                let permission = document?.data()?["allowLaunch"] as! Bool
                
                //run completion with the permission value
                complete(permission)
            }
        }
    }
    
    //function to check permissions for a school
    func checkPermissionsForSchool(school: String, complete: @escaping (Bool) -> Void) {
        //first, run function to see if the app is allowed to launch
        checkLaunchPermission { (launchAllowed) in
            //run if statement to determine if the launch if permitted, and handle completion if necessary
            if launchAllowed == false {
                complete(false)
            } else {
                //initiate connection to the school
                self.storeRef.collection(school).document("MainInfo").getDocument { (document, error) in
                    //run an error check
                    if error != nil {
                        print(error! as NSError)
                        //treat as disabled
                        complete(false)
                    } else {
                        //download the permission
                        let permission = document?.data()?["allowLaunch"] as! Bool
                        
                        //run completion with the permission value
                        complete(permission)
                    }
                }
            }
        }
    }
    
    //function to determine if new questions are allowed for a certain class in a school
    func checkNewQuestionsMasterPermission(school: String, complete: @escaping (Bool) -> Void) {
        //first, run permission function for the school
        checkPermissionsForSchool(school: school) { (schoolAllowed) in
            //first, check if the school is allowed, which also checks if the app launch is permitted
            if schoolAllowed == false {
                complete(false)
            } else {
                //initiate conection to the question collection to the school
                self.storeRef.collection(school).document("Questions").getDocument { (document, error) in
                    //run an error check
                    if error != nil {
                        print(error! as NSError)
                        //treat as if it were disabled
                        complete(false)
                    } else {
                        //download the permissions value
                        let permission = document?.data()?["allowNewQuestions"] as! Bool
                        
                        //run completion function with the found value
                        complete(permission)
                    }
                }
            }
        }
    }
    
    //function to check permissions for a certain class in a certain school
    func checkNewQuestionsPermissionForClass(school: String, forClass: String, complete: @escaping (Bool) -> Void) {
        //first run permission for school, to ensure the school is permitted
        checkNewQuestionsMasterPermission(school: school) { (masterPermission) in
            //run if statement to determine if master value is true, which also checked if launch and school are allowed
            if masterPermission == false {
                complete(false)
            } else {
                //initiate connection to the school, and then to the class
                self.storeRef.collection(school).document("Questions").collection(forClass).document("Info").getDocument { (document, error) in
                    //run an error check
                    if error != nil {
                        print(error! as NSError)
                        //treat as disabled
                        complete(false)
                    } else {
                        //download the permissions value
                        let permission = document?.data()?["allowQuestions"] as? Bool ?? true
                        
                        //run completion function with the permission value
                        complete(permission)
                    }
                }
            }
        }
    }
    
    //function to determine if a question is currently allowing responses
    func checkNewResponsesPermissionForQuestion(forSchool: String, forClass: String, forQuestion: String, complete: @escaping (Bool) -> Void) {
        
        print(forSchool, forClass, forQuestion)
        
        //first run function to determine if new questions are allowed for the class
        checkNewQuestionsPermissionForClass(school: forSchool, forClass: forClass) { (classPermission) in
            //check to see if class new questions are permitted, also checks if class, school, and app launch is permitted
            if classPermission == false {
                complete(false)
            } else {
                //initiate connection to the response collection for the question
                self.storeRef.collection(forSchool).document("Questions").collection(forClass).document(forQuestion).collection("Responses").document("Info").getDocument { (document, error) in
                    //run an error check
                    if error != nil {
                        print(error! as NSError)
                        //treat as if disabled
                        complete(false)
                    } else {
                        //download the permissions value
                        guard let permission = document?.data()?["allowResponses"] as? Bool else {
                            complete(false)
                            return
                        }
                        
                        //run completion function with permission variable
                        complete(permission)
                    }
                }
            }
        }
    }
    
    //function to determine if the school is accepting new users
    func checkNewUsersPermission(school: String, complete: @escaping (Bool) -> Void) {
        //first, check to see if app launch and school is allowed
        checkPermissionsForSchool(school: school) { (schoolPermission) in
            //run if to see if the school is permitted, also checks to see if app launch is allowed
            if schoolPermission == false {
                complete(false)
            } else {
                //initiate connection to the Info document in the Users collection
                self.storeRef.collection(school).document("Users").collection("UsereCollection").document("Info").getDocument { (document, error) in
                    //run error check
                    if error != nil {
                        print(error! as NSError)
                        //treat as if disabled
                        complete(false)
                    } else {
                        //download the permissions value
                        let permission = document?.data()?["allowNewUsers"] as! Bool
                        
                        //run completion function with the permissions variable
                        complete(permission)
                    }
                }
            }
        }
    }
    
    //function to determine if sign ups to the TTP are allowed
    func checkTTPPermissions(complete: @escaping (Bool) -> Void) {
        //first, check if app launch is allowed
        checkLaunchPermission { (launchPermission) in
            if launchPermission == false {
                complete(false)
            } else {
                //initiate conection to the main info section of the database
                Firestore.firestore().collection("AppInfo").document("MainInfo").getDocument { (document, error) in
                    //run error check
                    if error != nil {
                        print(error!)
                        complete(false)
                    } else {
                        //download the permissions value
                        let TTPPermission = document?.data()?["allowTTPSignUp"] as! Bool
                        
                        complete(TTPPermission)
                    }
                }
            }
        }
    }
    
    //MARK: REPEATED CHECK FUNCTION
    //static variable to turn on or off the repeated check
    static var allowRepeatedCheck: Bool = true
    //function to run repeadtedly to determine if use is still allowed
    func initiateRepeatedCheck() {
        //create a time to go off every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { (timer) in
            //switch the current repeated check variable
            switch Permissions.allowRepeatedCheck {
            case false:
                //set for false, deactivate the timer
                timer.invalidate()
            case true:
                //start running through permissions functions
                //first, determine if the school is enabled, which also checks app availability
                self.checkPermissionsForSchool(school: Profile().getUserSchoolName()) { (schoolPermission) in
                    //run if statement to say if the school is enabled
                    if schoolPermission == false {
                        //cause the app to crash
                        fatalError("PERMISSION CHANGE")
                    } else {
                        //run function to determine any changes with user banishment
                        self.determineIfUserIsOnList(uid: Auth.auth().currentUser!.uid) { (list) in
                            //enter switch statement to determine what type of list the user is in
                            switch list {
                            case .dayLong, .weekLong, .permenant:
                                //crash the app
                                fatalError("USER BANNED")
                            default:
                                print("User Cleared for Use \(NSDate.now)")
                                
                                //run function to determine if there is any new data
                                Notifications().compareData()
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: PERSONAL PERMISSIONS FUNCTIONS
    func determineIfUserIsOnList(uid: String, complete: @escaping (Reporting.ReportListType?) -> Void) {
        //download the lists of reported users
        storeRef.collection("AppInfo").document("ReportData").getDocument { (document, error) in
            //run error check
            if error != nil {
                print(error! as NSError)
                complete(.none)
            } else {
                //download the lists
                let firstOffense: [String] = document?.data()?["firstOffense"] as! [String]
                let secondOffense: [String] = document?.data()?["secondOffense"] as! [String]
                let thirdOffense: [String] = document?.data()?["thirdOffense"] as! [String]
                let dayList: [String] = document?.data()?["24HourBlackList"] as! [String]
                let weekList: [String] = document?.data()?["WeekBlackList"] as! [String]
                let permenantList: [String] = document?.data()?["theBlackList"] as! [String]
                
                //run through a series of if statements
                if firstOffense.contains(uid) {
                    complete(.firstOffense)
                } else if secondOffense.contains(uid) {
                    complete(.secondOffense)
                } else if thirdOffense.contains(uid) {
                    complete(.thirdOffense)
                } else if dayList.contains(uid) {
                    complete(.dayLong)
                } else if weekList.contains(uid) {
                    complete(.weekLong)
                } else if permenantList.contains(uid) {
                    complete(.permenant)
                } else {
                    complete(.none)
                }
            }
        }
    }
}
