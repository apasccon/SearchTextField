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
    @IBOutlet weak var countryInLineTextField: SearchTextField!
    @IBOutlet weak var emailInlineTextField: SearchTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        
        tableView.tableFooterView = UIView()
        
        // 1 - Configure a simple search text field
        configureSimpleSearchTextField()
        
        // 2 - Configure a custom search text field
        configureCustomSearchTextField()

        // 3 - Configure an "inline" suggestions search text field
        configureSimpleInLineSearchTextField()

        // 4 - Configure a custom "inline" suggestions search text field
        configureCustomInLineSearchTextField()
    }
    
    // 1 - Configure a simple search text view
    fileprivate func configureSimpleSearchTextField() {
        // Start visible even without user's interaction as soon as created - Default: false
        countryTextField.startVisibleWithoutInteraction = true
        
        // Set data source
        let countries = localCountries()
        countryTextField.filterStrings(countries)
    }
    
    
    // 2 - Configure a custom search text view
    fileprivate func configureCustomSearchTextField() {
        // Set theme - Default: light
        acronymTextField.theme = SearchTextFieldTheme.lightTheme()
        
        // Define a header - Default: nothing
        let header = UILabel(frame: CGRect(x: 0, y: 0, width: acronymTextField.frame.width, height: 30))
        header.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        header.textAlignment = .center
        header.font = UIFont.systemFont(ofSize: 14)
        header.text = "Pick your option"
        acronymTextField.resultsListHeader = header

        
        // Modify current theme properties
        acronymTextField.theme.font = UIFont.systemFont(ofSize: 12)
        acronymTextField.theme.bgColor = UIColor.lightGray.withAlphaComponent(0.2)
        acronymTextField.theme.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
        acronymTextField.theme.separatorColor = UIColor.lightGray.withAlphaComponent(0.5)
        acronymTextField.theme.cellHeight = 50
        acronymTextField.theme.placeholderColor = UIColor.lightGray
        
        // Max number of results - Default: No limit
        acronymTextField.maxNumberOfResults = 5
        
        // Max results list height - Default: No limit
        acronymTextField.maxResultsListHeight = 200
        
        // Set specific comparision options - Default: .caseInsensitive
        acronymTextField.comparisonOptions = [.caseInsensitive]

        // You can force the results list to support RTL languages - Default: false
        acronymTextField.forceRightToLeft = false

        // Customize highlight attributes - Default: Bold
        acronymTextField.highlightAttributes = [NSAttributedString.Key.backgroundColor: UIColor.yellow, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)]
        
        // Handle item selection - Default behaviour: item title set to the text field
        acronymTextField.itemSelectionHandler = { filteredResults, itemPosition in
            // Just in case you need the item position
            let item = filteredResults[itemPosition]
            print("Item at position \(itemPosition): \(item.title)")
            
            // Do whatever you want with the picked item
            self.acronymTextField.text = item.title
        }
        
        // Update data source when the user stops typing
        acronymTextField.userStoppedTypingHandler = {
            if let criteria = self.acronymTextField.text {
                if criteria.count > 1 {
                    
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
        } as (() -> Void)
    }
    
    // 3 - Configure a simple inline search text view
    fileprivate func configureSimpleInLineSearchTextField() {
        // Define the inline mode
        countryInLineTextField.inlineMode = true
        
        
        // Set data source
        let countries = localCountries()
        countryInLineTextField.filterStrings(countries)
    }

    // 4 - Configure a custom inline search text view
    fileprivate func configureCustomInLineSearchTextField() {
        // Define the inline mode
        emailInlineTextField.inlineMode = true
        
        emailInlineTextField.startFilteringAfter = "@"
        emailInlineTextField.startSuggestingImmediately = true
        
        // Set data source
        emailInlineTextField.filterStrings(["gmail.com", "yahoo.com", "yahoo.com.ar"])
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
                    } else {
                        DispatchQueue.main.async {
                            callback([])
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
