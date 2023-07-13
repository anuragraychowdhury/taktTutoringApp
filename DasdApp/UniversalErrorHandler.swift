//
//  UniversalErrorHandler.swift
//  DasdApp
//

//contains enums for all errors
//contains function to handle regular errors and a seperate function to handle firebase errors

//  Created by Ethan Miller on 10/25/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import Foundation
import UIKit
import Firebase

//struct to hold the different enums holding errors
struct ErrorIdentifires {
    enum appErrors {
        //non firebase network errors
        case appDisabled
        case schoolDisabled
        
        //sign in errors, non firebase
        case newUsersDisabled
        
        //unkown error
        case unknownError
    }
    
    //errors for the question/response functions
    enum questionErrors {
        case accessDenied
        case noQuestions
        case noResponses
        case unexpectedError
    }
}



struct ErrorFunctions {
    //function to handle the errors from category
    func handleError(sender: UIViewController, error: ErrorIdentifires.appErrors) {
        //switch the error to determine which message to send
        switch error {
        case .appDisabled:
            presentMessage(sender: sender, title: "App Disabled", message: "The app is currently disabled! Try again later!")
        case .schoolDisabled:
            presentMessage(sender: sender, title: "School Disabled!", message: "Signing into this school is currently unavailable! Try again leter!")
        case .newUsersDisabled:
            presentMessage(sender: sender, title: "New Users Disabled!", message: "New user's are currently disabled! Try again later!")
        case .unknownError:
            presentUnexpectedErrorMessage(sender: sender)
        }
    }
    
    //function to handle question errors
    func handleQuestionErrors(sender: UIViewController, error: ErrorIdentifires.questionErrors) {
        //switch the error to determine which message to send
        switch error {
        case .accessDenied:
            presentMessage(sender: sender, title: "Access Denied", message: "Access to this school/class/question has been disabled! Please contact support or check the website!")
        case .noQuestions:
            presentMessage(sender: sender, title: "No Questions", message: "There are no questions in this class! Be the first to ask!")
        case .noResponses:
            presentMessage(sender: sender, title: "No Responses", message: "There are no responses to this question. If you have the answer, do not be afraid to share!")
        case .unexpectedError:
            presentUnexpectedErrorMessage(sender: sender)
        }
    }

    //function to handle firebase Auth error
    func handleFirebaseAuthError(sender: UIViewController, error: NSError) {
        let firebaseError = AuthErrorCode(rawValue: error.code)
        
        //switch the type of error from the AuthErrorCode. Then present the corresponding message to the sender
        if firebaseError! == AuthErrorCode.emailAlreadyInUse {
            presentMessage(sender: sender, title: "Email Already In Use", message: "The email you entered already has an account in our server. Please try a different email or log in below!")
        } else if firebaseError! == AuthErrorCode.invalidEmail {
            presentMessage(sender: sender, title: "Invalid Email", message: "The email you entered is invalid. Please try another one!")
        } else if firebaseError! == AuthErrorCode.wrongPassword {
            presentMessage(sender: sender, title: "Incorrect Password", message: "The password you entered was incorrect! Please try again!")
        } else if firebaseError! == AuthErrorCode.weakPassword {
            presentMessage(sender: sender, title: "Weak Password", message: "The password you entered was weak. Please make a stronger password!")
        } else if firebaseError! == AuthErrorCode.userNotFound {
            presentMessage(sender: sender, title: "User Not Found", message: "The user you entered was not found! Please make sure you info was entered correctly!")
        } else if firebaseError! == AuthErrorCode.networkError {
            presentMessage(sender: sender, title: "Network Error!", message: "Please verifiy your network connection!")
        } else if firebaseError! == AuthErrorCode.userDisabled {
            presentMessage(sender: sender, title: "//USER DISABLED//", message: "Please contact app support for info!")
        } else if firebaseError! == AuthErrorCode.tooManyRequests {
            fatalError("//POTENTIAL HACKING//")
        } else {
            print(error)
            presentUnexpectedErrorMessage(sender: sender)
        }
    }
    
    //function to handle firebase storage errors
    func handleFirebaseStorageError(sender: UIViewController, error: NSError) {
        let firebaseError = StorageErrorCode(rawValue: error.code)
        
        //switch the error type
        switch firebaseError! {
        case StorageErrorCode.downloadSizeExceeded:
            presentMessage(sender: sender, title: "File too Large!", message: "The file you are trying to move is too large!")
        case StorageErrorCode.unauthenticated:
            fatalError("//POTENTIAL HACKING//")
        case StorageErrorCode.objectNotFound:
            presentMessage(sender: sender, title: "File Does Not Exsist!", message: "The file you are trying to get does not exsist!")
        case StorageErrorCode.quotaExceeded:
            presentMessage(sender: sender, title: "Server Full!", message: "Please contact support!")
        case StorageErrorCode.retryLimitExceeded:
            fatalError("//POTENTIAL HACKING//")
        default:
            presentUnexpectedErrorMessage(sender: sender)
        }
    }
    
}
