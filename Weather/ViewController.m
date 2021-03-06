//
//  ViewController.m
//  Weather
//
//  Created by Robert Ryan on 11/6/12.
//  Copyright (c) 2012 Robert Ryan. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

#warning Replace following value for kWundergroundKey with value of "key id" you get from http://www.wunderground.com/weather/api/

const NSString *kWundergroundKey = @"dxxxxxxxxxxxxxxx";

@interface ViewController () <CLLocationManagerDelegate, UITextFieldDelegate>
{
    CLLocationManager *locationManager;
    UIActivityIndicatorView *activityIndicator;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.statusLabel.text = @"Determining location";
    
    [self hideZipCode:YES animate:NO];
    
    // show spinning activity indicator while load of location/weather information is in progress
    
    [self startActivityIndicator];
    
    // turn on location services so we can determine the current location
    
    [self startSignificantUpdates];
}

// this is a little utility method that
//   (a) sets the status message
//   (b) optionally stops the spinning activity indicator
//   (c) optionally stops the location services; and
//   (d) optionally logs some useful diagnostic information
// we do this because 99% of the time, when we want to update the status message on the UI,
// we also want to take care of the activity indicator and location services at the same time.

- (void)updateStatusMessage:(NSString *)userInterfaceMessage
      stopActivityIndicator:(BOOL)stopActivityIndicator
       stopLocationServices:(BOOL)stopLocationServices
                 logMessage:(id)systemLogInformation
{
    self.statusLabel.text = userInterfaceMessage;
    
    if (stopActivityIndicator)
        [self stopActivityIndicator];
    
    if (stopLocationServices)
        [self stopSignificantUpdates];
    
    // note, we should only use NSLog during diagnostic phase of development;
    // in production app, we should comment out the following NSLog!
    
    if (systemLogInformation)
        NSLog(@"%s %@", __FUNCTION__, @[userInterfaceMessage, systemLogInformation]);
}

#pragma mark - UIActivityIndicator helper methods

- (void)startActivityIndicator
{
    // create activity indicator
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    // make sure it's on the center of the screen
    
    activityIndicator.center = self.view.center;
    
    // start the spinner
    
    [activityIndicator startAnimating];
    
    // add the activity indicator to the screen
    
    [self.view addSubview:activityIndicator];
}

- (void)stopActivityIndicator
{
    // stop the spinning
    
    [activityIndicator stopAnimating];
    
    // remove it from the view
    
    [activityIndicator removeFromSuperview];
}

#pragma mark - CLLocationManager location change start/stop methods

- (void)startSignificantUpdates
{
    if (locationManager == nil)
    {
        locationManager = [[CLLocationManager alloc] init];
        
        locationManager.delegate = self;
        
        [locationManager startMonitoringSignificantLocationChanges];
    }
}

- (void)stopSignificantUpdates
{
    if (locationManager != nil)
    {
        [locationManager stopMonitoringSignificantLocationChanges];
        locationManager = nil;
    }
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation* location = [locations lastObject];
    
    [self retrieveWeatherForLocation:location orZipCode:nil];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self hideZipCode:NO animate:YES];

    // handle location errors here, such as case where user doesn't let app use iphone's location
    
    [self updateStatusMessage:@"Unable to determine location. You must enable location services for this app in Settings. Or just enter zip code."
        stopActivityIndicator:YES
         stopLocationServices:NO
                   logMessage:error];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status != kCLAuthorizationStatusAuthorized)
    {
        [self updateStatusMessage:@"You must authorize this app to determine location of device for this app in Settings."
            stopActivityIndicator:YES
             stopLocationServices:NO
                       logMessage:@(status)];
    }
    
    if (status == kCLAuthorizationStatusDenied)
    {
        [self hideZipCode:NO animate:YES];
    }
}

#pragma mark - Methods for retrieving weather from Wunderground

