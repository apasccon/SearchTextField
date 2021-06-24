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
        
        var items = [SearchTextFieldItem]()

        for i in 0..<10 {

            // prepare title

            let attributedTitle = NSMutableAttributedString()
            let searchableTitlePart = "\(i) Searchable title part"
            let nonSearchableTitlePart = " Non-searchable"

            attributedTitle.append(NSAttributedString(string: searchableTitlePart, attributes: [.font : UIFont.systemFont(ofSize: 15), .foregroundColor : UIColor.green]))
            attributedTitle.append(NSAttributedString(string: nonSearchableTitlePart, attributes: [.font : UIFont.systemFont(ofSize: 12), .foregroundColor : UIColor.gray]))

            let titleSearchRange = (attributedTitle.string as NSString).range(of: searchableTitlePart)

            // prepare subtitle

            let attributedSubtitle = NSMutableAttributedString()
            let searchableSubtitlePart = "Searchable subtitle part"
            let nonSearchableSubtitlePart = " Non-searchable"

            attributedSubtitle.append(NSAttributedString(string: searchableSubtitlePart, attributes: [.font : UIFont.systemFont(ofSize: 11), .foregroundColor : UIColor.green]))
            attributedSubtitle.append(NSAttributedString(string: nonSearchableSubtitlePart, attributes: [.font : UIFont.systemFont(ofSize: 9), .foregroundColor : UIColor.gray]))

            let subtitleSearchRange = (attributedSubtitle.string as NSString).range(of: searchableSubtitlePart)

            let item = SearchTextFieldItem(
                    attributedTitle: attributedTitle,
                    attributedSubtitle: attributedSubtitle,
                    titleSearchRange: titleSearchRange,
                    subtitleSearchRange: subtitleSearchRange)

            items.append(item)
        }

        searchTextField.filterItems(items)

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

