//
//  PopupDurationPicker.m
//  PopupDurationPicker
//
//  Created by Pierre Houston on 2013-08-28.
//  Copyright (c) 2013 Room1337 Ventures. All Rights Reserved.
//

#import "PopupDurationPicker.h"
#import "KSAdvancedPicker.h"
#import "ARCHelper.h" // for kicks, let's make this source file arc-agnostic too

#define BALLOON_POINT_HEIGHT 10
#define BALLOON_BORDER 6

#define NARROW_BALLOON_POINT_X 16
#define NARROW_BALLOON_EXPAND_X 32
#define NARROW_BALLOON_EXPAND_Y 30

#define REGULAR_BALLOON_POINT_X 21
#define REGULAR_BALLOON_LEFT_EXPAND_X 11
#define REGULAR_BALLOON_RIGHT_EXPAND_X 1
#define REGULAR_BALLOON_EXPAND_Y 30

#define DEFAULT_POPUP_WIDTH 132
#define POPUP_Y_BORDER 6
#define PICKER_Y_OFFSET 12
#define PICKER_X_BORDER 5
#define PICKER_HEIGHT 162
#define PICKER_ROW_HEIGHT 24
#define PICKER_UNIT_X_OFFSET 4
#define PICKER_WHITE_SELECTOR_ALPHA 0.45
#define PICKER_DIGIT_FONT_SIZE 19
#define PICKER_UNITS_FONT_SIZE 19
#define PICKER_DIGIT_WIDTH_FUDGE 1

#define MINUTES_LABEL NSLocalizedString(@"m", @"Duration Picker Minutes Label")
#define SECONDS_LABEL NSLocalizedString(@"s", @"Duration Picker Seconds Label")
#define SAMPLE_SINGLE_DIGITS @"0"
#define SAMPLE_DOUBLE_DIGITS @"00"

NSMutableArray *shownPopupDurationPickers = nil;


@interface PopupDurationPicker () <KSAdvancedPickerDataSource, KSAdvancedPickerDelegate>

@property (nonatomic, retain) UIImage *narrowBalloonImage;
@property (nonatomic, retain) UIImage *regularBalloonLeftImage;
@property (nonatomic, retain) UIImage *regularBalloonRightImage;
@property (nonatomic, retain) UIImage *pointlessBalloonImage;
@property (nonatomic, retain) UIFont *digitsFont;
@property (nonatomic, retain) UIFont *unitsFont;
@property (nonatomic, assign) CGFloat minutesLabelWidth;
@property (nonatomic, assign) CGFloat secondsLabelWidth;
@property (nonatomic, assign) CGFloat minutesDigitsWidth;
@property (nonatomic, assign) CGFloat secondsDigitsWidth;
@property (nonatomic, assign) NSUInteger previousMinutesRow;
@property (nonatomic, assign) NSUInteger previousSecondsRow;

@end



@implementation PopupDurationPicker

- (id)init {
    if (!(self = [super init]))
        return nil;
	[self loadImages];
	self.title = @"";
	self.value = 0;
	self.maximumMinutes = 99;
	self.minimumSeconds = 0;
	self.contentWidth = DEFAULT_POPUP_WIDTH;
    return self;
}

- (id)initWithTitle:(NSString *)titleString value:(NSTimeInterval)initialValue
		 minSeconds:(NSInteger)minSeconds maxMinutes:(NSInteger)maxMinutes
{
    if (!(self = [self init]))
        return nil;
	self.title = titleString;
	self.value = initialValue;
	self.maximumMinutes = maxMinutes;
	self.minimumSeconds = minSeconds;
    return self;
}

- (id)initWithTitle:(NSString *)titleString value:(NSTimeInterval)initialValue
		 minSeconds:(NSInteger)minSeconds maxMinutes:(NSInteger)maxMinutes
			  width:(CGFloat)width extraView:(UIView *)view
{
    if (!(self = [self init]))
        return nil;
	self.title = titleString;
	self.value = initialValue;
	self.maximumMinutes = maxMinutes;
	self.minimumSeconds = minSeconds;
	self.contentWidth = width;
	self.extraView = view;
    return self;
}

