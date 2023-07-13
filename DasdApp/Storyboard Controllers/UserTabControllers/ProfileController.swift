//
//  ProfileController.swift
//  DasdApp
//
//  Created by Ethan Miller on 10/13/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import Firebase
import MessageUI

class ProfileController: CustomViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate {

    //variables representing stuff in the main view
    @IBOutlet weak var mainStackView: UIStackView!
    
    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var headerLabel: UITextField!
    
    @IBOutlet weak var approvalScoreLabel: UILabel!
    
    @IBOutlet weak var profileContentStackView: UIStackView!
    @IBOutlet weak var classesStackView: UIStackView!
    @IBOutlet weak var classesStackViewHeader: UILabel!
    @IBOutlet weak var recentQuestionsStackView: UIStackView!
    @IBOutlet weak var recentQuestionsStackViewHeader: UILabel!
    
    @IBOutlet weak var supportStackView: UIStackView!
    @IBOutlet weak var supportButton: UIButton!
    
    @IBOutlet weak var controlStackView: UIStackView!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var changeClasses: UIButton!
    @IBOutlet weak var websiteButton: UIButton!
    
    
    
    //create global variable to hold the classes of the user
    var userClasses: [String] = []
    //create global variable to hold the array of recently asked questions
    var recentQuestions: [String] = []
    var responseCounts: [Int] = []
    
    //variable to represent whenther the user is editing profile
    var editingEnabled: Bool = false
    
    let storeRef = Firestore.firestore()
    let storageRef = Storage.storage().reference()
    
    //create constant representing the edit image for the header image
    let editImageView = UIButton()
    
    //global variable to hold the text for the approval score label
    var approvalLabelScores: String! = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set the delegate for the text field/header label
        headerLabel.delegate = self
        
        //get the array of classes from the Profile
        userClasses = Profile().getArrayOfClasses()
        
        //set the text of the header label to the user name
        headerLabel.text = Profile().getUserName()
        
        //run function that adds labels to the class stack view
        addClassLabels()
        
        //run function to get the info for the recent question labels
        getInfoForRecentQuestions()
        
        //set the header label so that it is not editable
        headerLabel.isEnabled = false
        
        //run function to add edit button to the profile image
        addEditButton()
        
        //run function to get the user's profile picture
        getProfileImage()
        headerImage.contentMode = .scaleAspectFill
        
