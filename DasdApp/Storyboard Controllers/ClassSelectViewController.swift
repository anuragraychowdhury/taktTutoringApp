//
//  ClassSelectViewController.swift
//  DasdApp
//

//contains public array representing the class categories
//contains class for the classSelectionViewController

//  Created by Ethan Miller on 10/26/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

public var classCategories: [String] = ["Math", "Literature", "Social Studies", "Science", "Language"]

public var currentClasses: [String] = []

class ClassSelectViewController: CustomViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    

    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subHeaderLabel: UILabel!
    @IBOutlet weak var classPickerView: UIPickerView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    
    //create global constant to the firestore
    let storeRef = Firestore.firestore()
    
    //arrays to represent the 5 different core classes
    var mathClasses: [String] = []
    var litClasses: [String] = []
    var socialStudiesClasses: [String] = []
    var scienceClasses: [String] = []
    var languageClasses: [String] = []
    
    //array to represent all of the classes
    var allClasses: [String] = []
    
    //array of classes that the user has selected
    var userClasses: [String] = []
    
    //variable to represent the current category
    var currentCategory: Int = 0
    //variable to represent the array currently in the picker
    var currentArray: [String] = []
    //variable representing the class currently selected
    var selectedClass: String = ""
    //variable to represent the maximum number of classes the student can sign up for
    var maximumNumberOfClasses: Int = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set up delegate and data source for the picker view
        classPickerView.delegate = self
        classPickerView.dataSource = self
        
        //add corner radii to the buttons
        backButton.layer.cornerRadius = 15
        backButton.layer.masksToBounds = true
        continueButton.layer.cornerRadius = 15
        continueButton.layer.masksToBounds = true
        
        //run function to find the maximum number of classes in the school
        findMaxNumberOfClasses(school: UserDefaults.standard.value(forKey: "UserInfo/School") as! String, completion: {() in
            //run function to download the school classes
            self.downloadClassesForSchool(school: UserDefaults.standard.value(forKey: "UserInfo/School") as! String)
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UserDefaults.standard.value(forKey: "User/DidAddClasses") as? Bool != true {
//            //present alert for beta testers
//            presentMessage(sender: self, title: "A Message for Beta Testers \n(Plz Read)", message: "Thank you for helping to beta-test TAKT Tutoring! Just a small disclamer, TestFlight will collect crash logs from your device if TAKT were to crash while you are using it. This log will include you device name, MAC address, IP address, Wifi Information, and geographical location. We will not use, sell, or misuse this information, we are only interested in why the app crashed. In addition, if you are to experience any problems with TAKT, just take a screenshot in the app, and we will automatically receive this screenshot (this only happens while you are using TAKT). In order to test, all users will use the same class (\"Mr. Browns Physics\"), there will be no other classes available at this time. Also, on the profile page, there is a 'Support' button. Should you have a comment, question, or concern, just press this button. Have fun!")
        }
    }
    
    //function to download the maximum number of classes the student can choose
    func findMaxNumberOfClasses(school: String, completion: @escaping () -> Void) {
        //connect to the Main Info document for the school
        storeRef.collection(school).document("MainInfo").getDocument { (document, error) in
            //run error check
            if error != nil {
                print(error! as NSError)
                presentUnexpectedErrorMessage(sender: self)
            } else {
                //download the document representing the max number and assign to the global variable
                self.maximumNumberOfClasses = document?.data()?["maxNumberofClasses"] as! Int
                
                print(self.maximumNumberOfClasses)
                
                completion()
            }
        }
    }
    
    //function to download the names of all the classes for the school
    func downloadClassesForSchool(school: String) {
        //initiate connection to the school of the user and get the arrays of classes
        storeRef.collection(school).document("Classes").getDocument { (document, error) in
            //run error check
            if error != nil {
                //handle error
                print(error! as NSError)
                presentUnexpectedErrorMessage(sender: self)
            } else {
                //get arrays of classes
                self.mathClasses = document?.data()?["Math"] as! [String]
                self.litClasses = document?.data()?["Literature"] as! [String]
                self.socialStudiesClasses = document?.data()?["Social Studies"] as! [String]
                self.scienceClasses = document?.data()?["Science"] as! [String]
                self.languageClasses = document?.data()?["Language"] as! [String]
                
                //add the arrays together to create the overall array
                self.allClasses = self.mathClasses + self.litClasses + self.socialStudiesClasses + self.scienceClasses + self.languageClasses
                
                //add none to all of the class arrays
                self.mathClasses.insert("None", at: 0)
                self.litClasses.insert("None", at: 0)
                self.socialStudiesClasses.insert("None", at: 0)
                self.scienceClasses.insert("None", at: 0)
                self.languageClasses.insert("None", at: 0)
                self.allClasses.insert("None", at: 0)
                
                //run function to set up the picker
                self.setUpPicker(forMode: self.currentCategory)
            }
        }
    }
    
    func setUpPicker(forMode: Int) {
        //enter switch statement to determine which mode to set up the picker for
        switch forMode {
        //case to make sure the mode number isnt equal to the maximum number of classes
        case maximumNumberOfClasses:
            
            //add the classes to a userdefault
            UserDefaults.standard.set(userClasses, forKey: "UserInfo/Classes")
            
            //set userdefault stating that classes have been set
            UserDefaults.standard.set(true, forKey: "User/DidAddClasses")
            
            print(currentClasses.count)
            
            //done, dismiss the view
            self.dismiss(animated: true, completion: nil)
            
            //set the editing classes to nil
            currentClasses = []
            
            //upload the classes to the user's profile
            storeRef.collection(UserDefaults.standard.value(forKey: "UserInfo/School") as! String).document("Users").collection("UserCollection").document(Auth.auth().currentUser!.uid).updateData(["classes": userClasses])
        case 0:
            //set up array and label for math classes
            currentArray = mathClasses
            subHeaderLabel.text = "Select Your Math Class!"
        case 1:
            //set up array and label for lit classes
            currentArray = litClasses
            subHeaderLabel.text = "Select Your Lit Class!"
        case 2:
            //set up array and label for social studies classes
            currentArray = socialStudiesClasses
            subHeaderLabel.text = "Select Your Social Studies Class!"
        case 3:
            //set up array and label for science classes
            currentArray = scienceClasses
            subHeaderLabel.text = "Select Your Science Class!"
        case 4:
            //set up array and label for language classes
            currentArray = languageClasses
            subHeaderLabel.text = "Select Your Language Class!"
        default:
            //set up array and label for all classes, presents all classes until the maximum number is met
            currentArray = allClasses
            subHeaderLabel.text = "Select Another Class!"
        }
        
        print(userClasses)
        
        //set the first value of the array to the selected class
        selectedClass = currentArray.first!
        
        //reload the picker view
        classPickerView.reloadAllComponents()
        
        //set the selected item to the first row
        classPickerView.selectRow(0, inComponent: 0, animated: true)
        
        //run function to determine if classes are being edited
        selectClassForEditing()
    }
    
    //function to determine if classes are being edited, then set up picker appropriately
    func selectClassForEditing() {
        //determine if there are classes or editing (if the array is nil)
        if currentClasses.isEmpty == true {
            //no classes set for editing
        } else {
            //create a constant representing the index
            var index: Int!
            
            print("Current classes: \(currentClasses), user selected classes: \(userClasses), current category: \(currentCategory)")
            
            //enter switch with the current catergory, to know which class array to pull from
            switch currentCategory {
            case 0:
                //set data for the math class
                index = mathClasses.firstIndex(of: currentClasses[0])!
                //set the selected class to the class found, to prevent selection conflict
                selectedClass = mathClasses[index]
            case 1:
                //set data for the lit class
                index = litClasses.firstIndex(of: currentClasses[1])!
                //set the selected class to the class found
                selectedClass = litClasses[index]
            case 2:
                //set data for the ss class
                index = socialStudiesClasses.firstIndex(of: currentClasses[2])!
                selectedClass = socialStudiesClasses[index]
            case 3:
                //set data for the science class
                index = scienceClasses.firstIndex(of: currentClasses[3])!
                selectedClass = scienceClasses[index]
            case 4:
                //set data for the language class
                index = languageClasses.firstIndex(of: currentClasses[4])!
                selectedClass = languageClasses[index]
            default:
                //set data for all other classes
                index = allClasses.firstIndex(of: currentClasses[currentCategory])!
                selectedClass = allClasses[index]
            }
            
            //select the row according to the index
            classPickerView.selectRow(index, inComponent: 0, animated: true)
        }
    }
    
    //function to return the number of components in the picker view
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //function to determine the number of rows in the picker view
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currentArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //take the selected component and set the array
        selectedClass = currentArray[row]
    }
    
    //function to set up the titles in the picker view
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if currentArray.count <= 0 {
            return "Loading..."
        } else {
            return currentArray[row]
        }
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        //subtract one from the current category
        currentCategory -= 1
        
        //ensure that the current category
        if currentCategory <= 0 {
            currentCategory = 0
        }
        
        //run function to set up the picker view
        setUpPicker(forMode: currentCategory)
    }
    
    @IBAction func continueButton(_ sender: UIButton) {
        //add the current class to the user classes, ensure that the value is empty first
        if userClasses.count <= currentCategory {
            userClasses.insert(selectedClass, at: currentCategory)
        } else {
            userClasses[currentCategory] = selectedClass
        }

        
        //add one to the current category
        currentCategory += 1
        
        //run function to set up the picker view
        setUpPicker(forMode: currentCategory)
    }
}