- (void)dealloc {
	[self dismissMenu];
	self.title = nil;
	self.extraView = nil;
	self.narrowBalloonImage = nil;
	self.regularBalloonLeftImage = nil;
	self.regularBalloonRightImage = nil;
	self.pointlessBalloonImage = nil;
	[super ah_dealloc];
}

- (void)showInView:(UIView *)parentView fromRect:(CGRect)originFrame {
	[self showInView:parentView fromRect:originFrame withOrientation:UIInterfaceOrientationPortrait];
}

- (void)showInView:(UIView *)parentView fromRect:(CGRect)originFrame withOrientation:(UIInterfaceOrientation)orientation {
	if (self.maximumMinutes > 99) // support no more than 2 digits
		self.maximumMinutes = 99;
	if (self.minimumSeconds >= 60)
		self.minimumSeconds = 59;
	
	if (self.value < 0)
		self.value = 0;
	NSUInteger minutes = self.value / 60;
	if (minutes > self.maximumMinutes)
		minutes = self.maximumMinutes;
	NSUInteger seconds = self.value - minutes * 60;
	if (seconds > 60) // will happen if minutes>maximumMinutes above
		seconds = 60;
	if (minutes == 0 && seconds < self.minimumSeconds)
		seconds = self.minimumSeconds;
	if (minutes * 60 + seconds != self.value)
		self.value = minutes * 60 + seconds;
	
	NSString *minutesAbbreviation = MINUTES_LABEL;
	NSString *secondsAbbreviation = SECONDS_LABEL;
	
	self.digitsFont = [UIFont boldSystemFontOfSize:PICKER_DIGIT_FONT_SIZE];
	self.unitsFont = [UIFont systemFontOfSize:PICKER_UNITS_FONT_SIZE];
	if ([NSString instancesRespondToSelector:@selector(sizeWithAttributes:)]) {
		NSDictionary *unitsStringAttributes = [NSDictionary dictionaryWithObject:self.unitsFont forKey:NSFontAttributeName];
		NSDictionary *digitsStringAttributes = [NSDictionary dictionaryWithObject:self.unitsFont forKey:NSFontAttributeName];
		self.secondsLabelWidth = ceil([secondsAbbreviation sizeWithAttributes:unitsStringAttributes].width);
		self.minutesLabelWidth = ceil([minutesAbbreviation sizeWithAttributes:unitsStringAttributes].width);
		self.secondsDigitsWidth = ceil([SAMPLE_DOUBLE_DIGITS sizeWithAttributes:digitsStringAttributes].width);
		self.minutesDigitsWidth = (self.maximumMinutes >= 10) ? self.secondsDigitsWidth : ceil([SAMPLE_SINGLE_DIGITS sizeWithAttributes:digitsStringAttributes].width);
	} else {
		self.secondsLabelWidth = ceil([secondsAbbreviation sizeWithFont:self.unitsFont].width);
		self.minutesLabelWidth = ceil([minutesAbbreviation sizeWithFont:self.unitsFont].width);
		self.secondsDigitsWidth = ceil([SAMPLE_DOUBLE_DIGITS sizeWithFont:self.digitsFont].width);
		self.minutesDigitsWidth = (self.maximumMinutes >= 10) ? self.secondsDigitsWidth : ceil([SAMPLE_SINGLE_DIGITS sizeWithFont:self.digitsFont].width);
	}
	self.secondsDigitsWidth += PICKER_DIGIT_WIDTH_FUDGE;
	self.minutesDigitsWidth += PICKER_DIGIT_WIDTH_FUDGE;
	
	UILabel *titleLabel = nil;
	CGFloat labelPlusGapHeight = 0;
	if (self.title.length > 0) {
		titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		titleLabel.text = self.title;
		titleLabel.textColor = [UIColor whiteColor];
		titleLabel.backgroundColor = [UIColor blackColor];
		titleLabel.font = [UIFont boldSystemFontOfSize:16];
		[titleLabel sizeToFit];
		CGFloat labelHeight = titleLabel.bounds.size.height;
		titleLabel.center = CGPointMake(floor(self.contentWidth / 2), POPUP_Y_BORDER + floor(labelHeight/2));
		labelPlusGapHeight = labelHeight + PICKER_Y_OFFSET;
	}
	
	CGFloat pickerWidth = self.contentWidth - PICKER_X_BORDER - PICKER_X_BORDER;
	KSAdvancedPicker *picker = [[KSAdvancedPicker alloc] initWithFrame:CGRectMake(PICKER_X_BORDER, labelPlusGapHeight, pickerWidth, PICKER_HEIGHT)];
	picker.dataSource = self;
	picker.delegate = self;
	[picker selectRow:minutes inComponent:0 animated:NO];
	[picker selectRow:seconds inComponent:1 animated:NO];
	self.previousMinutesRow = minutes;
	self.previousSecondsRow = seconds;
	
	CGFloat popUpHeight = POPUP_Y_BORDER + labelPlusGapHeight + PICKER_HEIGHT + POPUP_Y_BORDER;
	UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentWidth, popUpHeight)];
	if (titleLabel) {
		[contentView addSubview:titleLabel];
		[titleLabel release];
	}
	[contentView addSubview:picker];
	[picker release];
	
	[self showMenuInView:parentView fromRect:originFrame withOrientation:orientation subview:contentView];
	[contentView release];
	
	// add to global array of popups to keep a strong reference while the view is showing
	if (!shownPopupDurationPickers)
		shownPopupDurationPickers = [[NSMutableArray alloc] init];
	[shownPopupDurationPickers addObject:self];
}