        //run function to set up the score label
        getScoresForLabel()
    }
    
    //function to run whenever the view is laid out
    override func viewDidLayoutSubviews() {
        //add corner radius to the header image to make it a circle
        headerImage.layer.cornerRadius = headerImage.frame.height / 2
        headerImage.layer.masksToBounds = true
        
        headerImage.backgroundColor = UIColor.lightGray
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("view appearing")
        resetClassLabels()
        getInfoForRecentQuestions()
        getScoresForLabel()
        
        //run if to determine if the tutorial has been shown before
        if UserDefaults.standard.value(forKey: "Tutorial/Profile") as? Bool != true {
            //present the tutorial message
            presentMessageWithAction(sender: self, title: "Your Profile", message: "Here you can see your profile, including your classes and recent questions. Press the \"Edit Profile\" button to change your user name, profile picture, and password. You can also change your classes, contact support, or enter the TTP program.", actionTitle: "Ok") {
                UserDefaults.standard.set(true, forKey: "Tutorial/Profile")
            }
        }
    }
    
    //MARK: SCORE LABEL FUNCTIONS
    func getScoresForLabel() {
        //run function to get the approval rating
        ApprovalRating().getRating(uid: Auth.auth().currentUser!.uid) { (approvalRating) in
            //run function to get the number of questions
            ProfileCounts().getNumberOfQuestions { (questionCount) in
                //run function to get the number of responses
                ProfileCounts.Responses().getNumberOfResponses { (responseCount) in
                    //set the score label
                    self.approvalScoreLabel.text = "\(approvalRating) | \(questionCount) | \(responseCount)"
                    self.approvalLabelScores = self.approvalScoreLabel.text!
                    
                    //run function to add a touch sensor to the label
                    self.addTouchSensorToApprovalLabel()
                }
            }
        }
    }
    
    //add a touch sensor to the approval label
    func addTouchSensorToApprovalLabel() {
        let touchSensor = UITapGestureRecognizer(target: self, action: #selector(touchSensorPressed(sender:)))
        
        approvalScoreLabel.isUserInteractionEnabled = true
        approvalScoreLabel.isMultipleTouchEnabled = true
        approvalScoreLabel.addGestureRecognizer(touchSensor)
    }
    
    //function to activate when the touch sensor on the score label is pressed
    @objc func touchSensorPressed(sender: UITapGestureRecognizer) {
        //enter switch statement to determine which text the labl is currently showing
        switch approvalScoreLabel.text! {
        case approvalLabelScores:
            approvalScoreLabel.text = "Rating | # of Questions | # of Responses"
        default:
            approvalScoreLabel.text = approvalLabelScores
        }
    }
    
    //function reset the class labels in the class labesl stack view
    func resetClassLabels() {
        print("reseting class labels")
        //enter for statement to remove labels that aren't the header
        for subview in classesStackView.arrangedSubviews {
            if subview != classesStackViewHeader {
                subview.removeFromSuperview()
            }
        }
        
        //reset the user classes variable
        userClasses = Profile().getArrayOfClasses()
        
        //fun functions to set up the stack views again, to refpresh after the edit views disappear
        addClassLabels()
    }
    
    
    //MARK: Add Label Functions
    //function to add labels to the array of student classes
    func addClassLabels() {
        //enter for loop for all of the user classes
        for userClass in userClasses {
            //determine if the class is listed as NONE
            if userClass == "None" {
                //class is NONE, so do not add a label
            } else {
                //add class label as usual
                
                //create constant representing a UILabel
                let label = UILabel()
                
                //set up the font, color, etc. for the label
                label.font = UIFont(name: "Copperplate", size: 15)
                label.textColor = UIColor.label
                
                //set up the text for the label (the class from the for loop)
                label.text = userClass
                
                //size the label to fit the text
                label.sizeToFit()
                
                //add the label to the stack view of class labels
                classesStackView.insertArrangedSubview(label, at: classesStackView.arrangedSubviews.count)
            }
        }
    }
    
    //function to get info for the question labels
    func getInfoForRecentQuestions() {
        //run function to get the recent queations from the profile
        QuestionsForProfile().getQuestionsFromProfile { (questionsFromProfile) in
            //reset previous functions
            self.responseCounts.removeAll()
            self.recentQuestions.removeAll()
            self.recentQuestionsStackView.subviews.forEach { (view) in
                if view != self.recentQuestionsStackViewHeader {
                    view.removeFromSuperview()
                }
            }
            
            //enter for statement to get the response counts
            for question in questionsFromProfile {
                if self.recentQuestions.count > 3 {
                    break
                }
                
                //add the question to the recent questions array
                self.recentQuestions.insert(question.questionText, at: 0)
                
                //run function to get the number of responses
                Questions.Responses().getNumberOfResponses(school: Profile().getUserSchoolName(), forClass: question.classText, questionTitle: question.questionText) { (count, error) in
                    //run error check
                    if error != nil {
                        self.responseCounts.append(0)
                    } else {
                        //add the count to the array
                        self.responseCounts.append(count)
                    }
                }
            }
            
            //create timer to determine if the full array of counts has been found
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
                print(self.responseCounts, self.recentQuestions)
                
                //run if to determine if the full array of counts has been found
                if self.responseCounts.count != self.recentQuestions.count {
                    print("Waiting for counts")
                } else {
                    //run function to set up the labels
                    self.addQuestionLabels()
                    timer.invalidate()
                }
            }
        }
    }
    
    //function to add labels to the recent questions
    func addQuestionLabels() {
        //determine if the question array is empty
        if recentQuestions.isEmpty {
            //set the header label to show that there are no questions
            recentQuestionsStackViewHeader.text = "You havn't asked any questions yet!"
        } else {
            var index: Int = 0
            
            //enter for loop to handle each question individually
            for question in recentQuestions {
                //create stack view to hold the accompaning views
                let stackView = UIStackView()
                //set up additional info for the stack view
                stackView.distribution = .fillProportionally
                stackView.spacing = 3
                stackView.axis = .vertical
                
                //create the title label to hold the name of the question
                let label = UILabel()
                label.font = UIFont(name: "Copperplate", size: 15)
                label.text = question
                label.numberOfLines = 3
                label.sizeToFit()
                label.textAlignment = .right
                
                //create sublabel to show the number of repsonses
                let subLabel = UILabel()
                subLabel.font = UIFont(name: "Copperplate", size: 10)
                subLabel.textColor = UIColor.systemGray2
                subLabel.text = "\(responseCounts[index]) Responses"
                subLabel.sizeToFit()
                subLabel.textAlignment = .right
                
                stackView.sizeToFit()
                
                //add the label and sublabel to the stack view
                stackView.addArrangedSubview(label)
                stackView.addArrangedSubview(subLabel)
                
                //add the sub stack view to the questions stack view
                recentQuestionsStackView.insertArrangedSubview(stackView, at: recentQuestionsStackView.arrangedSubviews.count)
                
                index += 1
            }
        }
    }
    
    //MARK: Edit Profile Button
    //function to activate whenever the edit profile button is pressed
    @IBAction func editProfile(_ sender: UIButton) {
        //toggle the variable representing the editing mode of the user
        editingEnabled.toggle()
        
        //switch the editing enables variable
        switch editingEnabled {
        case true:
            //enable the header label
            headerLabel.isEnabled = true
            //add a border to the header label
            headerLabel.layer.borderWidth = 5
            headerLabel.layer.borderColor = UIColor.white.cgColor
            //add a corner radius to the label
            headerLabel.layer.cornerRadius = 15
            headerLabel.layer.masksToBounds = true
            
            //set the button labels
            editProfileButton.setTitle("End Editing", for: .normal)
            changeClasses.setTitle("Change Password", for: .normal)
            
            //hide the appropriate stack view
            classesStackView.isHidden = true
            recentQuestionsStackView.isHidden = true
            
            //show the edit image
            editImageView.isHidden = false
        case false:
            headerLabel.isEnabled = false
            //remove the border from the text field
            headerLabel.layer.borderColor = UIColor.clear.cgColor
            
            //set the button labels
            editProfileButton.setTitle("Edit Profile", for: .normal)
            changeClasses.setTitle("Change Classes", for: .normal)
            
            //unhide the appropriate stack views
            classesStackView.isHidden = false
            recentQuestionsStackView.isHidden = false
            
            //hide the edit image
            editImageView.isHidden = true
        }
    }
    
    //MARK: Text Field
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text?.last == ";" || textField.text?.last == ":" {
            textField.text?.removeLast()
        }
    }
    
    //function to run when the enter button is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //get a local variable of the text from the field
        let newName = textField.text!
        
        //run function to determine if the text is appropriate
        let appropriation = determineIfTextIsAppropriate(text: newName)
        
        if appropriation == false {
            presentMessage(sender: self, title: "Illegal Text", message: "The text you entered contains banned phrases or words")
            textField.text = nil
        } else {
            if Profile().getUserName().contains(" ;") {
                //assign the new name to the name userdefault
                UserDefaults.standard.set(newName + " ;", forKey: "UserInfo/Name")
                
                //send the name to the user profile
                Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document("\(Auth.auth().currentUser!.uid)").updateData(["userName":newName])
                
                //resign the first responder of the text field
                textField.resignFirstResponder()
            } else if Profile().getUserName().contains(":") {
                //assign the new name to the name userdefault
                UserDefaults.standard.set(newName + " :", forKey: "UserInfo/Name")
                
                //send the name to the user profile
                Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document("\(Auth.auth().currentUser!.uid)").updateData(["userName":newName])
                
                //resign the first responder of the text field
                textField.resignFirstResponder()
            } else {
                //assign the new name to the name userdefault
                UserDefaults.standard.set(newName, forKey: "UserInfo/Name")
                
                //send the name to the user profile
                Firestore.firestore().collection(Profile().getUserSchoolName()).document("Users").collection("UserCollection").document("\(Auth.auth().currentUser!.uid)").updateData(["userName":newName])
                
                //resign the first responder of the text field
                textField.resignFirstResponder()
            }
        }
        
        return true
    }
    
    //MARK: Change Classes Button
    //function to run whenver the change classes button is pressed
    @IBAction func changeClasses(_ sender: UIButton) {
        //button is multipurpose, changes roles depending whether the user is editing their profile or not
        
        //run if statement to determine what purpose the button will serve
        if editingEnabled == true {
            //button will be used to change password
            
            //create constant representing a ui alert
            let alert = UIAlertController(title: "Change Your Password!", message: "Enter your old password, then enter your new password!", preferredStyle: .alert)
            
            //add the first text field, the old password
            alert.addTextField { (textField) in
                textField.isSecureTextEntry = true
                textField.placeholder = "OLD Password"
            }
            
            //add the second text field, the new password
            alert.addTextField { (textField) in
                textField.isSecureTextEntry = true
                textField.placeholder = "NEW Password"
            }
            
            //add cancel action
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            //add an action that leads to functions to reset the password
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { (_) in
                //assign the text from the fields to local variables
                let oldPassword = alert.textFields!.first!.text!
                let newPassword = alert.textFields!.last!.text!
                
                //first, check that both text fields are not nil
                if oldPassword == "" || newPassword == "" {
                    //handle error
                    presentMessage(sender: self, title: "Text FIeld Blank", message: "Please fill out both of the text fields!")
                } else {
                    //get representation of the user
                    let user = Auth.auth().currentUser;
                    //get the user's credentials, using current email and entered old password
                    let credential = EmailAuthProvider.credential(withEmail: Profile().getUserEmail(), password: oldPassword)
                    
                    print(credential)
                    
                    // Prompt the user to re-provide their sign-in credentials
                    user!.reauthenticate(with: credential, completion: { (result, error) in
                        //check for an error
                        if error != nil {
                            //handle an error
                            print(error! as NSError)
                            ErrorFunctions().handleFirebaseAuthError(sender: self, error: error! as NSError)
                        } else {
                            // run password change funtion
                            Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { (secondError) in
                                //run an error chack
                                if secondError != nil {
                                    print(secondError! as NSError)
                                    //run error handling software
                                    ErrorFunctions().handleFirebaseAuthError(sender: self, error: secondError! as NSError)
                                } else {
                                    //show a completion message
                                    presentMessage(sender: self, title: "Success!", message: "The password was reset!")
                                }
                            })
                        }
                    })
                }
            }))
            
            //present the alert
            self.present(alert, animated: true, completion: nil)
        } else {
            //button will be used to change classes
            
            //set the public variable representing the current classes
            currentClasses = userClasses
            
            //activate segue to the edit classes view controller
            self.performSegue(withIdentifier: "showClassesEditor", sender: self)
        }
    }
    
    // MARK: PROFILE PICTURE FUNCTIONS
    //function to get the user's profile image from servers
    func getProfileImage() {
        storageRef.child("UserIcons/\(Auth.auth().currentUser!.uid)").getData(maxSize: 10000000) { (data, error) in
            //run error check
            if error != nil {
                print(error! as NSError)
                ErrorFunctions().handleFirebaseStorageError(sender: self, error: error! as NSError)
            } else {
                //convert the raw data to image data
                let imageData = UIImage(data: data!)
                
                //set the header image to the profile picture
                self.headerImage.image = imageData!
            }
        }
    }
    
    //function to add an edit button to the profile image
    func addEditButton() {
        //set the image for the view
        editImageView.setImage(UIImage(systemName: "pencil.circle"), for: .normal)

        //set the frame for the image
        editImageView.frame = CGRect(x: 15 , y: 15, width: 75, height: 75)
        
        //add the image view to the profile picture
        headerImage.addSubview(editImageView)
        //make the header image multitouch and interaction enabled
        headerImage.isMultipleTouchEnabled = true
        headerImage.isUserInteractionEnabled = true
        
        //hide the edit image, to be shown when the user selects to edit profile
        editImageView.isHidden = true
        
        //add the target for the edit button
        editImageView.addTarget(self, action: #selector(editPicture), for: .touchUpInside)
    }
    
    //function to activate when the edit button is pressed
    @objc func editPicture() {
        print("editing picture")
        
        //create variable representing the image picker view
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        //set appropriate info to present photo library
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        
        //present the picker view
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    //function to run when the user selects an image from the image picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        //run if let statement to get the image the user chose
        guard let chosenImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            print("error selecting image")
            presentMessage(sender: self, title: "Error Selecting Image!", message: "There was an error selecting the new image, please try again.")
            return
        }
        
        //turn the image into jpeg data
        let imageData = chosenImage.jpegData(compressionQuality: 0.25)
        //set the metadata for the image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        print("picked image")
        
        //set url for the user profile image
        storageRef.child("UserIcons/\(Auth.auth().currentUser!.uid)").putData(imageData!, metadata: metadata) { (metadata, error) in
            //run error check
            if error != nil {
                //handle error
                print(error! as NSError)
                //function to handle universal error
                ErrorFunctions().handleFirebaseStorageError(sender: self, error: error! as NSError)
            } else {
                //run function to download the new image and set it to the profile image
                self.getProfileImage()
                print("setting profile image")
            }
        }
    }
    
    //button activated when the support button is pressed
    @IBAction func supportButton(_ sender: UIButton) {
        //create constant to represent the mail controller
        let mailComposer = MFMailComposeViewController()
        
        //set the delegate
        mailComposer.mailComposeDelegate = self
        
        //set the message data
        mailComposer.setToRecipients(["takttutoring@gmail.com"])
        mailComposer.setSubject("Cutomer Request")
        mailComposer.setMessageBody("<h4 style=\"text-align:center;\"> Customer Request Or Comment </h4> <p>Enter Your request or comment here... </p><p>  </p><p>  </p> <hr> <p>\(Profile().getUserName())</p> <p>\(Auth.auth().currentUser!.uid)</p>", isHTML: true)
        
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
    
    //function activated when the website button is pressed
    @IBAction func websiteButton(_ sender: UIButton) {
        //create URL to the webstie
        let url = URL(string: "https://sites.google.com/student.dasd.org/takt-tutoring")
        //open Url in safari
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }
    
    //MARK: Sign Out Functions
    //function to activate whenever the sign out button is pressed
    @IBAction func signOut(_ sender: UIButton) {
        //create a constant represeting a alert
        let alert = UIAlertController(title: "Sign Out?", message: "All of your files will remain saved in the cloud!", preferredStyle: .alert)
        
        //add cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //add action to continue with the sign out
        alert.addAction(UIAlertAction(title: "SIGN OUT", style: .destructive, handler: { (_) in
            //run function to sign out the user, then check if completion is true
            Profile().signOut { (completion) in
                //check if complete
                if completion == false {
                    //handle error
                    presentUnexpectedErrorMessage(sender: self)
                } else {
                    //disable the repeated profile check
                    Permissions.allowRepeatedCheck = false
                    
                    //activate seuge to the welcomeViewController
                    self.performSegue(withIdentifier: "showWelcomeScreen", sender: self)
                }
            }
        }))
        
        //present the alert
        self.present(alert, animated: true, completion: nil)
    }
}



