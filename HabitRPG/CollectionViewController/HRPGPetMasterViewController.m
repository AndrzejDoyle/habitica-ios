//
//  HRPGPetViewController.m
//  Habitica
//
//  Created by Phillip on 07/06/14.
//  Copyright (c) 2014 Phillip Thelen. All rights reserved.
//

#import "HRPGPetMasterViewController.h"
#import "HRPGPetViewController.h"
#import "HRPGAppDelegate.h"
#import "HRPGFeedViewController.h"
#import "HRPGManager.h"
#import "Pet.h"
#import "Egg.h"
#import "HatchingPotion.h"
#import "HRPGArrayViewController.h"
#import "HRPGNavigationController.h"
#import "HRPGTopHeaderNavigationController.h"

@interface HRPGPetMasterViewController ()
@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) NSArray *eggs;
@property (nonatomic) NSArray *hatchingPotions;
@property (nonatomic) NSString *selectedPet;
@property (nonatomic) NSString *selectedType;
@property (nonatomic) NSString *selectedColor;
@property (nonatomic) NSArray *sortedPets;
@property UIBarButtonItem *navigationButton;
@property NSInteger groupByKey;
@property CGSize screenSize;
@end

@implementation HRPGPetMasterViewController
NSUserDefaults *defaults;

- (void)viewDidLoad {
    [super viewDidLoad];
    defaults = [NSUserDefaults standardUserDefaults];
    self.groupByKey = [defaults integerForKey:@"groupPetsBy"];
    
    self.screenSize = [[UIScreen mainScreen] bounds].size;
    
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Egg" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    self.eggs = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"HatchingPotion" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    self.hatchingPotions = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
}

- (Egg*) eggWithKey:(NSString*)key {
    for (Egg *egg in self.eggs) {
        if ([egg.key isEqualToString:key]) {
            return egg;
        }
    }
    return nil;
}

- (NSString*) eggNameWithKey:(NSString*)key {
    for (Egg *egg in self.eggs) {
        if ([egg.key isEqualToString:key]) {
            return egg.text;
        }
    }
    return key;
}

- (NSString*) hatchingPotionNameWithKey:(NSString*)key {
    for (HatchingPotion *hPotion in self.hatchingPotions) {
        if ([hPotion.key isEqualToString:key]) {
            return hPotion.text;
        }
    }
    return key;
}

- (void)preferredContentSizeChanged:(NSNotification *)notification {
    [self.collectionView reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.sortedPets[section] count];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *petArray = self.sortedPets[indexPath.section][indexPath.item];
    Pet *namePet = [petArray firstObject];
    for (Pet *pet in petArray) {
        if (pet.trained) {
            if (self.groupByKey) {
                self.selectedColor = [namePet.key componentsSeparatedByString:@"-"][1];
            } else {
                self.selectedPet = [namePet.key componentsSeparatedByString:@"-"][0];
                if ([namePet.type isEqualToString:@" "]) {
                    self.selectedColor = [namePet.key componentsSeparatedByString:@"-"][1];
                }
            }
            self.selectedType = namePet.type;
            return YES;
        }
    }
    return NO;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 121.0f;
    height = height + [@" " boundingRectWithSize:CGSizeMake(90.0f, MAXFLOAT)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{
                                                   NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                                   }
                                         context:nil].size.height*3;
    height = height + [@" " boundingRectWithSize:CGSizeMake(90.0f, MAXFLOAT)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{
                                                   NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                   }
                                         context:nil].size.height;
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        return CGSizeMake(self.screenSize.width/4-15, height);
    }
    return CGSizeMake(self.screenSize.width/3-10, height);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SectionCell" forIndexPath:indexPath];
    UILabel *label = (UILabel*)[headerView viewWithTag:1];
    NSString *sectionName = [[self.fetchedResultsController sections][indexPath.section] name];
    if ([sectionName isEqualToString:@"questPets"]) {
        label.text = NSLocalizedString(@"Quest Pets", nil);
    } else if ([sectionName isEqualToString:@" "]) {
        label.text = NSLocalizedString(@"Special Pets", nil);
    } else {
        label.text = NSLocalizedString(@"Base Pets", nil);
    }
    return headerView;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


