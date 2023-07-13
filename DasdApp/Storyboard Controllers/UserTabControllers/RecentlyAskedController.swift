//
//  TutorSectionsController.swift
//  DasdApp
//
//  Created by Ethan Miller on 10/13/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class RecentlyAskedController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var mainTableView: UITableView!
    
    //array to hold the names of the user classes
    var classes: [String] = []
    //array to hold the questions for each class
    var questions: [String: [String]] = [:]
    var responses: [String: [String]] = [:]
    
    var allowQuestionSetUp: BooleanLiteralType = false
    
    let storeRef = Firestore.firestore()
    
    //  MARK: VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()

        //set up data for the table view
        mainTableView.delegate = self
        mainTableView.dataSource = self
        mainTableView.separatorStyle = .none
        mainTableView.backgroundColor = UIColor().blueColor()
        mainTableView.rowHeight = 80
        mainTableView.sectionHeaderHeight = 60
        
        mainTableView.tableHeaderView = nil
        //run function to add a main header for the table view
        createMainHeader()
        
        //get the array of user classes
        classes = Profile().getArrayOfClasses()
        
        //remove cases in the class that say "None"
        classes.removeAll(where: {$0 == "None"})
        
        //disable the table
        self.mainTableView.allowsSelection = false
        
        //run function to pull complete list of questions their responses for the classes
        Questions().getQuestionsResponseArraysForClasses(school: Profile().getUserSchoolName(), forClasses: classes) { (foundQuestions, foundResponses, error) in
            //run error check
            if error != nil {
                //handle error
                print(error!)
                ErrorFunctions().handleQuestionErrors(sender: self, error: error!)
            } else {
                //enter for loop to reorganize the data
                for Class in self.classes {
                    //find the index of the class within the class array
                    let index = self.classes.firstIndex(of: Class)
                    
                    //get the questions for the class
                    let localQuestions: [String] = foundQuestions[index!]
                    
                    //set the data to the global arrays
                    self.questions[Class] = localQuestions
                    
                    //variable to represent the index of the response being analyzed
                    var responseIndex: Int = 0
                    
                    //enter for loop to get the responses to the correct section of array
                    for currentResponses in foundResponses[index!] {
                        self.responses["\(Class): \(self.questions[Class]![responseIndex])"] = currentResponses
                        
                        responseIndex += 1
                    }
                }
                
                print(self.questions)
                print(self.responses)
                self.mainTableView.reloadData()
                self.allowQuestionSetUp = true
                self.mainTableView.allowsSelection = true
            }
        }
    }
    
    //view idd appear
    override func viewDidAppear(_ animated: Bool) {
        //deterimine if the table has already been set up
        if allowQuestionSetUp == true {
            viewDidLoad()
        }
        
        //run if to determine if the tutorial has been shown before
        if UserDefaults.standard.value(forKey: "Tutorial/RecentlyAsked") as? Bool != true {
            //present the tutorial message
            presentMessageWithAction(sender: self, title: "Welcome to TAKT!", message: "Thank you for using TAKT, a new way to tutor. Here you can see the classes you sign up for and their recent questions. Tap on the name of a class to view all the questions for that class. Tap on a question to view all of its responses.", actionTitle: "Ok") {
                UserDefaults.standard.set(true, forKey: "Tutorial/RecentlyAsked")
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        mainTableView.reloadData()
    }
    
    //MARK: USER DATA COLLECTION
    
    //function to return the three most recent questions of a class, determined by section and row number
    func getRecentQuestionText(section: Int, row: Int) -> String {
        if allowQuestionSetUp == false {
            return "Loading..."
        } else {
            //get the string of the class from the section number
            let classFromSection = classes[section]
            
            //get all of the questions for the class
            let questionsFromClass = questions[classFromSection]!
            
            //determine the number of questions to determine if a question text can be returned
            if questionsFromClass.isEmpty {
                //questions is empty, there are no questions yet
                return "No Questions Yet!"
            } else if questionsFromClass.count == 1 {
                //only one question
                
                //use if statement to determine if a question string can be returned
                if row > 0 {
                    return "Not Enough Questions!"
                } else {
                    return questionsFromClass[row]
                }
            } else if questionsFromClass.count == 2 {
                //only two questions, run if statemnt to determine is a question text can be returned
                if row > 1 {
                    return "Not Enough Questions!"
                } else {
                    return questionsFromClass[row]
                }
            } else {
                //three or more questions, return questions according to row
                return questionsFromClass[row]
            }
        }
    }
    
    //function to take the question and row to return the number of responses
    func getResponseCounts(section: Int, row: Int, questionLabel: UILabel) -> String {
        //determine if load is allowed
        if allowQuestionSetUp == false {
            //not yet allowed, show loading sign
            return "Loading..."
        } else {
            //get the string to the class
            let currentClass = classes[section]
            
            //determine if the question label shows there is a question
            if questionLabel.text! == "Not Enough Questions!" || questionLabel.text! == "No Questions Yet!" {
                return "Question Does Not Exsist!"
            } else {
                //get the current question
                let currentQuestion: String = self.questions[currentClass]![row]
                
                //get the array of responses
                let responses: [String] = self.responses["\(currentClass): \(currentQuestion)"]!
                
                if responses.count == 1 {
                    return "1 Response"
                } else if responses.count == 0 {
                    return "No Responses!"
                }else {
                    return "\(responses.count) Responses"
                }
            }
        }
    }
    
    //MARK: TABLE VIEW FUNCTIONS
    //function to create a main header for the table view
    func createMainHeader() {
        //create representation of the main view
        let headerView = UITableViewHeaderFooterView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
        headerView.backgroundColor = UIColor.lightText
        headerView.`self`()
        
        //create main header label, as the label for the header view
        let headerLabel = headerView.textLabel!
        headerLabel.font = UIFont(name: "Copperplate", size: 25)
        headerLabel.text = "Recently Asked Questions"
        
        mainTableView.tableHeaderView = headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //switch the section to determine the class the questions are coming from
        let cell = UITableViewCell(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 80))
        
        //add a view to the cell
        let view = UIView(frame: CGRect(x: 5, y: 5, width: self.view.frame.width - 10, height: 70))
        view.backgroundColor = UIColor().blueColor()
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        
        //add a label to add to the view for the cell
        let label = UILabel(frame: CGRect(x: 5, y: 5, width: view.frame.width - 10, height: 20))
        label.font = UIFont(name: "Copperplate", size: 17)
        label.text = getRecentQuestionText(section: indexPath.section, row: indexPath.row)
        
        //add a sub label to the view
        let subLabel = UILabel(frame: CGRect(x: 5, y: 30, width: self.view.frame.width - 10, height: 20))
        subLabel.font = UIFont(name: "Copperplate", size: 15)
        subLabel.text = getResponseCounts(section: indexPath.section, row: indexPath.row, questionLabel: label)
        subLabel.textColor = .darkGray
        
        //add a sub sub label to the view
        let subSubLabel = UILabel(frame: CGRect(x: 5, y: 55, width: self.view.frame.width - 10, height: 15))
        subSubLabel.font = UIFont(name: "Copperplate", size: 7)
        subSubLabel.text = "(Tap to View Responses)"
        subSubLabel.textColor = UIColor.lightGray
        
        //add the labels to the main view
        view.addSubview(label)
        view.addSubview(subLabel)
        view.addSubview(subSubLabel)
        
        //run an if statement to determine if the the questions exsists, and hide appropriate labels
        if label.text == "No Questions Yet!" || label.text == "Not Enough Questions!" {
            subLabel.isHidden = true
            subSubLabel.isHidden = true
        }
        
        //add the view to the cell label
        cell.addSubview(view)
        
        //return the table cell
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return classes.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //create view to be the background for the header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
        headerView.backgroundColor = UIColor().darkBlueColor()
        headerView.isUserInteractionEnabled = true
        headerView.isMultipleTouchEnabled = true
        
        //create button to act as the title of the header, but interactive
        let titleButton = ClassButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 30))
        titleButton.setTitleColor(UIColor.white, for: .normal)
        titleButton.setTitle(classes[section], for: .normal)
        titleButton.titleLabel!.font = UIFont(name: "Copperplate", size: 20)
        //add target for the header
        titleButton.addTarget(self, action: #selector(classButtonPressed(sender:)), for: .touchUpInside)
        //set the ClassID for each button
        titleButton.ClassID = classes[section]
        
        //create sub header to hold sub header text
        let subHeader = UILabel(frame: CGRect(x: 0, y: 30, width: self.view.frame.width, height: 30))
        subHeader.textColor = UIColor.lightGray
        subHeader.text = "(Tap to View Class)"
        subHeader.font = UIFont(name: "Copperplate", size: 10)
        subHeader.textAlignment = .center
        
        //add title button and the sub header label to the background view
        headerView.addSubview(titleButton)
        headerView.addSubview(subHeader)
        
        //return the background view
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //find the class from the header section
        let selectedClass = classes[indexPath.section]
        
        //get the array of questions for the class
        let selectedQuestions = questions[selectedClass]
        
        print(selectedQuestions!.count, indexPath.row)
        
        //determine if there is a questions
        if selectedQuestions!.count < indexPath.row || selectedQuestions!.isEmpty {
            print("Not a question")
        } else {
            //get the name of the selected question
            let selectedQuestion = selectedQuestions![indexPath.row]
            
            //set the static variables
            QuestionController.className = selectedClass
            QuestionController.questionName = selectedQuestion
            
            //perform segue
            self.performSegue(withIdentifier: "showQuestionView", sender: self)
        }
    }
    
    
    //MARK: CLASS BUTTON PRESSED FUNCTIONS
    
    @objc func classButtonPressed(sender: ClassButton) {
        //constat to represent the class the button represents
        let classFromButton = sender.ClassID
        
        //set the class name to a static variable in the class class
        ClassController.className = classFromButton!
        
        //perform segue to the class view controller
        self.performSegue(withIdentifier: "showClassView", sender: self)
    }
}

//button class to hold a string to tell which class the button belongs to
class ClassButton: UIButton {
    var ClassID: String!
}
