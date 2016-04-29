//
//  SearchTextField.swift
//  SearchTextField
//
//  Created by Alejandro Pasccon on 4/20/16.
//  Copyright © 2016 Alejandro Pasccon. All rights reserved.
//

import UIKit

public class SearchTextField: UITextField {

    ////////////////////////////////////////////////////////////////////////
    // Public interface
    
    /// Maximum number of results to be shown in the suggestions list
    public var maxNumberOfResults = 0
    
    /// Set your custom visual theme, or just choose between pre-defined SearchTextFieldTheme.lightTheme() and SearchTextFieldTheme.darkTheme() themes
    public var theme = SearchTextFieldTheme.lightTheme() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    /// Show the suggestions list without filter when the text field is focused
    public var startVisible = false
    
    /// Set an array of SearchTextFieldItem's to be used for suggestions
    public func filterItems(items: [SearchTextFieldItem]) {
        filterDataSource = items
    }

    /// Set an array of strings to be used for suggestions
    public func filterStrings(strings: [String]) {
        var items = [SearchTextFieldItem]()
        
        for value in strings {
            items.append(SearchTextFieldItem(title: value))
        }
        
        filterDataSource = items
    }
    
    /// Closure to handle when the user pick an item
    public var itemSelectionHandler: SearchTextFieldItemHandler?
    
    /// Closure to handle when the user stops typing
    public var userStoppedTypingHandler: (Void -> Void)?
    
    /// Set your custom set of attributes in order to highlight the string found in each item
    public var highlightAttributes: [String: AnyObject] = [NSFontAttributeName:UIFont.boldSystemFontOfSize(10)]
    
    public func showLoadingIndicator() {
        self.rightViewMode = .Always
        indicator.startAnimating()
    }

    public func stopLoadingIndicator() {
        self.rightViewMode = .Never
        indicator.stopAnimating()
    }
    

    ////////////////////////////////////////////////////////////////////////
    // Private implementation
    
    private var tableView: UITableView?
    private var shadowView: UIView?
    private var direction: Direction = .Down
    private var fontConversionRate: CGFloat = 0.7
    private var keyboardFrame: CGRect?
    private var timer: NSTimer? = nil
    private static let cellIdentifier = "APSearchTextFieldCell"
    private let indicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    private var filteredResults = [SearchTextFieldItem]()
    private var filterDataSource = [SearchTextFieldItem]() {
        didSet {
            filter(false)
            redrawSearchTableView()
        }
    }