- (void)dismiss {
	[self dismissMenu];
}

- (void)dismissMenu {
	if (self.delegate && [self.delegate respondsToSelector:@selector(willDismissPopupDurationPicker:)])
		[self.delegate willDismissPopupDurationPicker:self];
	
	[super dismissMenu];
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(didDismissPopupDurationPicker:)])
		[self.delegate didDismissPopupDurationPicker:self];
	
	// remove from global array of popups, if caller has no retain then this should cause the final release
	[shownPopupDurationPickers removeObject:self];
}



#pragma mark - custom menu background

- (void)loadImages
{
	UIImage *image = [UIImage imageNamed:@"popup-balloon1"];
	self.narrowBalloonImage = [image stretchableImageWithLeftCapWidth:NARROW_BALLOON_EXPAND_X topCapHeight:NARROW_BALLOON_EXPAND_Y];
	image = [UIImage imageNamed:@"popup-balloon2a"];
	self.regularBalloonLeftImage = [image stretchableImageWithLeftCapWidth:REGULAR_BALLOON_LEFT_EXPAND_X topCapHeight:REGULAR_BALLOON_EXPAND_Y];
	image = [UIImage imageNamed:@"popup-balloon2b"];
	self.regularBalloonRightImage = [image stretchableImageWithLeftCapWidth:REGULAR_BALLOON_RIGHT_EXPAND_X topCapHeight:REGULAR_BALLOON_EXPAND_Y];
	image = [UIImage imageNamed:@"popup-balloon3"];
	self.pointlessBalloonImage = [image stretchableImageWithLeftCapWidth:floor(image.size.width/2) topCapHeight:floor(image.size.height/2)];
}

- (CGFloat)arrowSize {
	return BALLOON_POINT_HEIGHT;
}

- (CGFloat)innerBorder {
	return BALLOON_BORDER;
}

