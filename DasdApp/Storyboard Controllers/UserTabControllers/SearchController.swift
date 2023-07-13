//
//  SearchController.swift
//  DasdApp
//
//  Created by Ethan Miller on 10/13/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import UIKit

class SearchController: CustomViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var mainTableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    //variable to represent the classes of the user
    var classes = Profile().getArrayOfClasses()
    
    var localQuestions: [[String]] = []
    var localResponses: [[[String]]] = []
    
    var matchedQuestions: [String] = []
    var matchedQuestionsWithClass: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.systemBackground
        
        mainTableView.delegate = self
        mainTableView.dataSource = self
        mainTableView.rowHeight = 60
        mainTableView.backgroundColor = UIColor.systemBackground
        mainTableView.separatorStyle = .none
        
        searchBar.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getUserInfo()
    }
    
    func getUserInfo() {
        print(classes)
        
        classes.removeAll(where: {($0 == "None")})
        
        //disable the search bar
        searchBar.text = nil
        searchBar.placeholder = "Loading..."
        searchBar.isUserInteractionEnabled = false
        
        //get arrays of the questions and responses that for all the classes the user belongs to
        Questions().getQuestionsResponseArraysForClasses(school: Profile().getUserSchoolName(), forClasses: classes) { (questions, responses, error) in
            //see if there was an error
            if error != nil {
                //handle error
                print(error!)
                ErrorFunctions().handleQuestionErrors(sender: self, error: error!)
            } else {
                //complete, indexes match. (ex index 1 for each array has the questions and responses for the class that is index 1 in the classes array)
                //set data to local variables
                self.localQuestions = questions
                self.localResponses = responses
                
                self.searchBar.placeholder = "Search Questions in Your Classes"
                self.searchBar.isUserInteractionEnabled = true
            }
        }
    }
    
    //function to return the number of rows in the search bar
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchedQuestions.count
    }
    
    //function to set up the table cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = matchedQuestions[indexPath.row]
        
        //create a background view
        let backgroundView = UIView(frame: CGRect(x: 2.5, y: 2.5, width: self.view.frame.width - 5, height: mainTableView.rowHeight - 5))
        backgroundView.backgroundColor = UIColor().darkBlueColor()
        backgroundView.layer.cornerRadius = 15
        backgroundView.layer.masksToBounds = true
        
        //create a label to hold the results
        let resultsLabel = UILabel(frame: CGRect(x: 2.5, y: 2.5, width: backgroundView.frame.width - 5, height: backgroundView.frame.height - 5))
        resultsLabel.textColor = UIColor.white
        resultsLabel.font = UIFont(name: "Copperplate", size: 12)
        resultsLabel.numberOfLines = 3
        resultsLabel.text = matchedQuestions[indexPath.row]
        
        //add everything to appropriate superview
        backgroundView.addSubview(resultsLabel)
        
        cell.addSubview(backgroundView)
        
        return cell
    }
    
    //function to activate when a row is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //get the class that the question belongs to
        let Class = matchedQuestionsWithClass[tableView.cellForRow(at: indexPath)!.textLabel!.text!]
        
        QuestionController.className = Class!
        QuestionController.questionName = tableView.cellForRow(at: indexPath)!.textLabel!.text!
        
        self.performSegue(withIdentifier: "showQuestion", sender: self)
    }
    
    //function activated when the search button is clicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        mainTableView.allowsSelection = true
        searchBar.resignFirstResponder()
        
        let searchText: String = (searchBar.text ?? "").lowercased()
        
        var index: Int = 0
        
        for Class in classes {
            
            let questionsForClass: [String] = localQuestions[index]
            
            for question in questionsForClass {
                if question.lowercased().contains(searchText) {
                    matchedQuestions.append(question)
                    matchedQuestionsWithClass[question] = Class
                } else {
                    print("\(question) does not contain \(searchText)")
                }
                
                
            }
            
            index += 1
        }
        
        
        if matchedQuestions.isEmpty == true {
            matchedQuestions.append("No Results Containing \"\(searchText)\"")
            self.mainTableView.allowsSelection = false
        }
        
        print("matched questions: \(matchedQuestions)")
        mainTableView.reloadData()
    }
    
    //function to activate when the search bar begins editing
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //remove all data from the results arrays
        matchedQuestions = []
        matchedQuestionsWithClass = [:]
        //reset the table
        mainTableView.reloadData()
    }
}
