//
//  HRPGAddViewController.m
//  HabitRPG
//
//  Created by Phillip Thelen on 08/03/14.
//  Copyright (c) 2014 Phillip Thelen. All rights reserved.
//

#import "HRPGFormViewController.h"
#import "ChecklistItem.h"
#import "NSString+Emoji.h"
#import "Tag.h"
#import "XLForm.h"
#import "HRPGAppDelegate.h"
#import "HRPGManager.h"

@interface HRPGFormViewController ()
@property (nonatomic) NSArray *tags;
@property (nonatomic) BOOL formFilled;
@property (nonatomic) XLFormSectionDescriptor *duedateSection;
@property NSInteger customDayStart;
@end

@implementation HRPGFormViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        HRPGAppDelegate *appdelegate = (HRPGAppDelegate *) [[UIApplication sharedApplication] delegate];
        HRPGManager *sharedManager = appdelegate.sharedManager;
        User *user = [sharedManager getUser];
        self.customDayStart = [user.dayStart integerValue];
        self.managedObjectContext = sharedManager.getManagedObjectContext;
        [self initializeForm];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.formFilled) {
        [self fillForm];
    }
}

-(void)initializeForm {
    XLFormDescriptor *formDescriptor = [XLFormDescriptor formDescriptorWithTitle:@"New"];
    
    formDescriptor.assignFirstResponderOnShow = YES;
    
    XLFormSectionDescriptor *section;
    XLFormRowDescriptor *row;
    
    section = [XLFormSectionDescriptor formSectionWithTitle:@"Task"];
    [formDescriptor addFormSection:section];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"text" rowType:XLFormRowDescriptorTypeText title:NSLocalizedString(@"Text", nil)];
    row.required = YES;
    [section addFormRow:row];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"notes" rowType:XLFormRowDescriptorTypeTextView title:NSLocalizedString(@"Notes", nil)];
    [section addFormRow:row];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"priority" rowType:XLFormRowDescriptorTypeSelectorPush title:NSLocalizedString(@"Difficulty", nil)];
    row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@(0.1) displayText:NSLocalizedString(@"Trivial", nil)],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(1) displayText:NSLocalizedString(@"Easy", nil)],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(1.5) displayText:NSLocalizedString(@"Medium", nil)],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(2) displayText:NSLocalizedString(@"Hard", nil)]
                            ];
    row.value = [XLFormOptionsObject formOptionsObjectWithValue:@(1) displayText:NSLocalizedString(@"Easy", nil)];
    row.required = YES;
    row.selectorTitle = NSLocalizedString(@"Select Difficulty", nil);
    [section addFormRow:row];
    
    self.form = formDescriptor;
}

