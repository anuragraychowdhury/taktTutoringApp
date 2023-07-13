//
//  QuestionResponseController.swift
//  DasdApp
//
//  Created by Ethan Miller on 1/1/20.
//  Copyright © 2020 Ethan Miller. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore

//MARK: QUESTION FUNCTIONS
struct Questions {
    //function to get all of the questions for a certain school and class
    func getAllQuestionsForClass(forSchool: String, forClass: String, completion: @escaping ([String], ErrorIdentifires.questionErrors?, String) -> Void) {
        //run permission function to determine if the class is allowed
        Permissions().checkNewQuestionsPermissionForClass(school: forSchool, forClass: forClass) { (permission) in
            //run if statement to determine the permission
            if permission == false {
                //not permitted, run completion with error
                completion([], .accessDenied, forClass)
            } else {
                //create reference to the firestore
                let storeRef = Firestore.firestore()
                
                //initiate connection to the question collection and the class subcollection
                storeRef.collection(forSchool).document("Questions").collection(forClass).document("Info").getDocument { (document, error) in
                    //run check for firebase errors
                    if error != nil {
                        //there was a firebase error, handle it
                        print(error! as NSError)
                        completion([], .unexpectedError, forClass)
                    } else {
                        //download the array of questions
                        let questions = document?.data()?["arrayOfQuestions"] as! [String]
                        
                        //run check to make sure the questions array is not empty
                        if questions.isEmpty {
                            completion([], .noQuestions, forClass)
                        } else {
                            completion(questions, nil, forClass)
                        }
                    }
                }
            }
        }
    }
    
    //function to return the number of questions for a certain school and class
    func getNumberOfQuestionsForClass(school: String, forClass: String, complete: @escaping (Int, ErrorIdentifires.questionErrors?) -> Void) {
        //check permission to the class
        Permissions().checkNewQuestionsPermissionForClass(school: school, forClass: forClass) { (permission) in
            //run if statement to get the permission
            if permission == false {
                //run completion, not permitted
                complete(0, .accessDenied)
            } else {
                //run function to collect the array of questions
                self.getAllQuestionsForClass(forSchool: school, forClass: forClass) { (questionArray, error, forClass) in
                    //run error check
                    if error != nil {
                        //run completion, error present
                        complete(0, error!)
                    } else {
                        //run complete function with the count from the question array
                        complete(questionArray.count, nil)
                    }
                }
            }
        }
    }
    
