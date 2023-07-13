//
//  TextHandling.swift
//  DasdApp
//
//  Created by Ethan Miller on 10/26/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import Foundation

public func determineIfTextIsAppropriate(text: String) -> Bool {
    //create variable of the text, lowercased
    let lowercasedText: NSString = NSString(string: text.lowercased())

    
    //enter for loop to anaylze for all the words
    for word in offensiveLanguageArray {
        if lowercasedText.range(of: word).location <= 100000 {
            print("contians: \(word)")
            return false
        } else {
            print("clear: \(word)")
        }
    }
    
    //for loop complete, return
    return true
}

public let offensiveLanguageArray: [String] = ["shit", "crap", "ass", "bitch", "fuck", "penis", "pussy", "dick", "A$D", "titty", "vagina", "douchebag", "bastard", "cunt", "damn", "prick", "whore", "hoe", "slut", "cock", "cum", "piss", "twat", "jizz", "wanker", "bellend", "arse", "scrote", "hag", "boner", "poon", "dildo", "condom", "smegma", "queef", "turd", "blowjob", "rimjob", "butt", "bumblefuck", "hell", "cameltoe", "bimbo", "jock", "retard", "sped", "idiot", "stupid", "wimp", "nigger", "nigga", "niglet", "niggle", "fag", "faggot", "gag", "420", "69", ";", ":"]






extension String {
    func isNumber() -> Bool {
        guard let _ = Int(self) else {
            return false
        }
        
        return true
    }
    
    func isOperator() -> Bool {
        switch self {
        case "+", "-", "*", "/", ")", "(":
            return true
        default:
            return false
        }
    }
    
    //seperate phrase into array of words
    func seperateIntoWords() -> [String] {
        //seperated array
        var wordsArray: [String] = []
        //sub array
        var subArray: [String] = []
        
        //enter for loop to handle the characters
        for character in self {
            if character != " " {
                //add the character to the sub array
                subArray.append(String(character))
            } else {
                //add the sub array to the main array
                wordsArray.append(subArray.joined())
                //clear the sub array
                subArray.removeAll()
            }
        }
        
        //catch remaining word
        wordsArray.append(subArray.joined())
        
        return wordsArray
    }
    
    //function to turn words into number
    func convertWordToNumber() -> Int? {
        //an array of text numbers
        let textNumbers: [String] = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"]
        
        //an array of numbers
        let numbers: [Int] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
        
        guard let index = textNumbers.firstIndex(of: self.lowercased()) else {
            return nil
        }
        
        return numbers[index]
    }
    
    
    //function to turn words into operators
    func convertWordToOperator() -> String? {
        //an array of word operators
        let textOperators: [String] = ["plus", "minus", "divided", "multiplied", "added", "subtracted"]
        
        //an array of operators
        let operators: [String] = ["+", "-", "/", "*", "+", "-"]
        
        guard let index = textOperators.firstIndex(of: self.lowercased()) else {
            return nil
        }
        
        return operators[index]
    }
}
