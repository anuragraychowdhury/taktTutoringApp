//
//  TTPController.swift
//  DasdApp
//
//  Created by Ethan Miller on 2/29/20.
//  Copyright © 2020 Ethan Miller. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class TTPController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subHeaderLabel: UILabel!
    
    @IBOutlet weak var seperatorView: UIView!
    
    @IBOutlet weak var formHeaderLabel: UILabel!
    @IBOutlet weak var legalNameView: UITextField!
    
    @IBOutlet weak var applyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        legalNameView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        determineIfInTTP()
    }
    
    //function to determine if the user already in the TTP
    func determineIfInTTP() {
        //run external function to determine if the user is in the TTP
        TTP().determineIfTutor { (isInTTP) in
            //switch the found value
            switch isInTTP {
            case true:
                print("In TTP")
                //present message
                self.applyButton.isEnabled = false
                presentMessageWithAction(sender: self, title: "Already in TTP", message: "You are already a member of the TTP", actionTitle: "Continue") {
                    self.dismiss(animated: true, completion: nil)
                }
            case false:
                print("Not in TTP")
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    @IBAction func applyButton(_ sender: UIButton) {
        //determine if a sign up is allowed to the TTP
        Permissions().checkTTPPermissions { (permission) in
            //run if statement to determine if the wign up is allowed
            if permission == false {
                //run action to present an error
                presentMessageWithAction(sender: self, title: "Access Denied!", message: "Sign ups for the TTP are currently disabled. Please try again later.", actionTitle: "Continue") {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                //continue with function
                
                //create local variables for the text fields
                let legalName = self.legalNameView.text
                
                //determine if text was entered for both fields
                if legalName == "" {
                    presentMessage(sender: self, title: "Blank Fields", message: "Be sure to fill out your legal name!")
                } else {
                    //run function to check if the approval rating is above 50
                    ApprovalRating().getRating(uid: Auth.auth().currentUser!.uid) { (rating) in
                        if rating < 25 {
                            presentMessage(sender: self, title: "Low Rating", message: "Your rating is not high enough to apply. You must have a rating of 25 or higher.")
                        } else {
                            //run function to get the number of questions within the profile
                            ProfileCounts().getNumberOfQuestions { (numberOfQuestions) in
                                if numberOfQuestions < 25 {
                                    presentMessage(sender: self, title: "Not Enough Questions", message: "You must have at least 25 questions to apply.")
                                } else {
                                    //run function to get the number of responses in the profile
                                    ProfileCounts.Responses().getNumberOfResponses { (numberOfResponses) in
                                        if numberOfResponses < 50 {
                                            presentMessage(sender: self, title: "Not Enough Responses", message: "You must have responded to questions 50 times in order to apply.")
                                        } else {
                                            //run functions to set up the profile
                                            TTP().changeTutorValue {
                                                TTP().alterUserName {
                                                    //show a completion message
                                                    presentMessageWithAction(sender: self, title: "Success", message: "You are now a Terrific Tutor! You will find a message in your inbox soon!", actionTitle: "Continue") {
                                                        self.dismiss(animated: true, completion: nil)
                                                    }
                                                }
                                                
                                                //run function to change the user default of the user name
                                                UserDefaults.standard.set("\(Profile().getUserName()) :", forKey: "UserInfo/Name")
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
