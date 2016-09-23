//
//  SearchTextField.swift
//  SearchTextField
//
//  Created by Alejandro Pasccon on 4/20/16.
//  Copyright © 2016 Alejandro Pasccon. All rights reserved.
//

import UIKit

open class SearchTextField: UITextField {

    ////////////////////////////////////////////////////////////////////////
    // Public interface
    
    /// Maximum number of results to be shown in the suggestions list
    open var maxNumberOfResults = 0

    /// Maximum height of the results list
    open var maxResultsListHeight = 0

    /// Set your custom visual theme, or just choose between pre-defined SearchTextFieldTheme.lightTheme() and SearchTextFieldTheme.darkTheme() themes
    open var theme = SearchTextFieldTheme.lightTheme() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    /// Show the suggestions list without filter when the text field is focused
    open var startVisible = false
    
    /// Set an array of SearchTextFieldItem's to be used for suggestions
    open func filterItems(_ items: [SearchTextFieldItem]) {
        filterDataSource = items
    }

    /// Set an array of strings to be used for suggestions
    open func filterStrings(_ strings: [String]) {
        var items = [SearchTextFieldItem]()
        
        for value in strings {
            items.append(SearchTextFieldItem(title: value))
        }
        
        filterDataSource = items
    }
    
    /// Closure to handle when the user pick an item
    open var itemSelectionHandler: SearchTextFieldItemHandler?
    
    /// Closure to handle when the user stops typing
    open var userStoppedTypingHandler: ((Void) -> Void)?
    
    /// Set your custom set of attributes in order to highlight the string found in each item
    open var highlightAttributes: [String: AnyObject] = [NSFontAttributeName:UIFont.boldSystemFont(ofSize: 10)]
    
    open func showLoadingIndicator() {
        self.rightViewMode = .always
        indicator.startAnimating()
    }

    open func stopLoadingIndicator() {
        self.rightViewMode = .never
        indicator.stopAnimating()
    }
    
    open var inlineMode = false
    

    ////////////////////////////////////////////////////////////////////////
    // Private implementation
    
    fileprivate var tableView: UITableView?
    fileprivate var shadowView: UIView?
    fileprivate var direction: Direction = .down
    fileprivate var fontConversionRate: CGFloat = 0.7
    fileprivate var keyboardFrame: CGRect?
    fileprivate var timer: Timer? = nil
    fileprivate var placeholderLabel: UILabel?
    fileprivate static let cellIdentifier = "APSearchTextFieldCell"
    fileprivate let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    fileprivate var filteredResults = [SearchTextFieldItem]()
    fileprivate var filterDataSource = [SearchTextFieldItem]() {
        didSet {
            filter(false)
            redrawSearchTableView()
        }
    }
    
