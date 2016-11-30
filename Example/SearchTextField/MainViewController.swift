//
//  MainViewController.swift
//  SearchTextField
//
//  Created by Alejandro Pasccon on 11/30/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SearchTextField

class MainViewController: UITableViewController {

    @IBOutlet weak var countryTextField: SearchTextField!
    @IBOutlet weak var acronymTextField: SearchTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        // 1 - Configure a simple search text view
        configureSimpleSearchTextField()
        
        // 2 - Configure a custom search text view
        configureCustomSearchTextField()
    }
    
    
    
    // 1 - Configure a simple search text view
    fileprivate func configureSimpleSearchTextField() {
        // Start visible - Default: false
        countryTextField.startVisible = true
        
        // Set data source
        let countries = localCountries()
        countryTextField.filterStrings(countries)
    }
    
    
    // 2 - Configure a custom search text view
    fileprivate func configureCustomSearchTextField() {
        // Set theme - Default: light
        acronymTextField.theme = SearchTextFieldTheme.lightTheme()
        
        // Modify current theme properties
        acronymTextField.theme.font = UIFont.systemFont(ofSize: 12)
        acronymTextField.theme.bgColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 0.3)
        acronymTextField.theme.borderColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        acronymTextField.theme.separatorColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 0.5)
        acronymTextField.theme.cellHeight = 50
        
        // Max number of results - Default: No limit
        acronymTextField.maxNumberOfResults = 5
        
        // Max results list height - Default: No limit
        acronymTextField.maxResultsListHeight = 200
        
        // Customize highlight attributes - Default: Bold
        acronymTextField.highlightAttributes = [NSBackgroundColorAttributeName: UIColor.yellow, NSFontAttributeName:UIFont.boldSystemFont(ofSize: 12)]
        
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
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    ////////////////////////////////////////////////////////
    // Data Sources
    
    fileprivate func localCountries() -> [String] {
        if let path = Bundle.main.path(forResource: "countries", ofType: "json") {
            do {
                let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .dataReadingMapped)
                let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as! [[String:String]]
                
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
    
    fileprivate func filterAcronymInBackground(_ criteria: String, callback: @escaping ((_ results: [SearchTextFieldItem]) -> Void)) {
        let url = URL(string: "http://www.nactem.ac.uk/software/acromine/dictionary.py?sf=\(criteria)")
        
        if let url = url {
            let task = URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
                do {
                    if let data = data {
                        let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [[String:AnyObject]]
                        
                        if let firstElement = jsonData.first {
                            let jsonResults = firstElement["lfs"] as! [[String: AnyObject]]
                            
                            var results = [SearchTextFieldItem]()
                            
                            for result in jsonResults {
                                results.append(SearchTextFieldItem(title: result["lf"] as! String, subtitle: criteria.uppercased(), image: UIImage(named: "acronym_icon")))
                            }
                            
                            DispatchQueue.main.async {
                                callback(results)
                            }
                        } else {
                            DispatchQueue.main.async {
                                callback([])
                            }
                        }
                    }
                }
                catch {
                    print("Network error: \(error)")
                    DispatchQueue.main.async {
                        callback([])
                    }
                }
            })
            
            task.resume()
        }
    }


}