    override public func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        
        self.addTarget(self, action: #selector(SearchTextField.textFieldDidChange), forControlEvents: .EditingChanged)
        self.addTarget(self, action: #selector(SearchTextField.textFieldDidBeginEditing), forControlEvents: .EditingDidBegin)
        self.addTarget(self, action: #selector(SearchTextField.textFieldDidEndEditing), forControlEvents: .EditingDidEnd)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SearchTextField.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SearchTextField.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        buildSearchTableView()
        
        // Create the loading indicator
        indicator.hidesWhenStopped = true
        self.rightView = indicator
    }
    
    override public func rightViewRectForBounds(bounds: CGRect) -> CGRect {
        var rightFrame = super.rightViewRectForBounds(bounds)
        rightFrame.origin.x -= 5
        return rightFrame
    }
    
    // Create the filter table and shadow view
    private func buildSearchTableView() {
        if let tableView = tableView, let shadowView = shadowView {
            tableView.layer.masksToBounds = true
            tableView.layer.borderWidth = 0.5
            tableView.dataSource = self
            tableView.delegate = self
            tableView.separatorInset = UIEdgeInsetsZero
            
            shadowView.backgroundColor = UIColor.whiteColor()
            shadowView.layer.shadowColor = UIColor.blackColor().CGColor
            shadowView.layer.shadowOffset = CGSizeZero
            shadowView.layer.shadowOpacity = 1
            
            superview?.addSubview(tableView)
            superview?.addSubview(shadowView)
        } else {
            tableView = UITableView(frame: CGRectZero)
            shadowView = UIView(frame: CGRectZero)
        }
        
        redrawSearchTableView()
    }
    
    // Re-set frames and theme colors
    private func redrawSearchTableView() {
        if let tableView = tableView {
            let positionGap: CGFloat = 10
            
            if self.direction == .Down {
                let tableHeight = min((tableView.contentSize.height + positionGap), (UIScreen.mainScreen().bounds.size.height - frame.origin.y - theme.cellHeight))
                tableView.frame = CGRectMake(frame.origin.x + 2, (frame.origin.y + frame.size.height - positionGap), frame.size.width - 4, tableHeight)
                shadowView!.frame = CGRectMake(frame.origin.x + 3, (frame.origin.y + frame.size.height - 3), frame.size.width - 6, 1)
                tableView.contentInset = UIEdgeInsets(top: positionGap, left: 0, bottom: 0, right: 0)
                tableView.contentOffset = CGPointMake(0, -positionGap)
            } else {
                let tableHeight = min((tableView.contentSize.height + positionGap), (UIScreen.mainScreen().bounds.size.height - frame.origin.y - theme.cellHeight * 2))
                tableView.frame = CGRectMake(frame.origin.x + 2, (frame.origin.y - tableHeight + positionGap), frame.size.width - 4, tableHeight)
                shadowView!.frame = CGRectMake(frame.origin.x + 3, (frame.origin.y + 3), frame.size.width - 6, 1)
                tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
                tableView.contentOffset = CGPointMake(0, 0)
            }
            
            superview?.bringSubviewToFront(tableView)
            superview?.bringSubviewToFront(shadowView!)
            
            if self.isFirstResponder() {
                superview?.bringSubviewToFront(self)
            }

            tableView.layer.borderColor = theme.borderColor.CGColor
            tableView.separatorColor = theme.separatorColor
            tableView.backgroundColor = theme.bgColor
            
            tableView.reloadData()
        }
    }
    
    // Handle keyboard events
    public func keyboardWillShow(notification: NSNotification) {
        keyboardFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        if let keyboardFrame = keyboardFrame {
            var newFrame = frame
            newFrame.size.height += theme.cellHeight
            
            if CGRectIntersectsRect(keyboardFrame, newFrame) {
                direction = .Up
            } else {
                direction = .Down
            }
            
            redrawSearchTableView()
        }
    }
    
    public func keyboardWillHide(notification: NSNotification) {
        direction = .Down
        redrawSearchTableView()
    }
    
    public func typingDidStop() {
        if userStoppedTypingHandler != nil {
            self.userStoppedTypingHandler!()
        }
    }
    
    // Handle text field changes
    public func textFieldDidChange() {
        // Detect pauses while typing
        timer?.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.8, target: self, selector: #selector(SearchTextField.typingDidStop), userInfo: self, repeats: false)
        
        if text!.isEmpty {
            clearResults()
            tableView?.reloadData()
        } else {
            filter(false)
        }
    }
    
    public func textFieldDidBeginEditing() {
        if startVisible && text!.isEmpty {
            clearResults()
            filter(true)
        }
    }
    
    public func textFieldDidEndEditing() {
        clearResults()
        tableView?.reloadData()
    }

    private func filter(addAll: Bool) {
        clearResults()
        
        for i in 0 ..< filterDataSource.count {
            
            var item = filterDataSource[i]
            
            // Find text in title and subtitle
            let titleFilterRange = (item.title as NSString).rangeOfString(text!, options: .CaseInsensitiveSearch)
            let subtitleFilterRange = item.subtitle != nil ? (item.subtitle! as NSString).rangeOfString(text!, options: .CaseInsensitiveSearch) : NSMakeRange(NSNotFound, 0)
            
            if titleFilterRange.location != NSNotFound || subtitleFilterRange.location != NSNotFound || addAll {
                item.attributedTitle = NSMutableAttributedString(string: item.title)
                item.attributedSubtitle = NSMutableAttributedString(string: (item.subtitle != nil ? item.subtitle! : ""))

                item.attributedTitle!.setAttributes(highlightAttributes, range: titleFilterRange)
                
                if subtitleFilterRange.location != NSNotFound {
                    item.attributedSubtitle!.setAttributes(highlightAttributesForSubtitle(), range: subtitleFilterRange)
                }
                
                filteredResults.append(item)
            }
        }
    
        tableView?.reloadData()
    }
    
    // Clean filtered results
    private func clearResults() {
        filteredResults.removeAll()
    }
    
    
    // Look for Font attribute, and if it exists, adapt to the subtitle font size
    private func highlightAttributesForSubtitle() -> [String: AnyObject] {
        var highlightAttributesForSubtitle = [String: AnyObject]()
        
        for attr in highlightAttributes {
            if attr.0 == NSFontAttributeName {
                let fontName = (attr.1 as! UIFont).fontName
                let pointSize = (attr.1 as! UIFont).pointSize * fontConversionRate
                highlightAttributesForSubtitle[attr.0] = UIFont(name: fontName, size: pointSize)
            } else {
                highlightAttributesForSubtitle[attr.0] = attr.1
            }
        }
        
        return highlightAttributesForSubtitle
    }
}

extension SearchTextField: UITableViewDelegate, UITableViewDataSource {
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.hidden = (filteredResults.count == 0)
        shadowView?.hidden = (filteredResults.count == 0)
        
        if maxNumberOfResults > 0 {
            return min(filteredResults.count, maxNumberOfResults)
        } else {
            return filteredResults.count
        }
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(SearchTextField.cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: SearchTextField.cellIdentifier)
        }
        
        cell!.backgroundColor = UIColor.clearColor()
        cell!.layoutMargins = UIEdgeInsetsZero
        cell!.preservesSuperviewLayoutMargins = false
        cell!.textLabel?.font = theme.font
        cell!.detailTextLabel?.font = UIFont(name: theme.font.fontName, size: theme.font.pointSize * fontConversionRate)
        cell!.textLabel?.textColor = theme.fontColor
        cell!.detailTextLabel?.textColor = theme.fontColor
        
        cell!.textLabel?.text = filteredResults[indexPath.row].title
        cell!.detailTextLabel?.text = filteredResults[indexPath.row].subtitle
        cell!.textLabel?.attributedText = filteredResults[indexPath.row].attributedTitle
        cell!.detailTextLabel?.attributedText = filteredResults[indexPath.row].attributedSubtitle

        cell!.imageView?.image = filteredResults[indexPath.row].image
        
        cell!.selectionStyle = .None
        
        return cell!
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return theme.cellHeight
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if itemSelectionHandler == nil {
            self.text = filteredResults[indexPath.row].title
        } else {
            itemSelectionHandler!(item: filteredResults[indexPath.row])
        }
        
        clearResults()
        tableView.reloadData()
    }
}

