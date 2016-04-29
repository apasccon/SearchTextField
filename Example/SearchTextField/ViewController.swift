//
//  ViewController.swift
//  SearchTextField
//
//  Created by Alejandro Pasccon on 04/25/2016.
//  Copyright (c) 2016 Alejandro Pasccon. All rights reserved.
//

import UIKit
import SearchTextField

class ViewController: UIViewController {
    
    @IBOutlet weak var countryTextField: SearchTextField!
    @IBOutlet weak var acronymTextField: SearchTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1 - Configure a simple search text view
        configureSimpleSearchTextField()
        
        // 2 - Configure a custom search text view
        configureCustomSearchTextField()
    }
    
    
    
    // 1 - Configure a simple search text view
    private func configureSimpleSearchTextField() {
        // Start visible - Default: false
        countryTextField.startVisible = true
        
        // Set data source
        let countries = localCountries()
        countryTextField.filterStrings(countries)
    }
    
    
    // 2 - Configure a custom search text view
    private func configureCustomSearchTextField() {
        // Set theme - Default: light
        acronymTextField.theme = SearchTextFieldTheme.lightTheme()
        
        // Modify current theme properties
        acronymTextField.theme.font = UIFont.systemFontOfSize(12)
        acronymTextField.theme.bgColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 0.3)
        acronymTextField.theme.borderColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        acronymTextField.theme.separatorColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 0.5)
        acronymTextField.theme.cellHeight = 50
        
        // Max number of results - Default: No limit
        acronymTextField.maxNumberOfResults = 5
        
        // Customize highlight attributes - Default: Bold
        acronymTextField.highlightAttributes = [NSBackgroundColorAttributeName: UIColor.yellowColor(), NSFontAttributeName:UIFont.boldSystemFontOfSize(12)]
        
        // Handle item selection - Default: title set to the text field
        acronymTextField.itemSelectionHandler = {item in
            self.acronymTextField.text = item.title
        }
        
        // Update data source when the user stops typing
        acronymTextField.userStoppedTypingHandler = {
            if let criteria = self.acronymTextField.text {
                if criteria.characters.count > 1 {
                    
                    // Show loading indicator
                    self.acronymTextField.showLoadingIndicator()
                    
                    self.filterAcronymInBackground(criteria) { results in
                        // Set new items to filter
                        self.acronymTextField.filterItems(results)
                        
                        // Stop loading indicator
                        self.acronymTextField.stopLoadingIndicator()
                    }
                }
            }
        }
    }
    
    // Hide keyboard when touching the screen
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
    }
    
    ////////////////////////////////////////////////////////
    // Data Sources
    
    private func localCountries() -> [String] {
        if let path = NSBundle.mainBundle().pathForResource("countries", ofType: "json") {
            do {
                let jsonData = try NSData(contentsOfFile: path, options: .DataReadingMapped)
                let jsonResult = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as! [[String:String]]
                
                var countryNames = [String]()
                for country in jsonResult {
                    countryNames.append(country["name"]!)
                }
                
                return countryNames
            } catch {
                print("Error parsing jSON: \(error)")
                return []
            }
        }
        return []
    }
    
    private func filterAcronymInBackground(criteria: String, callback: ((results: [SearchTextFieldItem]) -> Void)) {
        let url = NSURL(string: "http://www.nactem.ac.uk/software/acromine/dictionary.py?sf=\(criteria)")
        
        if let url = url {
            let task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
                do {
                    if let data = data {
                        let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! [[String:AnyObject]]
                        
                        if let firstElement = jsonData.first {
                            let jsonResults = firstElement["lfs"] as! [[String: AnyObject]]
                            
                            var results = [SearchTextFieldItem]()
                            
                            for result in jsonResults {
                                results.append(SearchTextFieldItem(title: result["lf"] as! String, subtitle: criteria.uppercaseString, image: UIImage(named: "acronym_icon")))
                            }
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                callback(results: results)
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                callback(results: [])
                            }
                        }
                    }
                }
                catch {
                    print("Network error: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(results: [])
                    }
                }
            }
            
            task.resume()
        }
    }
}
