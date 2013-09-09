//
//  ViewController.h
//  PopupDurationPickerDemo
//
//  Created by Pierre Houston on 2013-09-08.
//  Copyright (c) 2013 Room1337. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (IBAction)squareTapped:(id)sender;

- (void)orientationChosen:(id)sender;

@end

// the embdedded tableview controller
@interface TableViewController : UITableViewController
@property (nonatomic, assign, readonly) UIInterfaceOrientation chosenOrientation;
@end
