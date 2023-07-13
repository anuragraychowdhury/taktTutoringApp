//
//  OnlineProfileStorage.swift
//  DasdApp
//
//  Created by Ethan Miller on 2/16/20.
//  Copyright © 2020 Ethan Miller. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage

//struct to hold functions to assign questions and responses to profiles
struct QuestionsForProfile {
    //firebase firestore constant, set to the class of the user
    let profileRef = Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(Auth.auth().currentUser!.uid)
    
    //function to assign the question to the profile
    func assignQuestionToProfile(forClass: String, questionText: String) {
        //set up the data for upload
        let combinedData: String = "\(forClass)†\(questionText)"
        
        //download the current array of quections from the profile
        profileRef.getDocument { (document, error) in
            //continue, ignore error check
            var arrayOfQuestions = document?.data()?["userQuestions"] as! [String]
            
            //insert the new data
            arrayOfQuestions.insert(combinedData, at: 0)
            
            //upload the new data
            self.profileRef.updateData(["userQuestions": arrayOfQuestions])
        }
    }
    
    //function to return the combined array of questions
    func getQuestionsFromProfile(completion: @escaping ([ProfileQuestion]) -> Void) {
        //download the array of questions from the user profile
        profileRef.getDocument { (document, error) in
            //continue, ignore error check
            let downloadedArray = document?.data()?["userQuestions"] as! [String]
            
            //create variable to hold the seperated data in an array
            var seperatedData: [ProfileQuestion] = []
            
            //enter for loop to seperate all of the data
            for item in downloadedArray {
                //run function to seperate the data and add it to the array
                seperatedData.append(item.seperate(byCharacter: "†"))
            }
            
            //return the data
            completion(seperatedData)
        }
    }
    
    //response version of function
    struct Responses {
        let responsesProfileRef = Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(Auth.auth().currentUser!.uid)
        
        //function to assign the response to the user profile
        func assignResponseToProfile(forClass: String, forQuestion: String, responseText: String) {
            //set up the data for upload
            let combinedData = "\(forClass)†\(forQuestion)~\(responseText)"
            
            //download the current array from the profile
            responsesProfileRef.getDocument { (document, error) in
                //download the document, ignore error check
                var currentArray: [String] = document?.data()?["userResponses"] as! [String]
                
                //insert the new data in the array
                currentArray.insert(combinedData, at: 0)
                
                //upload the new data to the profile
                self.responsesProfileRef.updateData(["userResponses": currentArray])
            }
        }
        
        //function to return an array of responses from the profile
        func getResponsesFromProfile(completion: @escaping ([ProfileQuestion]) -> Void) {
            //initiate connection to the profile
            responsesProfileRef.getDocument { (document, error) in
                //continue, ignore error check
                //download the array of responses
                let downloadedArray: [String] = document?.data()?["userResponses"] as! [String]
                
                //create variable to represent the seperated array
                var seperatedData: [ProfileQuestion] = []
                
                //enter for loop to seperate the data
                for data in downloadedArray {
                    //set the data to the array, and seperate it in the process
                    seperatedData.insert(data.seperate(firstCharacter: "†", secondCharacter: "~"), at: 0)
                }
                
                //run completion
                completion(seperatedData)
            }
        }
    }
}

//class to handle the use of questions stored in a user's profile
class ProfileQuestion {
    var classText: String!
    var questionText: String!
    var responseText: String!
    
    init(forClass: String, forQuestion: String) {
        classText = forClass
        questionText = forQuestion
    }
    
    init(forClass: String, forQuestion: String, forResponse: String) {
        classText = forClass
        questionText = forQuestion
        responseText = forResponse
    }
}

//extension to a string, to seperate text
extension String {
    //function to seperate a string by a certain character, into two halves
    func seperate(byCharacter: Character) -> ProfileQuestion {
        //turn the string into an array
        var array: [Character] = Array(self)
        
        //create variables to hold the first half and second half of the data, first half is removed from the overall array, thus the second half is in the "array" variable
        var firstHalf: [String] = []
        
        //enter for loop
        for item in String(array) {
            //enter if statement to determine if the character is the seperator
            if item != byCharacter {
                //add the character to the first half array
                firstHalf.append(String(item))
                
                //remove the item from the array
                array.removeFirst()
            } else {
                print("Found Speerator: \(byCharacter)")
                //remove the seperator from the array
                array.removeFirst()
                //break from the loop
                break
            }
        }
        
        //create array to hold string version of second half
        var secondHalf: [String] = []
        
        //convert the array into a string array
        array.forEach { (arrayCharacter) in
            secondHalf.append(String(arrayCharacter))
        }
        
        //set up the data as a profile question
        let returnData = ProfileQuestion(forClass: firstHalf.joined(), forQuestion: secondHalf.joined())
        
        return returnData
    }
    
