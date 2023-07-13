//
//  SignInController.swift
//  DasdApp
//

// Has public enum stating sign in types
// Contains UIViewCOntroller for the app sign in, and additional functions to sign in a user

//  Created by Ethan Miller on 10/20/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

//public enum for sign in methods
public enum SignInMode {
    case signUp
    case logIn
}

//class to handle the sign in view controller
class SignInController: CustomViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var contentStackView: UILabel!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInModeSwitchButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    @IBOutlet weak var schoolPicker: UIPickerView!
    
    //variable to represent the current sign in method
    var currentSignInMethod: SignInMode = .signUp
    
    //constant to represent the auth
    let authRef = Auth.auth()
    //constant to represent the firestore
    let storeRef = Firestore.firestore()
    //constant representing the storage
    let storageRef = Storage.storage()
    
    //constant to hold the array of schools
    var schools: [String] = []
    
    //variable to hold the name of the selected school
    var selectedSchool: String = ""
    
    //functions to run when the view loads
    override func viewDidLoad() {
        super.viewDidLoad()

        //set up secure text for the password field
        passwordField.isSecureTextEntry = true
        
        //set up delegates for the text fields
        emailField.delegate = self
        passwordField.delegate = self
        
        //set up delegate and data source for the picker view
        schoolPicker.delegate = self
        schoolPicker.dataSource = self
        
        //download the schools array
        storeRef.collection("AppInfo").document("MainInfo").getDocument { (document, error) in
            //check for error
            if error != nil {
                print(error! as NSError)
                presentUnexpectedErrorMessage(sender: self)
            } else {
                //download the array of schools
                self.schools = document?.data()?["Schools"] as! [String]
                
                //set the first value to the selected school
                self.selectedSchool = self.schools.first!
                
                self.schoolPicker.reloadAllComponents()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //show a message to present alert about the privacy policy and the code of conduct
        presentMessageWithActionAndCancel(sender: self, title: "Privacy Policy and Code of Conduct", message: "In order to continue you must agree to the Provacy Policy and Code of Conduct. Both are available on our website.", actionTitle: "View Website", cancelTitle: "I Agree") {
            //create URL to the webstie
            let url = URL(string: "https://sites.google.com/student.dasd.org/takt-tutoring")
            //open Url in safari
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
    }
    
    //function to run when the views are already laid out
    override func viewDidLayoutSubviews() {
        //add a corner radius to the buttons
        signInModeSwitchButton.layer.cornerRadius = signInModeSwitchButton.frame.height / 2
        signInModeSwitchButton.layer.masksToBounds = true
        goButton.layer.cornerRadius = goButton.frame.height / 2
        goButton.layer.masksToBounds = true
    }
    
    //function to run every time the mode switch button is pressed
    @IBAction func signInModeSwitchButton(_ sender: UIButton) {
        //toggle the signin mode
        if currentSignInMethod == .signUp {
            currentSignInMethod = .logIn
            //run function to set up the appropriate texts
            changeHeaderText(toMode: .logIn)
        } else {
            currentSignInMethod = .signUp
            //run function to set up the appropriate texts
            changeHeaderText(toMode: .signUp)
        }
    }
    
    //function to run everytime the go button is pressed
    @IBAction func goButton(_ sender: UIButton) {
        signInModeSwitchButton.isEnabled = false
        goButton.isEnabled = false
        
        
        //ensure both text fields have text entry
        if emailField.text == "" && passwordField.text == "" {
            //fields were left blank, send error
            presentMessage(sender: self, title: "Text Field Blank!", message: "Make sure both fields are filled out!")
        } else {
            //create local variables for the email and the password
            let email = emailField.text!
            let password = emailField.text!
            
            //initiate connection to the main app info for the app, to determin ultimate accessibility
            storeRef.collection("AppInfo").document("MainInfo").getDocument { (document, error) in
                //check for error
                if error != nil {
                    //handle error
                    print(error! as NSError)
                    presentUnexpectedErrorMessage(sender: self)
                    
                    self.signInModeSwitchButton.isEnabled = true
                    self.goButton.isEnabled = true
                } else {
                    //get the document stating global app availability
                    let globalAppLaunch = document?.data()?["allowLaunch"] as! Bool
                    
                    //run if statement to determine if the app chould launch globably
                    if globalAppLaunch == false {
                        //access denied handle error
                        ErrorFunctions().handleError(sender: self, error: .appDisabled)
                        
                        self.signInModeSwitchButton.isEnabled = true
                        self.goButton.isEnabled = true
                    } else {
                        print(self.selectedSchool)
                        
                        //initiate connection to the school collection to detemine school based availability, no error check necessary
                        self.storeRef.collection(self.selectedSchool).document("MainInfo").getDocument { (document2, schoolError) in
                            //get document determining the app availability for the particular school
                            let schoolAppLaunch = document2?.data()?["allowLaunch"] as! Bool
                            
                            //determine if lauch is available according to the selected school
                            if schoolAppLaunch == false {
                                //acess denied, handle error
                                ErrorFunctions().handleError(sender: self, error: .schoolDisabled)
                                
                                self.signInModeSwitchButton.isEnabled = true
                                self.goButton.isEnabled = true
                            } else {
                                //permissions accepted continue sign in
                                
                                //determine the current sign in method
                                if self.currentSignInMethod == .logIn {
                                    //log in the user
                                    self.authRef.signIn(withEmail: email, password: password) { (dataResult, logInError) in
                                        //run error check
                                        if logInError != nil {
                                            print(logInError! as NSError)
                                            //handle error
                                            ErrorFunctions().handleFirebaseAuthError(sender: self, error: logInError! as NSError)
                                            
                                            self.signInModeSwitchButton.isEnabled = true
                                            self.goButton.isEnabled = true
                                        } else {
                                            //run function to set up data for the log in
                                            logInUser(school: self.selectedSchool, userEmail: email, UID: dataResult!.user.uid)
                                            //dismiss the view controller
                                            self.dismiss(animated: true, completion: nil)
                                            
                                            Permissions.allowRepeatedCheck = true
                                        }
                                    }
                                } else {
                                    //sign up the user
                                    self.authRef.createUser(withEmail: email, password: password) { (dataResult, signUpError) in
                                        //run error check
                                        if signUpError != nil {
                                            print(signUpError! as NSError)
                                            //handle error
                                            ErrorFunctions().handleFirebaseAuthError(sender: self, error: signUpError! as NSError)
                                            
                                            self.signInModeSwitchButton.isEnabled = true
                                            self.goButton.isEnabled = true
                                        } else {
                                            //continue to collect name function for sign in
                                            self.determineIfTeacher(school: self.selectedSchool, UID: dataResult!.user.uid, userEmail: email)
                                            
                                            Permissions.allowRepeatedCheck = true
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //function to change the header text
    func changeHeaderText(toMode: SignInMode) {
        //text to use in the new label
        var text: String = ""
        
        if toMode == .logIn {
            text = "Log In!"
            signInModeSwitchButton.setTitle("Switch To Sign Up", for: .normal)
        } else {
            text = "Sign Up!"
            signInModeSwitchButton.setTitle("Switch To Log In", for: .normal)
        }
        
        UIView.animate(withDuration: 1) {
            self.headerLabel.text = text
        }
    }
    
    //function to determine the number of components in the picker view
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //set up the number of rows in each component
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return schools.count
    }
    
    //set up the titles for each row
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return schools[row]
    }
    
    //function to activate every time the picker view is changed
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedSchool = schools[row]
    }
    
    //function to determine if the person is a teacher
    func determineIfTeacher(school: String, UID: String, userEmail: String) {
        presentMessageWithActions(sender: self, title: "Are you a student or teacher?", message: "Be aware that if you sign up as a teacher, an admin will review your profile to ensure you are not a fraud.", actionTitle: "I am a Student", secondActionTitle: "I am a Teacher", action: {
            self.collectName(school: school, UID: UID, userEmail: userEmail, isTeacher: false)
        }) {
            self.collectName(school: school, UID: UID, userEmail: userEmail, isTeacher: true)
        }
    }
    
    //function run after completed sign in, collecting the name of the user, ONLY FOR SIGN UP FUNCTION
    func collectName(school: String, UID: String, userEmail: String, isTeacher: Bool) {
        //create constant to a new UIALert
        let alert = UIAlertController(title: "Please Enter Your Name!", message: "Please enter an appropriate name you would like to go by. Your legal name is not recommended.", preferredStyle: .alert)
        
        //create text field for the alert
        alert.addTextField { (textField) in
            
        }
        
        //create continue action for the alert
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { (action) in
            //create vairable to for the text in the text field
            var inputedName: String? = alert.textFields?.first?.text
            
            //make sure there is user input
            if inputedName == "" || inputedName == nil {
                //restart message
                self.collectName(school: school, UID: UID, userEmail: userEmail, isTeacher: isTeacher)
            } else {
                //check to see if the name is appropriate to continue
                if determineIfTextIsAppropriate(text: inputedName!) == false {
                    //restart message
                    self.collectName(school: school, UID: UID, userEmail: userEmail, isTeacher: isTeacher)
                } else {
                    print("Succeeded in collecting name")
                    
                    //add if statement to determine if the person signing up is a teacher
                    if isTeacher == false {
                        print("Not a Teacher")
                        
                        //continue to sign in function
                        signUpUser(UID: UID, school: school, userEmail: userEmail, userName: inputedName!)
                        //dismiss the view controller
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        //add symbol to the user name
                        inputedName! += " :"
                        
                        //set userdefault showing that the user is a teacher
                        UserDefaults.standard.set(true, forKey: "UserInfo/isTeacher")
                        
                        //activate function to sign up the user
                        signUpUser(UID: UID, school: school, userEmail: userEmail, userName: inputedName!)
                        
                        //run function to send a request to the servers
                        TeacherFunctions().uploadRequestForTeacher(uid: UID, email: userEmail)
                        
                        //present message
                        presentMessageWithAction(sender: self, title: "Await Approval", message: "Sorry, but to ensure a student is not trying to impersonate you, we must first confirm your account. Be sure to check your email in the next 24 hours!", actionTitle: "Restart App") {
                            fatalError()
                        }
                    }
                }
            }
        }))
        
        //present the alert
        self.present(alert, animated: true, completion: nil)
    }
}


//function to set up the user's firestore document
public func signUpUser(UID: String, school: String, userEmail: String, userName: String) {
    //create constant to the firebase firestore
    let storeRef = Firestore.firestore()
    //create constant representing the storage
    let storageRef = Storage.storage().reference()
    
    
    //create constant representing the sign in view controller
    let signInViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignInController")
    
    //initiate connection to the school collection in the firestore
    storeRef.collection(school).document("Users").getDocument { (schoolUserDocument, error) in
        //run error check
        if error != nil {
            //handle error
            print(error! as NSError)
            presentUnexpectedErrorMessage(sender: signInViewController)
        } else {
            //download the population document
            var population = schoolUserDocument?.data()?["population"] as! Int
            //add 1 to the population
            population += 1
            //upload the new population
            storeRef.collection(school).document("Users").updateData(["population": population])
            
            //initiate connection to the user's collection in the school collection, do not run error check
            storeRef.collection(school).document("Users").collection("UserCollection").document("Info").getDocument { (userCollectionDocument, secondError) in
                //get document stating whether new user's are allowed for this school
                let newUsersAllowed = userCollectionDocument?.data()?["allowNewUsers"] as! Bool
                
                if newUsersAllowed == false {
                    //handle error
                    ErrorFunctions().handleError(sender: signInViewController, error: .newUsersDisabled)
                } else {
                    //continue with sign up process
                    
                    //create new user document
                    storeRef.collection(school).document("Users").collection("UserCollection").document(UID).setData(["userEmail": userEmail, "classes": ["NO CLASSES"], "userName": userName, "userReputation": 0, "userQuestions": [], "userResponses": [], "isTutor": false, "numberOfQuestions": 0, "numberOfResponses": 0], completion: nil)
                    
                    //save files to user defaults
                    UserDefaults.standard.set(userEmail, forKey: "UserInfo/Email")
                    UserDefaults.standard.set(school, forKey: "UserInfo/School")
                    UserDefaults.standard.set(userName, forKey: "UserInfo/Name")
                    
                    //get a default image to upload, also compress to jPeg data
                    let defaultImageData = Profile().returnDefaultImage(name: Profile().getUserName()).jpegData(compressionQuality: 1.0)
                    //create reference for the image to upload
                    let uploadRef = storageRef.child("UserIcons/\(Auth.auth().currentUser!.uid)")
                    //create reference representing the metadata
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    
                    //upload the image
                    uploadRef.putData(defaultImageData!, metadata: metadata) { (metadata, error) in
                        //run error check
                        if error != nil {
                            print(error! as NSError)
                        } else {
                            print("Yay!")
                        }
                    }
                    
                    //upload the uid to the array
                    storeRef.collection(school).document("Users").getDocument { (document, error) in
                        //download the current array of uids
                        var uids = document?.data()?["UIDs"] as! [String]
                        
                        //append the uid of the new user
                        uids.append(Auth.auth().currentUser!.uid)
                        
                        //upload the edited array
                        storeRef.collection(school).document("Users").updateData(["UIDs": uids])
                    }
                    
                    
                    print("COMPLETED SIGN UP")
                    
                    //set userdefualts showing the user has signed in
                    UserDefaults.standard.set(true, forKey: "User/DidLogIn")
                }
            }
        }
    }
}

//function to set up user's local profile
public func logInUser(school: String, userEmail: String, UID: String) {
    //create reference to the firebase firestore
    let storeRef = Firestore.firestore()
    
    print(UID)
    
    //inititate connection to the profile of the user and get the user name and classes, without error check
    storeRef.collection(school).document("Users").collection("UserCollection").document(UID).getDocument { (document, error) in
        //download the userName and the array of classes
        let userName: String = document?.data()?["userName"] as! String
        let classes: [String] = document?.data()?["classes"] as! [String]
        
        //save the data to userdefaults
        UserDefaults.standard.set(userEmail, forKey: "UserInfo/Email")
        UserDefaults.standard.set(school, forKey: "UserInfo/School")
        UserDefaults.standard.set(userName, forKey: "UserInfo/Name")
        UserDefaults.standard.set(classes, forKey: "UserInfo/Classes")
        
        print("COMPLETED LOG IN")
        
        //set userdefaults showing the user has signed in, and that classes have been selected
        UserDefaults.standard.set(true, forKey: "User/DidLogIn")
        UserDefaults.standard.set(true, forKey: "User/DidAddClasses")
        
        //run function to determine if the user is a teacher
        TeacherFunctions().determineIfTeacher(school: school, uid: UID) { (isTeacher) in
            UserDefaults.standard.set(isTeacher, forKey: "UserInfo/isTeacher")
        }
    }
}

