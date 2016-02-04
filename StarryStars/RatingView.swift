//
//  RatingView.swift
//
//  Created by Peter Prokop on 18/10/15.
//  Copyright © 2015 Peter Prokop. All rights reserved.
//

import UIKit

@objc public protocol RatingViewDelegate {
    /**
     Called when user's touch ends
     
     - parameter ratingView: Rating view, which calls this method
     - parameter didChangeRating newRating: New rating
     */
    func ratingView(ratingView: RatingView, didChangeRating newRating: Float)
}

/**
 Rating bar, fully customisable from Interface builder
 */
@IBDesignable
public class RatingView: UIView {
    
    /// Total number of stars
    @IBInspectable public var starCount: Int = 5
    
    /// Image of unlit star, if nil "starryStars_off" is used
    @IBInspectable public var offImage: UIImage?
    
    /// Image of fully lit star, if nil "starryStars_on" is used
    @IBInspectable public var onImage: UIImage?
    
    /// Image of half-lit star, if nil "starryStars_half" is used
    @IBInspectable public var halfImage: UIImage?
    
    /// Current rating, updates star images after setting
    @IBInspectable public var rating: Float = Float(0) {
        didSet {
            // If rating is more than starCount simply set it to starCount
            rating = min(Float(starCount), rating)
            
            updateRating()
        }
    }
    
    /// If set to "false" only full stars will be lit
    @IBInspectable public var halfStarsAllowed: Bool = true
    
    /// If set to "false" user will not be able to edit the rating
    @IBInspectable public var editable: Bool = true
    
    
    /// Delegate, must confrom to *RatingViewDelegate* protocol
    public weak var delegate: RatingViewDelegate?
    
    var stars = [UIImageView]()
    var ratingCandidate: Float = 0.0
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        customInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        customInit()
    }
    
    override public func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        customInit()
    }
    
    func customInit() {
        let bundle = NSBundle(forClass: RatingView.self)
        
        if offImage == nil {
            offImage = UIImage(named: "starryStars_off", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
        }
        if onImage == nil {
            onImage = UIImage(named: "starryStars_on", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
        }
        if halfImage == nil {
            halfImage = UIImage(named: "starryStars_half", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
        }
        
        guard let offImage = offImage else {
            assert(false, "offImage is not set")
            return
        }
        
        for var i = 1; i <= starCount; i++ {
            let iv = UIImageView(image: offImage)
            addSubview(iv)
            stars.append(iv)
            
        }
        
        layoutStars()
        updateRating()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        layoutStars()
    }
    
    func layoutStars() {
        
        if stars.count == 0 {
            return
        }
        guard let offImage = stars.first?.image else {
            return
        }
        
        let imageWidth = offImage.size.width
        let imageHeight = offImage.size.height
        let spacesBetweenStars = (bounds.size.width - (imageWidth * CGFloat(starCount))) / CGFloat(starCount - 1)
        let distance = spacesBetweenStars + imageWidth
        
        var i = 0
        for iv in stars {
            iv.frame = CGRectMake(CGFloat(i) * distance, 0, imageWidth, imageHeight)
            i++
        }
    }
    
    /**
     Compute and adjust rating when user touches begin/move/end
     */
    func handleTouches(touches: Set<UITouch>) {
        let touch = touches.first!
        let touchLocation = touch.locationInView(self)
        
        for var i = starCount - 1; i >= 0; i-- {
            let imageView = stars[i]
            
            let x = touchLocation.x;
            
            if x >= CGRectGetMinX(imageView.frame) {
                let newRating = Float(i) + 1
                rating = newRating == ratingCandidate ? 0 : newRating
                return
            } else if x >= CGRectGetMinX(imageView.frame) && halfStarsAllowed {
                rating = Float(i) + 0.5
                return
            }
        }
        
        rating = 0
    }
    
    /**
     Adjust images on image views to represent new rating
     */
    func updateRating() {
        // To avoid crash when using IB
        if stars.count == 0 {
            return
        }
        
        // Set every full star
        var i = 1
        for ; i <= Int(rating); i++ {
            let star = stars[i-1]
            star.image = onImage
        }
        
        if i > starCount {
            return
        }
        
        // Now add a half star
        if rating - Float(i) + 1 >= 0.5 {
            let star = stars[i-1]
            star.image = halfImage
            i++
        }
        
        
        for ; i <= starCount; i++ {
            let star = stars[i-1]
            star.image = offImage
        }
    }
}

// MARK: Override UIResponder methods

extension RatingView {
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard editable else { return }
        ratingCandidate = rating
        handleTouches(touches)
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard editable else { return }
        handleTouches(touches)
        ratingCandidate = 0.0
        guard let delegate = delegate else { return }
        delegate.ratingView(self, didChangeRating: rating)
    }
}