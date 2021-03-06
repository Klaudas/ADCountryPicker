//
//  ADCountryPicker.swift
//  ADCountryPicker
//
//  Created by Ibrahim, Mustafa on 1/24/16.
//  Copyright © 2016 Mustafa Ibrahim. All rights reserved.
//

import UIKit

public struct Section {
    var countries: [ADCountry] = []
    mutating func addCountry(_ country: ADCountry) {
        countries.append(country)
    }
}

@objc public protocol ADCountryPickerDelegate: class {
    @objc optional func countryPicker(_ picker: ADCountryPicker,
                       didSelectCountryWithName name: String,
                       code: String)
    func countryPicker(_ picker: ADCountryPicker,
                                      didSelectCountryWithName name: String,
                                      code: String,
                                      dialCode: String)
}

open class ADCountryPicker: UITableViewController {
    
    public convenience init(countries: [ADCountry], currentCountry: ADCountry?) {
        self.init(style: .grouped)
        self.countries = countries
        self.currentCountry = currentCountry
    }
    
    deinit { print("deinit", type(of: self)) }
    
    private var customCountriesCode: [String]?
    fileprivate var searchController: UISearchController!
    fileprivate var filteredList = [ADCountry]()
    private var countries = [ADCountry]()
    private var currentCountry: ADCountry?
    
