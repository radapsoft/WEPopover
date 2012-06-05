//
//  WEPopoverContainerView.h
//  WEPopover
//
//  Created by Werner Altewischer on 02/09/10.
//  Copyright 2010 Werner IT Consultancy. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @brief Properties for the container view determining the area where the actual content view can/may be displayed. Also Images can be supplied for the arrow images and background.
 */
@interface WEPopoverContainerViewProperties : NSObject
{
	NSString *bgImageName;
	NSString *upArrowImageName;
	NSString *downArrowImageName;
	NSString *leftArrowImageName;
	NSString *rightArrowImageName;
	CGFloat leftBgMargin;
	CGFloat rightBgMargin;
	CGFloat topBgMargin;
	CGFloat bottomBgMargin;
	NSInteger topBgCapSize;
	NSInteger leftBgCapSize;
	CGFloat arrowMargin;
}

@property(nonatomic, strong) NSString *bgImageName;
@property(nonatomic, strong) NSString *upArrowImageName;
@property(nonatomic, strong) NSString *downArrowImageName;
@property(nonatomic, strong) NSString *leftArrowImageName;
@property(nonatomic, strong) NSString *rightArrowImageName;
@property(nonatomic) CGFloat leftBgMargin;
@property(nonatomic) CGFloat rightBgMargin;
@property(nonatomic) CGFloat topBgMargin;
@property(nonatomic) CGFloat bottomBgMargin;
@property(nonatomic) CGFloat leftContentMargin;
@property(nonatomic) CGFloat rightContentMargin;
@property(nonatomic) CGFloat topContentMargin;
@property(nonatomic) CGFloat bottomContentMargin;
@property(nonatomic) NSInteger topBgCapSize;
@property(nonatomic) NSInteger leftBgCapSize;
@property(nonatomic) CGFloat arrowMargin;

@end

@class WEPopoverContainerView;

/**
 * @brief Container/background view for displaying a popover view.
 */
@interface WEPopoverContainerView : UIView {
	UIImage *bgImage;
	UIImage *arrowImage;
	
	WEPopoverContainerViewProperties *properties;
	
	UIPopoverArrowDirection arrowDirection;
	
	CGRect arrowRect;
	CGRect bgRect;
	CGPoint offset;
	CGPoint arrowOffset;
	
	CGSize correctedSize;
	UIView *contentView;
}

/**
 * @brief The current arrow direction for the popover.
 */
@property (nonatomic, readonly) UIPopoverArrowDirection arrowDirection;

/**
 * @brief The content view being displayed.
 */
@property (nonatomic, strong) UIView *contentView;

/**
 * @brief Initializes the position of the popover with a size, anchor rect, display area and permitted arrow directions and optionally the properties. 
 * If the last is not supplied the defaults are taken (requires images to be present in bundle representing a black rounded background with partial transparency).
 */
- (id)initWithSize:(CGSize)theSize 
		anchorRect:(CGRect)anchorRect 
	   displayArea:(CGRect)displayArea
permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections
		properties:(WEPopoverContainerViewProperties *)properties;	

/**
 * @brief To update the position of the popover with a new anchor rect, display area and permitted arrow directions
 */
- (void)updatePositionWithAnchorRect:(CGRect)anchorRect 
						 displayArea:(CGRect)displayArea
			permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections;	

@end
