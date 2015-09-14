//
//  HRPGTagViewController.m
//  Habitica
//
//  Created by Phillip on 08/06/14.
//  Copyright (c) 2014 Phillip Thelen. All rights reserved.
//

#import "HRPGFilterViewController.h"
#import "Tag.h"
#import <NIKFontAwesomeIconFactory.h>
#import <NIKFontAwesomeIconFactory+iOS.h>

@interface HRPGFilterViewController ()

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property NIKFontAwesomeIconFactory *iconFactory;
@property UIView *headerView;
@property UISegmentedControl *filterTypeControl;
@end

@implementation HRPGFilterViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.iconFactory = [NIKFontAwesomeIconFactory tabBarItemIconFactory];
    self.iconFactory.square = YES;
    self.iconFactory.colors = @[[UIColor darkGrayColor]];
    self.iconFactory.strokeColor = [UIColor darkGrayColor];
    self.iconFactory.renderingMode = UIImageRenderingModeAlwaysOriginal;
    
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    if ([self.taskType isEqualToString:@"habit"]) {
        self.filterTypeControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"All", nil), NSLocalizedString(@"Weak", nil), NSLocalizedString(@"Strong", nil)]];
    } else if ([self.taskType isEqualToString:@"daily"]) {
        self.filterTypeControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"All", nil), NSLocalizedString(@"Due", nil), NSLocalizedString(@"Grey", nil)]];
    } else if ([self.taskType isEqualToString:@"todo"]) {
        self.filterTypeControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"Active", nil), NSLocalizedString(@"Dated", nil), NSLocalizedString(@"Done", nil)]];
    }
    self.filterTypeControl.frame = CGRectMake(8, (self.headerView.frame.size.height-30)/2, self.headerView.frame.size.width-16, 30);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.filterTypeControl.selectedSegmentIndex = [defaults integerForKey:[NSString stringWithFormat:@"%@Filter", self.taskType]];
    [self.filterTypeControl addTarget:self action:@selector(filterTypeChanged:) forControlEvents: UIControlEventValueChanged];

    [self.headerView addSubview:self.filterTypeControl];
    
    self.tableView.tableHeaderView = self.headerView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:NO];
    if (self.selectedTags == nil) {
        self.selectedTags = [[NSMutableArray alloc] init];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.fetchedResultsController sections][section] name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];

    UITableViewCell *cell;
    if ([tag.challenge boolValue]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ChallengeCell" forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    }
    [self configureCell:cell atIndexPath:indexPath withAnimation:NO];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSInteger height = [tag.name boundingRectWithSize:CGSizeMake(260.0f, MAXFLOAT)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{
                                                         NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                                         }
                                               context:nil].size.height + 22;
    return height;
}


- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeMove:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath withAnimation:YES];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath withAnimation:(BOOL)animate {
    Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UILabel *textLabel = (UILabel*)[cell viewWithTag:1];
    textLabel.text = tag.name;
    UISwitch *tagSwitch = (UISwitch*)[cell viewWithTag:2];
    tagSwitch.on = NO;
    for (Tag *selectedTag in self.selectedTags) {
        if ([tag.id isEqualToString:selectedTag.id]) {
            tagSwitch.on = YES;
             break;
        }
    }
    
    if (tag.challenge) {
        cell.imageView.image = [self.iconFactory createImageForIcon:NIKFontAwesomeIconBullhorn];
    } else {
        cell.imageView.image = nil;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"UnwindTagSegue"]) {
        int counter = 0;
        for (Tag *tag in [self.fetchedResultsController fetchedObjects]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:counter inSection:0];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UISwitch *tagSwitch = (UISwitch*)[cell viewWithTag:2];
            if (tagSwitch.on) {
                if (![self.selectedTags containsObject:tag]) {
                    [self.selectedTags addObject:tag];
                }
            } else {
                if ([self.selectedTags containsObject:tag]) {
                    [self.selectedTags removeObject:tag];
                }
            }
            counter++;
        }
    }
}

- (IBAction)clearTags:(id)sender {
    int activatedSwitches = 0;
    for (int i = 0; i < [self.tableView numberOfRowsInSection:0]; i++) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        UISwitch *tagSwitch = (UISwitch*)[cell viewWithTag:2];
        if (tagSwitch.on) {
            activatedSwitches++;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.15 * activatedSwitches * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [tagSwitch setOn:NO animated:YES];
            });
        }
    }
}

- (void)filterTypeChanged:(UISegmentedControl *)segment {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:segment.selectedSegmentIndex forKey:[NSString stringWithFormat:@"%@Filter", self.taskType]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"taskFilterChanged" object:nil];
}

@end
