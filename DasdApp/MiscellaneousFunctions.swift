//
//  MiscellaneousFunctions.swift
//  DasdApp
//
//  Created by Ethan Miller on 12/7/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import Foundation
import UIKit

struct MiscellaneousFunctions {
    //function to return a random color
    func getRandomColor() -> UIColor {
        //create variable representing a random color
        let randomNumber = Int(arc4random_uniform(6))
        
        //create an array of colors
        let arrayOfColors: [UIColor] = [UIColor(red: 75/255, green: 155/255, blue: 0, alpha: 1.0), UIColor(red: 160/255, green: 155/255, blue: 255/255, alpha: 1.0), UIColor(red: 230/255, green: 230/255, blue: 0, alpha: 1.0), UIColor(red: 255/255, green: 90/255, blue: 100/255, alpha: 1.0), UIColor(red: 70/255, green: 170/255, blue: 255/255, alpha: 1.0), UIColor(red: 70/255, green: 255/255, blue: 180/255, alpha: 1.0)]
        
        //return a color from the array, based off of the random number
        return arrayOfColors[randomNumber]
    }
}
