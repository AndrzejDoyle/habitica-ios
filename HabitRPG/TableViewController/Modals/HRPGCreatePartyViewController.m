//
//  HRPGCreatePartyViewController.m
//  Habitica
//
//  Created by Phillip Thelen on 23/09/15.
//  Copyright © 2015 Phillip Thelen. All rights reserved.
//

#import "HRPGCreatePartyViewController.h"
#import "Group.h"
#import "NSString+Emoji.h"
#import "XLForm.h"
#import "HRPGAppDelegate.h"
#import "HRPGManager.h"

@interface HRPGCreatePartyViewController ()

@end

@implementation HRPGCreatePartyViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        HRPGAppDelegate *appdelegate = (HRPGAppDelegate *) [[UIApplication sharedApplication] delegate];
        HRPGManager *sharedManager = appdelegate.sharedManager;
        self.managedObjectContext = sharedManager.getManagedObjectContext;
        [self initializeForm];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.editParty) {
        [self fillEditForm];
    }
}

-(void)initializeForm {
    XLFormDescriptor *formDescriptor = [XLFormDescriptor formDescriptorWithTitle:NSLocalizedString(@"New Party", nil)];
    formDescriptor.assignFirstResponderOnShow = YES;
    
    XLFormSectionDescriptor *section;
    XLFormRowDescriptor *row;
    
    section = [XLFormSectionDescriptor formSectionWithTitle:@"Party"];
    [formDescriptor addFormSection:section];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"name" rowType:XLFormRowDescriptorTypeText title:NSLocalizedString(@"Name", nil)];
    row.required = YES;
    [section addFormRow:row];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"hdescription" rowType:XLFormRowDescriptorTypeTextView title:NSLocalizedString(@"Description", nil)];
    [section addFormRow:row];
    
    self.form = formDescriptor;
}
- (void)fillEditForm {
    self.navigationItem.title = NSLocalizedString(@"Edit Party", nil);
    [self.form formRowWithTag:@"name"].value = self.party.name;
    [self.form formRowWithTag:@"hdescription"].value = self.party.hdescription;

    [self.tableView reloadData];
}

- (void)showFormValidationError:(NSError *)error {
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Validation Error", nil) message:error.localizedDescription delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alertView show];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"unwindSaveSegue"]) {
        NSArray * validationErrors = [self formValidationErrors];
        if (validationErrors.count > 0){
            [self showFormValidationError:[validationErrors firstObject]];
            return NO;
        }
    }
    return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    [self.tableView endEditing:YES];
    if ([segue.identifier isEqualToString:@"unwindSaveSegue"]) {
        if (!self.editParty) {
            self.party = [NSEntityDescription
                           insertNewObjectForEntityForName:@"Group"
                           inManagedObjectContext:self.managedObjectContext];
            self.party.type = @"party";
        }
        NSDictionary *formValues = [self.form formValues];
        for (NSString *key in formValues) {
            if (formValues[key] == [NSNull null]) {
                [self.party setValue:nil forKeyPath:key];
                continue;
            }
            [self.party setValue:formValues[key] forKeyPath:key];
        }
    }
}

@end
