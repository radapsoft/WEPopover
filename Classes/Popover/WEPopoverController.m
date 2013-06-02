//
//  WEPopoverController.m
//  WEPopover
//
//  Created by Werner Altewischer on 02/09/10.
//  Copyright 2010 Werner IT Consultancy. All rights reserved.
//

#import "WEPopoverController.h"
#import "WEPopoverParentView.h"
#import "UIBarButtonItem+WEPopover.h"

#define FADE_DURATION 0.25

@interface WEPopoverController(Private)

- (UIView *)keyView;
- (void)updateBackgroundPassthroughViews;
- (void)setView:(UIView *)v;
- (CGRect)displayAreaForView:(UIView *)theView;
- (WEPopoverContainerViewProperties *)defaultContainerViewProperties;
- (void)dismissPopoverAnimated:(BOOL)animated userInitiated:(BOOL)userInitiated;

@end


@implementation WEPopoverController

@synthesize contentViewController;
@synthesize popoverContentSize;
@synthesize popoverVisible;
@synthesize popoverArrowDirection;
@synthesize delegate;
@synthesize view;
@synthesize containerViewProperties;
@synthesize context;
@synthesize passthroughViews;

- (id)init {
	if ((self = [super init])) {
	}
	return self;
}

- (id)initWithContentViewController:(UIViewController *)viewController {
	if ((self = [self init])) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone )
        {
            self.contentViewController  = viewController;
            iosPopover                  = nil;
        }
        else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad )
        {
            iosPopover                  = [[UIPopoverController alloc] initWithContentViewController:
                                            viewController];
            iosPopover.delegate         = self;
        }
	}
	return self;
}

- (void)dealloc {
    if ( iosPopover == nil )
    {
        [self dismissPopoverAnimated:NO];
        self.context = nil;
    }
}

- (void)setContentViewController:(UIViewController *)vc {
	if ( iosPopover == nil )
    {
        if ( vc != contentViewController) {
            contentViewController = vc;
            popoverContentSize = CGSizeZero;
        }
    }
    else
    {
        iosPopover.contentViewController = vc;
    }
}

//Overridden setter to copy the passthroughViews to the background view if it exists already
- (void)setPassthroughViews:(NSArray *)array {
    if ( iosPopover == nil )
    {
        passthroughViews = nil;
        if (array) {
            passthroughViews = [[NSArray alloc] initWithArray:array];
        }
        [self updateBackgroundPassthroughViews];
    }
    else
    {
        iosPopover.passthroughViews = array;
    }
}

- (UIViewController*)contentViewController
{
    if ( iosPopover == nil )
    {
        return contentViewController;
    }
    else
    {
        return iosPopover.contentViewController;
    }
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)theContext {
	if ( iosPopover == nil )
    {
        if ([animationID isEqual:@"FadeIn"]) {
            self.view.userInteractionEnabled = YES;
            popoverVisible = YES;
            [contentViewController viewDidAppear:YES];
        } else {
            popoverVisible = NO;
            [contentViewController viewDidDisappear:YES];
            [self.view removeFromSuperview];
            self.view = nil;
            [backgroundView removeFromSuperview];
            backgroundView = nil;
            
            BOOL userInitiatedDismissal = [(__bridge NSNumber *)theContext boolValue];
            
            if (userInitiatedDismissal) {
                //Only send message to delegate in case the user initiated this event, which is if he touched outside the view
                [delegate popoverControllerDidDismissPopover:self];
            }
        }
    }
}

