//
//  ReportFunctions.swift
//  DasdApp
//
//  Created by Ethan Miller on 3/12/20.
//  Copyright © 2020 Ethan Miller. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth


struct Reporting {
    //enum to hold the different types of reporting
    enum ReportType {
        case abuseOffenseLanguage
        case threteningLanguage
        case troll
        case assesmentCheating
        case fakeInformation
        case other
    }
    
    //enu, to hold the types of lists the user can be added to
    enum ReportListType {
        case firstOffense
        case secondOffense
        case thirdOffense
        case dayLong
        case weekLong
        case permenant
    }
    
    //function to receive a report, determine where to aim punishment
    func receiveReport(report: ReportType, uid: String, question: String, response: String) {
        
        //switch the type of the report
        switch report {
        case .fakeInformation:
            addOffenseToUser(uid: uid, report: report)
        case.troll:
            addOffenseToUser(uid: uid, report: report)
        case .assesmentCheating:
            addOffenseToUser(uid: uid, report: report)
        case .abuseOffenseLanguage:
            addToList(uid: uid, list: .weekLong)
        case .threteningLanguage:
            addToList(uid: uid, list: .permenant)
        default:
            addOffenseToUser(uid: uid, report: report)
        }
    }
    
    //function to remove a name from a list and add to a new list
    func addOffenseToUser(uid: String, report: ReportType) {
        //add event to the report log
        addReportToLog(uid: uid, reportText: "'adding offense to user ++ Reason: \(report)'")
        
        //download all the offense lists
        Firestore.firestore().collection("AppInfo").document("ReportData").getDocument { (document, error) in
            //run error check
            if error != nil {
                print(error! as NSError)
            } else {
                //download all the offense lists
                let firstOffenses: [String] = document?.data()?["firstOffense"] as! [String]
                let secondOffenses: [String] = document?.data()?["secondOffense"] as! [String]
                let thirdOffenses: [String] = document?.data()?["thirdOffense"] as! [String]
                let dayLong: [String] = document?.data()?["24HourBlackList"] as! [String]
                let weekLong: [String] = document?.data()?["WeekBlackList"] as! [String]
                let permenant: [String] = document?.data()?["theBlackList"] as! [String]
                
                //run through a cycle of if statements to determine if the user belongs to the list
                if permenant.contains(uid) {
                    self.removeAndAddToList(uid: uid, currentList: .firstOffense, newList: .secondOffense)
                } else if weekLong.contains(uid) {
                    self.removeAndAddToList(uid: uid, currentList: .secondOffense, newList: .thirdOffense)
                } else if dayLong.contains(uid) {
                    self.removeAndAddToList(uid: uid, currentList: .thirdOffense, newList: .dayLong)
                } else if thirdOffenses.contains(uid) {
                    self.removeAndAddToList(uid: uid, currentList: .dayLong, newList: .weekLong)
                } else if secondOffenses.contains(uid) {
                    self.removeAndAddToList(uid: uid, currentList: .weekLong, newList: .permenant)
                } else if firstOffenses.contains(uid) {
                    
                } else {
                    //not on any list, add to the first offense list
                    self.addToList(uid: uid, list: .firstOffense)
                }
            }
        }
    }
    
    //function to add the user to the first list
    func addToList(uid: String, list: ReportListType) {
        //log event
        addReportToLog(uid: uid, reportText: "'adding user to offense list--List: \(list)'")
        
        //upload the user's name to the first offense list
        Firestore.firestore().collection("AppInfo").document("ReportData").getDocument { (document, error) in
            //download the current list, ignore error
            var currentList = document?.data()?["firstOffense"] as! [String]
            //add the uid to the list
            currentList.insert(uid, at: 0)
            
            //upload the new list
            Firestore.firestore().collection("AppInfo").document("ReportData").updateData([self.convertListTypeToString(type: list): currentList])
        }
    }
    
    //function to remove a user from a list and add to a new list
    func removeAndAddToList(uid: String, currentList: ReportListType, newList: ReportListType) {
        //run function to log event
        addReportToLog(uid: uid, reportText: "'removing user from list--List: \(currentList) ++ adding user to list--List: \(newList)'")
        
        //initiate connection to the first list
        Firestore.firestore().collection("AppInfo").document("ReportData").getDocument { (document, error) in
            //ignore error check, download the currentList
            var current: [String] = document?.data()?[self.convertListTypeToString(type: currentList)] as! [String]
            
            //remove user from list
            let index = current.firstIndex(of: uid)
            current.remove(at: index!)
            
            //upload the new list
            Firestore.firestore().collection("AppInfo").document("ReportData").updateData([self.convertListTypeToString(type: currentList): current]) { (error) in
                //continue, ignore error check
                
                //download the new list
                var new: [String] = document?.data()?[self.convertListTypeToString(type: newList)] as! [String]
                
                //insert the new name of the user
                new.insert(uid, at: 0)
                
                //upload the new list
                Firestore.firestore().collection("AppInfo").document("ReportData").updateData([self.convertListTypeToString(type: newList): new], completion: nil)
            }
        }
    }
    
    //function to convert the ReportListType to a string
    func convertListTypeToString(type: ReportListType) -> String {
        switch type {
        case .firstOffense:
            return "firstOffense"
        case .secondOffense:
            return "secondOffense"
        case .thirdOffense:
            return "thirdOffense"
        case .dayLong:
            return "24HourBlackList"
        case .weekLong:
            return "WeekBlackList"
        case .permenant:
            return "theBlackList"
        }
    }
    
    //function to add an action to the log
    func addReportToLog(uid: String, reportText: String) {
        //get the date components of the current date
        let date = NSDate.now
        
        //create the report string to upload
        let report = "Report Log: \(date)//\(reportText)//affecting-user: \(uid)//sent-by: \(Auth.auth().currentUser!.uid)"
        
        //upload the report
        Firestore.firestore().collection("AppInfo").document("ReportData").getDocument { (document, error) in
            //get the current log, ignore error
            var log = document?.data()?["log"] as! [String]
            
            //insert the new element
            log.insert(report, at: 0)
            
            //upload the new data
            Firestore.firestore().collection("AppInfo").document("ReportData").updateData(["log": log])
        }
    }
}