- (void)setupBackgroundWithSize:(CGSize)size inView:(UIView *)view withArrowDirection:(KxMenuViewArrowDirection)arrowDirection andPosition:(CGFloat)arrowPosition {
    CGRect rect = (CGRect){ CGPointZero, size };
	if (arrowDirection == KxMenuViewArrowDirectionUp || arrowDirection == KxMenuViewArrowDirectionDown) {
		if (arrowPosition < REGULAR_BALLOON_POINT_X || rect.size.width - arrowPosition < REGULAR_BALLOON_POINT_X) {
			UIImageView *balloonImageView = [[UIImageView alloc] initWithImage:self.narrowBalloonImage];
			if (arrowPosition < REGULAR_BALLOON_POINT_X)
				balloonImageView.transform = (arrowDirection == KxMenuViewArrowDirectionUp) ? CGAffineTransformIdentity : CGAffineTransformMakeScale(1, -1);
			else
				balloonImageView.transform = (arrowDirection == KxMenuViewArrowDirectionUp) ? CGAffineTransformMakeScale(-1, 1) : CGAffineTransformMakeScale(-1, -1);
			
			if (rect.size.width < self.narrowBalloonImage.size.width)
				rect.size.width = self.narrowBalloonImage.size.width;
			if (rect.size.height < self.narrowBalloonImage.size.height)
				rect.size.height = self.narrowBalloonImage.size.height;
			balloonImageView.frame = rect;
			
			[view insertSubview:balloonImageView atIndex:0];
			[balloonImageView release];
		} else {
			UIImageView *balloonImageView = [[UIImageView alloc] initWithImage:self.regularBalloonLeftImage];
			UIImageView *balloonImageView2 = [[UIImageView alloc] initWithImage:self.regularBalloonRightImage];
			balloonImageView.transform = balloonImageView2.transform =
				(arrowDirection == KxMenuViewArrowDirectionUp) ? CGAffineTransformIdentity : CGAffineTransformMakeScale(1, -1);
			
			if (rect.size.width < self.regularBalloonLeftImage.size.width + self.regularBalloonRightImage.size.width)
				rect.size.width = self.regularBalloonLeftImage.size.width + self.regularBalloonRightImage.size.width;
			if (rect.size.height < self.regularBalloonLeftImage.size.height)
				rect.size.height = self.regularBalloonLeftImage.size.height;
			NSAssert(arrowPosition - REGULAR_BALLOON_POINT_X >= 0, @"");
			CGRect rectL = (CGRect) { 0, 0, self.regularBalloonLeftImage.size.width + arrowPosition - REGULAR_BALLOON_POINT_X, rect.size.height };
			NSAssert(rect.size.width - rectL.size.width >= self.regularBalloonRightImage.size.width, @"");
			CGRect rectR = (CGRect) { rectL.size.width, 0, rect.size.width - rectL.size.width, rect.size.height };
			balloonImageView.frame = rectL;
			balloonImageView2.frame = rectR;
		
			[view insertSubview:balloonImageView atIndex:0];
			[balloonImageView release];
			[view insertSubview:balloonImageView2 atIndex:0];
			[balloonImageView2 release];
		}
		
	} else if (arrowDirection == KxMenuViewArrowDirectionLeft || arrowDirection == KxMenuViewArrowDirectionRight) {
		if (arrowPosition < REGULAR_BALLOON_POINT_X || rect.size.height - arrowPosition < REGULAR_BALLOON_POINT_X) {
			UIImageView *balloonImageView = [[UIImageView alloc] initWithImage:self.narrowBalloonImage];
			if (arrowPosition < REGULAR_BALLOON_POINT_X)
				balloonImageView.transform = (arrowDirection == KxMenuViewArrowDirectionRight) ? CGAffineTransformMakeRotation(M_PI_2) : CGAffineTransformRotate(CGAffineTransformMakeScale(-1, 1), M_PI_2);
			else
				balloonImageView.transform = (arrowDirection == KxMenuViewArrowDirectionRight) ? CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI_2), -1, 1) : CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI_2), -1, -1);
			
			if (rect.size.width < self.narrowBalloonImage.size.height) // <- note compared to unrotated image height instead of width
				rect.size.width = self.narrowBalloonImage.size.height;
			if (rect.size.height < self.narrowBalloonImage.size.width) // <- note compared to unrotated image width instead of height
				rect.size.height = self.narrowBalloonImage.size.width;
			
			balloonImageView.frame = rect;
			[view insertSubview:balloonImageView atIndex:0];
			[balloonImageView release];
		} else {
			UIImageView *balloonImageView = [[UIImageView alloc] initWithImage:self.regularBalloonLeftImage];
			UIImageView *balloonImageView2 = [[UIImageView alloc] initWithImage:self.regularBalloonRightImage];
			balloonImageView.transform = balloonImageView2.transform =
				(arrowDirection == KxMenuViewArrowDirectionRight) ? CGAffineTransformMakeRotation(M_PI_2) : CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI_2), 1, -1);
			
			if (rect.size.width < self.regularBalloonLeftImage.size.height) // <- note compared to unrotated image height instead of width
				rect.size.width = self.regularBalloonLeftImage.size.height; //    and image height used as width below too
			if (rect.size.height < self.regularBalloonLeftImage.size.width + self.regularBalloonRightImage.size.width) // <- note compared to unrotated image width instead of height
				rect.size.height = self.regularBalloonLeftImage.size.width + self.regularBalloonRightImage.size.width; //    and image width used as height below too
			
			NSAssert(arrowPosition - REGULAR_BALLOON_POINT_X >= 0, @"");
			CGRect rectT = (CGRect) { 0, 0, rect.size.width, self.regularBalloonLeftImage.size.width + arrowPosition - REGULAR_BALLOON_POINT_X };
			NSAssert(rect.size.height - rectT.size.width >= self.regularBalloonRightImage.size.width, @"");
			CGRect rectB = (CGRect) { 0, rectT.size.height, rect.size.width, rect.size.height - rectT.size.height };
			balloonImageView.frame = rectT;
			balloonImageView2.frame = rectB;
			
			[view insertSubview:balloonImageView atIndex:0];
			[balloonImageView release];
			[view insertSubview:balloonImageView2 atIndex:0];
			[balloonImageView2 release];
		}
		
	} else {
		UIImageView *balloonImageView = [[UIImageView alloc] initWithImage:self.pointlessBalloonImage];
		if (rect.size.width < self.pointlessBalloonImage.size.width)
			rect.size.width = self.pointlessBalloonImage.size.width;
		if (rect.size.height < self.pointlessBalloonImage.size.height)
			rect.size.height = self.pointlessBalloonImage.size.height;
		balloonImageView.frame = rect;
		[view insertSubview:balloonImageView atIndex:0];
		[balloonImageView release];
	}
}

