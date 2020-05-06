//
//  ADCountry.swift
//  ADCountryPicker
//
//  Created by Amila on 21/04/2017.
//  Copyright © 2017 Amila Diman. All rights reserved.
//

import UIKit

public class ADCountry: NSObject {
    @objc public let name: String
    public let code: String
    public var section: Int?
    public let dialCode: String
    public let flag: UIImage
    
    init(name: String, code: String, dialCode: String, flag: UIImage) {
        self.name = name
        self.code = code
        self.dialCode = dialCode
        self.flag = flag
    }
}
