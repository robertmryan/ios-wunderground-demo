//
//  ViewController.h
//  Weather
//
//  Created by Robert Ryan on 11/6/12.
//  Copyright (c) 2012 Robert Ryan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *zipCodePromptLabel;
@property (weak, nonatomic) IBOutlet UITextField *zipCodeTextField;
@property (weak, nonatomic) IBOutlet UIButton *zipCodeGoButton;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *pressureMbLabel;
@property (weak, nonatomic) IBOutlet UILabel *tempCLabel;

- (IBAction)pressedZipCodeGoButton:(id)sender;

@end
