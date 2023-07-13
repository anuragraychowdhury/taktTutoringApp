//
//  NotificationFunctions.swift
//  DasdApp
//
//  Created by Ethan Miller on 4/11/20.
//  Copyright © 2020 Ethan Miller. All rights reserved.
//

import Foundation
import UserNotifications
import FirebaseFirestore
import FirebaseAuth

struct Notifications {
    //function to store local data for comparison
    func getData(complete: @escaping ([String: Int]) -> Void) {
        QuestionsForProfile().getQuestionsFromProfile { (questions) in
            //create variables to hold the found data
            var assignedCounts: [[String]: Int] = [:]
            
            var counts: [String: Int] = [:]
            
            //enter for loop to get the recent questions for the profile
            for question in questions {
                //get the number of responses for the questions
                Questions.Responses().getNumberOfResponses(school: Profile().getUserSchoolName(), forClass: question.classText, questionTitle: question.questionText) { (count, error) in
                    //run an error check
                    if error != nil && error != .noResponses {
                        print(error!)
                    } else {
                        assignedCounts[[question.classText, question.questionText]] = count
                    }
                }
            }
            
            
            //create timer to monitor progress
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (timer) in
                if assignedCounts.count == questions.count {
                    //run function to turn the data into a string
                    for question in questions {
                        counts["\(question.classText!)~\(question.questionText!)"] = assignedCounts[[question.classText, question.questionText]]!
                    }
                    
                    timer.invalidate()
                    
                    print(counts)
                    
                    //run a completion
                    complete(counts)
                } else {
                    print("waiting: \(assignedCounts.count)/\(questions.count)")
                }
            }
        }
    }
    
    //function to store the data for comparison
    func storeDataForComparison() {
        //run function to get the data
        getData { (data) in
            //enter for statement to assign the data
            for element in data {
                UserDefaults.standard.set(element.value, forKey: element.key)
                
                print("storing data: \(element):")
            }
        }
    }
    
    //function to compare the data
    func compareData() {
        //function to get the most current data
        getData { (newData) in
            //enter for loop to got to each element in the data array
            for data in newData {
                //run if statemen tto determine if the data is new or changed
                if UserDefaults.standard.value(forKey: data.key) == nil {
                    print("Error: New data")
                } else if UserDefaults.standard.value(forKey: data.key) as! Int == data.value {
                    print("Data Unchanged")
                } else {
                    print("new data found for \(data)")
                    //run function to seperate the data
                    let seperatedKey = data.key.seperate(byCharacter: "~")
                    
                    //determine the change
                    let oldCount = UserDefaults.standard.value(forKey: data.key) as! Int
                    
                    //run if statement to determine the level of the change
                    if (data.value - oldCount) == 1 {
                        notifyUser(title: "Your Question in \(seperatedKey.classText!) Has a New Response", subHeading: seperatedKey.questionText!, body: "Open TAKT to view the response!", afterTime: 1)
                    } else {
                        notifyUser(title: "Your Question in \(seperatedKey.classText!) Has \(data.value - oldCount) New Responses", subHeading: seperatedKey.questionText!, body: "Open TAKT to view the response!", afterTime: 1)
                    }
                }
            }
            
            //run function to save the data
            self.storeDataForComparison()
            
            if newData.isEmpty {
                print("No New Data")
            }
        }
    }
}

//public function to present a notification
func notifyUser(title: String, body: String, afterTime: Int) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    
    content.sound = UNNotificationSound.default
        
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(afterTime), repeats: false)
    
    let request = UNNotificationRequest(identifier: "defaultNotification", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
}

//public func to notify user with a subheading
func notifyUser(title: String, subHeading: String, body: String, afterTime: Int) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.subtitle = subHeading
    content.body = body
    
    content.sound = UNNotificationSound.default
        
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(afterTime), repeats: false)
    
    let request = UNNotificationRequest(identifier: "defaultNotification", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
}