    fileprivate var currentInlineItem = ""

    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        self.addTarget(self, action: #selector(SearchTextField.textFieldDidChange), for: .editingChanged)
        self.addTarget(self, action: #selector(SearchTextField.textFieldDidBeginEditing), for: .editingDidBegin)
        self.addTarget(self, action: #selector(SearchTextField.textFieldDidEndEditing), for: .editingDidEnd)
        self.addTarget(self, action: #selector(SearchTextField.textFieldDidEndEditingOnExit), for: .editingDidEndOnExit)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SearchTextField.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchTextField.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        buildSearchTableView()
        buildPlaceholderLabel()
        
        // Create the loading indicator
        indicator.hidesWhenStopped = true
        self.rightView = indicator
    }
    
    override open func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rightFrame = super.rightViewRect(forBounds: bounds)
        rightFrame.origin.x -= 5
        return rightFrame
    }
    
    // Create the filter table and shadow view
    fileprivate func buildSearchTableView() {
        if let tableView = tableView, let shadowView = shadowView {
            tableView.layer.masksToBounds = true
            tableView.layer.borderWidth = 0.5
            tableView.dataSource = self
            tableView.delegate = self
            tableView.separatorInset = UIEdgeInsets.zero
            
            shadowView.backgroundColor = UIColor.white
            shadowView.layer.shadowColor = UIColor.black.cgColor
            shadowView.layer.shadowOffset = CGSize.zero
            shadowView.layer.shadowOpacity = 1
            
            superview?.addSubview(tableView)
            superview?.addSubview(shadowView)
        } else {
            tableView = UITableView(frame: CGRect.zero)
            shadowView = UIView(frame: CGRect.zero)
        }
        
        redrawSearchTableView()
    }
    
    fileprivate func buildPlaceholderLabel() {
        var textRect = self.textRect(forBounds: self.bounds)
        textRect.origin.y -= 1
        
        if let placeholderLabel = placeholderLabel {
            placeholderLabel.font = self.font
            placeholderLabel.frame = textRect
        } else {
            placeholderLabel = UILabel(frame: textRect)
            placeholderLabel?.font = self.font
            placeholderLabel?.textColor = UIColor ( red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0 )
            placeholderLabel?.backgroundColor = UIColor.clear
            placeholderLabel?.lineBreakMode = .byClipping

            self.addSubview(placeholderLabel!)
        }
    }
    
    // Re-set frames and theme colors
    fileprivate func redrawSearchTableView() {
        if inlineMode {
            tableView?.isHidden = true
            return
        }
        
        if let tableView = tableView {
            let positionGap: CGFloat = 10
            
            if self.direction == .down {
                var tableHeight = min((tableView.contentSize.height + positionGap), (UIScreen.main.bounds.size.height - frame.origin.y - theme.cellHeight))
                
                if maxResultsListHeight > 0 {
                    tableHeight = min(tableHeight, CGFloat(self.maxResultsListHeight))
                }
                
                tableView.frame = CGRect(x: frame.origin.x + 2, y: (frame.origin.y + frame.size.height - positionGap), width: frame.size.width - 4, height: tableHeight)
                shadowView!.frame = CGRect(x: frame.origin.x + 3, y: (frame.origin.y + frame.size.height - 3), width: frame.size.width - 6, height: 1)
                tableView.contentInset = UIEdgeInsets(top: positionGap, left: 0, bottom: 0, right: 0)
                tableView.contentOffset = CGPoint(x: 0, y: -positionGap)
            } else {
                let tableHeight = min((tableView.contentSize.height + positionGap), (UIScreen.main.bounds.size.height - frame.origin.y - theme.cellHeight * 2))
                tableView.frame = CGRect(x: frame.origin.x + 2, y: (frame.origin.y - tableHeight + positionGap), width: frame.size.width - 4, height: tableHeight)
                shadowView!.frame = CGRect(x: frame.origin.x + 3, y: (frame.origin.y + 3), width: frame.size.width - 6, height: 1)
                tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
                tableView.contentOffset = CGPoint(x: 0, y: 0)
            }
            
            superview?.bringSubview(toFront: tableView)
            superview?.bringSubview(toFront: shadowView!)
            
            if self.isFirstResponder {
                superview?.bringSubview(toFront: self)
            }

            tableView.layer.borderColor = theme.borderColor.cgColor
            tableView.separatorColor = theme.separatorColor
            tableView.backgroundColor = theme.bgColor
            
            tableView.reloadData()
        }
    }
    
    // Handle keyboard events
    open func keyboardWillShow(_ notification: Notification) {
        keyboardFrame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        if let keyboardFrame = keyboardFrame {
            var newFrame = frame
            newFrame.size.height += theme.cellHeight
            
            if keyboardFrame.intersects(newFrame) {
                direction = .up
            } else {
                direction = .down
            }
            
            redrawSearchTableView()
        }
    }
    
    open func keyboardWillHide(_ notification: Notification) {
        direction = .down
        redrawSearchTableView()
    }
    
    open func typingDidStop() {
        if userStoppedTypingHandler != nil {
            self.userStoppedTypingHandler!()
        }
    }
    
    // Handle text field changes
    open func textFieldDidChange() {
        // Detect pauses while typing
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(SearchTextField.typingDidStop), userInfo: self, repeats: false)
        
        if text!.isEmpty {
            clearResults()
            tableView?.reloadData()
            self.placeholderLabel?.text = ""
        } else {
            filter(false)
        }
    }
    
    open func textFieldDidBeginEditing() {
        if startVisible && text!.isEmpty {
            clearResults()
            filter(true)
        }
        placeholderLabel?.attributedText = nil
    }
    
    open func textFieldDidEndEditing() {
        clearResults()
        tableView?.reloadData()
        placeholderLabel?.attributedText = nil
    }

    open func textFieldDidEndEditingOnExit() {
        self.text = filteredResults.first?.title
    }

    fileprivate func filter(_ addAll: Bool) {
        clearResults()
        
        for i in 0 ..< filterDataSource.count {
            
            var item = filterDataSource[i]
            
            if !inlineMode {
                // Find text in title and subtitle
                let titleFilterRange = (item.title as NSString).range(of: text!, options: .caseInsensitive)
                let subtitleFilterRange = item.subtitle != nil ? (item.subtitle! as NSString).range(of: text!, options: .caseInsensitive) : NSMakeRange(NSNotFound, 0)
                
                if titleFilterRange.location != NSNotFound || subtitleFilterRange.location != NSNotFound || addAll {
                    item.attributedTitle = NSMutableAttributedString(string: item.title)
                    item.attributedSubtitle = NSMutableAttributedString(string: (item.subtitle != nil ? item.subtitle! : ""))
                    
                    item.attributedTitle!.setAttributes(highlightAttributes, range: titleFilterRange)
                    
                    if subtitleFilterRange.location != NSNotFound {
                        item.attributedSubtitle!.setAttributes(highlightAttributesForSubtitle(), range: subtitleFilterRange)
                    }
                    
                    filteredResults.append(item)
                }
            } else {
                if item.title.lowercased().hasPrefix(text!.lowercased()) {
                    item.attributedTitle = NSMutableAttributedString(string: item.title)
                    item.attributedTitle?.addAttribute(NSForegroundColorAttributeName, value: UIColor.clear, range: NSRange(location:0, length:text!.characters.count))
                    filteredResults.append(item)
                }
            }
            
        }
    
        tableView?.reloadData()
        
        if inlineMode {
            handleInlineFiltering()
        }
    }
    
    // Clean filtered results
    fileprivate func clearResults() {
        filteredResults.removeAll()
    }
    
    // Look for Font attribute, and if it exists, adapt to the subtitle font size
    fileprivate func highlightAttributesForSubtitle() -> [String: AnyObject] {
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
    
    // Handle inline behaviour
    func handleInlineFiltering() {
        if let text = self.text {
            if text == "" {
                self.placeholderLabel?.attributedText = nil
            } else {
                if let firstResult = filteredResults.first {
                    self.placeholderLabel?.attributedText = firstResult.attributedTitle
                } else {
                    self.placeholderLabel?.attributedText = nil
                }
            }
        }
    }
}

extension SearchTextField: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.isHidden = (filteredResults.count == 0)
        shadowView?.isHidden = (filteredResults.count == 0)
        
        if maxNumberOfResults > 0 {
            return min(filteredResults.count, maxNumberOfResults)
        } else {
            return filteredResults.count
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: SearchTextField.cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: SearchTextField.cellIdentifier)
        }
        