////////////////////////////////////////////////////////////////////////
// Search Text Field Theme

public struct SearchTextFieldTheme {
    public var cellHeight: CGFloat
    public var bgColor: UIColor
    public var borderColor: UIColor
    public var separatorColor: UIColor
    public var font: UIFont
    public var fontColor: UIColor
    
    init(cellHeight: CGFloat, bgColor:UIColor, borderColor: UIColor, separatorColor: UIColor, font: UIFont, fontColor: UIColor) {
        self.cellHeight = cellHeight
        self.borderColor = borderColor
        self.separatorColor = separatorColor
        self.bgColor = bgColor
        self.font = font
        self.fontColor = fontColor
    }
    
    public static func lightTheme() -> SearchTextFieldTheme {
        return SearchTextFieldTheme(cellHeight: 30, bgColor: UIColor (red: 1, green: 1, blue: 1, alpha: 0.6), borderColor: UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0), separatorColor: UIColor.clearColor(), font: UIFont.systemFontOfSize(10), fontColor: UIColor.blackColor())
    }
    
    public static func darkTheme() -> SearchTextFieldTheme {
        return SearchTextFieldTheme(cellHeight: 30, bgColor: UIColor (red: 0.8, green: 0.8, blue: 0.8, alpha: 0.6), borderColor: UIColor (red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0), separatorColor: UIColor.clearColor(), font: UIFont.systemFontOfSize(10), fontColor: UIColor.whiteColor())
    }
}

////////////////////////////////////////////////////////////////////////
// Filter Item

public struct SearchTextFieldItem {
    // Private vars
    private var attributedTitle: NSMutableAttributedString?
    private var attributedSubtitle: NSMutableAttributedString?

    // Public interface
    public var title: String
    public var subtitle: String?
    public var image: UIImage?
    
    public init(title: String, subtitle: String?, image: UIImage?) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }

    public init(title: String, subtitle: String?) {
        self.title = title
        self.subtitle = subtitle
    }

    public init(title: String) {
        self.title = title
    }
}

public typealias SearchTextFieldItemHandler = (item: SearchTextFieldItem) -> Void

////////////////////////////////////////////////////////////////////////
// Suggestions List Direction

enum Direction {
    case Down
    case Up
}