    func seperate(firstCharacter: String, secondCharacter: String) -> ProfileQuestion {
        //convert the string into an array
        var array: [Character] = Array(self)
        
        //create variables representing each third of the array
        var firstHalf: [String] = []
        var secondHalf: [String] = []
        var thirdHalf: [String] = []
        
        //enter for loop to handle the character individually
        for character in array {
            //run if statement to determine if the process should seperate 1 from 2 or 2 from 3
            if array.contains(Character(firstCharacter)) {
                //determine if the chracter is the first seperator
                if character == Character(firstCharacter) {
                    //item is the seperator, remove from array without joining
                    array.removeFirst()
                } else {
                    //item is a regular character, add it to the first half, and remove it from the main array
                    firstHalf.append(String(character))
                    array.removeFirst()
                }
            } else if array.contains(Character(secondCharacter)) {
                //determine if the character is the seperator
                if character == Character(secondCharacter) {
                    //item is the seperator, remove from array without joining
                    array.removeFirst()
                } else {
                    secondHalf.append(String(character))
                    array.removeFirst()
                }
            } else {
                //does not contain either seperators, add remaining to third half and break
                array.forEach({( thirdHalf.append(String($0)) )})
                break
            }
        }
        
        //return the data in the ProfileQuestion format
        return ProfileQuestion(forClass: firstHalf.joined(), forQuestion: secondHalf.joined(), forResponse: thirdHalf.joined())
    }
}

//struct to hold functions to change the profile approval rating
struct ApprovalRating {
    //function to get the current approval rating
    func getRating(uid: String, completion: @escaping (Int) -> Void) {
        Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(uid).getDocument { (document, error) in
            //run error check
            if error != nil {
                completion(0)
            } else {
                //download the approval rating
                let rating = document?.data()?["userReputation"] as! Int
                
                //run completion
                completion(rating)
            }
        }
    }
    
    //function to get the current rating, and change it
    func changeApprovalRating(uid: String, by: Int, completion: @escaping () -> Void) {
        //run function to get the current score
        getRating(uid: uid) { (rating) in
            print(rating)
            
            //set rating to a variable
            let changedRating = rating + by
            
            print(changedRating)
            
            //upload the rating
Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(uid).updateData(["userReputation": changedRating])
            
            //run completion
            completion()
        }
    }
}

//struct to hold the TTP profile storage functions
struct TTP {
    //function to determine if the user is a tutor
    func determineIfTutor(completion: @escaping (Bool) -> Void) {
        //connect to the user profile
        Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(Auth.auth().currentUser!.uid).getDocument { (document, error) in
            //run error check
            if error != nil {
                completion(false)
            } else {
                //download the bool value from the profile
                let isTutor = document?.data()?["isTutor"] as! Bool
                
                //run completion
                completion(isTutor)
            }
        }
    }
    
    //function to chage the value of the bool stored in the profile
    func changeTutorValue(completion: @escaping () -> Void) {
        //run function to get the current value
        determineIfTutor { (isTutor) in
            //create constant with toggled value of the found tutor value
            let changedTutor = isTutor.opposite()
            
            //upload the changed value
Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(Auth.auth().currentUser!.uid).updateData(["isTutor": changedTutor])
            
            //run completion functions
            completion()
        }
    }
    
    //function to take the name of the user and add the tutor symbol to it
    func alterUserName(completion: @escaping () -> Void) {
        //get the current name of the user, and add the tutor character
        let currentName = Profile().getUserName() + " ;"
        
        //upload the new name
        Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(Auth.auth().currentUser!.uid).updateData(["userName": currentName]) { (error) in
            if error != nil {
                print(error! as NSError)
            } else {
                completion()
            }
        }
        
    }
}