        cell!.backgroundColor = UIColor.clear
        cell!.layoutMargins = UIEdgeInsets.zero
        cell!.preservesSuperviewLayoutMargins = false
        cell!.textLabel?.font = theme.font
        cell!.detailTextLabel?.font = UIFont(name: theme.font.fontName, size: theme.font.pointSize * fontConversionRate)
        cell!.textLabel?.textColor = theme.fontColor
        cell!.detailTextLabel?.textColor = theme.fontColor
        
        cell!.textLabel?.text = filteredResults[(indexPath as NSIndexPath).row].title
        cell!.detailTextLabel?.text = filteredResults[(indexPath as NSIndexPath).row].subtitle
        cell!.textLabel?.attributedText = filteredResults[(indexPath as NSIndexPath).row].attributedTitle
        cell!.detailTextLabel?.attributedText = filteredResults[(indexPath as NSIndexPath).row].attributedSubtitle

        cell!.imageView?.image = filteredResults[(indexPath as NSIndexPath).row].image
        
        cell!.selectionStyle = .none
        
        return cell!
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return theme.cellHeight
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if itemSelectionHandler == nil {
            self.text = filteredResults[(indexPath as NSIndexPath).row].title
        } else {
            itemSelectionHandler!(filteredResults[(indexPath as NSIndexPath).row])
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
        return SearchTextFieldTheme(cellHeight: 30, bgColor: UIColor (red: 1, green: 1, blue: 1, alpha: 0.6), borderColor: UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0), separatorColor: UIColor.clear, font: UIFont.systemFont(ofSize: 10), fontColor: UIColor.black)
    }
    
    public static func darkTheme() -> SearchTextFieldTheme {
        return SearchTextFieldTheme(cellHeight: 30, bgColor: UIColor (red: 0.8, green: 0.8, blue: 0.8, alpha: 0.6), borderColor: UIColor (red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0), separatorColor: UIColor.clear, font: UIFont.systemFont(ofSize: 10), fontColor: UIColor.white)
    }
}

////////////////////////////////////////////////////////////////////////
// Filter Item

public struct SearchTextFieldItem {
    // Private vars
    fileprivate var attributedTitle: NSMutableAttributedString?
    fileprivate var attributedSubtitle: NSMutableAttributedString?

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

public typealias SearchTextFieldItemHandler = (_ item: SearchTextFieldItem) -> Void

////////////////////////////////////////////////////////////////////////
// Suggestions List Direction

enum Direction {
    case down
    case up
}