-(void)fillForm {
    if (self.formFilled) {
        return;
    }
    XLFormSectionDescriptor *section;
    XLFormRowDescriptor *row;
    
    if (self.editTask) {
        self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Edit %@", nil), self.readableTaskType];
    } else {
        self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Add %@", nil), self.readableTaskType];
    }
    
    if (![self.taskType isEqualToString:@"habit"]) {
        section = [XLFormSectionDescriptor formSectionWithTitle:@"Checklist" sectionOptions:XLFormSectionOptionCanReorder | XLFormSectionOptionCanInsert | XLFormSectionOptionCanDelete sectionInsertMode:XLFormSectionInsertModeButton];
        section.multivaluedAddButton.title = NSLocalizedString(@"Add a new checklist item", nil);
        section.multivaluedTag = @"checklist";
        // Set up row template
        row = [XLFormRowDescriptor formRowDescriptorWithTag:nil rowType:XLFormRowDescriptorTypeText];
        [[row cellConfig] setObject:NSLocalizedString(@"Add a new checklist item", nil) forKey:@"textField.placeholder"];
        section.multivaluedRowTemplate = row;
        [self.form addFormSection:section];
    }
    
    if ([self.taskType isEqualToString:@"habit"]) {
        section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Actions", nil)];
        [self.form addFormSection:section];
        
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"up" rowType:XLFormRowDescriptorTypeBooleanCheck title:NSLocalizedString(@"Positive (+)", nil)];
        row.value = [NSNumber numberWithBool:YES];
        [section addFormRow:row];
        
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"down" rowType:XLFormRowDescriptorTypeBooleanCheck title:NSLocalizedString(@"Negative (-)", nil)];
        row.value = [NSNumber numberWithBool:YES];
        [section addFormRow:row];
    }
    
    if ([self.taskType isEqualToString:@"daily"]) {
        section = [self.form formSectionAtIndex:0];
        XLFormRowDescriptor *row = [XLFormRowDescriptor formRowDescriptorWithTag:@"startDate" rowType:XLFormRowDescriptorTypeDateInline title:@"Start Date"];
        NSDate *date = [NSDate new];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSHourCalendarUnit) fromDate:date];
        if (components.hour < self.customDayStart) {
            [components setHour:-24];
            date = [calendar dateByAddingComponents:components toDate:date options:0];
        }
        row.value = date;
        [section addFormRow:row];
        
        section = [XLFormSectionDescriptor formSectionWithTitle:@""];
        [self.form addFormSection:section];
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"frequency" rowType:XLFormRowDescriptorTypeSelectorPush title:NSLocalizedString(@"Frequency", nil)];
        row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@"daily" displayText:NSLocalizedString(@"Every x days", nil)],
                                [XLFormOptionsObject formOptionsObjectWithValue:@"weekly" displayText:NSLocalizedString(@"On certain days of the week", nil)]
                                ];
        row.value = [XLFormOptionsObject formOptionsObjectWithValue:@"weekly" displayText:NSLocalizedString(@"Weekly", nil)];
        row.required = YES;
        row.selectorTitle = NSLocalizedString(@"Select Frequency", nil);
        if (!self.editTask) {
            [self setFrequencyRows:@"weekly"];
        }
        [section addFormRow:row];
    }
    
    if ([self.taskType isEqualToString:@"todo"]) {
        self.duedateSection = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Due Date", nil)];
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"hasDueDate" rowType:XLFormRowDescriptorTypeBooleanCheck title:NSLocalizedString(@"Has a due date", nil)];
        row.value = [NSNumber numberWithBool:NO];
        [self.duedateSection addFormRow:row];
        [self.form addFormSection:self.duedateSection];
        
    }
    
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Tags", nil)];
    [self.form addFormSection:section];
    [self fetchTags];
    for (Tag *tag in self.tags) {
        row = [XLFormRowDescriptor formRowDescriptorWithTag:[NSString stringWithFormat:@"tag.%@", tag.id] rowType:XLFormRowDescriptorTypeBooleanCheck title:tag.name];
        row.value = [NSNumber numberWithBool:[self.activeTags containsObject:tag]];
        [section addFormRow:row];
        
    }
    
    self.formFilled = YES;
}

- (void)fillEditForm {
    if (!self.formFilled) {
        [self fillForm];
    }
    [self.form formRowWithTag:@"text"].value = [self.task.text stringByReplacingEmojiCheatCodesWithUnicode];
    [self.form formRowWithTag:@"notes"].value = [self.task.notes stringByReplacingEmojiCheatCodesWithUnicode];
    
    if ([self.task.priority floatValue] == 0.1f) {
        [self.form formRowWithTag:@"priority"].value = [XLFormOptionsObject formOptionsObjectWithValue:self.task.priority displayText:NSLocalizedString(@"Trivial", nil)];
    } else if ([self.task.priority floatValue] == 1) {
        [self.form formRowWithTag:@"priority"].value = [XLFormOptionsObject formOptionsObjectWithValue:self.task.priority displayText:NSLocalizedString(@"Easy", nil)];
    } else if ([self.task.priority floatValue] == 1.5f) {
        [self.form formRowWithTag:@"priority"].value = [XLFormOptionsObject formOptionsObjectWithValue:self.task.priority displayText:NSLocalizedString(@"Medium", nil)];

    } else if ([self.task.priority floatValue] == 2) {
        [self.form formRowWithTag:@"priority"].value = [XLFormOptionsObject formOptionsObjectWithValue:self.task.priority displayText:NSLocalizedString(@"Hard", nil)];
    }
    
    if (![self.taskType isEqualToString:@"habit"]) {
        XLFormSectionDescriptor *section = [self.form formSectionAtIndex:1];
        
        for (ChecklistItem *item in self.task.checklist) {
            XLFormRowDescriptor *row = [XLFormRowDescriptor formRowDescriptorWithTag:item.id rowType:XLFormRowDescriptorTypeText];
            [[row cellConfig] setObject:NSLocalizedString(@"Add a new checklist item", nil) forKey:@"textField.placeholder"];
            row.value = item.text;
            [section addFormRow:row];
        }
    }
    
    if ([self.taskType isEqualToString:@"habit"]) {
        [self.form formRowWithTag:@"up"].value = self.task.up;
        [self.form formRowWithTag:@"down"].value = self.task.down;
    }
    
    if ([self.taskType isEqualToString:@"daily"]) {
        [self.form formRowWithTag:@"startDate"].value = self.task.startDate;
        [self.form formRowWithTag:@"frequency"].value = self.task.frequency;
    }
    
    if ([self.taskType isEqualToString:@"todo"]) {
        if (self.task.duedate) {
            [self.form formRowWithTag:@"hasDueDate"].value = [NSNumber numberWithBool:YES];
            [self.form formRowWithTag:@"duedate"].value = self.task.duedate;
        }
        
    }

    for (Tag *tag in self.task.tags) {
        [self.form formRowWithTag:[NSString stringWithFormat:@"tag.%@", tag.id]].value = [NSNumber numberWithBool:YES];
    }

    [self.tableView reloadData];
}