    fileprivate var _sections: [Section]?
    fileprivate var sections: [Section] {
        
        if _sections != nil {
            return _sections!
        }
        
        let countries: [ADCountry] = self.countries.map { country in
            country.section = collation.section(for: country, collationStringSelector: #selector(getter: ADCountry.name))
            return country
        }
        
        // create empty sections
        var sections = [Section]()
        for _ in 0..<self.collation.sectionIndexTitles.count {
            sections.append(Section())
        }
        
        
        // put each country in a section
        for country in countries {
            sections[country.section!].addCountry(country)
        }
        
        // sort each section
        for section in sections {
            var s = section
            s.countries = collation.sortedArray(from: section.countries, collationStringSelector: #selector(getter: ADCountry.name)) as! [ADCountry]
        }
        
        // Adds current location
        
        if let currentCountry = currentCountry {
            sections.insert(Section(), at: 0)
            currentCountry.section = 0
            sections[0].addCountry(currentCountry)
        }
        
//        if countryData.count > 0, let dialCode = countryData[0]["dial_code"] {
//            country = ADCountry(name: displayName!, code: countryCode, dialCode: dialCode)
//        } else {
//            country = ADCountry(name: displayName!, code: countryCode, dialCode: "")
//        }
        
        _sections = sections
        
        return _sections!
    }
    
    fileprivate let collation = UILocalizedIndexedCollation.current()
        as UILocalizedIndexedCollation
    open weak var delegate: ADCountryPickerDelegate?
    
    public var firstCountry: ADCountry? {
        return sections.first?.countries.first
    }
    
    open var didSelectCallback: ((ADCountry) -> Void)?
    
    /// Closure which returns country name and ISO code
    open var didSelectCountryClosure: ((String, String) -> ())?
    
    /// Closure which returns country name, ISO code, calling codes
    open var didSelectCountryWithCallingCodeClosure: ((String, String, String) -> ())?
    
    /// Flag to indicate if calling codes should be shown next to the country name. Defaults to false.
    open var showCallingCodes = false
    
    /// Flag to indicate whether country flags should be shown on the picker. Defaults to true
    open var showFlags = true
    
    /// The nav bar title to show on picker view
    open var pickerTitle = "Select a Country"
    
    /// The default current location, if region cannot be determined. Defaults to US
    open var defaultCountryCode = "US"
    
    /// Flag to indicate whether the defaultCountryCode should be used even if region can be deteremined. Defaults to false
    open var forceDefaultCountryCode = false
    
    // The text color of the alphabet scrollbar. Defaults to black
    open var alphabetScrollBarTintColor = UIColor.black
    
    /// The background color of the alphabet scrollar. Default to clear color
    open var alphabetScrollBarBackgroundColor = UIColor.clear
    
    // The tint color of the close icon in presented pickers. Defaults to black
    open var closeButtonTintColor = UIColor.black
    
    /// The font of the country name list
    open var countryFont = UIFont(name: "Helvetica Neue", size: 15)
    
    open var phoneFont = UIFont(name: "Helvetica Neue", size: 15)
    
    /// The color of text
    open var countryTextColor = UIColor.black
    
    /// The color of text
    open var phoneCodeTextColor = UIColor.black
    
    /// The height of the flags shown. Default to 40px
    open var flagHeight = 35
    
    /// Flag to indicate if the navigation bar should be hidden when search becomes active. Defaults to true
    open var hidesNavigationBarWhenPresentingSearch = false
    
    open var currentLocationTitle = "Current location"
    
    /// The background color of the searchbar. Defaults to lightGray
    open var searchBarBackgroundColor = UIColor.lightGray
    
    convenience public init(completionHandler: @escaping ((String, String) -> ())) {
        self.init()
        self.didSelectCountryClosure = completionHandler
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = pickerTitle
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        createSearchBar()
        tableView.reloadData()
        
        definesPresentationContext = true
        
        if self.presentingViewController != nil {
            
            let bundle = "assets.bundle/"
            let closeButton = UIBarButtonItem(image: UIImage(named: bundle + "close_icon" + ".png",
                                                             in: Bundle(for: ADCountryPicker.self),
                                                             compatibleWith: nil),
                                              style: .plain,
                                              target: self,
                                              action: #selector(self.dismissView))
            closeButton.tintColor = closeButtonTintColor
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.leftBarButtonItem = closeButton
        }
        
        tableView.sectionIndexColor = alphabetScrollBarTintColor
        tableView.sectionIndexBackgroundColor = alphabetScrollBarBackgroundColor
        tableView.separatorColor = UIColor(red: (222)/(255.0),
                                           green: (222)/(255.0),
                                           blue: (222)/(255.0),
                                           alpha: 1)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let barItem = UIBarButtonItem()
        barItem.title = ""
        navigationController?.navigationBar.topItem?.backBarButtonItem = barItem
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let y = tableView.contentOffset.y - searchController.searchBar.frame.origin.y - 10
        tableView.setContentOffset(.init(x: 0, y: y), animated: true)
    }
    
    // MARK: Methods
    
    @objc private func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func createSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.barTintColor = self.searchBarBackgroundColor
        searchController.obscuresBackgroundDuringPresentation = false
        if #available(iOS 13.0, *) {
            searchController.automaticallyShowsCancelButton = true
        } else {
            searchController.searchBar.showsCancelButton = false
        }
        navigationItem.searchController = searchController
    }
    
    @discardableResult
    fileprivate func filter(_ searchText: String) -> [ADCountry] {
        filteredList.removeAll()
        
        sections.forEach { (section) -> () in
            section.countries.forEach({ (country) -> () in
                if country.name.count >= searchText.count {
                    let result = country.name.compare(searchText, options: [.caseInsensitive, .diacriticInsensitive],
                                                      range: searchText.startIndex ..< searchText.endIndex)
                    if result == .orderedSame {
                        filteredList.append(country)
                    }
                }
            })
        }
        
        return filteredList
    }
    
    fileprivate func getCountry(_ code: String) -> [ADCountry] {
        filteredList.removeAll()
        
        sections.forEach { (section) -> () in
            section.countries.forEach({ (country) -> () in
                if country.code.count >= code.count {
                    let result = country.code.compare(code, options: [.caseInsensitive, .diacriticInsensitive],
                                                      range: code.startIndex ..< code.endIndex)
                    if result == .orderedSame {
                        filteredList.append(country)
                    }
                }
            })
        }
        
        return filteredList
    }
    
    
    // MARK: - Public method
    
    /// Returns the country flag for the given country code
    ///
    /// - Parameter countryCode: ISO code of country to get flag for
    /// - Returns: the UIImage for given country code if it exists
    public func getFlag(countryCode: String) -> UIImage? {
        let bundle = "assets.bundle/"
        if #available(iOS 13.0, *) {
            return UIImage(named: bundle + countryCode.uppercased() + ".png",
                           in: Bundle(for: ADCountryPicker.self),
                           with: nil)
        } else {
            return UIImage(named: bundle + countryCode.uppercased() + ".png",
                           in: Bundle(for: ADCountryPicker.self),
                           compatibleWith: nil)
        }
    }
    
