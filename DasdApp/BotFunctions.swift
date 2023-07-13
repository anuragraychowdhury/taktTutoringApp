//
//  BotFunctions.swift
//  DasdApp
//
//  Created by Ethan Miller on 4/19/20.
//  Copyright © 2020 Ethan Miller. All rights reserved.
//

import Foundation
import Firebase
import CoreML
import Metal

struct Bots {
    struct MathBot {
        //function to determine if the math bot should activate
        func determineActivation(forSchool: String, forClass: String, forQuestion: String, activation: BotActivation) {
            //value to determine if the question has any math operators
            var containsOperators: Bool! = false
            var containsNumbers: Bool! = false
            
            //variable to represetned the question
            var question: String = forQuestion
            
            //remove characters
            question.removeAll(where: { (character) -> Bool in
                switch character {
                case "?", "!", ",":
                    return true
                default:
                    return false
                }
            })
            
            var words: [String] = []
            //convert the question to an array of words
            words  = question.seperateIntoWords()
            
            var index:Int = 0
            
            //enter for statement to split the words into characters and determine character combinations
            for word in words {
                let arrayedWord = Array(word)
                
                var newArray: [String] = []
                
                var previousCharacter: String! = ""
                
                for character in arrayedWord {
                    if String(character).isNumber() {
                        if previousCharacter.isOperator() || previousCharacter.isNumber() {
                            if newArray.isEmpty {
                                newArray = [previousCharacter, String(character)]
                            } else {
                                newArray.append(String(character))
                            }
                        }
                    } else if String(character).isOperator() {
                        if previousCharacter.isNumber() || previousCharacter.isOperator() {
                            if newArray.isEmpty {
                                newArray = [previousCharacter, String(character)]
                            } else {
                                newArray.append(String(character))
                            }
                        }
                    }
                    
                    previousCharacter = String(character)
                }
                
                var additionIndex: Int! = 0
                
                for item in newArray {
                    if additionIndex == 0 {
                        words[index] = item
                    } else {
                        words.insert(item, at: index + additionIndex)
                    }
                    
                    additionIndex += 1
                }
                
                index += (1 + additionIndex)
            }
            
            //enter for loop to determine if the array contains operators and numbers
            for word in words {
                print(word)
                //determine if there are any numbers in the question
                if word.convertWordToNumber() != nil || word.isNumber() {
                    containsNumbers = true
                }
                
                //determine if there are any math operators in the question
                if word.convertWordToOperator() != nil || word.isOperator() {
                    containsOperators = true
                }
            }
            
            //determine if function is possible
            if containsOperators == false || containsNumbers == false {
                print("not a function: \(words)")
                
                if activation == .userActivation {
                    sendBotResponseFromRequest(forSchool: forSchool, forClass: forClass, forQuestion: forQuestion, answer: nil, error: .mathNotPossible, message: nil)
                }
                
            } else {
                print("is a function: \(words)")
                //continue to function to perform the math function
                conductBotMathOperation(forSchool: forSchool, forClass: forClass, forQuestion: forQuestion, wordsArray: words, activation: activation)
            }
        }
        