- (void)drawBackgroundWithSize:(CGSize)size inContext:(CGContextRef)ref withArrowDirection:(KxMenuViewArrowDirection)arrowDirection andPosition:(CGFloat)arrowPosition {
	// intentionally empty, base class' manual drawing here replaced by subviews setup above that draw themselves
}


#pragma mark - picker

- (NSInteger)numberOfComponentsInAdvancedPicker:(KSAdvancedPicker *)picker {
	return 2;
}

- (NSInteger)advancedPicker:(KSAdvancedPicker *)picker numberOfRowsInComponent:(NSInteger)component {
	if (component == 0)
		return self.maximumMinutes + 1;
	else
		return 60;
}

- (CGFloat)heightForRowInAdvancedPicker:(KSAdvancedPicker *)picker {
	return PICKER_ROW_HEIGHT;
}

- (void)getXPositionsOfMinutesDigit:(CGFloat *)minutesDigitsPos minutesUnit:(CGFloat *)minutesUnitPos secondsDigit:(CGFloat *)secondsDigitsPos secondsUnit:(CGFloat *)secondsUnitPos forPicker:(KSAdvancedPicker *)picker {
	CGFloat workingWidth = picker.frame.size.width;
	workingWidth -= self.minutesDigitsWidth + PICKER_UNIT_X_OFFSET + self.minutesLabelWidth + self.secondsDigitsWidth + PICKER_UNIT_X_OFFSET + self.secondsLabelWidth;
	CGFloat borderWidth = ceil(workingWidth / 3);
	CGFloat separationWidth = workingWidth - borderWidth - borderWidth;
	CGFloat redistribute = floor(separationWidth / 3); // narrow the separation
	separationWidth -= redistribute;
	borderWidth += floor(redistribute / 2); // the other 1/2 ends up on the right border
	if (self.maximumMinutes >= 10)
		borderWidth -= floor(self.secondsDigitsWidth / 4); // further redistribute space from left border to the right
	
	CGFloat pos = borderWidth;
	if (minutesDigitsPos)
		*minutesDigitsPos = pos;
	pos += self.minutesDigitsWidth + PICKER_UNIT_X_OFFSET;
	if (minutesUnitPos)
		*minutesUnitPos = pos;
	pos += self.minutesLabelWidth + separationWidth;
	if (secondsDigitsPos)
		*secondsDigitsPos = pos;
	pos += self.secondsDigitsWidth + PICKER_UNIT_X_OFFSET;
	if (secondsUnitPos)
		*secondsUnitPos = pos;
}

