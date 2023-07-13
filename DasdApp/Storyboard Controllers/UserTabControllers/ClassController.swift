//
//  ClassController.swift
//  DasdApp
//
//  Created by Ethan Miller on 12/25/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ClassController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var mainTableView: UITableView!
    
    static var className: String = ""
    
    var classNameLocal: String = ""
    var schoolName: String = ""
    
    var questions: [String] = []
    var responses: [[String]] = []
    
    let storeRef = Firestore.firestore()
    
    var hasCompletedDataCollection: Bool = false
    
    var timer = Timer()
    
    var newQuestionImage: UIImage?
    
    //MARK: VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()

        //set up data for the table view
        mainTableView.dataSource = self
        mainTableView.delegate = self
        mainTableView.rowHeight = 80
        mainTableView.separatorStyle = .none
        
        //assign the static class name to a local variable
        classNameLocal = ClassController.className
        
        //get the name of the school the user is signed into
        schoolName = Profile().getUserSchoolName()
        
        createTableHeader()
        
        getClassData {
            //reload the table view
            self.mainTableView.reloadData()
            
            //set variable showing the data is collected
            self.hasCompletedDataCollection = true
            
            //remove and replace the header
            self.mainTableView.tableHeaderView = nil
            self.createTableHeader()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //run if to determine if the tutorial has been shown before
        if UserDefaults.standard.value(forKey: "Tutorial/Class") as? Bool != true {
            //present the tutorial message
            presentMessageWithAction(sender: self, title: "View Your Class", message: "Here you can see all the questions asked for this particular class. Tap on a question to view its responses. Tap the button in the upper right corner to ask a question.", actionTitle: "Ok") {
                UserDefaults.standard.set(true, forKey: "Tutorial/Class")
            }
        }
    }
    
    //MARK: CLASS DATA COLLECTION
    //function run to get necessary data for the user
    func getClassData(completion: @escaping () -> Void) {
        //get the array of questions
        Questions().getAllQuestionsForClass(forSchool: schoolName, forClass: classNameLocal) { (foundQuestions, error, _) in
            //run error check
            if error != nil {
                print(error!)
                self.mainTableView.allowsSelection = false
                self.hasCompletedDataCollection = true
                self.createTableHeader()
                ErrorFunctions().handleQuestionErrors(sender: self, error: error!)
            } else {
                //set the found questions to the global variable
                self.questions = foundQuestions
                
                //get the responses for each question
                Questions.Responses().getResponseArraysForQuestions(school: self.schoolName, forClass: self.classNameLocal, questions: self.questions) { (foundResponses, secondError, _) in
                    //run error check
                    if error != nil {
                        print(secondError!)
                        self.mainTableView.allowsSelection = false
                        self.hasCompletedDataCollection = true
                        self.createTableHeader()
                        ErrorFunctions().handleQuestionErrors(sender: self, error: secondError!)
                    } else {
                        //set the found responses to a local array
                        self.responses = foundResponses
                        
                        //set completion
                        completion()
                    }
                }
            }
        }
    }
    
    //MARK: TABLE VIEW FUNCTIONS
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if questions.isEmpty == true {
            return 1
        } else {
            return questions.count
        }
    }
    
    //MARK: Create a Header
    func createTableHeader() {
        //create constant to represent the header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 120))
        headerView.backgroundColor = UIColor().darkBlueColor()
        headerView.subviews.forEach({$0.removeFromSuperview()})
        
        //add a stack view to hold all of the labels
        let stackView = UIStackView(frame: CGRect(x: 5, y: 5, width: headerView.frame.width - 10, height: headerView.frame.height - 10))
        stackView.spacing = 10
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.arrangedSubviews.forEach({$0.removeFromSuperview()})
        
        //create a horizontal stack view to hold back and add button
        let horiStackView = UIStackView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 15))
        horiStackView.axis = .horizontal
        horiStackView.spacing = 10
        horiStackView.distribution = .fillEqually
        horiStackView.arrangedSubviews.forEach({$0.removeFromSuperview()})
        
        //create a back button
        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 10))
        backButton.setTitle("< Back", for: .normal)
        backButton.setTitleColor(.blue, for: .normal)
        backButton.titleLabel?.font = UIFont(name: "Copperplate", size: 15)
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 10
        backButton.layer.masksToBounds = true
        backButton.addTarget(self, action: #selector(backButtonFunc), for: .touchUpInside)
        
        //create a create question function
        let createButton = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 10))
        createButton.setTitle("Ask Question", for: .normal)
        createButton.setTitleColor(.blue, for: .normal)
        createButton.titleLabel?.font = UIFont(name: "Copperplate", size: 15)
        createButton.backgroundColor = .white
        createButton.layer.cornerRadius = 10
        createButton.layer.masksToBounds = true
        createButton.addTarget(self, action: #selector(presentQuestionUI), for: .touchUpInside)
        
        
        print("creating header")
        //if statement to determine if the classes are empty, or if the table is still oading
        if questions.isEmpty && hasCompletedDataCollection == true {
            //create a bool variable
            var flashIndicator: Bool = false
            
            //set timer to flash the ask question button
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
                print("timer on: \(flashIndicator)")
                
                //switch the flash indicator
                switch flashIndicator {
                case true:
                    createButton.backgroundColor = UIColor.white
                case false :
                    createButton.backgroundColor = UIColor.green
                }
                
                //toggle the variable
                flashIndicator.toggle()
            })
        } else {
            //invalidate the timer
            timer.invalidate()
        }
        
        //add the back and create button to the hori stack view
        horiStackView.addArrangedSubview(backButton)
        horiStackView.addArrangedSubview(createButton)
        
        //create a header label
        let headerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 25))
        headerLabel.font = UIFont(name: "Copperplate", size: 20)
        headerLabel.text = classNameLocal
        headerLabel.textColor = UIColor.white
        
        //create a subheader label to hold the number of questions
        let subHeaderLabel = UILabel(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 20))
        subHeaderLabel.font = UIFont(name: "Copperplate", size: 13)
        subHeaderLabel.textColor = UIColor.white
        subHeaderLabel.text = "Loading"
        subHeaderLabel.numberOfLines = 2
        subHeaderLabel.tag = 100
        
        //create a bottom label to hold instructions text
        let instructionsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 15))
        instructionsLabel.font = UIFont(name: "Copperplate", size: 10)
        instructionsLabel.textColor = .lightGray
        instructionsLabel.text = "(Tap on a question to view its responses)"
        instructionsLabel.numberOfLines = 2
        
        //add the labels to the stack view
        stackView.addArrangedSubview(horiStackView)
        stackView.addArrangedSubview(headerLabel)
        stackView.addArrangedSubview(subHeaderLabel)
        stackView.addArrangedSubview(instructionsLabel)
        
        //add the stack view to the main view
        headerView.addSubview(stackView)
        
        mainTableView.tableHeaderView = headerView
        
        //run function to update the number of questions
        questionNumberFunc()
    }
    
    //function to activate when the back button is pressed
    @objc func backButtonFunc() {
        self.dismiss(animated: true, completion: nil)
        
//        performSegue(withIdentifier: "backToRecentlyAsked", sender: self)
    }
    
    //MARK: ASK A QUESTION
    
    //function to activate when the create question button is pressed (DEPRECIATED)