- (void)retrieveWeatherForLocation:(CLLocation *)location orZipCode:(NSString *)zipCode
{
    NSString *urlString;
    
    // get URL for current conditions
    
    if (location)
    {
        // based upon longitude and latitude returned by CLLocationManager
        
        urlString = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/conditions/q/%+f,%+f.json",
                     kWundergroundKey,
                     location.coordinate.latitude,
                     location.coordinate.longitude];
    }
    else if ([zipCode length] == 5)
    {
        // based upon the zip code
        
        urlString = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/conditions/q/%@.json",
                     kWundergroundKey,
                     zipCode];
        
    }
    else
    {
        NSAssert(NO, @"You must provide a CLLocation object or five digit zip code");
    }
    
    // Log it so you can see what the URL was for diagnostic purposes.
    // It's often useful to pull this up in a web browser like FireFox
    // so you can diagnose what's going on.
    
    [self updateStatusMessage:@"Identified location; determining weather" stopActivityIndicator:NO stopLocationServices:NO logMessage:urlString];
    
    NSURL *url          = [NSURL URLWithString:urlString];
    
    NSData *weatherData = [NSData dataWithContentsOfURL:url];
    
    // make sure we were able to get some response from the URL; if not
    // maybe your internet connection is not operational, or something
    // like that.
    
    if (weatherData == nil)
    {
        [self updateStatusMessage:@"Unable to retrieve data from weather service" stopActivityIndicator:YES stopLocationServices:YES logMessage:@"weatherData is nil"];
        return;
    }
    
    // parse the JSON results
    
    NSError *error;
    id weatherResults = [NSJSONSerialization JSONObjectWithData:weatherData options:0 error:&error];
    
    // if there was an error, report this
    
    if (error != nil)
    {
        [self updateStatusMessage:@"Error parsing results from weather service" stopActivityIndicator:YES stopLocationServices:YES logMessage:error];
        return;
    }
    
    // otherwise, let's make sure we got a NSDictionary like we expected
    
    else if (![weatherResults isKindOfClass:[NSDictionary class]])
    {
        [self updateStatusMessage:@"Unexpected results from weather service" stopActivityIndicator:YES stopLocationServices:YES logMessage:weatherResults];
        return;
    }
    
    // if we've gotten here, that means that we've parsed the JSON feed from Wunderground,
    // so now let's see if we got the expected response
    
    NSDictionary *response = weatherResults[@"response"];
    if (response == nil || ![response isKindOfClass:[NSDictionary class]])
    {
        [self updateStatusMessage:@"Unable to parse results from weather service" stopActivityIndicator:YES stopLocationServices:YES logMessage:weatherResults];
        return;
    }
    
    // now, let's see if that response reported any particular error
    
    NSDictionary *errorDictionary = response[@"error"];
    if (errorDictionary != nil)
    {
        NSString *message = @"Error reported by weather service";
        
        if (errorDictionary[@"description"])
            message = [NSString stringWithFormat:@"%@: %@", message, errorDictionary[@"description"]];
        [self updateStatusMessage:message stopActivityIndicator:YES stopLocationServices:YES logMessage:errorDictionary];
        
        if ([errorDictionary[@"type"] isEqualToString:@"keynotfound"])
        {
            NSLog(@"%s You must get a key for your app from http://www.wunderground.com/weather/api/", __FUNCTION__);
        }
        return;
    }
    
    // if no errors thus far, then we can now inspect the current_observation
    
    NSDictionary *currentObservation = weatherResults[@"current_observation"];
    
    if (currentObservation == nil)
    {
        // if not found, let's tell the user
        
        [self updateStatusMessage:@"No observation data found" stopActivityIndicator:YES stopLocationServices:YES logMessage:weatherResults];
        return;
    }
    
    // otherwise, let's look up the barometer information
    
    NSString *statusMessage;
    NSString *pressureMb = currentObservation[@"pressure_mb"];
    
    if (pressureMb)
    {
        statusMessage = @"Retrieved barometric pressure";
        self.pressureMbLabel.text = pressureMb;
    }
    else
    {
        statusMessage = @"No barometric information found";
    }
    
    NSNumber *tempC      = currentObservation[@"temp_c"];
    
    if (tempC)
    {
        statusMessage = @"Retrieved temperature";
        self.tempCLabel.text = [tempC stringValue];
    }
    else
    {
        statusMessage = @"No temperature information found";
    }
    
    // update the user interface status message
    
    [self updateStatusMessage:statusMessage stopActivityIndicator:YES stopLocationServices:YES logMessage:weatherResults];
}

#pragma mark - Zip code field methods

// helper function to hide or show zip code fields

- (void)hideZipCode:(BOOL)hide animate:(BOOL)animate
{
    BOOL goButtonHidden = hide || [self.zipCodeTextField.text length] != 5;
    
    if (animate)
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.zipCodePromptLabel.alpha = hide ? 0.0 : 1.0;
                             self.zipCodeTextField.alpha = hide ? 0.0 : 1.0;
                             self.zipCodeGoButton.alpha = goButtonHidden ? 0.0 : 1.0;
                         }];
    }
    else
    {
        self.zipCodePromptLabel.alpha = hide ? 0.0 : 1.0;
        self.zipCodeTextField.alpha = hide ? 0.0 : 1.0;
        self.zipCodeGoButton.alpha = goButtonHidden ? 0.0 : 1.0;
    }
}

// only allow numeric characters

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL shouldChange = NO;
    NSString *newValue = [textField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL goButtonHidden = (self.zipCodeGoButton.alpha < 0.5);
    BOOL goButtonShouldHide;
    
    // first, let's see if there were any non-numeric characters
    
    NSCharacterSet *nonNumeric = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    
    if (([string rangeOfCharacterFromSet:nonNumeric].location == NSNotFound) && [newValue length] <= 5)
    {
        shouldChange = YES;
        
        // and while we're here, show the go button if the length is exactly five characters
        
        goButtonShouldHide = ([newValue length] != 5);
        
        if (goButtonHidden != goButtonShouldHide)
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 self.zipCodeGoButton.alpha = goButtonShouldHide ? 0.0 : 1.0;
                             }];

            textField.returnKeyType = (goButtonShouldHide ? UIReturnKeyDone : UIReturnKeyGo);
        }
    }
    
    return shouldChange;
}

// don't return unless five characters

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if ([textField.text length] == 5)
    {
        [self retrieveWeatherForLocation:nil orZipCode:textField.text];
    }
    
    return YES;
}

// if we ended editing for any reason, dismiss the keyboard

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];

    return YES;
}

// user tapped on zipcode "go" button

- (IBAction)pressedZipCodeGoButton:(id)sender
{
    [self.zipCodeTextField resignFirstResponder];

    if ([self.zipCodeTextField.text length] == 5)
    {
        [self retrieveWeatherForLocation:nil orZipCode:self.zipCodeTextField.text];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:@"Please enter five number zip code"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

// detect touches anywhere on the screen, and if so, dismiss the keyboard

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.zipCodeTextField resignFirstResponder];
}
@end