- (void)dismissPopoverAnimated:(BOOL)animated {
	if ( iosPopover == nil )
    {
        [self dismissPopoverAnimated:animated userInitiated:NO];
    }
    else
    {
        [iosPopover dismissPopoverAnimated:animated];
    }
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
			   permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections 
							   animated:(BOOL)animated {
	if ( iosPopover == nil )
    {
        UIView *v = [self keyView];
        CGRect rect = [item frameInView:v];
        
        return [self presentPopoverFromRect:rect inView:v permittedArrowDirections:arrowDirections animated:animated];
    }
    else
    {
        [iosPopover presentPopoverFromBarButtonItem:item
                           permittedArrowDirections:arrowDirections
                                           animated:animated];
    }
}

- (void)presentPopoverFromRect:(CGRect)rect
						inView:(UIView *)theView 
	  permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections 
					  animated:(BOOL)animated {
	
	if ( iosPopover == nil )
    {
        [self dismissPopoverAnimated:NO];
        
        //First force a load view for the contentViewController so the popoverContentSize is properly initialized
        UIView*		contentViewObj	= [contentViewController view];
        
        if (CGSizeEqualToSize(popoverContentSize, CGSizeZero)) {
            popoverContentSize = contentViewController.contentSizeForViewInPopover;
        }
        
        CGRect displayArea = [self displayAreaForView:theView];
        
        WEPopoverContainerViewProperties *props = self.containerViewProperties ? self.containerViewProperties : [self defaultContainerViewProperties];
        WEPopoverContainerView *containerView = [[WEPopoverContainerView alloc] initWithSize:self.popoverContentSize anchorRect:rect displayArea:displayArea permittedArrowDirections:arrowDirections properties:props];
        popoverArrowDirection = containerView.arrowDirection;
        
        UIView *keyView = self.keyView;
        
        backgroundView = [[WETouchableView alloc] initWithFrame:keyView.bounds];
        backgroundView.contentMode = UIViewContentModeScaleToFill;
        backgroundView.autoresizingMask = ( UIViewAutoresizingFlexibleLeftMargin |
                                           UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleRightMargin |
                                           UIViewAutoresizingFlexibleTopMargin |
                                           UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleBottomMargin);
        backgroundView.backgroundColor = [UIColor clearColor];
        backgroundView.delegate = self;
        
        [keyView addSubview:backgroundView];
        
        containerView.frame = [theView convertRect:containerView.frame toView:backgroundView];
        
        [backgroundView addSubview:containerView];
        
        containerView.contentView = contentViewController.view;
        containerView.autoresizingMask = ( UIViewAutoresizingFlexibleLeftMargin |
                                          UIViewAutoresizingFlexibleRightMargin);
        
        self.view = containerView;
        [self updateBackgroundPassthroughViews];
        
        [contentViewController viewWillAppear:animated];
        
        [self.view becomeFirstResponder];
        
        if (animated) {
            self.view.alpha = 0.0;
            
            [UIView beginAnimations:@"FadeIn" context:nil];
            
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            [UIView setAnimationDuration:FADE_DURATION];
            
            self.view.alpha = 1.0;
            
            [UIView commitAnimations];
        } else {
            popoverVisible = YES;
            [contentViewController viewDidAppear:animated];
        }
    }
    else
    {
        [iosPopover presentPopoverFromRect:rect
                                    inView:theView
                  permittedArrowDirections:arrowDirections
                                  animated:animated];
    }
}

/*
- (void)repositionPopoverFromRect:(CGRect)rect
						   inView:(UIView *)theView
		 permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections {
	
	CGRect displayArea = [self displayAreaForView:theView];
	WEPopoverContainerView *containerView = (WEPopoverContainerView *)self.view;
	[containerView updatePositionWithAnchorRect:rect
									displayArea:displayArea
					   permittedArrowDirections:arrowDirections];
	
	popoverArrowDirection = containerView.arrowDirection;
	containerView.frame = [theView convertRect:containerView.frame toView:backgroundView];
}
 */

#pragma mark -
#pragma mark WETouchableViewDelegate implementation

- (void)viewWasTouched:(WETouchableView *)view {
    if ( iosPopover == nil )
    {
        if (popoverVisible) {
            if (!delegate || [delegate popoverControllerShouldDismissPopover:self]) {
                [self dismissPopoverAnimated:YES userInitiated:YES];
            }
        }
    }
}

@end


@implementation WEPopoverController(Private)

- (UIView *)keyView {
    if ( iosPopover == nil )
    {
        UIWindow *w = [[UIApplication sharedApplication] keyWindow];
        if (w.subviews.count > 0) {
            return [w.subviews objectAtIndex:0];
        } else {
            return w;
        }
    }
    else
    {
        NSLog(@"unexpected code path");
        abort();
    }
}

- (void)setView:(UIView *)v {
    if ( iosPopover == nil )
    {
        if (view != v) {
            view = v;
        }
    }
}

- (void)updateBackgroundPassthroughViews {
    if ( iosPopover == nil )
    {
        backgroundView.passthroughViews = passthroughViews;
    }
}


- (void)dismissPopoverAnimated:(BOOL)animated userInitiated:(BOOL)userInitiated {
	if (self.view) {
		[contentViewController viewWillDisappear:animated];
		popoverVisible = NO;
		[self.view resignFirstResponder];
		if (animated) {
			
			self.view.userInteractionEnabled = NO;
			[UIView beginAnimations:@"FadeOut" context:(__bridge_retained void*)[NSNumber numberWithBool:userInitiated]];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
			
			[UIView setAnimationDuration:FADE_DURATION];
			
			self.view.alpha = 0.0;
			
			[UIView commitAnimations];
		} else {
			[contentViewController viewDidDisappear:animated];
			[self.view removeFromSuperview];
			self.view = nil;
			[backgroundView removeFromSuperview];
			backgroundView = nil;
		}
	}
}

- (CGRect)displayAreaForView:(UIView *)theView {
    if ( iosPopover == nil )
    {
        CGRect displayArea = CGRectZero;
        if ([theView conformsToProtocol:@protocol(WEPopoverParentView)] && [theView respondsToSelector:@selector(displayAreaForPopover)]) {
            displayArea = [(id <WEPopoverParentView>)theView displayAreaForPopover];
        } else {
            displayArea = [[[UIApplication sharedApplication] keyWindow] convertRect:[[UIScreen mainScreen] applicationFrame] toView:theView];
        }
        return displayArea;
    }
    else
    {
        NSLog(@"unexpected code path");
        abort();
    }
}

//Enable to use the simple popover style
/*
- (WEPopoverContainerViewProperties *)defaultContainerViewProperties {
	WEPopoverContainerViewProperties *ret = [WEPopoverContainerViewProperties new];
	
	CGSize imageSize = CGSizeMake(30.0f, 30.0f);
	NSString *bgImageName = @"popoverBgSimple.png";
	CGFloat bgMargin = 6.0;
	CGFloat contentMargin = 2.0;
	
	ret.leftBgMargin = bgMargin;
	ret.rightBgMargin = bgMargin;
	ret.topBgMargin = bgMargin;
	ret.bottomBgMargin = bgMargin;
	ret.leftBgCapSize = imageSize.width/2;
	ret.topBgCapSize = imageSize.height/2;
	ret.bgImageName = bgImageName;
	ret.leftContentMargin = contentMargin;
	ret.rightContentMargin = contentMargin;
	ret.topContentMargin = contentMargin;
	ret.bottomContentMargin = contentMargin;
	ret.arrowMargin = 1.0;
	
	ret.upArrowImageName = @"popoverArrowUpSimple.png";
	ret.downArrowImageName = @"popoverArrowDownSimple.png";
	ret.leftArrowImageName = @"popoverArrowLeftSimple.png";
	ret.rightArrowImageName = @"popoverArrowRightSimple.png";
	return ret;
}
*/

/**
 Thanks to Paul Solt for supplying these background images and container view properties
 */
- (WEPopoverContainerViewProperties *)defaultContainerViewProperties {
	
	WEPopoverContainerViewProperties *props = [WEPopoverContainerViewProperties alloc];
	NSString *bgImageName = nil;
	CGFloat bgMargin = 0.0;
	CGFloat bgCapSize = 0.0;
	CGFloat contentMargin = 4.0;
	
	bgImageName = @"popoverBg.png";
	
	// These constants are determined by the popoverBg.png image file and are image dependent
	bgMargin = 13; // margin width of 13 pixels on all sides popoverBg.png (62 pixels wide - 36 pixel background) / 2 == 26 / 2 == 13 
	bgCapSize = 31; // ImageSize/2  == 62 / 2 == 31 pixels
	
	props.leftBgMargin = bgMargin;
	props.rightBgMargin = bgMargin;
	props.topBgMargin = bgMargin;
	props.bottomBgMargin = bgMargin;
	props.leftBgCapSize = bgCapSize;
	props.topBgCapSize = bgCapSize;
	props.bgImageName = bgImageName;
	props.leftContentMargin = contentMargin;
	props.rightContentMargin = contentMargin - 1; // Need to shift one pixel for border to look correct
	props.topContentMargin = contentMargin; 
	props.bottomContentMargin = contentMargin;
	
	props.arrowMargin = 4.0;
	
	props.upArrowImageName = @"popoverArrowUp.png";
	props.downArrowImageName = @"popoverArrowDown.png";
	props.leftArrowImageName = @"popoverArrowLeft.png";
	props.rightArrowImageName = @"popoverArrowRight.png";
	return props;	
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self.delegate popoverControllerDidDismissPopover:self];
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return [self.delegate popoverControllerShouldDismissPopover:self];
}

@end