- (void) fetchTags {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    NSError *error;
    self.tags = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
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
        NSError *error;
        if (!self.editTask || (self.editTask && [self.task.managedObjectContext existingObjectWithID:self.task.objectID error:&error] == nil)) {
            self.task = [NSEntityDescription
                         insertNewObjectForEntityForName:@"Task"
                         inManagedObjectContext:self.managedObjectContext];
            self.task.type = self.taskType;
        }
        NSDictionary *formValues = [self.form formValues];
        NSMutableDictionary *tagDictionary = [NSMutableDictionary dictionary];
        for (NSString *key in formValues) {
            if ([key isEqualToString:@"hasDueDate"]) {
                if (![formValues[key] boolValue]) {
                    self.task.duedate = nil;
                }
                continue;
            }
            if ([key isEqualToString:@"frequency"]) {
                self.task.frequency = [formValues[key] valueData];
                continue;
            }
            if ([key  hasPrefix:@"tag."]) {
                if (formValues[key] != [NSNull null]) {
                    [tagDictionary setObject:formValues[key] forKey:[key substringFromIndex:4]];
                } else {
                    [tagDictionary setObject:[NSNumber numberWithBool:NO] forKey:[key substringFromIndex:4]];
                }
                continue;
            }
            if ([key isEqualToString:@"checklist"]) {
                int checklistindex = 0;
                for (NSString *itemText in  formValues[key]) {
                    if ([itemText length] == 0) {
                        continue;
                    }
                    if ([self.task.checklist count] > checklistindex) {
                        ((ChecklistItem*)self.task.checklist[checklistindex]).text = itemText;
                    } else {
                        ChecklistItem *newItem = [NSEntityDescription
                                     insertNewObjectForEntityForName:@"ChecklistItem"
                                     inManagedObjectContext:self.managedObjectContext];
                        newItem.text = itemText;
                        [self.task addChecklistObject:newItem];
                    }
                    checklistindex++;
                }
                while ([self.task.checklist count] > checklistindex) {
                    [self.task removeChecklistObject:self.task.checklist[checklistindex]];
                }
                continue;
            }
            if (formValues[key] == [NSNull null]) {
                if ([key isEqualToString:@"text"] || [key isEqualToString:@"notes"]) {
                    [self.task setValue:@"" forKeyPath:key];
                } else {
                    [self.task setValue:nil forKeyPath:key];
                }
                continue;
            }
            if ([key isEqualToString:@"priority"]) {
                XLFormOptionsObject *value = formValues[key];
                self.task.priority = value.valueData;
                continue;
            }
            [self.task setValue:formValues[key] forKeyPath:key];
        }
        self.task.tagDictionary = tagDictionary;
    }
}


