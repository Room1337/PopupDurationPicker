//
//  ViewController.m
//  PopupDurationPickerDemo
//
//  Created by Pierre Houston on 2013-09-08.
//  Copyright (c) 2013 Room1337. All rights reserved.
//

#import "ViewController.h"
#import "PopupDurationPicker.h"
#import "ARCHelper.h"

@interface ViewController () <UITableViewDelegate>
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) UIInterfaceOrientation pickerOrientation;
@end

@implementation ViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// if embedded table view controller spotted getting embedded, get the correct orientation from it
	// (if no such embedded view controller, pickerOrientation goes uninitialized, i'm not gonna worry about it)
	if ([segue.destinationViewController isKindOfClass:[TableViewController class]])
		self.pickerOrientation = ((TableViewController *)segue.destinationViewController).chosenOrientation;
}

- (void)orientationChosen:(id)sender
{
	self.pickerOrientation = ((TableViewController *)sender).chosenOrientation;
}

- (IBAction)squareTapped:(id)sender
{
	if (![(NSObject *)sender isKindOfClass:[UIView class]])
		return;
	
	// this is the rect that the popup points towards
	CGRect sourceRect = ((UIView *)sender).frame;
	
	PopupDurationPicker *picker = [[[PopupDurationPicker alloc] init] autorelease];
	picker.title = @"Demo";
	picker.target = self;
	picker.action = @selector(durationPicked:);
	picker.value = self.duration;
	picker.minimumSeconds = 5;
	[picker showInView:self.view fromRect:sourceRect withOrientation:self.pickerOrientation];
	// i needed a feature for rotating subviews while keeping my main view portrait, so i added the orientation parameter
	// to keep the popup aligned with the view's normal autorotation, should normally use the method that omits withOrientation:
	// (or pass in UIInterfaceOrientationPortrait)
}

- (void)durationPicked:(id)sender
{
	self.duration = ((PopupDurationPicker *)sender).value;
}

@end


// the embedded table view controller with static contents
// can't make the parent view controller the table view delegate
// so need our own mechanism to inform it of changes to the orientation chose

@interface TableViewController ()
@property (nonatomic, assign, readwrite) UIInterfaceOrientation chosenOrientation;
@end

@implementation TableViewController

- (void)viewDidLoad
{
	self.chosenOrientation = UIInterfaceOrientationPortrait;
	
	UITableView *tableView = (UITableView *)self.view;
	
	// if nib checks one of the rows, then make that one the default instead (kinda unnecessary)
	for (NSInteger i = 0, n = [tableView numberOfRowsInSection:0]; i < n; ++i)
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
			self.chosenOrientation = [self orientationForRow:i];
			break;
		}
	}
	
	// make sure chosen row is checked and all others aren't
	for (NSInteger i = 0, n = [tableView numberOfRowsInSection:0]; i < n; ++i)
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
		cell.accessoryType = ([self orientationForRow:i] == self.chosenOrientation) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	}
}

- (UIInterfaceOrientation)orientationForRow:(NSInteger)row
{
	switch (row) {
		case 0: default: return UIInterfaceOrientationPortrait;
		case 1: return UIInterfaceOrientationLandscapeLeft;
		case 2: return UIInterfaceOrientationLandscapeRight;
		case 3: return UIInterfaceOrientationPortraitUpsideDown;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// don't stay selected
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	// remove checkmark from others cells, add checkmark to this one
	for (NSInteger i = 0, n = [tableView numberOfRowsInSection:0]; i < n; ++i)
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
		cell.accessoryType = (i == indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	}
	
	// set our public property
	self.chosenOrientation = [self orientationForRow:indexPath.row];
	
	// ping parent view controller
	if ([self.parentViewController isKindOfClass:[ViewController class]])
		[(ViewController *)self.parentViewController orientationChosen:self];
}

@end