    //MARK: Create Question
    //function to create a question
    func createQuestion(school: String, forClass: String, title: String, text: String, UID: String, userName: String, complete: @escaping (ErrorIdentifires.questionErrors?) -> Void) {
        //run permission function to determine if new questions are allowed for the class
        Permissions().checkNewQuestionsPermissionForClass(school: school, forClass: forClass) { (permission) in
            //run if statement to check the permission
            if permission == false {
                //not permitted, run completion
                complete(.accessDenied)
            } else {
                //run function to increase number of questions in profile
                ProfileCounts().increaseNumberOfQuestions(complete: nil)
                
                //run functions to check the question with the bots
                Bots.MathBot().determineActivation(forSchool: school, forClass: forClass, forQuestion: title, activation: .automated)
                
                //edit the data to remove slashes and periods
                var editedTitle = title.replacingOccurrences(of: "/", with: "÷")
                editedTitle = editedTitle.replacingOccurrences(of: ".", with: "‰")
                
                //create refrence to the school in the firebase servers
                let storeSchoolRef = Firestore.firestore().collection(school)
                
                //constant to represent the current time
                let currentTime = NSDate.now
                
                //initiate connection to the question collection, and create the question documents
                storeSchoolRef.document("Questions").collection(forClass).document(editedTitle).setData(["title": editedTitle, "text": text, "arrayOfResponses": [], "userUID": UID, "userName": userName, "creationTime": currentTime])
                //create the response collection
storeSchoolRef.document("Questions").collection(forClass).document(editedTitle).collection("Responses").document("Info").setData(["allowResponses": true])
                
                
                //update the number of questions for the school
                storeSchoolRef.document("Questions").getDocument { (document, error) in
                    //run error check
                    if error != nil {
                        print(error! as NSError)
                        //run completion with error
                        complete(.unexpectedError)
                    } else {
                        //download the number of questions
                        let numberOfQuestions: Int = (document?.data()?["numberOfQuestions"] as! Int) + 1
                        
                        //upload the new number of questions
                        storeSchoolRef.document("Questions").updateData(["numberOfQuestions": numberOfQuestions])
                        
                        //run function to add the question to the user's profile
                        QuestionsForProfile().assignQuestionToProfile(forClass: forClass, questionText: editedTitle)
                        
                        //update the number of questions for the class
                        storeSchoolRef.document("Questions").collection(forClass).document("Info").getDocument { (secondDocument, secondError) in
                            //run error check
                            if secondError != nil {
                                print(secondError! as NSError)
                                //run completion with error
                                complete(.unexpectedError)
                            } else {
                                //download the current number of questions
                                let classNumberOfQuestions = (secondDocument?.data()?["numberOfQuestions"] as! Int) + 1
                                
                                //upload the new number of questions
                    storeSchoolRef.document("Questions").collection(forClass).document("Info").updateData(["numberOfQuestions": classNumberOfQuestions])
                                
                                
                                //download the array of questions
                                var arrayOfQuestions = secondDocument?.data()?["arrayOfQuestions"] as! [String]
                                
                                //add the new question title to the array
                                arrayOfQuestions.insert(editedTitle, at: 0)
                                
                                //upload the new array of questions
                    storeSchoolRef.document("Questions").collection(forClass).document("Info").updateData(["arrayOfQuestions": arrayOfQuestions])
                                
                                complete(nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    //function to get arrays of questions and accompanying arrays of responses
    func getQuestionsResponseArraysForClasses(school: String, forClasses: [String], complete: @escaping ([[String]], [[[String]]], ErrorIdentifires.questionErrors?) -> Void) {
        //!! permissions function run in child function, unnecessary to run here
        //create variable to determine if it is safe to move onto the next class
        var isSafeToMove: Bool = true
        
        //create variables to represent the array of questions and the array of response arrays
        var questionsArrays: [[String]] = []
        var assignedQuestionArray: [String: [String]] = [:]
        var responseArrays: [[[String]]] = []
        var assignedResponseArray: [String: [[String]]] = [:]
        
        //create a main timer to control the entire process
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (mainTimer) in
            //create if statement to determine if a process is currently at work, preventing another process from starting
            if isSafeToMove == false {
                print("Waiting")
            } else {
                //set the is safe to false
                isSafeToMove = false
                
                //determine what information to collect
                if questionsArrays.isEmpty {
                    //COLLECT QUESTIONS
                    
                    //enter for loop to get all of the questions for each class
                    for Class in forClasses {
                        //run function to get all the questions for the class
                        self.getAllQuestionsForClass(forSchool: school, forClass: Class) { (foundQuestions, error, forClass) in
                            //run an error check
                            if error != nil && error != .noQuestions {
                                complete([], [], error!)
                                mainTimer.invalidate()
                            } else {
                                //add the found questions, and add to the question array
                                assignedQuestionArray[forClass] = foundQuestions
                            }
                        }
                    }
                    
                    //create a timer to monitor the collection of questions
                    Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (questionTimer) in
                        //create if statement to determnine if all questions have been collected
                        if assignedQuestionArray.count == forClasses.count {
                            questionTimer.invalidate()
                            
                            //run function to move the data from the assigned array and into the ordered array
                            for Class in forClasses {
                                questionsArrays.append(assignedQuestionArray[Class]!)
                            }
                            
                            isSafeToMove = true
                        } else {
                            print("waiting: \(questionsArrays.count)/\(forClasses.count)")
                        }
                    }
                    
                } else if responseArrays.isEmpty {
                    //COLLECT RESPONSES
                    
                    //create a variable to represent the index of the question array being analyzed
                    var index: Int = 0
                    
                    //enter for loop to get the array of questionc for a class
                    for classQuestions in questionsArrays {
                        let currentClass = forClasses[index]
                        
                        //run function to get the arrays of responses for the questions
                        Questions.Responses().getResponseArraysForQuestions(school: school, forClass: currentClass, questions: classQuestions) { (foundResponses, error, forClass) in
                            //run an error check
                            if error != nil && error != .noResponses {
                                print(error!)
                                complete([],[],error!)
                                mainTimer.invalidate()
                            } else {
                                //add the responses to the array
                                assignedResponseArray[forClass] = foundResponses
                            }
                        }
                        
                        //increase the index count
                        index += 1
                    }
                    
                    //create a timer to monitor response collection progress
                    Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (responseTimer) in
                        if assignedResponseArray.count == forClasses.count {
                            responseTimer.invalidate()
                            
                            //run function to order the responses
                            for Class in forClasses {
                                responseArrays.append(assignedResponseArray[Class]!)
                            }
                            
                            isSafeToMove = true
                        }
                    }
                } else {
                    //all info collected, run completion
                    complete(questionsArrays, responseArrays, nil)
                    //stop the timer
                    mainTimer.invalidate()
                }
            }
        }
    }
    
    //function to get time stamp for question and return it as a text
    func getQuestionTimeStamp(school: String, forClass: String, questionTitle: String, complete: @escaping (String, ErrorIdentifires.questionErrors?) -> Void) {
        Firestore.firestore().collection(school).document("Questions").collection(forClass).document(questionTitle).getDocument { (document, error) in
            //run error check
            if error != nil {
                print(error! as NSError)
                complete("", .unexpectedError)
            } else {
                let date: Timestamp = document?.data()?["creationTime"] as! Timestamp
                
                //find the number of days since now
                var daysSinceNow = Calendar.current.dateComponents([.day], from: date.dateValue(), to: NSDate.now).day!
                
                //create variable to represent the hour number
                var hour: Int! = 0
                //create variable to represent the time interval type
                var timeIntervalType: String = ""
                
                //get the hour from the
                let calender = Calendar.current
                hour = calender.component(.hour, from: date.dateValue())
                
                print(calender.component(.day, from: date.dateValue()))
                
                //enter if statement to set the correct day, subtracting dates does not account for hour difference
                if hour > calender.component(.hour, from: NSDate.now) {
                    daysSinceNow += 1
                }
                
                //enter if statement to organize the time
                if hour == 00 {
                    hour = 12
                    timeIntervalType = "AM"
                } else if hour > 12 {
                    hour = hour - 12
                    timeIntervalType = "PM"
                } else {
                    timeIntervalType = "AM"
                }
                
                //get the minute
                let minute = calender.component(.minute, from: date.dateValue())
                var stringMinute = "\(minute)"
                
                if minute < 10 {
                    stringMinute = "0\(minute)"
                }
                
                //determine if the date is from today
                if daysSinceNow == 0 {
                    complete("Today at \(hour!):\(stringMinute) \(timeIntervalType)", nil)
                } else if daysSinceNow == 1 {
                    complete("Yesterday at \(hour!):\(stringMinute) \(timeIntervalType)", nil)
                } else {
                    complete("\(daysSinceNow) days ago at \(hour!):\(stringMinute) \(timeIntervalType)", nil)
                }
            }
        }
    }
    
    //MARK: PICTURE HANDLING
    //function to add a picture to a question
    func addPictureForQuestion(picture: UIImage, question: String, forClass: String, forSchool: String, complete: @escaping (NSError?) -> Void) {
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        //upload the picture to storage
        Storage.storage().reference(withPath: "QuestionResponsePictures/\(forSchool)/\(forClass)/\(question)").putData(picture.jpegData(compressionQuality: 1)!, metadata: metadata) { (receivedMetadata, error) in
            if error != nil {
                print(error! as NSError)
                complete(error! as NSError)
            } else {
                complete(nil)
            }
        }
    }
    
    //function to get a picture for the question
    func getPictureForQuestion(question: String, forClass: String, forSchool: String, complete: @escaping (UIImage?, NSError?) -> Void) {
        Storage.storage().reference(withPath: "QuestionResponsePictures/\(forSchool)/\(forClass)/\(question)").getData(maxSize: 1000000) { (data, error) in
            if data == nil && error != nil {
                print(error! as NSError)
                complete(nil, nil)
            } else if error != nil {
                print(error! as NSError)
                complete(nil, error! as NSError)
            } else {
                complete(UIImage(data: data!), nil)
            }
        }
    }
    
    //MARK: RESPONSES FUNCTIONS
    struct Responses {
        //function to get array of responses
        func getArrayOfResponses(school: String, forClass: String, questionTitle: String, complete: @escaping ([String], ErrorIdentifires.questionErrors?, String) -> Void) {
            //check permission for new responses
            Permissions().checkNewResponsesPermissionForQuestion(forSchool: school, forClass: forClass, forQuestion: questionTitle) { (permission) in
                //run if statement to determine if permission is true
                if permission == false {
                    //not permitted handle error
                    complete([], .accessDenied, questionTitle)
                } else {
                    //constant to represent the question document
                    let questionRef = Firestore.firestore().collection(school).document("Questions").collection(forClass).document(questionTitle)
                    
                    //initiate connection to the info document of the question
                    questionRef.getDocument { (document, error) in
                        //run error check
                        if error != nil {
                            print(error! as NSError)
                            complete([], .unexpectedError, questionTitle)
                        } else {
                            //download the array of responses
                            let arrayOfResponses: [String] = document?.data()?["arrayOfResponses"] as! [String]
                            
                            //run if statement to determine if the array is empty
                            if arrayOfResponses.isEmpty {
                                //emtpy, run complete with error
                                complete([], .noResponses, questionTitle)
                            } else {
                                //run completion
                                complete(arrayOfResponses, nil, questionTitle)
                            }
                        }
                    }
                }
            }
        }
        
        //function to get the number of responses
        func getNumberOfResponses(school: String, forClass: String, questionTitle: String, complete: @escaping (Int, ErrorIdentifires.questionErrors?) -> Void) {
            //run function to get the full array of responses for the function, permissions check included
            getArrayOfResponses(school: school, forClass: forClass, questionTitle: questionTitle) { (questionArray, error, _) in
                //run error check
                if error != nil {
                    complete(0, error!)
                } else {
                    //run completion with the number of responses in the array
                    complete(questionArray.count, nil)
                }
            }
        }
        
        //function to return an array of response arrays from an array of questions
        func getResponseArraysForQuestions(school: String, forClass: String, questions: [String], complete: @escaping ([[String]], ErrorIdentifires.questionErrors?, String) -> Void) {
            //!!Permissions check is run in child functions, unnecessary to run here
            //create variable representing the array of response arrays
            var responseArrays: [[String]] = []
            var assignedResponses: [String: [String]] = [:]
            
            //create for loop to go to the individual questions
            for question in questions {
                //run function to get the array of responses for that question
                getArrayOfResponses(school: school, forClass: forClass, questionTitle: question) { (foundResponses, error, forQuestion) in
                    //determine if there was an error
                    if error != nil && error != .noResponses {
                        complete([], error!, forClass)
                    } else {
                        //add the responses to the main array
                        assignedResponses[forQuestion] = foundResponses
                    }
                }
            }
            
            //create a timer to monitor progress
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (timer) in
                if assignedResponses.count == questions.count {
                    timer.invalidate()
                    
                    //run function to order the responses
                    for question in questions {
                        responseArrays.append(assignedResponses[question]!)
                    }
                    
                    //run completion
                    complete(responseArrays, nil, forClass)
                } else {
                    print("waiting")
                }
            }
        }
        
        //MARK: Create Response
        //create a response to a questions
        func createResponse(school: String, forClass: String, questionTitle: String, responseText: String, userUID: String, userName: String, complete: @escaping (ErrorIdentifires.questionErrors?) -> Void) {
            //run permissions function to determine if responses are allowed for the question
            Permissions().checkNewResponsesPermissionForQuestion(forSchool: school, forClass: forClass, forQuestion: questionTitle) { (permission) in
                //run if statement to determine if responses are allowed
                if permission == false {
                    //run completion with error
                    complete(.accessDenied)
                } else {
                    //run function to increase the number of responses in the user profile
                    ProfileCounts.Responses().increaseNumberOfQuestions(complete: nil)
                    
                    //create constant representing the firestore and the question document
                    let questionStoreRef = Firestore.firestore().collection(school).document("Questions").collection(forClass).document(questionTitle)
                    
                    //get representation of the current time
                    let currentTime = NSDate.now
                    
                    //initiate connection to the response collection, creating a new response document
                    questionStoreRef.collection("Responses").document(responseText).setData(["responseText": responseText, "userUID": userUID, "userName": userName, "creationTime": currentTime, "teacherApprovals": []])
                    
                    //determine if the response is a bot
                    if userUID == "_MathBot" {
                        print("Is a bot")
                    } else {
                        //run function to set the response to the user's profile
                        QuestionsForProfile.Responses().assignResponseToProfile(forClass: forClass, forQuestion: questionTitle, responseText: responseText)
                    }
                    
                    //add the response text to a response array
                    questionStoreRef.getDocument { (document, error) in
                        //run error check
                        if error != nil {
                            print(error! as NSError)
                            complete(.unexpectedError)
                        } else {
                            //download the current array of responses
                            var responseArray: [String] = document?.data()?["arrayOfResponses"] as! [String]
                            
                            //add the new response to the array
                            responseArray.insert(responseText, at: 0)
                            
                            //upload the new response text
                            questionStoreRef.updateData(["arrayOfResponses": responseArray])
                            
                            //initiate connection to the class info document to update the number of responses
                            questionStoreRef.parent.document("Info").getDocument { (document, secondError) in
                                //run second error check
                                if secondError != nil {
                                    print(error! as NSError)
                                    complete(.unexpectedError)
                                } else {
                                    //download the current response count, add one to it
                                    let responseCount = (document?.data()?["numberOfResponses"] as! Int) + 1
                                    
                                    //upload the new response count
                                    questionStoreRef.parent.document("Info").updateData(["numberOfResponses": responseCount])
                                    
                                    complete(nil)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        //MARK: TEACHER APPROVAL
        //function to show that a teacher approved of the response
        func setApproval(school: String, forClass: String, questionTitle: String, responseTitle: String, teacherName: String) {
            //establish connection to the response
            Firestore.firestore().collection(school).document("Questions").collection(forClass).document(questionTitle).collection("Responses").document(responseTitle).getDocument { (document, error) in
                //run an error check
                if error != nil {
                    print(error! as NSError)
                } else {
                    //download the teacher response array, place in a guard statement to determine if question is outdated
                    guard var teacherApprovals: [String] = document?.data()?["teacherApprovals"] as? [String] else {
                        //no teacher approvals, create the new teacher approvals array
                        Firestore.firestore().collection(school).document("Questions").collection(forClass).document(questionTitle).collection("Responses").document(responseTitle).updateData(["teacherApprovals": [teacherName]])
                        
                        return
                    }
                    
                    
                    //add the teacher name to the teacher approvals
                    teacherApprovals.insert(teacherName, at: 0)
                    
                    //upload the new teacher approval array
                    Firestore.firestore().collection(school).document("Questions").collection(forClass).document(questionTitle).collection("Responses").document(responseTitle).updateData(["teacherApprovals" : teacherApprovals])
                }
            }
        }
        
        //function to get the list of teacher approvals
        func getTeacherApprovals(school: String, forClass: String, questionTitle: String, responseTitle: String, complete: @escaping ([String], String) -> Void) {
            //initiate connection to the response
            Firestore.firestore().collection(school).document("Questions").collection(forClass).document(questionTitle).collection("Responses").document(responseTitle).getDocument { (document, error) in
                //run error check
                if error != nil {
                    print(error! as NSError)
                    complete([], "")
                } else {
                    //download the teacher approvals, and run a guard statement
                    guard let teacherApprovals = document?.data()?["teacherApprovals"] as? [String] else {
                        complete([], responseTitle)
                        return 
                    }
                    
                    //run completion with the array of approvals
                    complete(teacherApprovals, responseTitle)
                }
            }
        }
        
        //MARK: Time Stamp Collection
        //function to get and return the time stamp for the responses
        func getTimeStamp(school: String, forClass: String, questionTitle: String, responseText: String, complete: @escaping (String, ErrorIdentifires.questionErrors?, String) -> Void) {
            //get connection to the response document
            Firestore.firestore().collection(school).document("Questions").collection(forClass).document(questionTitle).collection("Responses").document(responseText).getDocument { (document, error) in
                //run error check
                if error != nil {
                    print(error!)
                    complete("", .unexpectedError, "")
                } else {
                    //get the time data
                    let date: Timestamp = document?.data()?["creationTime"] as! Timestamp
                    
                    //find the number of days since now
                    var daysSinceNow = Calendar.current.dateComponents([.day], from: date.dateValue(), to: NSDate.now).day!
                    
                    //create variable to represent the hour number
                    var hour: Int! = 0
                    //create variable to represent the time interval type
                    var timeIntervalType: String = ""
                    
                    //get the hour from the
                    let calender = Calendar.current
                    hour = calender.component(.hour, from: date.dateValue())
                    
                    print(calender.component(.day, from: date.dateValue()))
                    
                    //enter if statement to set the correct day, subtracting dates does not account for hour difference
                    if hour > calender.component(.hour, from: NSDate.now) {
                        daysSinceNow += 1
                    }
                    
                    //enter if statement to organize the time
                    if hour == 00 {
                        hour = 12
                        timeIntervalType = "AM"
                    } else if hour > 12 {
                        hour = hour - 12
                        timeIntervalType = "PM"
                    } else {
                        timeIntervalType = "AM"
                    }
                    
                    //get the minute
                    let minute = calender.component(.minute, from: date.dateValue())
                    var stringMinute = "\(minute)"
                    
                    if minute < 10 {
                        stringMinute = "0\(minute)"
                    }
                    
                    //determine if the date is from today
                    if daysSinceNow == 0 {
                        complete("Today at \(hour!):\(stringMinute) \(timeIntervalType)", nil, responseText)
                    } else if daysSinceNow == 1 {
                        complete("Yesterday at \(hour!):\(stringMinute) \(timeIntervalType)", nil, responseText)
                    } else {
                        complete("\(daysSinceNow) days ago at \(hour!):\(stringMinute) \(timeIntervalType)", nil, responseText)
                    }
                }
            }
        }
        
        //get the user name of the user who sent the response
        func getUserName(school: String, forClass: String, questionTitle: String, responseText: String, complete: @escaping (String, ErrorIdentifires.questionErrors?, String) -> Void) {
            Firestore.firestore().collection(school).document("Questions").collection(forClass).document(questionTitle).collection("Responses").document(responseText).getDocument { (document, error) in
                //run error check
                if error != nil {
                    print(error! as NSError)
                    complete("", .unexpectedError, "")
                } else {
                    let userName = document?.data()?["userName"] as! String
                    
                    complete(userName, nil, responseText)
                }
            }
        }
        
        //MARK: PICTURE HANDLING
        //function to add a picture to a response
        func addPictureForResponse(forSchool: String, forClass: String, forQuestion: String, forResponse: String, image: UIImage, complete: @escaping (NSError?) -> Void) {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            //upload the picture to storage
            Storage.storage().reference(withPath: "QuestionResponsePictures/\(forSchool)/\(forClass)/\(forQuestion)/\(forResponse)").putData(image.jpegData(compressionQuality: 1)!, metadata: metadata) { (receivedMetadata, error) in
                if error != nil {
                    print(error! as NSError)
                    complete(error! as NSError)
                } else {
                    complete(nil)
                }
            }
        }
        
        //function to get a picture for a response
        func getPictureForResponse(forSchool: String, forClass: String, forQuestion: String, forResponse: String, complete: @escaping (UIImage?, NSError?) -> Void) {
            Storage.storage().reference(withPath: "QuestionResponsePictures/\(forSchool)/\(forClass)/\(forQuestion)/\(forResponse)").getData(maxSize: 1000000) { (data, error) in
                if data == nil && error != nil {
                    print(error! as NSError)
                    complete(nil, nil)
                } else if error != nil {
                    print(error! as NSError)
                    complete(nil, error! as NSError)
                } else {
                    complete(UIImage(data: data!), nil)
                }
            }
        }
    }
}
