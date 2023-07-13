//
//  LocalProfileStorage.swift
//  DasdApp ho
//
//  Created by Ethan Miller on 10/19/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import Foundation
import UIKit

struct Profile {
    static var name: String!
    static var email: String!
    
    //func to get the array of classes
    func getArrayOfClasses() -> [String] {
        return UserDefaults.standard.value(forKey: "UserInfo/Classes") as! [String]
    }
    
    //function to get the user's email
    func getUserEmail() -> String {
        return UserDefaults.standard.value(forKey: "UserInfo/Email") as! String
    }
    
    //function to get the name of the user's school
    func getUserSchoolName() -> String {
        return UserDefaults.standard.value(forKey: "UserInfo/School") as! String
    }
    
    //function to get the name of the user
    func getUserName() -> String {
        return UserDefaults.standard.value(forKey: "UserInfo/Name") as! String
    }
    
    //function to return all of the user's info in a speacialized array
    func getUserInfo() -> [UserInfo: Any] {
        return [.userName: getUserName(), .userEmail: getUserEmail(), .schoolName: getUserSchoolName(), .userClasses: getArrayOfClasses()]
    }
    
    //function to determine if the user is a teacher from local storage
    func getTeacherStatus() -> Bool {
        guard let isTeacher = UserDefaults.standard.value(forKey: "UserInfo/isTeacher") as? Bool else {
            return false
        }
        
        return isTeacher
    }
    
    //enum to represent the different user info available
    enum UserInfo {
        case userName
        case userEmail
        case schoolName
        case userClasses
    }
    
    func signOut(completion: (Bool) -> Void) {
        //set all of the profile user defaults to nil
        UserDefaults.standard.set(nil, forKey: "UserInfo/Name")
        UserDefaults.standard.set(nil, forKey: "UserInfo/Email")
        UserDefaults.standard.set(nil, forKey: "UserInfo/School")
        UserDefaults.standard.set(nil, forKey: "UserInfo/Classes")
        UserDefaults.standard.set(nil, forKey: "User/DidLogIn")
        UserDefaults.standard.set(nil, forKey: "User/DidAddClasses")
        
        completion(true)
    }
    
    //function to create and return a default image with the first letter of the user's name
    func returnDefaultImage(name: String) -> UIImage {
        //array the user's name
        let nameArray = Array(name)
        
        //set the first character of the array to a variable
        let nameFirstCharacter = String(nameArray.first!)
        
        //enter UIImage context to handle the creation of an image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 100, height: 100), false, UIScreen.main.scale)
        //create variable represting the context for the image to be drawn
        let context = UIGraphicsGetCurrentContext()
        
        //create variable representing the label
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        label.textAlignment = .center
        label.font = UIFont(name: "Copperplate", size: 100)
        label.text = nameFirstCharacter
        label.textColor = UIColor.darkGray
        
        //set the background color of the function from a random color function
        label.backgroundColor = MiscellaneousFunctions().getRandomColor()
        
        //render the label in the image
        label.layer.render(in: context!)
        
        //create variable represeting the image in the context
        let defaultImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        //end image context
        UIGraphicsEndImageContext()
        
        return defaultImage
    }
}


//UserDefualtStorages
//name of the user     - UserInfo/Name
//email of the user    - UserInfo/Email
//school of the user   - UserInfo/School
//classes of the user  - UserInfo/Classes
//is a teacher         - UserInfo/isTeacher

//Log-In Storages
//did log in - User/DidLogIn
//did add classes - User/DidAddClasses

//Tutorial Storages
//did view recently asked controller   - Tutorial/RecentlyAsked
//did view the class controller        - Tutorial/Class
//did view the question controller     - Tutorial/Question
//did view the profile controller      - Tutorial/Profile