- (void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)formRow oldValue:(id)oldValue newValue:(id)newValue {
    if ([formRow.tag isEqualToString:@"hasDueDate"]) {
        NSNumber *value = formRow.value;
        if ([value boolValue]) {
            XLFormRowDescriptor *row = [XLFormRowDescriptor formRowDescriptorWithTag:@"duedate" rowType:XLFormRowDescriptorTypeDateInline title:@"Date"];
            row.value = [NSDate new];
            [self.duedateSection addFormRow:row];
        } else {
            [self.form removeFormRowWithTag:@"duedate"];
        }
    } else if ([formRow.tag isEqualToString:@"frequency"]) {
        [self setFrequencyRows:[formRow.value valueData]];
        
    }
}

- (void)setFrequencyRows:(NSString *) frequencyType {
    if ([frequencyType  isEqualToString:@"daily"]) {
        XLFormSectionDescriptor *section = [self.form formSectionAtIndex:2];
        XLFormRowDescriptor *row;
        if (section.formRows.count == 1) {
            row = [XLFormRowDescriptor formRowDescriptorWithTag:@"everyX" rowType:XLFormRowDescriptorTypeInteger title:NSLocalizedString(@"Repeat every X days", nil)];
            [section addFormRow:row];
        } else {
            row = section.formRows[1];
        }
        if (self.editTask) {
            row.value = self.task.everyX;
        } else {
            row.value = [NSNumber numberWithInt:1];
        }
        row.required = YES;
        if (self.form.formSections.count > 4) {
            [self.form removeFormSectionAtIndex:3];
        }
    } else {
        XLFormSectionDescriptor *section = [self.form formSectionAtIndex:2];
        [section removeFormRowAtIndex:1];
        
        section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Repeat", nil)];
        [self.form addFormSection:section atIndex:3];
        XLFormRowDescriptor *row = [XLFormRowDescriptor formRowDescriptorWithTag:@"monday" rowType:XLFormRowDescriptorTypeBooleanCheck title:NSLocalizedString(@"Monday", nil)];
        row.value = [NSNumber numberWithBool:YES];
        [section addFormRow:row];
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"tuesday" rowType:XLFormRowDescriptorTypeBooleanCheck title:NSLocalizedString(@"Tuesday", nil)];
        row.value = [NSNumber numberWithBool:YES];
        [section addFormRow:row];
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"wednesday" rowType:XLFormRowDescriptorTypeBooleanCheck title:NSLocalizedString(@"Wednesday", nil)];
        row.value = [NSNumber numberWithBool:YES];
        [section addFormRow:row];
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"thursday" rowType:XLFormRowDescriptorTypeBooleanCheck title:NSLocalizedString(@"Thursday", nil)];
        row.value = [NSNumber numberWithBool:YES];
        [section addFormRow:row];
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"friday" rowType:XLFormRowDescriptorTypeBooleanCheck title:NSLocalizedString(@"Friday", nil)];
        row.value = [NSNumber numberWithBool:YES];
        [section addFormRow:row];
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"saturday" rowType:XLFormRowDescriptorTypeBooleanCheck title:NSLocalizedString(@"Saturday", nil)];
        row.value = [NSNumber numberWithBool:YES];
        [section addFormRow:row];
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"sunday" rowType:XLFormRowDescriptorTypeBooleanCheck title:NSLocalizedString(@"Sunday", nil)];
        row.value = [NSNumber numberWithBool:YES];
        [section addFormRow:row];
        if (self.editTask) {
            [self.form formRowWithTag:@"monday"].value = self.task.monday;
            [self.form formRowWithTag:@"tuesday"].value = self.task.tuesday;
            [self.form formRowWithTag:@"wednesday"].value = self.task.wednesday;
            [self.form formRowWithTag:@"thursday"].value = self.task.thursday;
            [self.form formRowWithTag:@"friday"].value = self.task.friday;
            [self.form formRowWithTag:@"saturday"].value = self.task.saturday;
            [self.form formRowWithTag:@"sunday"].value = self.task.sunday;
        }
    }
    
}

- (void)setTaskType:(NSString *)taskType {
    _taskType = taskType;
    [self initializeForm];
}

- (void)setEditTask:(BOOL)editTask {
    _editTask = editTask;
    [self fillEditForm];
}

@end
