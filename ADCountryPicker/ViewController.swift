//
//  ViewController.swift
//  ADCountryPicker
//
//  Created by Amila on 21/4/17.
//  Copyright © 2017 Amila Diman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var countryCodeLabel: UILabel!
    @IBOutlet weak var countryCallingCodeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openPickerAction(_ sender: AnyObject) {
        
        let manager = ADCountryManager()
        
        let picker = ADCountryPicker(countries: manager.allCountriesSorted, currentCountry: manager.currentCountry)
        // delegate
        picker.delegate = self

        // Display calling codes
        picker.showCallingCodes = true

        // or closure
        picker.didSelectCountryClosure = { name, code in
            self.navigationController?.popToRootViewController(animated: true)
            print(code)
        }
        
        
//        Use this below code to present the picker
        
        navigationController?.pushViewController(picker, animated: true)
        

        
//        navigationController?.pushViewController(picker, animated: true)
    }
}

extension ViewController: ADCountryPickerDelegate {
    
    func countryPicker(_ picker: ADCountryPicker, didSelectCountryWithName name: String, code: String, dialCode: String) {
        _ = picker.navigationController?.popToRootViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
        countryNameLabel.text = name
        countryCodeLabel.text = code
        countryCallingCodeLabel.text = dialCode
    }
}