        //function to conduct the operation
        func conductBotMathOperation(forSchool: String, forClass: String, forQuestion: String, wordsArray: [String], activation: BotActivation) {
            //operation array
            var array: [[Any]] = []
            
            var subArray: [Any] = []
            
            var previousCharacter: Any!
            
            //enter for loop to remove all except the operators and numbers
            for word in wordsArray {
                print(word)
                
                if word.isNumber() {
                    subArray.append(Float(word)!)
                    previousCharacter = Float(word)!
                } else if word.convertWordToNumber() != nil {
                    subArray.append(Float(word.convertWordToNumber()!))
                    previousCharacter = word.convertWordToNumber()!
                } else if word.isOperator() {
                    //first determine if the operator is a )
                    if word == ")" {
                        array.append(subArray)
                        subArray.removeAll()
                        print("found closed )")
                    } else if word == "(" {
                        if previousCharacter != nil {
                            array.append([previousCharacter!])
                        }
                        
                        print("found open (")
                        
                        subArray.removeAll()
                    } else {
                        subArray.append(word)
                    }
                    
                    previousCharacter = word
                } else if word.convertWordToOperator() != nil {
                    //first determine if the operator is a )
                    if word == ")" {
                        array.append(subArray)
                        subArray.removeAll()
                        print("founc closed )")
                    } else if word == "(" {
                        if previousCharacter != nil {
                            array.append([previousCharacter!])
                        }
                        
                        print("found (")
                        
                        subArray.removeAll()
                    } else {
                        subArray.append(word)
                    }
                    
                    previousCharacter = word.convertWordToOperator()
                }
            }
            
            //catch straggling sub array
            array.append(subArray)
            
            print("any array:", array)
            print("sub array:", subArray)
            
            var finalNumber: Float!
            
            var firstNumber: Float?
            var secondNumber: Float?
            var mathOperator: String!
            
            var stepNumbers: [Float] = []
            var stepOperators: [String] = []
            
            //enter for loop to conduct operation
            for sequence in array {
                //determine if the value is a step operator
                if sequence.count != 1 {
                    //enter for loop to handle the processes in parentesis
                    for item in sequence {
                        print("item: \(item), firstNumber: \(String(describing: firstNumber)), secondNumber: \(String(describing: secondNumber)), operator: \(String(describing: mathOperator))")
                        
                        //determine if the value is a number or an operator
                        if item as? Float != nil {
                            //determine if there is a two number set up
                            if sequence.count < 3 {
                                if mathOperator != nil {
                                    stepNumbers.append(item as! Float)
                                    
                                    stepOperators.append(mathOperator!)
                                    
                                    firstNumber = nil
                                    mathOperator = nil
                                    secondNumber = nil
                                } else {
                                    print("Error: Not a Math Equation")
                                    
                                    if activation == .userActivation {
                                        sendBotResponseFromRequest(forSchool: forSchool, forClass: forClass, forQuestion: forQuestion, answer: nil, error: .mathNotPossible, message: nil)
                                    }
                                    
                                    return
                                }
                            } else {
                                //determine which number it is
                                if firstNumber == nil {
                                    //add the number to the first number value
                                    firstNumber = (item as! Float)
                                } else {
                                    //add the value to the second number
                                    secondNumber = (item as! Float)
                                    
                                    //perform the action between the two numbers
                                    stepNumbers.append(performMathAction(firstNumber: firstNumber!, secondNumber: secondNumber!, forOperator: mathOperator))
                                    
                                    //set all of the values to nil
                                    firstNumber = nil
                                    secondNumber = nil
                                    mathOperator = nil
                                }
                            }
                        } else {
                            //run if statement to determine if the item is an operator, needs to be transformed, or is irrelevant
                            if (item as! String).isOperator() {
                                mathOperator = (item as! String)
                            } else if (item as! String).convertWordToOperator() != nil {
                                mathOperator = (item as! String).convertWordToOperator()!
                            }
                        }
                    }
                } else {
                    if (sequence.first as! String).isOperator() {
                        //append the step operator
                        stepOperators.append(sequence.first as! String)
                    } else if (sequence.first as! String).convertWordToOperator() != nil {
                        stepOperators.append((sequence.first as! String).convertWordToOperator()!)
                    }
                }
            }
            
            print("step numbers:", stepNumbers)
            print("step operators:", stepOperators)
            
            var operatorIndex: Int = 0
            for Operator in stepOperators {
                switch Operator {
                case "+", "-", "*", "/":
                    print("Allowed Operator")
                default:
                    stepOperators.remove(at: operatorIndex)
                }
                
                operatorIndex += 1
            }
            
            //create value representing the index
            var index: Int = 0
            
            //enter for loop to connect all of the step numbers
            for number in stepNumbers {
                if finalNumber == nil {
                    finalNumber = number
                } else {
                    finalNumber = performMathAction(firstNumber: finalNumber, secondNumber: number, forOperator: stepOperators[index])
                    
                    index += 1
                }
            }
            
            if finalNumber == nil {
                print("Error: No Math Performed")
                
                if activation == .userActivation {
                    sendBotResponseFromRequest(forSchool: forSchool, forClass: forClass, forQuestion: forQuestion, answer: nil, error: .noMath, message: nil)
                }
            } else {
                print("final number:", finalNumber!)
                
                if activation == .automated {
                    //run function to sent the response
                    sendBotResponseFromQuestion(forSchool: forSchool, forClass: forClass, forQuestion: forQuestion, answer: finalNumber)
                } else {
                    //run function to send the response
                    sendBotResponseFromRequest(forSchool: forSchool, forClass: forClass, forQuestion: forQuestion, answer: finalNumber!, error: nil, message: nil)
                }
            }
            
            
        }
        
        //function to determine the operator and perform the math function
        func performMathAction(firstNumber: Float, secondNumber: Float, forOperator: String) -> Float {
            switch forOperator {
            case "+":
                return firstNumber + secondNumber
            case "-":
                return firstNumber - secondNumber
            case "*":
                return firstNumber * secondNumber
            case "/":
                return firstNumber / secondNumber
            default:
                return 0
            }
        }
        
        //function to activate and send the response
        func sendBotResponseFromQuestion(forSchool: String, forClass: String, forQuestion: String, answer: Float) {
            var editedQuestion: String!
            
            print(forQuestion)
            
            //replace some characters in the question
            editedQuestion = forQuestion.replacingOccurrences(of: "/", with: "÷")
            editedQuestion = editedQuestion.replacingOccurrences(of: ".", with: "‰")
            
            print("edited: \(editedQuestion!)")
            
            //generate a random number
            let randomNumber = Int(arc4random_uniform(5))
            
            //create variable to hold the text of the bots response, starts with generic and has a different add-on
            var botResponse = "Hi I'm MathBot™. I detected that your response was a math question. \n"
            
            switch randomNumber {
            case 0:
                botResponse += "I think the answer is: \(answer)."
            case 1:
                botResponse += "I have come up with an answer of: \(answer)."
            case 2:
                botResponse += "By my calculations, the answer is: \(answer)."
            case 3:
                botResponse += "I have done some math and found an answer of: \(answer)."
            case 4:
                botResponse += "After some hard thinking, I think the answer is: \(answer)"
            default:
                botResponse = "Uh oh. I've suffered an internal error. Please let App Support know so I don't crash again."
            }
            
            //send the response
            Questions.Responses().createResponse(school: forSchool, forClass: forClass, questionTitle: editedQuestion, responseText: botResponse, userUID: "_MathBot", userName: "MathBot") { (error) in
                if error != nil {
                    print(error!)
                } else {
                    print("bot response sent")
                }
            }
        }
        