    /// Returns the country dial code for the given country code
    ///
    /// - Parameter countryCode: ISO code of country to get dialing code for
    /// - Returns: the dial code for given country code if it exists
    public func getDialCode(countryCode: String) -> String? {
        let countries = self.getCountry(countryCode)
        
        if countries.count == 1 {
            return countries.first?.phoneCode
        }
        else {
            return nil
        }
    }
    
    /// Returns the country name for the given country code
    ///
    /// - Parameter countryCode: ISO code of country to get dialing code for
    /// - Returns: the country name for given country code if it exists
    public func getCountryName(countryCode: String) -> String? {
        let countries = self.getCountry(countryCode)
        
        if countries.count == 1 {
            return countries.first?.name
        }
        else {
            return nil
        }
    }
}

// MARK: - Table view data source

extension ADCountryPicker {
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.searchBar.text!.count > 0 {
            return 1
        }
        return sections.count
    }
    
    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.searchBar.text!.count > 0 {
            return filteredList.count
        }
        return sections[section].countries.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        let country: ADCountry!
        if searchController.searchBar.text!.count > 0 {
            country = filteredList[indexPath.row]
        } else {
            country = sections[indexPath.section].countries[indexPath.row]
            
        }
        
        cell.textLabel?.font = countryFont
        cell.textLabel?.textColor = countryTextColor
        cell.textLabel?.text = country.name
        
        cell.detailTextLabel?.font = phoneFont
        cell.detailTextLabel?.textColor = phoneCodeTextColor
        
        if showCallingCodes {
            cell.detailTextLabel?.text = country.phoneCode
        } else {
            cell.detailTextLabel?.text = nil
        }
                
        if showFlags {
            cell.imageView?.image = country.flag.fitImage(size: CGSize(width: flagHeight, height: flagHeight))
        }
        
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !sections[section].countries.isEmpty {
            if searchController.searchBar.text!.count > 0 {
                if let name = filteredList.first?.name {
                    let index = name.index(name.startIndex, offsetBy: 0)
                    return String(describing: name[index])
                }
                
                return ""
            }
            
            if section == 0 {
                return currentLocationTitle
            }
            
            return self.collation.sectionTitles[section-1] as String
            
            
        }
        
        return ""
    }
    
    override open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 50
        }
        else {
            return 26
        }
    }
    
    override open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return collation.sectionIndexTitles
    }
    
    override open func tableView(_ tableView: UITableView,
                                 sectionForSectionIndexTitle title: String,
                                 at index: Int)
        -> Int {
            return collation.section(forSectionIndexTitle: index+1)
    }
}

// MARK: - Table view delegate

extension ADCountryPicker {
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country: ADCountry!
        if searchController.searchBar.text!.count > 0 {
            country = filteredList[indexPath.row]
        } else {
            country = sections[indexPath.section].countries[indexPath.row]
        }
        didSelectCallback?(country)
        delegate?.countryPicker?(self, didSelectCountryWithName: country.name, code: country.code)
        delegate?.countryPicker(self, didSelectCountryWithName: country.name, code: country.code, dialCode: country.phoneCode)
        didSelectCountryClosure?(country.name, country.code)
        didSelectCountryWithCallingCodeClosure?(country.name, country.code, country.phoneCode)
    }
}

// MARK: - UISearchDisplayDelegate

extension ADCountryPicker: UISearchResultsUpdating {
    
    public func updateSearchResults(for searchController: UISearchController) {
        filter(searchController.searchBar.text!)
        
        if #available(iOS 13.0, *) {
        } else {
            searchController.searchBar.showsCancelButton = searchController.isActive
        }
        
        tableView.reloadData()
    }
}

// MARK: - UIImage extensions

extension UIImage {
    func fitImage(size: CGSize) -> UIImage? {
        let widthRatio = size.width / self.size.width
        let heightRatio = size.height / self.size.height
        let ratio = min(widthRatio, heightRatio)
        
        let imageWidth = self.size.width * ratio
        let imageHeight = self.size.height * ratio
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width:imageWidth, height:imageHeight), false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
