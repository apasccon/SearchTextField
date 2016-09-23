# SearchTextField

[![CI Status](http://img.shields.io/travis/Alejandro Pasccon/SearchTextField.svg?style=flat)](https://travis-ci.org/Alejandro Pasccon/SearchTextField)
[![Version](https://img.shields.io/cocoapods/v/SearchTextField.svg?style=flat)](http://cocoapods.org/pods/SearchTextField)
[![License](https://img.shields.io/cocoapods/l/SearchTextField.svg?style=flat)](http://cocoapods.org/pods/SearchTextField)
[![Platform](https://img.shields.io/cocoapods/p/SearchTextField.svg?style=flat)](http://cocoapods.org/pods/SearchTextField)

## Overview

**SearchTextField** is a subclass of UITextField, written in Swift that makes really easy the ability to show an autocomplete suggestions list.   
You can decide wether to show the list as soon as the field is focused or when the user starts typing.   
You can also detects when the user stops typing, very useful when you can get a suggestion list from a remote server.   
   
   
------   
![alt_tag](https://raw.githubusercontent.com/apasccon/SearchTextField/master/Example/SearchTextField/SearchTextField_Demo.gif)

## Requirements

* iOS 8

## Installation

SearchTextField is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```swift
use_frameworks!

pod "SearchTextField"
```

###Manual installation

Just import SearchTextField.swift into your project

## Usage

### You can use it in the simplest way...

```swift
import SearchTextField

// Connect your IBOutlet...
@IBOutlet weak var mySearchTextField: SearchTextField!

// ...or create it manually
let mySearchTextField = SearchTextField(frame: CGRectMake(10, 100, 200, 40))

// Set the array of strings you want to suggest
mySearchTextField.filterStrings(["Red", "Blue", "Yellow"])
```
### ...or you can customize it as you want

```swift
// Show also a subtitle and an image for each suggestion:

let item1 = SearchTextFieldItem(title: "Blue", subtitle: "Color", image: UIImage(named: "icon_blue"))
let item2 = SearchTextFieldItem(title: "Red", subtitle: "Color", image: UIImage(named: "icon_red"))
let item3 = SearchTextFieldItem(title: "Yellow", subtitle: "Color", image: UIImage(named: "icon_yellow"))
mySearchTextField.filterItems([item1, item2, item3])

// Set a visual theme (SearchTextFieldTheme). By default it's the light theme
mySearchTextField.theme = SearchTextFieldTheme.darkTheme()

// Modify current theme properties
mySearchTextField.theme.font = UIFont.systemFontOfSize(12)
mySearchTextField.theme.bgColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 0.3)
mySearchTextField.theme.borderColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
mySearchTextField.theme.separatorColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 0.5)
mySearchTextField.theme.cellHeight = 50

// Set the max number of results. By default it's not limited
mySearchTextField.maxNumberOfResults = 5

// You can also limit the max height of the results list
mySearchTextField.maxResultsListHeight = 200

// Customize the way it highlights the search string. By default it bolds the string
mySearchTextField.highlightAttributes = [NSBackgroundColorAttributeName: UIColor.yellowColor(), NSFontAttributeName:UIFont.boldSystemFontOfSize(12)]

// Handle what happens when the user picks an item. By default the title is set to the text field
mySearchTextField.itemSelectionHandler = {item in
    mySearchTextField.text = item.title
}

/** 
* Update data source when the user stops typing. 
* It's useful when you want to retrieve results from a remote server while typing 
* (but only when the user stops doing it)
**/
mySearchTextField.userStoppedTypingHandler = {
    if let criteria = self.mySearchTextField.text {
        if criteria.characters.count > 1 {

        // Show the loading indicator
        self.mySearchTextField.showLoadingIndicator()

        self.searchMoreItemsInBackground(criteria) { results in
            // Set new items to filter
            self.acronymTextField.filterItems(results)

            // Hide loading indicator
            self.mySearchTextField.stopLoadingIndicator()
        }
    }
}
```


## Demo

Check out the Example project.

## Author

Alejandro Pasccon, apasccon@gmail.com

## License

SearchTextField is available under the MIT license. See the LICENSE file for more info.