        //function to activate and send a response from a user request
        func sendBotResponseFromRequest(forSchool: String, forClass: String, forQuestion: String, answer: Float?, error: BotError?, message: String?) {
            //determine if there is an error
            if error != nil {
                var errorText: String!
                
                //determine which error happened
                switch error {
                case .mathNotPossible:
                    errorText = "Error 1: Math Not Possible"
                case .noCommand:
                    errorText = "Error 2: Command Does Not Exist"
                case .noMath:
                    errorText = "Error 3: No Math Found"
                case .removalNotPossible:
                    errorText = "Error 4: Removal Not Possible"
                case .unexpectedError:
                    errorText = "Error 5: Unexpected Error"
                default:
                    errorText = "Error 6: Unknown Error"
                }
                
                //send the response
                Questions.Responses().createResponse(school: forSchool, forClass: forClass, questionTitle: forQuestion, responseText: errorText, userUID: "_MathBot", userName: "MathBot") { (error) in
                    if error != nil {
                        print(error!)
                    }
                }
            } else {
                //determine if there is a message
                if message != nil {
                    Questions.Responses().createResponse(school: forSchool, forClass: forClass, questionTitle: forQuestion, responseText: message!, userUID: "_MathBot", userName: "MathBot") { (error) in
                        if error != nil {
                            print(error!)
                        }
                    }
                } else {
                    //send the response
                    Questions.Responses().createResponse(school: forSchool, forClass: forClass, questionTitle: forQuestion, responseText: "Answer of: \(answer!)", userUID: "_MathBot", userName: "MathBot") { (error) in
                        if error != nil {
                            print(error!)
                        }
                    }
                }
            }
        }
        
        //take a response and determine if it was a command
        func determineEditingText(forSchool: String, forClass: String, forQuestion: String, text: String) {
            //seperate the response into words
            let seperatedWord: [String] = text.seperateIntoWords()
            
            //determine if command symbol is in front
            if seperatedWord.first?.contains("\\") == true {
                //determine Bot to run
                if seperatedWord.first! == "\\MathBot"{
                    //determine the second word
                    if seperatedWord[1] == "recalculate" {
                        determineActivation(forSchool: forSchool, forClass: forClass, forQuestion: forQuestion, activation: .userActivation)
                    } else if seperatedWord[1] == "getInfo" {
                        sendBotResponseFromRequest(forSchool: forSchool, forClass: forClass, forQuestion: forQuestion, answer: nil, error: nil, message: "||MathBot||\nVersion 1.1\nCommand Enabled\nVisit Website for Details")
                    } else if seperatedWord[1] == "remove" {
                        //get the array of responses
                        Firestore.firestore().collection(forSchool).document("Questions").collection(forClass).document(forQuestion).getDocument { (document, error) in
                            //check for an error
                            if error != nil {
                                self.sendBotResponseFromRequest(forSchool: forSchool, forClass: forClass, forQuestion: forQuestion, answer: nil, error: .unexpectedError, message: "Unexpected Error! Please try again!")
                            } else {
                                //download the array of responses
                                var responses = (document?.data()?["arrayOfResponses"] as! [String])
                                
                                var index: Int = 0
                                var foundBotResponse: Bool = false
                                
                                for response in responses {
                                    if response.contains("™") {
                                        print("response to remove?", response, index)
                                        responses.remove(at: index)
                                        foundBotResponse = true
                                        break
                                    }
                                    
                                    index += 1
                                }
                                
                                if foundBotResponse == false {
                                    self.sendBotResponseFromRequest(forSchool: forSchool, forClass: forClass, forQuestion: forQuestion, answer: nil, error: .removalNotPossible, message: nil)
                                } else {
                                    Firestore.firestore().collection(forSchool).document("Questions").collection(forClass).document(forQuestion).updateData(["arrayOfResponses": responses])
                                }
                            }
                        }
                    } else {
                        sendBotResponseFromRequest(forSchool: forSchool, forClass: forClass, forQuestion: forQuestion, answer: nil, error: .noCommand, message: nil)
                    }
                }
            }
        }
    }
    
    //enumeration to determine if the activation is automated or user created
    enum BotActivation {
        case automated
        case userActivation
    }
    
    //enumberation for a user request error
    enum BotError {
        case noMath
        case mathNotPossible
        case noCommand
        case unexpectedError
        case removalNotPossible
    }
}
