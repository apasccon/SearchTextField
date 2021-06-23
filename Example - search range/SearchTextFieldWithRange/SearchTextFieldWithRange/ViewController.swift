//
//  ViewController.swift
//  SearchTextFieldWithRange
//
//  Created by Alexander Kormanovsky on 23.06.2021.
//

import UIKit
import SearchTextField


class ViewController: UIViewController {
    
    @IBOutlet var searchTextField: SearchTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }

    func setup() {
        
        var testArr = [SearchTextFieldItem]()

        for i in 0..<10 {
            testArr.append(SearchTextFieldItem(title: "title \(i)", subtitle: "subtitle \(i)"))
        }

        searchTextField.filterItems(testArr)

        searchTextField.maxNumberOfResults = 10
        searchTextField.minCharactersNumberToStartFiltering = 2
        searchTextField.typingStoppedDelay = 0.4

        searchTextField.theme.font = UIFont.systemFont(ofSize: 17)
        searchTextField.theme.bgColor = .white

        searchTextField.itemSelectionHandler = { filteredResults, itemPosition in
            let item = filteredResults[itemPosition]
            // ...
        }

        searchTextField.userStoppedTypingHandler = {
            if let text = self.searchTextField.text, text.count >= self.searchTextField.minCharactersNumberToStartFiltering {
                self.searchTextField.showLoadingIndicator()

                // ...

                self.searchTextField.stopLoadingIndicator()
            }
        }
        
    }

}