- (CGFloat)advancedPicker:(KSAdvancedPicker *)picker widthForComponent:(NSInteger)component {
	CGFloat secondsDigitsPosition;
	[self getXPositionsOfMinutesDigit:NULL minutesUnit:NULL secondsDigit:&secondsDigitsPosition secondsUnit:NULL forPicker:picker];
	if (component == 0)
		return secondsDigitsPosition; // minutes table extends to the left of the seconds digit
	else
		return picker.frame.size.width - secondsDigitsPosition; // seconds table is what's left
}

- (UIView *)advancedPicker:(KSAdvancedPicker *)picker viewForComponent:(NSInteger)component inRect:(CGRect)rect {
	// rect param is apparently bogus & should be ignored
	CGFloat minutesDigitsPosition;
	CGFloat secondsDigitsPosition;
	[self getXPositionsOfMinutesDigit:&minutesDigitsPosition minutesUnit:NULL secondsDigit:&secondsDigitsPosition secondsUnit:NULL forPicker:picker];
	CGFloat tableWidth;
	CGFloat digitsPosition;
	CGFloat digitsWidth;
	if (component == 0) {
		tableWidth = secondsDigitsPosition; // minutes table extends to the left of the seconds digit
		digitsPosition = minutesDigitsPosition;
		digitsWidth = self.minutesDigitsWidth;
	} else {
		tableWidth = picker.frame.size.width - secondsDigitsPosition; // seconds table is what's left
		digitsPosition = 0; // but the seconds digit starts right at the start of its table
		digitsWidth = self.secondsDigitsWidth;
	}
	
	UIView *parentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableWidth, PICKER_ROW_HEIGHT)];
    parentView.backgroundColor = [UIColor blackColor];
	
	UILabel *digits = [[UILabel alloc] initWithFrame:CGRectMake(digitsPosition, 0, digitsWidth, PICKER_ROW_HEIGHT)];
	digits.font = self.digitsFont;
	digits.textColor = [UIColor whiteColor];
	digits.backgroundColor = [UIColor blackColor];
	digits.textAlignment = NSTextAlignmentRight;
	[parentView addSubview:digits];
	[digits release];
	
	return [parentView autorelease];
}

- (void)advancedPicker:(KSAdvancedPicker *)picker setDataForView:(UIView *)view row:(NSInteger)row inComponent:(NSInteger)component {
	BOOL disableRow = (component == 1 && [picker selectedRowInComponent:0] == 0 && row < self.minimumSeconds);
	
	UILabel *label = (UILabel *)view.subviews.lastObject;
	label.text = [NSString stringWithFormat:@"%d", row];
	label.enabled = !disableRow;
}

