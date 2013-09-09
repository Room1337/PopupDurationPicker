//
//  PopupDurationPicker.h
//  PopupDurationPicker
//
//  Created by Pierre Houston on 2013-08-28.
//  Copyright (c) 2013 Room1337 Ventures. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "KxMenu.h"

@protocol PopupDurationPickerDelegate;


@interface PopupDurationPicker : KxMenu

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSUInteger minimumSeconds;
@property (nonatomic, assign) NSUInteger maximumMinutes;
@property (nonatomic, assign) CGFloat contentWidth;
@property (nonatomic, retain) UIView *extraView; // unused thus far

@property (nonatomic, assign) NSTimeInterval value;

@property (nonatomic, unsafe_unretained) id target;
@property (nonatomic, assign) SEL action; // called when value changed (not on dismissal)
@property (nonatomic, unsafe_unretained) id<PopupDurationPickerDelegate> delegate;

- (id)initWithTitle:(NSString *)titleString value:(NSTimeInterval)initialValue
		 minSeconds:(NSInteger)minSeconds maxMinutes:(NSInteger)maxMinutes;

- (void)showInView:(UIView *)parentView fromRect:(CGRect)originFrame;
- (void)showInView:(UIView *)parentView fromRect:(CGRect)originFrame withOrientation:(UIInterfaceOrientation)orientation;

- (void)dismiss;

@end


@protocol PopupDurationPickerDelegate <NSObject>
@optional
- (void)willDismissPopupDurationPicker:(PopupDurationPicker *)popup;
- (void)didDismissPopupDurationPicker:(PopupDurationPicker *)popup;
- (void)didChangeValueFrom:(NSTimeInterval)oldValue ofPopupDurationPicker:(PopupDurationPicker *)popup;
@end
