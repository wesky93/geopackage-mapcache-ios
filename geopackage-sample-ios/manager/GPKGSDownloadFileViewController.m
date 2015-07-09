//
//  GPKGSDownloadFileViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/9/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSDownloadFileViewController.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGIOUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"

@interface GPKGSDownloadFileViewController ()

@property (nonatomic) BOOL active;
@property (nonatomic, strong) NSNumber * progress;
@property (nonatomic, strong) NSNumber * maxProgress;

@end

@implementation GPKGSDownloadFileViewController

#define TAG_PRELOADED 1

- (void)viewDidLoad {
    [super viewDidLoad];
    [self disableButton:self.importButton];
    
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:flexSpace, doneBarButton, nil];
    self.nameTextField.inputAccessoryView = toolbar;
    self.urlTextField.inputAccessoryView = toolbar;
}

- (void) doneButtonPressed {
    [self.nameTextField resignFirstResponder];
    [self.urlTextField resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)cancel:(id)sender {
    if(self.active){
        self.active = false;
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)preloaded:(id)sender {
    NSMutableArray * options = [[NSMutableArray alloc] init];
    NSArray * urls = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS];
    for(NSDictionary * url in urls){
        [options addObject:[url objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_LABEL]];
    }
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_IMPORT_URL_PRELOADED_LABEL]
                          message:nil
                          delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:nil];
    
    for (NSString *option in options) {
        [alert addButtonWithTitle:option];
    }
    alert.cancelButtonIndex = [alert addButtonWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]];
    
    alert.tag = TAG_PRELOADED;
    
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
            
        case TAG_PRELOADED:
            if(buttonIndex >= 0){
                NSArray * urls = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS];
                if(buttonIndex < [urls count]){
                    NSDictionary * url = (NSDictionary *)[urls objectAtIndex:buttonIndex];
                    [self.nameTextField setText:[url objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_NAME]];
                    [self.urlTextField setText:[url objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_URL]];
                    [self updateImportButtonState];
                }
            }
            
            break;
    }
}

- (IBAction)import:(id)sender {
    
    [self disableButton:self.preloadedButton];
    [self disableButton:self.importButton];
    [self disableTextField:self.urlTextField];
    [self disableTextField:self.nameTextField];
    
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory getManager];
    
    self.active = true;
    self.progress = [NSNumber numberWithInt:0];
    self.progressView.hidden = false;
    
    @try {
        NSURL *url = [NSURL URLWithString:self.urlTextField.text];
        [manager importGeoPackageFromUrl:url withName:self.nameTextField.text andProgress:self];
    }
    @catch (NSException *exception) {
        [self failureWithError:[exception description]];
    }

}

- (IBAction)nameChanged:(id)sender {
    [self updateImportButtonState];
}

- (IBAction)urlChanged:(id)sender {
    [self updateImportButtonState];
}

-(void) updateImportButtonState{
    if([self.nameTextField.text length] == 0 || [self.urlTextField.text length] == 0){
        [self disableButton:self.importButton];
    }else{
        [self enableButton:self.importButton];
    }
}

-(void) disableButton: (UIButton *) button{
    if(button.enabled){
        button.enabled = false;
        button.alpha = 0.3;
    }
}

-(void) enableButton: (UIButton *) button{
    if(!button.enabled){
        button.enabled = true;
        button.alpha = 1.0;
    }
}

-(void) disableTextField: (UITextField *) textField{
    if(textField.enabled){
        textField.enabled = false;
        textField.alpha = 0.3;
    }
}

-(void) updateProgress{
    if(self.maxProgress != nil){
        float progress = [self.progress floatValue] / [self.maxProgress floatValue];
        [self.downloadedLabel setText:[NSString stringWithFormat:@"( %@ of %@ )", [GPKGIOUtils formatBytes:[self.progress intValue]], [GPKGIOUtils formatBytes:[self.maxProgress intValue]]]];
        [self.progressView setProgress:progress];
    }
}

-(void) setMax: (int) max{
    self.maxProgress = [NSNumber numberWithInt:max];
    [self updateProgress];
}

-(void) addProgress: (int) progress{
    self.progress = [NSNumber numberWithInt:[self.progress intValue] + progress];
    [self updateProgress];
}

-(BOOL) isActive{
    return self.active;
}

-(BOOL) cleanupOnCancel{
    return true;
}

-(void) completed{
    [self.delegate downloadFileViewController:self downloadedFile:true withError:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) failureWithError: (NSString *) error{
    NSString * errorMessage = self.active ? error : nil;
    [self.delegate downloadFileViewController:self downloadedFile:false withError:errorMessage];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