//struct to contain functions to change the number of questions and responses relative to the user
struct ProfileCounts {
    func getNumberOfQuestions(complete: @escaping (Int) -> Void) {
        //initiate connection to the user profiel
        Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(Auth.auth().currentUser!.uid).getDocument { (document, error) in
            //run an error check
            if error != nil {
                print(error!)
                complete(0)
            } else {
                //download the number of questions
                let numberOfQuestions = document?.data()?["numberOfQuestions"] as! Int
                
                //run completion
                complete(numberOfQuestions)
            }
        }
    }
    
    //increase number of questions
    func increaseNumberOfQuestions(complete: (() -> Void)?) {
        //get the current number of questions
        getNumberOfQuestions { (number) in
            //add one to the number of questions
            let newNumber = number + 1
            
            //upload the new number to the user's profile
            Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(Auth.auth().currentUser!.uid).updateData(["numberOfQuestions": newNumber])
        }
    }
    
    //struct to hold similar functions for responses
    struct Responses {
        func getNumberOfResponses(complete: @escaping (Int) -> Void) {
            //initiate connection to the user profiel
            Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(Auth.auth().currentUser!.uid).getDocument { (document, error) in
                //run an error check
                if error != nil {
                    print(error!)
                    complete(0)
                } else {
                    //download the number of questions
                    let numberOfQuestions = document?.data()?["numberOfResponses"] as! Int
                    
                    //run completion
                    complete(numberOfQuestions)
                }
            }
        }
        
        //increase number of questions
        func increaseNumberOfQuestions(complete: (() -> Void)?) {
            //get the current number of questions
            getNumberOfResponses { (number) in
                //add one to the number of questions
                let newNumber = number + 1
                
                //upload the new number to the user's profile
                Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(Auth.auth().currentUser!.uid).updateData(["numberOfResponses": newNumber])
            }
        }
    }
}

//extention of bool, to state the opposite value
extension Bool {
    func opposite() -> Bool {
        switch self {
        case true:
            return false
        case false:
            return true
        }
    }
}

//struct to hold functions to determine if the user is a teacher
struct TeacherFunctions {
    //function to upload a request to become a teacher
    func uploadRequestForTeacher(uid: String, email: String) {
        //make connection to the teacher approval document
        Firestore.firestore().collection("AppInfo").document("TeacherApproval").getDocument { (document, error) in
            //download the current list of requests
            var list = document?.data()?["TeachersToApprove"] as! [String]
            
            list.append("\(uid)~\(email)")
            
            Firestore.firestore().collection("AppInfo").document("TeacherApproval").updateData(["TeachersToApprove": list])
        }
    }
    
    //function to determine what list the user is in
    func determineInTeacherList(uid: String, complete: @escaping (Lists?) -> Void) {
        //make connection to the teacher approval documents
        Firestore.firestore().collection("AppInfo").document("TeacherApproval").getDocument { (document, error) in
            //run an error check
            if error != nil {
                print(error! as NSError)
                complete(.toApprove)
            } else {
                //download all of the lists
                let toApprove: [String] = document?.data()?["TeachersToApprove"] as! [String]
                let approved: [String] = document?.data()?["ApprovedTeachers"] as! [String]
                let denied: [String] = document?.data()?["RejectedTeachers"] as! [String]
                
                var toApproveUIDs: [String] = []
                
                for data in toApprove {
                    toApproveUIDs.append(data.seperate(byCharacter: "~").classText)
                }
                
                if toApproveUIDs.contains(uid) {
                    complete(.toApprove)
                } else if approved.contains(uid) {
                    complete(.approved)
                } else if denied.contains(uid) {
                    complete(.denied)
                } else {
                    complete(nil)
                }
            }
        }
    }
    
    //struct to represent the lists for teachers
    enum Lists {
        case approved
        case denied
        case toApprove
    }
    
    //function to determine if the user is a teacher
    func determineIfTeacher(school: String, uid: String, complete: @escaping (Bool) -> Void) {
        //create a connection to the users document
        Firestore.firestore().collection(school).document("Users").collection("UserCollection").document(uid).getDocument { (document, error) in
            //run an error check
            if error != nil {
                print(error!)
                complete(false)
            } else {
                //download the name of the user
                let name = document?.data()?["userName"] as! String
                
                //turn the name into an array
                let array = Array(name)
                
                //determine if the name contains the teacher character
                if array.last! == ":" {
                    complete(true)
                } else {
                    complete(false)
                }
            }
        }
    }
}
