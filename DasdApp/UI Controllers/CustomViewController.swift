//
//  CustomViewController.swift
//  DasdApp
//
//  Created by Ethan Miller on 10/13/19.
//  Copyright © 2019 Ethan Miller. All rights reserved.
//

import UIKit

class CustomViewController: UIViewController {

    override func awakeFromNib() {
        super.viewDidLoad()
        //set the UI trait collection to a constant
        let traits = traitCollection
        
        //set if statement to determine if dark mode is active, and set the appropriate background color
        if traits.userInterfaceStyle == .dark {
            self.view.backgroundColor = UIColor().darkBlueColor()
        } else {
            self.view.backgroundColor = UIColor().blueColor()
        }
    }
}

//class to hold the custom blue color
extension UIColor {
    func blueColor() -> UIColor {
        return UIColor(red: 0/255, green: 120/255, blue: 155/255, alpha: 1.0)
    }
    
    func darkBlueColor() -> UIColor {
        return UIColor(red: 0/255, green: 50/255, blue: 110/255, alpha: 1.0)
    }
}
