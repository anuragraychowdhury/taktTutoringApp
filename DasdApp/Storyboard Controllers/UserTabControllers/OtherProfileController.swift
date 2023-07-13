//
//  OtherProfileController.swift
//  DasdApp
//
//  Created by Ethan Miller on 2/12/20.
//  Copyright © 2020 Ethan Miller. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import MessageUI

class OtherProfileController: CustomViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var kudosButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var reportButton: UIButton!
    
    //static variable to hold the name of the user
    static var userNameTransfer: String!
    static var questionNameTransfer: String!
    static var responseNameTransfer: String?
    static var classNameTransfer: String!
    
    var questionName: String!
    var responseName: String?
    var className: String!
    
    //local variable to hold the name of the user
    var userName: String!
    //variable to hold the uid of the user
    var uid: String!
    //variable to hold the email of the user
    var email: String!
    
    var currentUserReputation: Int!
    var userQuestionNumber: Int!
    var userResponseNumber: Int!
    
    var questionRef = Firestore.firestore().collection("AppInfo").document("MainInfo")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //assign the static variable to a local variable
        userName = OtherProfileController.userNameTransfer
        questionName = OtherProfileController.questionNameTransfer
        responseName = OtherProfileController.responseNameTransfer
        className = OtherProfileController.classNameTransfer
        
        kudosButton.layer.cornerRadius = 15
        kudosButton.layer.masksToBounds = true
        messageButton.layer.cornerRadius = 15
        messageButton.layer.masksToBounds = true
        reportButton.layer.cornerRadius = 15
        reportButton.layer.masksToBounds = true
        
        //run function to get user info
        getUserInfoFromQuestion()
    }
    
    //function to activate when the view disappears
    override func viewDidDisappear(_ animated: Bool) {
        //set the static vars to nil
        OtherProfileController.userNameTransfer = nil
        OtherProfileController.questionNameTransfer = nil
        OtherProfileController.responseNameTransfer = nil
    }
    
    //function to get the user info
    func getUserInfoFromQuestion() {
        //run if statement to determine if the name came from a question or a response
        if responseName == nil {
            //make connection to the main info of a question to get the user uid
            Firestore.firestore().collection(Profile().getUserSchoolName()).document("Questions").collection(className).document(questionName).getDocument { (document, error) in
                //run an error check
                if error != nil {
                    print(error! as NSError)
                    presentUnexpectedErrorMessage(sender: self)
                } else {
                    //download the uid of the user who asked the question
                    let downloadeduid = document?.data()?["userUID"] as! String
                    
                    //set the uid to a local variable
                    self.uid = downloadeduid
                    
                    //run function to continue to get user info
                    self.getUserInfoFromProfile()
                }
            }
        } else {
            //initiate connection to the main info of a response, in order to get the uid
            Firestore.firestore().collection(Profile().getUserSchoolName()).document("Questions").collection(className).document(questionName).collection("Responses").document(responseName!).getDocument { (document, error) in
                //run an error check
                if error != nil {
                    print(error! as NSError)
                    presentUnexpectedErrorMessage(sender: self)
                } else {
                    //download the uid
                    let downloadedUID = document?.data()?["userUID"] as? String
                    
                    //set the uid to a local variable
                    self.uid = downloadedUID!
                    
                    //run function to continue to get user infor from the user profile
                    self.getUserInfoFromProfile()
                }
            }
        }
    }
    
    //function to get the user info after the uid is found
    func getUserInfoFromProfile() {
        //initiate connection to the user's profile
        Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document(uid).getDocument { (document, error) in
            //run error check
            if error != nil {
                print(error! as NSError)
                presentUnexpectedErrorMessage(sender: self)
            } else {
                //download various user info
                self.email = (document?.data()?["userEmail"] as! String)
                self.currentUserReputation = (document?.data()?["userReputation"] as! Int)
                self.userQuestionNumber = (document?.data()?["numberOfQuestions"] as! Int)
                self.userResponseNumber = (document?.data()?["numberOfResponses"] as! Int)
                self.userName = (document?.data()?["userName"] as! String)
                
                //initiate connection to the storage to get the user profile image
                Storage.storage().reference(withPath: "UserIcons/\(self.uid!)").getData(maxSize: 1000000) { (data, error) in
                    //run error check
                    if error != nil {
                        print(error! as NSError)
                        ErrorFunctions().handleFirebaseStorageError(sender: self, error: error! as NSError)
                    } else {
                        //set the data to an image
                        let image = UIImage(data: data!)
                        
                        //set the image to the uiimageview
                        self.profileImage.image = image!
                        
                        //run functions to set up the UI
                        self.setUpUI()
                    }
                }
            }
        }
    }
    
    //function to set up various UI components
    func setUpUI() {
        //set various corner radii
        profileImage.layer.cornerRadius = profileImage.frame.height / 2
        profileImage.layer.masksToBounds = true
        profileImage.contentMode = .scaleAspectFill
        
        //set the user reputation, various other things to uilabels
        userNameLabel.text = userName
        ratingLabel.text = "\(String(currentUserReputation)) | \(String(userQuestionNumber)) | \(String(userResponseNumber))"
        
    }
    
    //function to activate when the kudos button is pressed
    @IBAction func kudosButtonPressed(_ sender: UIButton) {
        ApprovalRating().changeApprovalRating(uid: uid, by: 1) {
            self.getUserInfoFromProfile()
            
            self.kudosButton.isEnabled = false
            self.kudosButton.isHidden = true
        }
    }
    
    //function to activate when the message button is pressed
    @IBAction func messageButton(_ sender: UIButton) {
        //create constant to represent the mail controller
        let mailComposer = MFMailComposeViewController()
        
        //set the delegate
        mailComposer.mailComposeDelegate = self
        
        //set the message data
        mailComposer.setToRecipients([email])
        mailComposer.setSubject("Hi my name is \(Profile().getUserName())!")
        mailComposer.setMessageBody("<p>Your message here...<p>", isHTML: true)
        
        //determine if device can send mail, and then present the view controller
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposer, animated: true, completion: nil)
        }
    }
    
    //function to activate when mail controller is finished
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        //dismiss the controller
        controller.dismiss(animated: true, completion: nil)
        
        //use switch on the result to send completion message
        switch result {
        case .sent:
            presentMessage(sender: self, title: "Message Sent!", message: "Your message has been sent. Support will be sure to contact you in 72 hours.")
        case .saved:
            presentMessage(sender: self, title: "Message Saved.", message: nil)
        case .cancelled:
            print("message cancelled")
        case .failed:
            presentUnexpectedErrorMessage(sender: self)
        default:
            presentUnexpectedErrorMessage(sender: self)
        }
    }
    
    //function to activate when the report button is pressed
    @IBAction func reportButton(_ sender: UIButton) {
        //create a constant representing an alert
        let alert = UIAlertController(title: "Report User!", message: "Why are you reporting this user? Remember that abuse of this feature has consequences.", preferredStyle: .alert)
        
        //add a cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //add first option
        alert.addAction(UIAlertAction(title: "Abusive/Offensive Language", style: .destructive, handler: { (action) in
            self.actionToReportPlayer(forReport: .abuseOffenseLanguage)
        }))
        
        //add second option
        alert.addAction(UIAlertAction(title: "Threatening Language", style: .destructive, handler: { (action) in
            self.actionToReportPlayer(forReport: .threteningLanguage)
        }))
        
        //add third option
        alert.addAction(UIAlertAction(title: "Troll", style: .destructive, handler: { (action) in
            self.actionToReportPlayer(forReport: .troll)
        }))
        
        //add fourth option
        alert.addAction(UIAlertAction(title: "Assesment Cheating", style: .destructive, handler: { (action) in
            self.actionToReportPlayer(forReport: .assesmentCheating)
        }))
        
        //add fifth option
        alert.addAction(UIAlertAction(title: "Fake Information", style: .destructive, handler: { (action) in
            self.actionToReportPlayer(forReport: .fakeInformation)
        }))
        
        //add other option
        alert.addAction(UIAlertAction(title: "Other", style: .destructive, handler: { (action) in
            self.actionToReportPlayer(forReport: .other)
        }))
        
        //present the message
        self.present(alert, animated: true, completion: nil)
    }
    
    //function to run when an action is pressed to report
    func actionToReportPlayer(forReport: Reporting.ReportType) {
        //run action to report the player
        Reporting().receiveReport(report: forReport, uid: uid, question: questionName, response: responseName ?? "??No Response??")
        
        //show message
        presentMessage(sender: self, title: "User Reported", message: "If needed, support will follow up with you shortly")
    }
}