- (void)advancedPicker:(KSAdvancedPicker *)picker didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	NSUInteger minutes = (component == 0) ? row : [picker selectedRowInComponent:0];
	NSUInteger seconds = (component == 1) ? row : [picker selectedRowInComponent:1];
	
	if (self.minimumSeconds > 0) { // tweak seconds value & table to account for minimum desired seconds value
		if (component == 0) {
			if (self.previousMinutesRow == 0 && minutes != 0) // reload seconds if minutes changed from 0 to >0
				[picker reloadDataInComponent:1];
			
			else if (self.previousMinutesRow != 0 && minutes == 0) { // reload seconds and maybe adjust if minutes changed from >0 to 0
				if ([picker selectedRowInComponent:1] < self.minimumSeconds)
					[picker selectRow:(seconds = self.minimumSeconds) inComponent:1 animated:YES];
				[picker reloadDataInComponent:1];
			}
			
		} else if (component == 1) {
			if (minutes == 0 && seconds < self.minimumSeconds) // adjust seconds to minimum if changed to <minimum
				[picker selectRow:(seconds = self.minimumSeconds) inComponent:1 animated:YES];
		}
	}
	self.value = minutes * 60 + seconds;
	
	NSTimeInterval previousValue = self.previousMinutesRow * 60 + self.previousSecondsRow;
	if (self.value != previousValue) {
		if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeValueFrom:ofPopupDurationPicker:)])
			[self.delegate didChangeValueFrom:previousValue ofPopupDurationPicker:self];
		
		if (self.target && self.action)
			[[UIApplication sharedApplication] sendAction:self.action to:self.target from:self forEvent:nil];
	}
	
	self.previousMinutesRow = minutes;
	self.previousSecondsRow = seconds;
}

- (UIColor *)backgroundColorForAdvancedPicker:(KSAdvancedPicker *)picker {
	return [UIColor blackColor];
}

- (UIView *)overlayViewForAdvancedPickerSelector:(KSAdvancedPicker *)picker {
	UIView *overlay = [[UIView alloc] initWithFrame:picker.bounds];
	UIColor *solidBlack = [UIColor colorWithWhite:0 alpha:1];
	UIColor *transparent = [UIColor colorWithWhite:0 alpha:0];
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = picker.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)[solidBlack CGColor], (id)[transparent CGColor], (id)[transparent CGColor], (id)[solidBlack CGColor], nil];
	gradient.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0.15], [NSNumber numberWithFloat:0.85], [NSNumber numberWithFloat:1], nil];
	[overlay.layer insertSublayer:gradient atIndex:0];
	return [overlay autorelease];
}

- (UIView *)viewForAdvancedPickerSelector:(KSAdvancedPicker *)picker {
	UIView *selector = [[UIView alloc] initWithFrame:CGRectMake(0, 0, picker.bounds.size.width, PICKER_ROW_HEIGHT)];
	selector.backgroundColor = [UIColor lightGrayColor];
	selector.alpha = PICKER_WHITE_SELECTOR_ALPHA;
	
	CGFloat minutesLabelPosition;
	CGFloat secondsLabelPosition;
	[self getXPositionsOfMinutesDigit:NULL minutesUnit:&minutesLabelPosition secondsDigit:NULL secondsUnit:&secondsLabelPosition forPicker:picker];
	
	UILabel *selectorMinutesLabel = [[UILabel alloc] initWithFrame:CGRectMake(minutesLabelPosition, 0, self.minutesLabelWidth, PICKER_ROW_HEIGHT)];
	selectorMinutesLabel.font = self.unitsFont;
	selectorMinutesLabel.text = MINUTES_LABEL;
	selectorMinutesLabel.textColor = [UIColor blackColor];
	selectorMinutesLabel.backgroundColor = [UIColor clearColor];
	selectorMinutesLabel.textAlignment = NSTextAlignmentRight;
	[selector addSubview:selectorMinutesLabel];
	[selectorMinutesLabel release];
	
	UILabel *selectorSecondsLabel = [[UILabel alloc] initWithFrame:CGRectMake(secondsLabelPosition, 0, self.secondsLabelWidth, PICKER_ROW_HEIGHT)];
	selectorSecondsLabel.font = self.unitsFont;
	selectorSecondsLabel.text = SECONDS_LABEL;
	selectorSecondsLabel.textColor = [UIColor blackColor];
	selectorSecondsLabel.backgroundColor = [UIColor clearColor];
	selectorSecondsLabel.textAlignment = NSTextAlignmentRight;
	[selector addSubview:selectorSecondsLabel];
	[selectorSecondsLabel release];
	
	return [selector autorelease];
}

@end