//    @objc func createNewQuestion() {
//        //present a UI alert to get the title and the description of the question
//        let alert = UIAlertController(title: "Enter Your Question", message: nil, preferredStyle: .alert)
//
//        //create a cancel action
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//
//        //add a title text field
//        alert.addTextField { (field) in
//            field.font = UIFont(name: "Copperplate", size: 15)
//            field.placeholder = "The Title of Your Question"
//        }
//
//        alert.addTextField { (field) in
//            field.font = UIFont(name: "Copperplate", size: 15)
//            field.placeholder = "Some additional details"
//        }
//
//        //add a continue action
//        alert.addAction(UIAlertAction(title: "Ask!", style: .default, handler: { (action) in
//            //get representations of the text fields
//            let titleText = alert.textFields!.first?.text!
//            let detailsText = alert.textFields!.last?.text!
//
//            //determine if all fields were entered
//            if titleText == "" || detailsText == "" {
//                //present error
//                presentMessage(sender: self, title: "All Fields Required!", message: "Please enter the text for all the fields!")
//            } else {
//                //determine if the entered text passes explicative tests
//                if determineIfTextIsAppropriate(text: titleText!) == false || determineIfTextIsAppropriate(text: detailsText!) == false {
//                    //explicative detected
//                    presentMessage(sender: self, title: "Illegal Language!", message: "The text you entered contains illegal language!")
//                } else {
//                    //run function to create the question
//                    Questions().createQuestion(school: self.schoolName, forClass: self.classNameLocal, title: titleText!, text: detailsText!, UID: Auth.auth().currentUser!.uid, userName: Profile().getUserName()) { (error) in
//                        //run error check
//                        if error != nil {
//                            print(error!)
//                            //handle the error
//                            ErrorFunctions().handleQuestionErrors(sender: self, error: error!)
//                        } else {
//                            //show completion message
//                            presentMessage(sender: self, title: "Questions Submitted!", message: "Check back soon to see the responses!")
//
//                            self.getClassData {
//                                self.mainTableView.reloadData()
//                            }
//                        }
//                    }
//                }
//            }
//        }))
//
//        //present the alert
//        self.present(alert, animated: true, completion: nil)
//    }
    
    //function to present the UI to ask a question
    @objc func presentQuestionUI() {
        //create a background view
        let backgroundView: UIView = UIView(frame: self.view.frame)
        backgroundView.backgroundColor = UIColor.lightGray
        backgroundView.alpha = 1
        backgroundView.tag = 100
        
        //create a content view
        let contentView = UIView(frame: CGRect(x: 15, y: 35, width: backgroundView.frame.width - 30, height: backgroundView.frame.height - 70))
        contentView.backgroundColor = UIColor().blueColor()
        contentView.alpha = 1
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.tag = 99
        
        //create a stack view to hold all sub views
        let stackView = UIStackView(frame: CGRect(x: 5, y: 5, width: contentView.frame.width - 10, height: contentView.frame.height - 10))
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 15
        stackView.tag = 98
        
        //create a header view
        let headerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 35))
        headerLabel.font = UIFont(name: "Copperplate", size: 25)
        headerLabel.textColor = UIColor.label
        headerLabel.text = "Ask a Question."
        
        //create a text field to hold the title of the question
        let questionTitleField = UITextField(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 25))
        questionTitleField.borderStyle = .roundedRect
        questionTitleField.placeholder = "Title of Your Question"
        questionTitleField.font = UIFont(name: "Copperplate", size: 20)
        questionTitleField.tag = 1
        questionTitleField.delegate = self
        questionTitleField.backgroundColor = .clear
        
        //create a text field to hold the details for the question
        let questionDetailsField = UITextField(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 120))
        questionDetailsField.borderStyle = .roundedRect
        questionDetailsField.placeholder = "Some Details About Your Question"
        questionDetailsField.font = UIFont(name: "Copperplate", size: 15)
        questionDetailsField.tag = 2
        questionDetailsField.delegate = self
        questionDetailsField.backgroundColor = .clear
        
        //create stack view ot hold picture views
        let pictureStackView = UIStackView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 70))
        pictureStackView.axis = .horizontal
        pictureStackView.distribution = .fillEqually
        pictureStackView.spacing = 4
        
        //create button to add a picture
        let pictureButton = UIButton(frame: CGRect(x: 0, y: 0, width: stackView.frame.width/2 - 5, height: 70))
        pictureButton.setTitleColor(.white, for: .normal)
        pictureButton.setTitle("Add an Image", for: .normal)
        pictureButton.addTarget(self, action: #selector(setPicture(sender:)), for: .touchUpInside)
        
        //create a uiimageview to hold the image that will be attatched to the question
        let attachedImage = UIImageView(frame: CGRect(x: 0, y: 0, width: pictureStackView.frame.width/2 - 5, height: 70))
        attachedImage.contentMode = .scaleAspectFit
        attachedImage.tag = 5
        
        //create a horizontal stack view to hold the next buttons
        let horizontalStackView = UIStackView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 30))
        horizontalStackView.axis = .horizontal
        horizontalStackView.distribution = .fillEqually
        horizontalStackView.spacing = 10
        
        //create a button to cancel the function
        let cancelButton = UIButton(frame: CGRect(x: 0, y: 0, width: (horizontalStackView.frame.width/2) - 5, height: 30))
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.red, for: .normal)
        cancelButton.addTarget(self, action: #selector(dismissQuestionView(sender:)), for: .touchUpInside)
        
        //create a button to create the new question
        let questionButton = UIButton(frame: CGRect(x: 0, y: 0, width: (horizontalStackView.frame.width/2) - 5, height: 30))
        questionButton.setTitle("Ask!", for: .normal)
        questionButton.setTitleColor(.green, for: .normal)
        questionButton.addTarget(self, action: #selector(createNewQuestion2(sender:)), for: .touchUpInside)
        
        //add all views to their superviews
        pictureStackView.addArrangedSubview(pictureButton)
        pictureStackView.addArrangedSubview(attachedImage)
        
        horizontalStackView.addArrangedSubview(cancelButton)
        horizontalStackView.addArrangedSubview(questionButton)
        
        stackView.addArrangedSubview(headerLabel)
        stackView.addArrangedSubview(questionTitleField)
        stackView.addArrangedSubview(questionDetailsField)
        stackView.addArrangedSubview(pictureStackView)
        stackView.addArrangedSubview(horizontalStackView)
        
        contentView.addSubview(stackView)
        
        backgroundView.addSubview(contentView)
        
        self.view.addSubview(backgroundView)
    }
    
    //new function to create a question when the button is pressed
    @objc func createNewQuestion2(sender: UIButton) {
        //get representations of the appropriate labels
        let questionTitle = (sender.superview!.superview!.viewWithTag(1) as! UITextField).text!
        let questionDetails = (sender.superview!.superview!.viewWithTag(2) as! UITextField).text!
        
        //disable the buttons
        sender.superview?.subviews.forEach({(($0 as! UIButton).isEnabled = false)})
        
        //determine if all fields were entered
        if questionTitle == "" || questionDetails == "" {
            //present error
            presentMessage(sender: self, title: "All Fields Required!", message: "Please enter the text for all the fields!")
        } else {
            //determine if the entered text passes explicative tests
            if determineIfTextIsAppropriate(text: questionTitle) == false || determineIfTextIsAppropriate(text: questionDetails) == false {
                //explicative detected
                presentMessage(sender: self, title: "Illegal Language!", message: "The text you entered contains illegal language!")
            } else {
                //run function to create the question
                Questions().createQuestion(school: self.schoolName, forClass: self.classNameLocal, title: questionTitle, text: questionDetails, UID: Auth.auth().currentUser!.uid, userName: Profile().getUserName()) { (error) in
                    //run error check
                    if error != nil {
                        print(error!)
                        //handle the error
                        ErrorFunctions().handleQuestionErrors(sender: self, error: error!)
                    } else {
                       
                        
                        //determine if there is a picture
                        if self.newQuestionImage == nil {
                            print("without picture")
                            
                            self.dismissQuestionView(sender: sender)
                            
                            //show completion message
                            presentMessage(sender: self, title: "Questions Submitted!", message: "Check back soon to see the responses!")
                            
                            self.getClassData {
                                self.mainTableView.reloadData()
                            }
                        } else {
                            //upload the new picture
                            Questions().addPictureForQuestion(picture: self.newQuestionImage!, question: questionTitle, forClass: self.classNameLocal, forSchool: Profile().getUserSchoolName()) { (pictureError) in
                                if pictureError != nil {
                                    //handle error
                                    presentMessage(sender: self, title: "Picture Error", message: "The picture you submitted failed to upload. However, the question you asked was submitted.")
                                    print(error!)
                                    self.dismissQuestionView(sender: sender)
                                } else {
                                    //show completion message
                                    presentMessage(sender: self, title: "Questions Submitted!", message: "Check back soon to see the responses!")
                                    
                                    self.dismissQuestionView(sender: sender)
                                    
                                    //reset the table view
                                    self.getClassData {
                                        self.mainTableView.reloadData()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //function to get a picture for the question
    @objc func setPicture(sender: UIButton) {
        //create variable representing the image picker view
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        imageSender = sender
        
        //create an alert to ask to add from photos or take a photo
        let alert = UIAlertController(title: "Add a Picture", message: nil, preferredStyle: .alert)
        
        //create a cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //create action to take picture from camera
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (_) in
            //set appropriate info to present photo library
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            
            //present the picker view
            self.present(imagePicker, animated: true, completion: nil)
        }))
        
        //create an action to get picture from photos
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (_) in
            //set appropriate info to present photo library
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            
            //present the picker view
            self.present(imagePicker, animated: true, completion: nil)
        }))
        
        //present the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    var imageSender: UIButton!
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //dismiss the image picker
        picker.dismiss(animated: true, completion: nil)
        
        //ensure an image was returned
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            presentMessage(sender: self, title: "Error Getting Picture", message: "There was an error getting the picture. Please try again.")
            return
        }
        
        self.newQuestionImage = image
        
        presentMessage(sender: self, title: "Image Added", message: "The image will appear with your question")
        
        imageSender.superview!.subviews.forEach { (view) in
            if view.tag == 5 {
                (view as! UIImageView).image = image
            } else {
                print(view.tag)
            }
        }
    }
    
    //function to dismiss the question view
    @objc func dismissQuestionView(sender: UIButton) {
        //button > horistackview > mainStackview > contentview > backgroundview
        let backgroundView = sender.superview!.superview!.superview!.superview!
        backgroundView.removeFromSuperview()
    }
    
    //function to actiavte when a text field returns
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    //MARK: Number of Sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //MARK: Cell View Creation
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //create constant representing the table view cell
        let cell = UITableViewCell(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: tableView.rowHeight))
        
        //create constant representing the main view
        let view = UIView(frame: CGRect(x: 5, y: 5, width: self.view.frame.width - 10, height: mainTableView.rowHeight - 10))
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        
        //determine if the data has been collected and can display data
        if questions.isEmpty == true {
            //data has not been collected, will create on row to show a loading screen
            view.backgroundColor = UIColor.lightGray
            
            //create label to show the no questions message
            let label = UILabel(frame: CGRect(x: 5, y: 5, width: self.view.frame.width - 10, height: mainTableView.rowHeight - 10))
            label.font = UIFont(name: "Copperplate", size: 20)
            label.text = "No Questions Yet. Be the first to ask."
            label.numberOfLines = 2
            label.textColor = .black
            
            //add the label to the background view
            view.addSubview(label)
            
            //add the view to the tableview cell
            cell.addSubview(view)
            
            return cell
        } else {
            //data has been collected, show the questions
            
            view.backgroundColor = UIColor().blueColor()
            
            //create a vertical stack view
            let vertStackView = UIStackView(frame: CGRect(x: 5, y: 5, width: self.view.frame.width - 10, height: 60))
            vertStackView.axis = .vertical
            vertStackView.distribution = .fill
            vertStackView.spacing = 5
            
            //create a header label to show the text of the question
            let headerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: vertStackView.frame.width, height: tableView.rowHeight / 2 - 5))
            headerLabel.text = questions[indexPath.row].replacingOccurrences(of: "‰", with: ".")
            headerLabel.textAlignment = .left
            headerLabel.font = UIFont(name: "Copperplate", size: 20)
            
            //create a horizontal stack view to hold sub header info
            let horiStackView = UIStackView(frame: CGRect(x: 0, y: 0, width: vertStackView.frame.width, height: tableView.rowHeight / 2 - 10))
            horiStackView.axis = .horizontal
            horiStackView.distribution = .fillProportionally
            horiStackView.spacing = 10
            
            //create response count label
            let responseCount = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: horiStackView.frame.height))
            responseCount.font = UIFont(name: "Copperplate", size: 10)
            responseCount.textColor = .lightGray
            responseCount.text = responseCountFunc(row: indexPath.row)
            
            //create first response label
            let firstResponse = UILabel(frame: CGRect(x: 0, y: 0, width: horiStackView.frame.width - 50, height: horiStackView.frame.height))
            firstResponse.font = UIFont(name: "Copperplate", size: 13)
            firstResponse.textColor = .darkGray
            firstResponse.text = firstResponseFunc(row: indexPath.row)
            
            //add the response count and the response label to the horizontal stack view
            horiStackView.addArrangedSubview(responseCount)
            horiStackView.addArrangedSubview(firstResponse)
            
            //add the header label and the horizontal stack view to the vertical stack view
            vertStackView.addArrangedSubview(headerLabel)
            vertStackView.addArrangedSubview(horiStackView)
            
            //add the vertical stack view to the background view
            view.addSubview(vertStackView)
            
            //add the background view to the cell
            cell.addSubview(view)
            
            //return the tableview cell
            return cell
        }
    }
    
    //function to return text for the response count labels
    func responseCountFunc(row: Int) -> String {
        switch responses[row].count {
        case 0:
            return "No Responses!"
        case 1:
            return "1 Response!"
        default:
            return "\(responses[row].count) Responses"
        }
    }
    
    //function to return the first response in the array
    func firstResponseFunc(row: Int) -> String {
        switch responses[row].isEmpty {
        case true:
            return ""
        default:
            return responses[row].first!
        }
    }
    
    //function to return the number of questions
    func questionNumberFunc() {
        //create reference to the header view label
        let questionCountLabel = mainTableView.tableHeaderView!.viewWithTag(100)! as! UILabel
        
        //create variable to represent the text to send
        var text: String = ""
        
        switch questions.count {
        case 0:
            text = "No Questions Yet!"
        case 1:
            text = "1 Question"
        default:
            text = "\(questions.count) Questions"
        }
        
        questionCountLabel.text = text
    }
    
    //MARK: Header Creation
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //UNUSED, NO SECTIONS AS OF NOW
        return nil
    }
    
    
    //MARK: Row Selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //set the static variables
        QuestionController.className = classNameLocal
        QuestionController.questionName = questions[indexPath.row]
        
        //performm segue to the question controller
        self.performSegue(withIdentifier: "showQuestion", sender: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer.invalidate()
    }
}
