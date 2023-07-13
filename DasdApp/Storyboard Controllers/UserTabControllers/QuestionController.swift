//
//  QuestionController.swift
//  DasdApp
//
//  Created by Ethan Miller on 12/25/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class QuestionController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var mainTableView: UITableView!
    
    //set static variables to transfer the string data
    static var className: String!
    static var questionName: String!
    
    var localClassName: String!
    var localQuestionName: String!
    
    var questionDetails: String!
    var questionTimestamp: String!
    var askedBy: String!
    var numberOfResponses: String!
    
    var arrayOfResponses: [String] = []
    var arrayOfApprovals: [String:String] = [:]
    var arrayOfAuthors: [String:String] = [:]
    var arrayOfTimeStamps: [String:String] = [:]
    
    
    var questionImage: UIImage?
    var newResponseImage: UIImage?
    var responseImage: UIImage?
    
    var isAllowedToSetUpTable: Bool = false
    
    let storeRef = Firestore.firestore()
    
    //MARK: VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()

        //set the delegate and the data source for the table view
        mainTableView.delegate = self
        mainTableView.dataSource = self
        mainTableView.rowHeight = 200
        mainTableView.separatorStyle = .none
        mainTableView.allowsSelection = false
        mainTableView.isUserInteractionEnabled = true
        mainTableView.isMultipleTouchEnabled = true
        
        //set the static variables to local variable
        localClassName = QuestionController.className
        localQuestionName = QuestionController.questionName
        
        isAllowedToSetUpTable = false
        
        //create table header
        createTableHeader()
        
        //run function to set up user info
        getUserInfo()
        
        //run function to set up the touch sensor for the author label
        addSensorToAuthorLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //run if to determine if the tutorial has been shown before
        if UserDefaults.standard.value(forKey: "Tutorial/Question") as? Bool != true {
            //present the tutorial message
            presentMessageWithAction(sender: self, title: "View The Question", message: "Here you can see the question, its details, and even its picture (if one was uploaded). You can also see all the responses to the question, and the pictures included with the responses (if one was uploaded). In addition, press on a user name to view the person's profile.", actionTitle: "Ok") {
                UserDefaults.standard.set(true, forKey: "Tutorial/Question")
            }
        }
    }
    
    //MARK: USER INFO COLLECTION
    func getUserInfo() {
        //disable table loading
        isAllowedToSetUpTable = false
        
        self.arrayOfApprovals.removeAll()
        self.arrayOfAuthors.removeAll()
        self.arrayOfResponses.removeAll()
        self.arrayOfTimeStamps.removeAll()
        
        
        //download information for the question
        storeRef.collection(Profile().getUserSchoolName()).document("Questions").collection(localClassName).document(localQuestionName).getDocument { (questionDocument, error) in
            //run error check
            if error != nil {
                print(error! as NSError)
                presentUnexpectedErrorMessage(sender: self)
            } else {
                //get essential data
                self.questionDetails = (questionDocument?.data()?["text"] as! String)
                self.askedBy = (questionDocument?.data()?["userName"] as! String)
                
                //run function to get the time stamp for the question
                Questions().getQuestionTimeStamp(school: Profile().getUserSchoolName(), forClass: self.localClassName, questionTitle: self.localQuestionName) { (questionTimeStampLocal, timeStampError) in
                    //run error check
                    if error != nil {
                        print(error! as NSError)
                        presentUnexpectedErrorMessage(sender: self)
                    } else {
                        //assign the question time stamp to the global time stamp
                        self.questionTimestamp = questionTimeStampLocal
                        
                        //run function to check for an image for the question
                        Questions().getPictureForQuestion(question: self.localQuestionName, forClass: self.localClassName, forSchool: Profile().getUserSchoolName()) { (image, error) in
                            if error != nil {
                                print(error! as NSError)
                            } else {
                                //determine if an image exsists
                                if image == nil {
                                    self.questionImage = nil
                                    print("no image")
                                } else {
                                    self.questionImage = image!
                                    print("image found!")
                                }
                                
                                self.mainTableView.tableHeaderView = nil
                                self.createTableHeader()
                            }
                        }
                    }
                }
                
                //run function to get the array of responses
                Questions.Responses().getArrayOfResponses(school: Profile().getUserSchoolName(), forClass: self.localClassName, questionTitle: self.localQuestionName) { (responses, error, _) in
                    //run error check
                    if error != nil {
                        print(error!)
                        ErrorFunctions().handleQuestionErrors(sender: self, error: error!)
                    } else {
                        //assign the responses to the local variable
                        self.arrayOfResponses = responses
                        self.numberOfResponses = String(responses.count)
                        
                        //enter for loop to get the time stamp of the responses
                        for response in responses {
                            //get information from the response, first the time stamp
                            Questions.Responses().getTimeStamp(school: Profile().getUserSchoolName(), forClass: self.localClassName, questionTitle: self.localQuestionName, responseText: response) { (responseStamp, responseError, responseText) in
                                //run error check
                                if responseError != nil {
                                    //handle error
                                    print(responseError!)
                                    ErrorFunctions().handleQuestionErrors(sender: self, error: responseError!)
                                } else {
                                    //find the timestamp and add to the organized array
                                    self.arrayOfTimeStamps[responseText] = responseStamp
                                    
                                    //run function to get the user name
                                    Questions.Responses().getUserName(school: Profile().getUserSchoolName(), forClass: self.localClassName, questionTitle: self.localQuestionName, responseText: response) { (userName, userNameError, authorResponse) in
                                        //run error check
                                        if error != nil {
                                            print(userNameError!)
                                            ErrorFunctions().handleQuestionErrors(sender: self, error: userNameError!)
                                        } else {
                                            //find the name of the author user, and add to the organized array
                                            self.arrayOfAuthors[authorResponse] = userName
                                            
                                            //run program to get the array of teacher approvals
                                            Questions.Responses().getTeacherApprovals(school: Profile().getUserSchoolName(), forClass: self.localClassName, questionTitle: self.localQuestionName, responseTitle: response) { (teacherApprovals, approvalResponse) in
                                                //determine the number approvals, to send a different message
                                                if teacherApprovals.isEmpty {
                                                    print("no approvals")
                                                    self.arrayOfApprovals[approvalResponse] = ""
                                                } else if teacherApprovals.count == 1 {
                                                    self.arrayOfApprovals[approvalResponse] = "Approved by- \(teacherApprovals.first!)"
                                                } else {
                                                    self.arrayOfApprovals[approvalResponse] = "Approved by- \(teacherApprovals.first!) and \(teacherApprovals.count-1) other teacher(s)"
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        //activate timer to detect is functions are done
                        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
                            if self.arrayOfApprovals.count == responses.count {
                                //print the found data
                                print(self.questionDetails!, self.questionTimestamp!, self.askedBy!, self.numberOfResponses!)
                                print(self.arrayOfResponses, self.arrayOfTimeStamps, self.arrayOfAuthors, self.arrayOfApprovals)
                                
                                //allow the table to set up and set it
                                self.isAllowedToSetUpTable = true
                                self.mainTableView.reloadData()
                                
                                //reset the header
                                self.mainTableView.tableHeaderView = nil
                                self.createTableHeader()
                                
                                //invalidate the timer
                                timer.invalidate()
                            } else {
                                print("waiting", self.arrayOfApprovals.count, responses.count)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    //function to add a touch sensor to the author label
    func addSensorToAuthorLabel() {
        print("adding sensor label")
        
        //create a sensor, add to a constant
        let sensor = UITapGestureRecognizer(target: self, action: #selector(authorSensorActivated(sender:)))
        
        //add the sensor to the label
        (mainTableView.tableHeaderView!.viewWithTag(98) as! UIStackView).viewWithTag(99)!.isUserInteractionEnabled  = true
        (mainTableView.tableHeaderView!.viewWithTag(98) as! UIStackView).viewWithTag(99)!.isMultipleTouchEnabled = true
        (mainTableView.tableHeaderView!.viewWithTag(98) as! UIStackView).viewWithTag(99)!.addGestureRecognizer(sensor)
    }
    
    //function to be activated when the author label sensor is activated
    @objc func authorSensorActivated(sender: UITapGestureRecognizer) {
        //get the text from the view
        let authorName = (sender.view! as! UILabel).text!
        
        print("author label pressed")
        
        //set the static variable for the name of the user
        OtherProfileController.userNameTransfer = authorName
        OtherProfileController.questionNameTransfer = localQuestionName
        
        //perform segue to the other profile
        self.performSegue(withIdentifier: "showProfile", sender: self)
    }
    
    //MARK: TABLE VIEW FUNCTIONS
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //run if to see if the table can be set up yet
        if isAllowedToSetUpTable == true {
            return arrayOfResponses.count
        } else {
            return 0
        }
    }
    
    //MARK: Create Table Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //set constant to represent the table view cell
        let tableViewCell = UITableViewCell(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 140))
        //set the background for the view cell
        tableViewCell.backgroundColor = .secondarySystemBackground
        tableViewCell.isUserInteractionEnabled = true
        tableViewCell.isMultipleTouchEnabled = true
        
        //create constant for the background view
        let backgroundView = UIView(frame: CGRect(x: 5, y: 5, width: self.view.frame.width - 10, height: tableView.rowHeight - 10))
        //add the corner radius to the background view
        backgroundView.layer.cornerRadius = 15
        backgroundView.layer.masksToBounds = true
        backgroundView.isUserInteractionEnabled = true
        backgroundView.isMultipleTouchEnabled = true
        
        //enter if statement to see if the table view can be set up yet
        if isAllowedToSetUpTable == false {
            //set the background for the background view
            backgroundView.backgroundColor = UIColor.lightGray
            
            //create a label to show error message
            let label = UILabel(frame: CGRect(x: 5, y: 5, width: backgroundView.frame.width - 10, height: backgroundView.frame.width - 10))
            label.font = UIFont(name: "Copperplate", size: 20)
            label.textColor = .systemBackground
            label.text = ""
            
            //add the label to the background view
            backgroundView.addSubview(label)
            
            tableViewCell.addSubview(backgroundView)
            
            return tableViewCell
        } else {
            //enter if statement to see if there are any responses
            if arrayOfResponses.isEmpty {
                //set the background for the background view
                backgroundView.backgroundColor = .lightGray
                
                //create label to show error message
                let label = UILabel(frame: CGRect(x: 6, y: 6, width: backgroundView.frame.width - 10, height: tableView.rowHeight - 10))
                label.font = UIFont(name: "Copperplate", size: 20)
                label.textColor = .systemBackground
                label.numberOfLines = 3
                label.text = "No Responses! Help someone out and be the first to answer!"
                
                //add the label to the background view
                backgroundView.addSubview(label)
            } else {
                //set the background color for the view
                backgroundView.backgroundColor = UIColor().blueColor()
                
                //create a stack view to hold the information
                let vertStackView = UIStackView(frame: CGRect(x: 5, y: 5, width: backgroundView.frame.width - 10, height: tableView.rowHeight - 20))
                vertStackView.distribution = .fill
                vertStackView.spacing = 7
                vertStackView.axis = .vertical
                vertStackView.isUserInteractionEnabled = true
                vertStackView.isMultipleTouchEnabled = true
                
                //create a header label
                let headerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: vertStackView.frame.width, height: 25))
                headerLabel.font = UIFont(name: "Copperplate", size: 17)
                headerLabel.textColor = .systemBackground
                headerLabel.numberOfLines = 8
                //use the text in the header label to be able to
                headerLabel.text = arrayOfResponses[indexPath.row]
                headerLabel.tag = 200
                
                //create a horizontal stack view to hold the time label and the author lavel
                let horizontalStackView = UIStackView(frame: CGRect(x: 0, y: 0, width: vertStackView.frame.width, height: 20))
                horizontalStackView.axis = .horizontal
                horizontalStackView.distribution = .fillProportionally
                horizontalStackView.spacing = 5
                horizontalStackView.isUserInteractionEnabled = true
                horizontalStackView.isMultipleTouchEnabled = true
                
                //create label to show the time of the responses
                let timeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: vertStackView.frame.width/2, height: 15))
                timeLabel.font = UIFont(name: "Copperplate", size: 15)
                timeLabel.textColor = .systemGray
                timeLabel.text = arrayOfTimeStamps[headerLabel.text!]
                
                //create a touch sensor to add to the author label
                let sensor = UITapGestureRecognizer(target: self, action: #selector(cellAuthorLabelPressed(sender:)))
                
                //create label to hold the author text
                let authorLabel = UILabel(frame: CGRect(x: 0, y: 0, width: vertStackView.frame.width/2, height: 15))
                authorLabel.font = UIFont(name: "Takttutoring", size: 15)
                authorLabel.textColor = .systemGray
                authorLabel.textAlignment = .right
                authorLabel.attributedText = NSAttributedString(string: arrayOfAuthors[headerLabel.text!]!, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
                authorLabel.isUserInteractionEnabled = true
                authorLabel.isMultipleTouchEnabled = true
                authorLabel.addGestureRecognizer(sensor)
                
                //create a button that allows teachers to give their approval
                let teacherApprovalButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 15))
                teacherApprovalButton.setTitle("Approve", for: .normal)
                teacherApprovalButton.setTitleColor(.green, for: .normal)
                teacherApprovalButton.titleLabel?.font = UIFont(name: "system", size: 12)
                //set the target
                teacherApprovalButton.addTarget(self, action: #selector(teacherApprovalButton(sender:)), for: .touchUpInside)
                
                //create a button that allows the teacher to remove a response
                let teacherRemovalButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 15))
                teacherRemovalButton.setTitleColor(.red, for: .normal)
                teacherRemovalButton.setTitle("Remove", for: .normal)
                teacherRemovalButton.titleLabel?.font = UIFont(name: "system", size: 12)
                //set a target
                teacherRemovalButton.addTarget(self, action: #selector(teacherRemovalButton(sender:)), for: .touchUpInside)
                
                //determine if the user is a teacher
                if Profile().getTeacherStatus() == true {
                    //add the teacher approval button
                    horizontalStackView.addArrangedSubview(teacherApprovalButton)
                }
                
                //add the labels to the first horizontal stack view
                horizontalStackView.addArrangedSubview(timeLabel)
                horizontalStackView.addArrangedSubview(authorLabel)
                
                //determine if the user is a teacher to add the removal button
                if Profile().getTeacherStatus() == true {
                    //add the teacher remocal button
                    horizontalStackView.addArrangedSubview(teacherRemovalButton)
                }
                
                //add a button to check if there is an image attached to the response
                let imageButton = UIButton(frame: CGRect(x: 0, y: 0, width: vertStackView.frame.width, height: 15))
                imageButton.setTitleColor(.lightGray, for: .normal)
                imageButton.setTitle("View Response Image", for: .normal)
                imageButton.tag = indexPath.row
                imageButton.titleLabel?.font = UIFont(name: "Copperplate", size: 10)
                imageButton.addTarget(self, action: #selector(presentImage(sender:)), for: .touchUpInside)
                
                
                //add the views to the vertical stack view
                vertStackView.addArrangedSubview(headerLabel)
                vertStackView.addArrangedSubview(horizontalStackView)
                vertStackView.addArrangedSubview(imageButton)
                
                //first, determine if the user is not a teacher
                if Profile().getTeacherStatus() == false {
                    //determine if there was any teacher approval for this response
                    if arrayOfApprovals[headerLabel.text!]?.isEmpty == false && arrayOfApprovals[headerLabel.text!] != "" {
                        //create a label to hold the approval
                        let approvalLabel = UILabel(frame: CGRect(x: 0, y: 0, width: vertStackView.frame.width, height: 20))
                        approvalLabel.font = UIFont(name: "Takttutoring", size: 10)
                        approvalLabel.textColor = UIColor.green
                        approvalLabel.text = arrayOfApprovals[headerLabel.text!]
                        
                        //add to the stack view
                        vertStackView.addArrangedSubview(approvalLabel)
                    }
                }
                
                
                //add vert stack view to the background view
                backgroundView.addSubview(vertStackView)
            }
        }
        
        //add the background view to the table view cell
        tableViewCell.addSubview(backgroundView)
        
        return tableViewCell
    }
    
    //function to activate when the author label for a cell is pressed
    @objc func cellAuthorLabelPressed(sender: UITapGestureRecognizer) {
        //get representation of the text that the label showed
        let text = (sender.view! as! UILabel).text!
        
        //set the static variable for the other profile controller
        OtherProfileController.userNameTransfer = text
        
        //get representation to the vert stack view for the
        let vertStackView = sender.view!.superview!.superview!
        
        //get representation to the header label
        var headerLabel: UILabel!
        
        vertStackView.subviews.forEach( { if $0.tag == 200 {headerLabel = ($0 as! UILabel)} })
        
        //get representation of the response, from the label
        let responseText = headerLabel.text!
        
        //set the static variables
        OtherProfileController.responseNameTransfer = responseText
        OtherProfileController.questionNameTransfer = localQuestionName
        OtherProfileController.classNameTransfer = localClassName
        
        //perform segue to the other profile controller
        self.performSegue(withIdentifier: "showProfile", sender: self)
    }
    
    
    //function to activate when the teacher approval button is pressed
    @objc func teacherApprovalButton(sender: UIButton) {
        //get the header label
        var headerLabel: UILabel!
        
        sender.superview!.superview!.subviews.forEach({if $0.tag == 200 {headerLabel = ($0 as! UILabel)} })
        
        //get the title of the response
        let responseText = headerLabel.text!
        
        //run function to determine if the question already has the teachers reccomendation
        Questions.Responses().getTeacherApprovals(school: Profile().getUserSchoolName(), forClass: self.localClassName, questionTitle: self.localQuestionName, responseTitle: responseText) { (teacherApprovals, _) in
            if teacherApprovals.contains(Profile().getUserName()) {
                presentMessage(sender: self, title: "Already Approved!", message: "You've already given your approval for this question!")
                
                sender.isHidden = true
            } else {
                //does not contain the teacher name, continue with function
                //run function to set the teacher approval
                Questions.Responses().setApproval(school: Profile().getUserSchoolName(), forClass: self.localClassName, questionTitle: self.localQuestionName, responseTitle: responseText, teacherName: Profile().getUserName())
                
                sender.isHidden = true
                
                //send completion message
                presentMessage(sender: self, title: "Response Approved.", message: "Now when other students see this response they will see that you have personally approved it.")
            }
        }
    }
    
    //function to activate when the teacher removal button is pressed
    @objc func teacherRemovalButton(sender: UIButton) {
        //get the header label
        var headerLabel: UILabel!
        
        sender.superview!.superview!.subviews.forEach({if $0.tag == 200 {headerLabel = ($0 as! UILabel)} })
        
        //get the title of the response
        let responseText = headerLabel.text!
        
        //create connection to the question main info
        Firestore.firestore().collection(Profile().getUserSchoolName()).document("Questions").collection(self.localClassName).document(self.localQuestionName).getDocument { (document, error) in
            //run an error check
            if error != nil {
                print(error! as NSError)
                presentUnexpectedErrorMessage(sender: self)
            } else {
                //download the list of responses
                var responses = document?.data()?["arrayOfResponses"] as! [String]
                
                //get the index of the response that was pressed
                guard let index = responses.firstIndex(of: responseText) else {
                    //no index found, present error
                    presentMessage(sender: self, title: "Unexpected Error!", message: "The response was not found. Or may have already been deleted")
                    return
                }
                
                //remove the response at the found index
                responses.remove(at: index)
                
                //upload the new array of response
                Firestore.firestore().collection(Profile().getUserSchoolName()).document("Questions").collection(self.localClassName).document(self.localQuestionName).updateData(["arrayOfResponses":responses]) { (error) in
                    if error != nil {
                        presentUnexpectedErrorMessage(sender: self)
                    } else {
                        presentMessage(sender: self, title: "Response Deleted", message: "The response has been deleted, students will no longer be able to see it when they view this question.")
                        
                        sender.isHidden = true
                        
                        self.mainTableView.reloadData()
                    }
                }
            }
        }
        
    }
    
    
    //MARK: Create Table Header
    func createTableHeader() {
        //create view to hold the header
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 230))
        backgroundView.backgroundColor = UIColor().darkBlueColor()
        backgroundView.isUserInteractionEnabled = true
        backgroundView.isMultipleTouchEnabled = true
        
        //create a vertical stack view
        let verticalStackView: UIStackView = UIStackView(frame: CGRect(x: 5, y: 5, width: backgroundView.frame.width - 10, height: backgroundView.frame.height - 10))
        verticalStackView.axis = .vertical
        verticalStackView.distribution = .fill
        verticalStackView.spacing = 5
        verticalStackView.tag = 98
        verticalStackView.isUserInteractionEnabled = true
        verticalStackView.isMultipleTouchEnabled = true
        
        //create a horizontal stack view to hold the back button and the response button
        let horizontalStackView = UIStackView(frame: CGRect(x: 0, y: 0, width: verticalStackView.frame.width, height: 20))
        horizontalStackView.axis = .horizontal
        horizontalStackView.distribution = .fillEqually
        horizontalStackView.spacing = 10
        
        //create a back button
        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: horizontalStackView.frame.width/2, height: 20))
        backButton.backgroundColor = .white
        backButton.setTitleColor(.blue, for: .normal)
        backButton.setTitle("< Back", for: .normal)
        backButton.titleLabel?.font = UIFont(name: "Copperplate", size: 15)
        backButton.addTarget(self, action: #selector(backButtonFunc), for: .touchUpInside)
        backButton.layer.cornerRadius = 10
        backButton.layer.masksToBounds = true
        
        //create a response button
        let responseButton = UIButton(frame: CGRect(x: 0, y: 0, width: horizontalStackView.frame.width/2, height: 20))
        responseButton.backgroundColor = .white
        responseButton.setTitleColor(.blue, for: .normal)
        responseButton.setTitle("Answer Question!", for: .normal)
        responseButton.titleLabel?.font = UIFont(name: "Copperplate", size: 15)
        responseButton.addTarget(self, action: #selector(presentUIForResponse), for: .touchUpInside)
        responseButton.layer.cornerRadius = 10
        responseButton.layer.masksToBounds = true
        
        //add the buttons to the horizonal stack view
        horizontalStackView.addArrangedSubview(backButton)
        horizontalStackView.addArrangedSubview(responseButton)
        
        //create a header view to hold the question title
        let headerLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: verticalStackView.frame.width, height: 40))
        headerLabel.font = UIFont(name: "Copperplate", size: 20)
        headerLabel.textColor = .white
        headerLabel.text = localQuestionName.replacingOccurrences(of: "‰", with: ".")
        headerLabel.numberOfLines = 4
        
        //create a sub header to show the sub text of the question
        let subHeaderLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: verticalStackView.frame.width, height: 40))
        subHeaderLabel.font = UIFont(name: "Copperplate", size: 15)
        subHeaderLabel.textColor = .white
        subHeaderLabel.text = questionDetails
        subHeaderLabel.numberOfLines = 8
        
        //create another sub header to show who asked the question
        let authorLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: verticalStackView.frame.width, height: 10))
        authorLabel.font = UIFont(name: "Takttutoring", size: 12)
        authorLabel.textColor = .white
        authorLabel.tag = 99
        authorLabel.isUserInteractionEnabled = true
        authorLabel.isMultipleTouchEnabled = true
        if isAllowedToSetUpTable == true {
            authorLabel.attributedText = NSAttributedString(string: "Asked by- \(askedBy!)", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        } else {
            authorLabel.text = "Loading..."
        }
        
        //create another label to hold the time the question was asked
        let timeLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: verticalStackView.frame.width, height: 10))
        timeLabel.font = UIFont(name: "Copperplate", size: 12)
        timeLabel.textColor = .white
        timeLabel.text = questionTimestamp
        
        //add all of the labels and stack view to vert stack view
        verticalStackView.addArrangedSubview(horizontalStackView)
        verticalStackView.addArrangedSubview(headerLabel)
        verticalStackView.addArrangedSubview(subHeaderLabel)
        verticalStackView.addArrangedSubview(authorLabel)
        verticalStackView.addArrangedSubview(timeLabel)
        
        //create a button to view the image for the question, if the image exsits
        if questionImage != nil {
            let imageButton = UIButton(frame: CGRect(x: 0, y: 0, width: verticalStackView.frame.width, height: 30))
            imageButton.setTitleColor(.lightGray, for: .normal)
            imageButton.setTitle("View Image", for: .normal)
            imageButton.titleLabel?.font = UIFont(name: "Copperplate", size: 15)
            imageButton.tag = -1
            imageButton.addTarget(self, action: #selector(presentImage(sender:)), for: .touchUpInside)
            verticalStackView.addArrangedSubview(imageButton)
        }
        
        //add the stack view to background view
        backgroundView.addSubview(verticalStackView)
        
        //add the background view to the table view
        mainTableView.tableHeaderView = backgroundView
    }
    
    //MARK: BUTTON FUNCTIONS
    @objc func backButtonFunc() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //function to show an image in a view
    @objc func presentImage(sender: UIButton) {
        //create a view to be the background for the content
        let backgroundView = UIView(frame: CGRect(x: 15, y: 50, width: self.view.frame.width - 30, height: self.view.frame.height - 100))
        backgroundView.backgroundColor = UIColor().blueColor()
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = 15
        backgroundView.layer.masksToBounds = false
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowRadius = 15
        backgroundView.layer.shadowOpacity = 1
        
        //create an excape button
        let escapeButton = UIButton(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        escapeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        escapeButton.addTarget(self, action: #selector(dismissImageView(sender:)), for: .touchUpInside)
        
        //create an image view to hold the image
        let imageView = UIImageView(frame: CGRect(x: 15, y: 20, width: backgroundView.frame.width - 30, height: backgroundView.frame.height - 30))
        imageView.contentMode = .scaleAspectFit
        
        //create if statement to determine which image to show, -1 is the question, all others are the index of the response
        if sender.tag == -1 {
            //show question image
            imageView.image = questionImage!
        } else {
            //get the title of the response, the index of the response is the tag of the button
            let response = arrayOfResponses[sender.tag]
            
            //get the image
            Questions.Responses().getPictureForResponse(forSchool: Profile().getUserSchoolName(), forClass: localClassName, forQuestion: localQuestionName, forResponse: response) { (image, error) in
                //check for an error
                if error != nil {
                    ErrorFunctions().handleFirebaseStorageError(sender: self, error: error!)
                    backgroundView.removeFromSuperview()
                } else {
                    //determine if an image was returned
                    if image == nil {
                        presentMessage(sender: self, title: "No Image Found", message: "Sorry, but it appears that this response does not have an image attached to it")
                        backgroundView.removeFromSuperview()
                    } else {
                        //set the image
                        imageView.image = image!
                    }
                }
            }
        }
        
        //add everything to their superviews
        backgroundView.addSubview(escapeButton)
        backgroundView.addSubview(imageView)
        
        self.view.addSubview(backgroundView)
    }
    
    //function to make the image view disappear
    @objc func dismissImageView(sender: UIButton) {
        //the buttons super view is the background view, remove it
        sender.superview!.removeFromSuperview()
    }
    
    //MARK: RESPONSE CREATION
    //function to create a new response !!DEPRECIATED!!
//    @objc func createResponses() {
//        //create a UI alert to ask the user for their response
//        let alert = UIAlertController(title: "Type your response!", message: nil, preferredStyle: .alert)
//
//        //add a cancel action
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//
//        //add a text field
//        alert.addTextField { (textField) in
//            textField.font = UIFont(name: "Copperplate", size: 15)
//        }
//
//        //add action to add the response action
//        alert.addAction(UIAlertAction(title: "Send Response!", style: .default, handler: { (action) in
//            //get a local variable to represent the entered text, determine if text was entered
//            guard let responseText: String = alert.textFields?.first?.text else {
//                presentMessage(sender: self, title: "Enter a Response!", message: nil)
//                return
//            }
//
//            //determine if any illegal text was entered
//            if determineIfTextIsAppropriate(text: responseText) == false {
//                presentMessage(sender: self, title: "Inappropriate Text Detected!", message: nil)
//            } else {
//                //run function to create the response
//                Questions.Responses().createResponse(school: Profile().getUserSchoolName(), forClass: self.localClassName, questionTitle: self.localQuestionName, responseText: responseText, userUID: Auth.auth().currentUser!.uid, userName: Profile().getUserName()) { (error) in
//                    //run an error check
//                    if error != nil {
//                        //handle error
//                        print(error!)
//                        ErrorFunctions().handleQuestionErrors(sender: self, error: error!)
//                    } else {
//                        //show completion message, reset the table view
//                        presentMessage(sender: self, title: "Response Submitted", message: "Thanks for answering someone's question!")
//
//                        //reset the view
//                        self.getUserInfo()
//                    }
//                }
//            }
//        }))
//
//        //present the alert
//        self.present(alert, animated: true, completion: nil)
//    }
    
    @objc func presentUIForResponse() {
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
        headerLabel.numberOfLines = 4
        headerLabel.text = "Respond to \(askedBy!)'s Question"
        
        //create a text field to hold the title of the question
        let questionTitleField = UITextField(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 25))
        questionTitleField.borderStyle = .roundedRect
        questionTitleField.placeholder = "Your Response"
        questionTitleField.font = UIFont(name: "Copperplate", size: 20)
        questionTitleField.tag = 1
        questionTitleField.delegate = self
        questionTitleField.backgroundColor = .clear
        
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
        cancelButton.addTarget(self, action: #selector(dismissResponseView(sender:)), for: .touchUpInside)
        
        //create a button to create the new question
        let questionButton = UIButton(frame: CGRect(x: 0, y: 0, width: (horizontalStackView.frame.width/2) - 5, height: 30))
        questionButton.setTitle("Send!", for: .normal)
        questionButton.setTitleColor(.green, for: .normal)
        questionButton.addTarget(self, action: #selector(createResponses2(sender:)), for: .touchUpInside)
        
        //add all views to their superviews
        pictureStackView.addArrangedSubview(pictureButton)
        pictureStackView.addArrangedSubview(attachedImage)
        
        horizontalStackView.addArrangedSubview(cancelButton)
        horizontalStackView.addArrangedSubview(questionButton)
        
        stackView.addArrangedSubview(headerLabel)
        stackView.addArrangedSubview(questionTitleField)
        stackView.addArrangedSubview(pictureStackView)
        stackView.addArrangedSubview(horizontalStackView)
        
        contentView.addSubview(stackView)
        
        backgroundView.addSubview(contentView)
        
        self.view.addSubview(backgroundView)
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
        
        self.newResponseImage = image
        
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
    @objc func dismissResponseView(sender: UIButton) {
        //button > horistackview > mainStackview > contentview > backgroundview
        let backgroundView = sender.superview!.superview!.superview!.superview!
        backgroundView.removeFromSuperview()
    }
       
    //function to actiavte when a text field returns
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    //MARK: NEW RESPONSE CREATION FUNC
    @objc func createResponses2(sender: UIButton) {
        //get representations of the appropriate labels
        let responseTitle = (sender.superview!.superview!.viewWithTag(1) as! UITextField).text!
        
        //disable the buttons
        sender.superview?.subviews.forEach({(($0 as! UIButton).isEnabled = false)})
        
        //determine if any illegal text was entered
        if determineIfTextIsAppropriate(text: responseTitle) == false {
            presentMessage(sender: self, title: "Inappropriate Text Detected!", message: nil)
        } else {
            //run function to create the response
            Questions.Responses().createResponse(school: Profile().getUserSchoolName(), forClass: self.localClassName, questionTitle: self.localQuestionName, responseText: responseTitle, userUID: Auth.auth().currentUser!.uid, userName: Profile().getUserName()) { (error) in
                //run an error check
                if error != nil {
                    //handle error
                    print(error!)
                    ErrorFunctions().handleQuestionErrors(sender: self, error: error!)
                } else {
                    //determine if there was a picture with the upload
                    if self.newResponseImage == nil {
                        //show completion message, reset the table view
                        presentMessage(sender: self, title: "Response Submitted", message: "Thanks for answering someone's question!")
                        self.getUserInfo()
                        self.dismissResponseView(sender: sender)
                        
                        //run function to determine if the response is attempting to access the mathbot
                        Bots.MathBot().determineEditingText(forSchool: Profile().getUserSchoolName(), forClass: self.localClassName, forQuestion: self.localQuestionName, text: responseTitle)
                    } else {
                        //upload the new image
                        Questions.Responses().addPictureForResponse(forSchool: Profile().getUserSchoolName(), forClass: self.localClassName, forQuestion: self.localQuestionName, forResponse: responseTitle, image: self.newResponseImage!) { (error) in
                            if error != nil {
                                //present error message, then reset the table view
                                presentMessage(sender: self, title: "Image Error", message: "There was an issue uploading your image. However, the question successfully uploaded.")
                                
                                self.getUserInfo()
                                self.dismissResponseView(sender: sender)
                            } else {
                                //show completion message, reset the table view
                                presentMessage(sender: self, title: "Response Submitted", message: "Thanks for answering someone's question! With a picture.")
                                self.getUserInfo()
                                self.dismissResponseView(sender: sender)
                            }
                        }
                    }
                }
            }
        }
    }
}