- (NSArray*)sortedPets {
    if (_sortedPets) {
        return _sortedPets;
    }
    NSMutableArray *newSortedPets = [NSMutableArray array];
    for (id <NSFetchedResultsSectionInfo> sectionInfo in self.fetchedResultsController.sections) {
        NSMutableArray *sectionArray = [NSMutableArray array];
        [newSortedPets addObject:sectionArray];
        for (Pet *pet in [sectionInfo objects]) {
            if ([pet.type isEqualToString:@" "] && ![pet.trained boolValue]) {
                continue;
            }
            NSArray *nameParts = [pet.key componentsSeparatedByString:@"-"];
            NSMutableArray *petArray;
            for (NSMutableArray *oldPetArray in sectionArray) {
                if (oldPetArray) {
                    Pet *oldPet = [oldPetArray firstObject];
                    if ([nameParts[self.groupByKey] isEqualToString:[oldPet.key componentsSeparatedByString:@"-"][self.groupByKey]]) {
                        petArray = oldPetArray;
                        break;
                    }
                }
            }
            if (!petArray) {
                petArray = [NSMutableArray array];
                [sectionArray addObject:petArray];
            }
            [petArray addObject:pet];
        }
    }
    _sortedPets = newSortedPets;
    return newSortedPets;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Pet" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSSortDescriptor *typeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"type" ascending:YES];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"key" ascending:YES];
    NSArray *sortDescriptors = @[typeSortDescriptor, sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"type" cacheName:nil];
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
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.collectionView reloadData];
}

- (void)configureCell:(UICollectionViewCell*)cell atIndexPath:(NSIndexPath *)indexPath {
    NSArray *petArray = self.sortedPets[indexPath.section][indexPath.item];
    UILabel *label = (UILabel*)[cell viewWithTag:1];
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:2];
    UILabel *progressLabel = (UILabel*)[cell viewWithTag:3];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    progressLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    NSString *petType;
    NSString *petColor;
    int trained = 0;
    
    for (Pet *pet in petArray) {
        if (pet.trained) {
            if (petType == nil) {
                petType = [pet.key componentsSeparatedByString:@"-"][0];
                petColor = [pet.key componentsSeparatedByString:@"-"][1];
            }
            trained++;
        }
    }
    if (self.groupByKey) {
        if (petColor == nil) {
            petColor = [((Pet*)[petArray firstObject]).key componentsSeparatedByString:@"-"][1];
        }
        label.text = [self hatchingPotionNameWithKey:petColor];
    } else {
        if (petType == nil) {
            petType = [((Pet*)[petArray firstObject]).key componentsSeparatedByString:@"-"][0];
        }
        label.text = [self eggNameWithKey:petType];
    }
    
    if (trained > 0) {
        [imageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://habitica-assets.s3.amazonaws.com/mobileApp/images/Pet-%@-%@.png", petType, petColor]]
                  placeholderImage:[UIImage imageNamed:@"Placeholder"]];
        imageView.alpha = 1;
    } else {
        [imageView setImageWithURL:[NSURL URLWithString:@"https://habitica-assets.s3.amazonaws.com/mobileApp/images/PixelPaw.png"]
                  placeholderImage:[UIImage imageNamed:@"Placeholder"]];
        imageView.alpha = 0.3f;
    }
    
    progressLabel.text = [NSString stringWithFormat:@"%d/%lu", trained, (unsigned long)[petArray count]];
    if (trained == [petArray count]) {
        progressLabel.textColor = [UIColor colorWithRed:0.409 green:0.743 blue:0.037 alpha:1.0];
    } else {
        progressLabel.textColor = [UIColor darkTextColor];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *destViewController = segue.destinationViewController;
    if ([destViewController isKindOfClass:[HRPGNavigationController class]]) {
        HRPGNavigationController *destNavigationController = (HRPGNavigationController*)destViewController;
        destNavigationController.sourceViewController = self;
    }
    if ([segue.identifier isEqualToString:@"GroupBySegue"]) {
        UINavigationController *navController = (UINavigationController*)segue.destinationViewController;
        HRPGArrayViewController *arrayViewController = (HRPGArrayViewController*)navController.topViewController;
        arrayViewController.items = @[
                                      NSLocalizedString(@"Pet Type", nil),
                                      NSLocalizedString(@"Color", nil)
                                      ];
        arrayViewController.selectedIndex = [defaults integerForKey:@"groupPetsBy"];
    } else if (![segue.identifier isEqualToString:@"PetSegue"]) {
        HRPGPetViewController *petController = (HRPGPetViewController*)segue.destinationViewController;
        petController.petName = self.selectedPet;
        petController.petType = self.selectedType;
        petController.petColor = self.selectedColor;
    }
}


- (IBAction)unwindToListSave:(UIStoryboardSegue *)segue {
    HRPGArrayViewController *arrayViewController = (HRPGArrayViewController*)segue.sourceViewController;
    [defaults setInteger:arrayViewController.selectedIndex forKey:@"groupPetsBy"];
    self.groupByKey = arrayViewController.selectedIndex;
    self.selectedPet = nil;
    self.sortedPets = nil;
    [self.collectionView reloadData];
}

@end
