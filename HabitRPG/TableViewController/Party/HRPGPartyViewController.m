//
//  HRPGTableViewController.m
//  HabitRPG
//
//  Created by Phillip Thelen on 08/03/14.
//  Copyright (c) 2014 Phillip Thelen. All rights reserved.
//

#import "HRPGPartyViewController.h"
#import "HRPGAppDelegate.h"
#import "HRPGQuestDetailViewController.h"
#import "HRPGQuestParticipantsViewController.h"
#import "HRPGMessageViewController.h"
#import "QuestCollect.h"
#import "ChatMessage.h"
#import <DateTools/DateTools.h>
#import "NSString+Emoji.h"
#import "HRPGProgressView.h"
#import "HRPGUserProfileViewController.h"
#import "NSMutableAttributedString_GHFMarkdown.h"
#import <DTAttributedTextView.h>
#import "HRPGCreatePartyViewController.h"

@interface HRPGPartyViewController ()
@property NSMutableDictionary *chatAttributeMapping;
@property NSIndexPath *selectedIndex;
@property NSIndexPath *buttonIndex;
@property NSString *replyMessage;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@property NSMutableArray *rowHeights;
@property DTAttributedTextView *sizeTextView;
@end

@implementation HRPGPartyViewController
Quest *quest;
User *user;
NSUserDefaults *defaults;
NSString *partyID;
ChatMessage *selectedMessage;


- (void)viewDidLoad {
    [super viewDidLoad];
    user = [self.sharedManager getUser];

    self.rowHeights = [NSMutableArray array];
    self.sizeTextView = [[DTAttributedTextView alloc] init];
    
    defaults = [NSUserDefaults standardUserDefaults];
    partyID = [defaults objectForKey:@"partyID"];
    self.chatAttributeMapping = [[NSMutableDictionary alloc] init];
    _fetchedResultsController = nil;
    if (!partyID || [partyID isEqualToString:@""]) {
        [self.sharedManager fetchGroups:@"party" onSuccess:^(){
            partyID = [defaults objectForKey:@"partyID"];
            self.fetchedResultsController = nil;
            [self.tableView reloadData];
            if (partyID && ![partyID isEqualToString:@""]) {
                [self setUpPartyEditButton];
                [self refresh];
            }
        } onError:^() {

        }];
    } else {
        [self setUpPartyEditButton];
        [self refresh];
        if (self.party) {
            [self fetchQuest];
            UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle: UIFontTextStyleBody];
            UIFontDescriptor *boldFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits: UIFontDescriptorTraitBold];
            UIFont *boldFont = [UIFont fontWithDescriptor: boldFontDescriptor size: 0.0];
            
            for (User *member in self.party.member) {
                if (member.username) {
                    [self.chatAttributeMapping setObject:@{
                                                           NSForegroundColorAttributeName: [member classColor],
                                                           NSFontAttributeName: boldFont
                                                           } forKey:member.username];
                }
            }
        }
        
        UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
        [refresh addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refresh;
    }


    [[NSNotificationCenter defaultCenter] addObserverForName:@"newChatMessage" object:nil queue:nil usingBlock:^(NSNotification *notification) {
        NSString *groupID = notification.object;
        if ([groupID isEqualToString:partyID]) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"partyChanged" object:nil queue:nil usingBlock:^(NSNotification *notification) {
        _fetchedResultsController = nil;
        partyID = [defaults objectForKey:@"partyID"];
        [self.tableView reloadData];
    }];
}

- (void)preferredContentSizeChanged:(NSNotification *)notification {
    [super preferredContentSizeChanged:notification];
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle: UIFontTextStyleBody];
    UIFontDescriptor *boldFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits: UIFontDescriptorTraitBold];
    UIFont *boldFont = [UIFont fontWithDescriptor: boldFontDescriptor size: 0.0];
    
    for (User *member in self.party.member) {
        [self.chatAttributeMapping setObject:@{
                                               NSForegroundColorAttributeName: [member classColor],
                                               NSFontAttributeName: boldFont
                                               } forKey:member.username];
    }
}

- (void)refresh {
    [self.sharedManager fetchGroup:@"party" onSuccess:^() {
        [self.refreshControl endRefreshing];
        Group *party = self.party;
        if (party == nil) {
            return;
        }
        
        if (party.questKey != nil) {
            [self fetchQuest];
        }
        if (party.questKey != nil && ![party.questActive boolValue] && user.participateInQuest == nil) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UINavigationController *navigationController = (UINavigationController *) [storyboard instantiateViewControllerWithIdentifier:@"questInvitationNavigationController"];
            HRPGQuestDetailViewController *questInvitationController = (HRPGQuestDetailViewController *) navigationController.topViewController;
            questInvitationController.quest = quest;
            questInvitationController.party = self.party;
            questInvitationController.user = user;
            questInvitationController.sourceViewcontroller = self;
            [self presentViewController:navigationController animated:YES completion:nil];
        }
        party.unreadMessages = [NSNumber numberWithBool:NO];
        [self.sharedManager chatSeen:party.id];
    }                      onError:^() {
        [self.refreshControl endRefreshing];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.party) {
        return 4;
    } else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (self.party) {
                return 2;
            } else {
                return 1;
            }
        case 1:
            if (!self.party) {
                return 1;
            } else if ([self.party.questActive boolValue] && [quest.bossHp integerValue] == 0) {
                return [quest.collect count] + 2;
            } else if ([self.party.questActive boolValue] && [self.party.questHP integerValue] > 0) {
                return 3;
            } else if (self.party.questKey) {
                return 2;
            } else {
                return 1;
            }
        case 2: {
            return 1;
        }
        case 3: {
            if (self.party != nil && [self.party.chatmessages count] > 0) {
                if (self.buttonIndex) {
                    return [self.party.chatmessages count]+1;
                } else {
                    return [self.party.chatmessages count];
                }
            }
        }
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (self.party) {
                return self.party.name;
            } else {
                return NSLocalizedString(@"New Party", nil);
            }
        case 1:
            if (self.party) {
                return NSLocalizedString(@"Quest", nil);
            } else {
                return NSLocalizedString(@"Join Party", nil);
            }
        case 2:
            return NSLocalizedString(@"Chat", nil);
        default:
            return @"";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.item == 0) {
        if (!self.party) {
            return 100;
        }
        if (!self.party.questKey) {
            return 60;
        }
        NSInteger height = [quest.text boundingRectWithSize:CGSizeMake(270.0f, MAXFLOAT)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{
                                                         NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
                                                 }
                                                    context:nil].size.height + 22;
        return height;
    } else if (indexPath.section == 0 && indexPath.item == 0) {
        if (!self.party) {
            return 60;
        }
        return [self.party.hdescription boundingRectWithSize:CGSizeMake(290.0f, MAXFLOAT)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{
                                                     NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                             }
                                                context:nil].size.height + 20;
    } else if (indexPath.section == 0) {
        return 44;
    } else if (indexPath.section == 1 && indexPath.item == 1 && [self.party.questActive boolValue] && [self.party.questHP integerValue] > 0) {
        NSInteger height = [@"50/100" boundingRectWithSize:CGSizeMake(280.0f, MAXFLOAT)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{
                                                        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                                }
                                                   context:nil].size.height + 10;
        return height;
    } else if (indexPath.section == 1) {
        if ([self.party.questActive boolValue]) {
            return 44;
        } else {
            return 50;
        }
        
    } else if (indexPath.section != self.tableView.numberOfSections-1) {
        return 44;
    } else {
        if (self.buttonIndex && self.buttonIndex.item == indexPath.item) {
            return 44;
        }
        ChatMessage *message;
        if (self.buttonIndex && self.buttonIndex.item < indexPath.item) {
            if (self.rowHeights.count > indexPath.item-1) {
                if (self.rowHeights[indexPath.item-1] != [NSNull null]) {
                    return [self.rowHeights[indexPath.item-1] doubleValue];
                }
            } else {
                [self.rowHeights addObject:[NSNull null]];
            }
            message = (ChatMessage *) self.party.chatmessages[indexPath.item-1];
        } else {
            if (self.rowHeights.count > indexPath.item) {
                if (self.rowHeights[indexPath.item] != [NSNull null]) {
                    return [self.rowHeights[indexPath.item] doubleValue];
                }
            } else {
                [self.rowHeights addObject:[NSNull null]];
            }
            message = (ChatMessage *) self.party.chatmessages[indexPath.item];
        }
        float width;
        if (message.user == nil) {
            width = self.viewWidth - 32;
        } else {
            width = self.viewWidth - 83;
        }
        NSMutableAttributedString *attributedText = [NSMutableAttributedString ghf_mutableAttributedStringFromGHFMarkdown:message.text];
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentLeft;
        [attributedText addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] range:NSMakeRange(0, attributedText.length)];
        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, attributedText.length)];
        [attributedText ghf_applyAttributes:self.markdownAttributes];
        
        self.sizeTextView.attributedString = attributedText;
        self.sizeTextView.shouldDrawLinks = YES;
        
        CGSize suggestedSize = [self.sizeTextView.attributedTextContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:width];
        
        CGFloat height = suggestedSize.height+40;
        
        if (height < 70 && message.user != nil) {
            height = 70;
        }
        if (self.buttonIndex && self.buttonIndex.item < indexPath.item) {
            self.rowHeights[indexPath.item-1] = [NSNumber numberWithDouble:height];
        } else {
            self.rowHeights[indexPath.item] = [NSNumber numberWithDouble:height];
        }
        return height;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndex = indexPath;
    if (!self.party && indexPath.section == 0 && indexPath.item == 0) {
        return;
    }
    if (indexPath.section == 0 && indexPath.item == 1) {
        [self performSegueWithIdentifier:@"MembersSegue" sender:self];
    } else if (indexPath.section == 1 && indexPath.item == 0) {
        if (quest) {
            [self performSegueWithIdentifier:@"QuestDetailSegue" sender:self];
        } else {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    } else if ((indexPath.section == 1 && indexPath.item == 1 && [self.party.questHP integerValue] == 0) || (indexPath.section == 1 && indexPath.item == 2 && [self.party.questActive boolValue] && [self.party.questHP integerValue] > 0)) {
        [self performSegueWithIdentifier:@"ParticipantsSegue" sender:self];
    } else if (self.buttonIndex && self.buttonIndex.item == indexPath.item && self.buttonIndex.section == indexPath.section) {
        
    } else if (indexPath.section != self.tableView.numberOfSections-1) {
        [self performSegueWithIdentifier:@"MessageSegue" sender:self];
    } else if (indexPath.section == 2) {
        if (self.buttonIndex && self.buttonIndex.item < indexPath.item) {
            selectedMessage = (ChatMessage *) self.party.chatmessages[indexPath.item-1];
        } else {
            selectedMessage = (ChatMessage *) self.party.chatmessages[indexPath.item];
        }
        if (!selectedMessage.user) {
            selectedMessage = nil;
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        [self.tableView beginUpdates];
        if (self.buttonIndex) {
            [self.tableView deleteRowsAtIndexPaths:@[self.buttonIndex] withRowAnimation:UITableViewRowAnimationTop];
        }
        NSIndexPath *newIndex = [NSIndexPath indexPathForItem:indexPath.item+1 inSection:indexPath.section];
        if (newIndex.item != self.buttonIndex.item) {
            if (self.buttonIndex && self.buttonIndex.item < newIndex.item) {
                self.buttonIndex = [NSIndexPath indexPathForItem:indexPath.item inSection:indexPath.section];
            } else {
                self.buttonIndex = newIndex;
            }
            [self.tableView insertRowsAtIndexPaths:@[self.buttonIndex] withRowAnimation:UITableViewRowAnimationTop];
        } else {
            self.buttonIndex = nil;
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        [self.tableView endUpdates];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellname;
    Group *party = self.party;
    if (indexPath.section == 0 && indexPath.item == 0) {
        if (party) {
            cellname = @"SmallTextCell";
        } else {
            cellname = @"CreatePartyCell";
        }
    } else if (indexPath.section == 0 && indexPath.item == 1) {
            cellname = @"BaseCell";

    } else if (indexPath.section == 1 && indexPath.item == 0) {
        if (party) {
            if (party.questKey == nil) {
                cellname = @"NoQuestCell";
            } else {
                cellname = @"QuestCell";
            }
        } else {
            cellname = @"JoinPartyCell";
        }
    } else if (indexPath.section == 1 && indexPath.item == 1 && [party.questActive boolValue] && [party.questHP integerValue] > 0) {
        cellname = @"LifeCell";
    } else if ((indexPath.section == 1 && indexPath.item == 1) || (indexPath.section == 1 && indexPath.item == 2 && [party.questActive boolValue] && [party.questHP integerValue] > 0)) {
        if ([party.questActive boolValue]) {
            cellname = @"BaseCell";
        } else {
            cellname = @"SubtitleCell";
        }
    } else if (indexPath.section == 1) {
        cellname = @"CollectItemQuestCell";
    } else if (indexPath.section != self.tableView.numberOfSections-1) {
        cellname = @"ComposeCell";
    } else {
        if (self.buttonIndex && indexPath.item == self.buttonIndex.item) {
            ChatMessage *message = (ChatMessage *) party.chatmessages[indexPath.item-1];
            if ([message.user isEqualToString: user.username]) {
                cellname = @"OwnButtonCell";
            } else {
                cellname = @"ButtonCell";
            }
        } else {
            ChatMessage *message;
            if (self.buttonIndex && self.buttonIndex.item < indexPath.item) {
                message = (ChatMessage *) party.chatmessages[indexPath.item-1];
            } else {
                message = (ChatMessage *) party.chatmessages[indexPath.item];
            }
            if (message.user != nil) {
                cellname = @"ImageChatCell";
            } else {
                cellname = @"ChatCell";
            }
        }
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellname forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Group" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"id == %@", partyID]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
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
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeUpdate:
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeDelete:
            break;
        case NSFetchedResultsChangeInsert:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    self.rowHeights = [NSMutableArray array];
    [self.tableView reloadData];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Group *party = self.party;
    if (party) {
        if (indexPath.section == 0 && indexPath.item == 0) {
            cell.textLabel.text = party.hdescription;
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else if (indexPath.section == 0 && indexPath.item == 1) {
            if ([party.member count] == 1) {
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.textLabel.text = NSLocalizedString(@"1 Member", nil);
            } else {
                cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Members", nil), (unsigned long) [party.member count]];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.section == 1 && indexPath.item == 0) {
            if (party.questKey != nil) {
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.textLabel.text = quest.text;
                cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];   
            }
        } else if (indexPath.section == 1 && indexPath.item == 1 && [party.questActive boolValue] && [party.questHP integerValue] > 0) {
            UILabel *lifeLabel = (UILabel *) [cell viewWithTag:1];
            lifeLabel.text = [NSString stringWithFormat:@"%@ / %@", party.questHP, quest.bossHp];
            lifeLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            HRPGProgressView *lifeBar = (HRPGProgressView *) [cell viewWithTag:2];
            lifeBar.progress = [NSNumber numberWithFloat:([party.questHP floatValue] / [quest.bossHp floatValue])];
        } else if ((indexPath.section == 1 && indexPath.item == 1) || (indexPath.section == 1 && indexPath.item == 2 && [party.questActive boolValue] && [party.questHP integerValue] > 0)) {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            int acceptedCount = 0;

            if ([party.questActive boolValue]) {
                for (User *participant in party.member) {
                    if ([participant.participateInQuest boolValue]) {
                        acceptedCount++;
                    }
                }
                if (acceptedCount == 1) {
                    cell.textLabel.text = NSLocalizedString(@"1 Participant", nil);
                } else {
                    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d Participants", nil), acceptedCount];
                }
            } else {
                cell.textLabel.text = NSLocalizedString(@"Participants", nil);
                for (User *participant in party.member) {
                    if (participant.participateInQuest != nil) {
                        acceptedCount++;
                    }
                }
                cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d out of %d responded", nil), acceptedCount, [party.member count]];

            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        } else if (indexPath.section == 1) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            QuestCollect *collect = quest.collect[indexPath.item - 2];
            cell.textLabel.text = collect.text;
            if ([collect.count integerValue] == [collect.collectCount integerValue]) {
                cell.textLabel.textColor = [UIColor grayColor];
            } else {
                cell.textLabel.textColor = [UIColor blackColor];
            }
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@/%@", collect.collectCount, collect.count];
            cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        } else if (indexPath.section == 3) {
            if (self.buttonIndex && self.buttonIndex.item == indexPath.item) {
                return;
            }
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.backgroundColor = [UIColor whiteColor];
            ChatMessage *message;
            if (self.buttonIndex && self.buttonIndex.item < indexPath.item) {
                message = (ChatMessage *) party.chatmessages[indexPath.item-1];
            } else {
                message = (ChatMessage *) party.chatmessages[indexPath.item];
            }
            UILabel *authorLabel = (UILabel *) [cell viewWithTag:1];
            authorLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            authorLabel.text = message.user;
            DTAttributedTextView *textLabel = (DTAttributedTextView *) [cell viewWithTag:2];
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.delegate = self;
            if (message.user != nil) {
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                UIImageView *imageView = (UIImageView *) [cell viewWithTag:5];
                [message.userObject setAvatarOnImageView:imageView withPetMount:NO onlyHead:YES useForce:NO];
                authorLabel.textColor = [message.userObject classColor];
                cell.backgroundColor = [UIColor whiteColor];
                NSString *text = [message.text stringByReplacingEmojiCheatCodesWithUnicode];
                if (text) {
                    NSMutableAttributedString *attributedMessage = [NSMutableAttributedString ghf_mutableAttributedStringFromGHFMarkdown:text];
                    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
                    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
                    paragraphStyle.alignment = NSTextAlignmentLeft;
                    [attributedMessage addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] range:NSMakeRange(0, attributedMessage.length)];
                    [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, attributedMessage.length)];
                    NSError *error = nil;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:&error];
                    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
                    for (NSTextCheckingResult *match in matches) {
                        NSRange wordRange = [match rangeAtIndex:0];
                        NSString* username = [text substringWithRange:[match rangeAtIndex:1]];
                        NSDictionary *attributes = [self.chatAttributeMapping objectForKey:username];
                        if (attributes) {
                            [attributedMessage addAttributes:attributes range:wordRange];
                        }
                        if ([username isEqualToString:user.username]) {
                            cell.backgroundColor = [UIColor colorWithRed:0.474 green:1.000 blue:0.031 alpha:0.030];
                        }
                    }
                    [attributedMessage ghf_applyAttributes:self.markdownAttributes];

                    textLabel.attributedString = attributedMessage;
                }
            } else {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.backgroundColor = [UIColor colorWithRed:0.986 green:0.000 blue:0.047 alpha:0.020];
                NSMutableAttributedString *attributedMessage = [NSMutableAttributedString ghf_mutableAttributedStringFromGHFMarkdown:message.text];
                NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
                paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
                paragraphStyle.alignment = NSTextAlignmentLeft;
                [attributedMessage addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] range:NSMakeRange(0, attributedMessage.length)];
                [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, attributedMessage.length)];
                [attributedMessage ghf_applyAttributes:self.markdownAttributes];
                [[attributedMessage string] enumerateSubstringsInRange:NSMakeRange(0, [attributedMessage length]) options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                    NSDictionary *attributes = [self.chatAttributeMapping objectForKey:substring];
                    if (attributes) {
                        [attributedMessage addAttributes:attributes range:substringRange];
                    }
                    
                }];
                textLabel.attributedString = attributedMessage;
            }
            UILabel *dateLabel = (UILabel *) [cell viewWithTag:3];
            dateLabel.text = message.timestamp.timeAgoSinceNow;
            dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            //[dateLabel sizeToFit];
        }
    } else {
        if (indexPath.section == 1 && indexPath.item == 0) {
            UILabel *userIDLabel = (UILabel*)[cell viewWithTag:1];
            userIDLabel.text = user.id;
        }
    }
}

- (void)fetchQuest {
    if (self.party.questKey) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Quest" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", self.party.questKey]];
        NSError *error;
        NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if ([result count] > 0) {
            quest = result[0];
            if (!quest.text) {
                [self.sharedManager fetchContent:^() {
                    [self fetchQuest];
                }onError:^() {
                    
                }];
            }
        }
        [self.tableView reloadData];

    } else {
        quest = nil;
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"ParticipantsSegue"]) {
        HRPGQuestParticipantsViewController *qpViewcontroller = segue.destinationViewController;
        qpViewcontroller.party = self.party;
        qpViewcontroller.quest = quest;
    } else if ([segue.identifier isEqualToString:@"QuestDetailSegue"]) {
        HRPGQuestDetailViewController *qdViewcontroller = segue.destinationViewController;
        qdViewcontroller.quest = quest;
        qdViewcontroller.party = self.party;
        qdViewcontroller.user = user;
        qdViewcontroller.hideAskLater = [NSNumber numberWithBool:YES];
        qdViewcontroller.wasPushed = [NSNumber numberWithBool:YES];
    } else if ([segue.identifier isEqualToString:@"MessageSegue"]) {
        UINavigationController *navController = segue.destinationViewController;
        HRPGMessageViewController *messageViewController = (HRPGMessageViewController*) navController.topViewController;
        if (self.replyMessage) {
            messageViewController.presetText = self.replyMessage;
            self.replyMessage = nil;
        }
    } else if ([segue.identifier isEqualToString:@"UserProfileSegue"]) {
        HRPGUserProfileViewController *userProfileViewController = (HRPGUserProfileViewController*) segue.destinationViewController;
        userProfileViewController.userID = selectedMessage.userObject.id;
        userProfileViewController.username = selectedMessage.user;
    } else if ([segue.identifier isEqualToString:@"PartyFormSegue"]) {
        if (self.party) {
            UINavigationController *navigationController = (UINavigationController*)segue.destinationViewController;
            HRPGCreatePartyViewController *partyFormViewController = (HRPGCreatePartyViewController *) navigationController.topViewController;
            partyFormViewController.editParty = YES;
            partyFormViewController.party = self.party;
        }
    }
}

- (IBAction)unwindToListSendMessage:(UIStoryboardSegue *)segue {
    HRPGMessageViewController *messageController = (HRPGMessageViewController*)[segue sourceViewController];
    [self.sharedManager chatMessage:messageController.messageView.text withGroup:self.party.id onSuccess:nil onError:nil];
    
}

- (IBAction)showUserProfile:(id)sender {
    [self performSegueWithIdentifier:@"UserProfileSegue" sender:self];
}

- (IBAction)deleteMessage:(id)sender {
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[self.buttonIndex] withRowAnimation:UITableViewRowAnimationTop];
    self.buttonIndex = nil;
    [self.tableView endUpdates];
    [self.sharedManager deleteMessage:selectedMessage withGroup:@"party" onSuccess:^() {
        selectedMessage = nil;
    } onError:^() {
    }];
}

- (IBAction)replyToMessage:(id)sender {
    self.replyMessage = [NSString stringWithFormat:@"@%@ ", selectedMessage.user];
    [self performSegueWithIdentifier:@"MessageSegue" sender:self];

    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[self.buttonIndex] withRowAnimation:UITableViewRowAnimationTop];
    self.buttonIndex = nil;
    [self.tableView endUpdates];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    return YES;
}

- (Group*) party {
    if ([[self.fetchedResultsController sections] count] > 0 && [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects] > 0) {
        Group *party = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        if (party.id) {
            return party;
        }
    }
    return nil;
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue {
}

- (IBAction)unwindToListSave:(UIStoryboardSegue *)segue {
    HRPGCreatePartyViewController *formViewController = (HRPGCreatePartyViewController *) segue.sourceViewController;
    if (formViewController.editParty) {
        [self.sharedManager updateGroup:formViewController.party onSuccess:nil onError:nil];
    } else {
        [self.sharedManager createGroup:formViewController.party onSuccess:^() {
            partyID = [defaults objectForKey:@"partyID"];
            _fetchedResultsController = nil;
            [self.tableView reloadData];
        } onError:nil];
    }
}

- (void)setUpPartyEditButton {
    if ([self.party.leader.id isEqualToString:user.id]) {
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(openPartyForm)];
        self.navigationItem.rightBarButtonItem = barButton;
    }
}

- (void) openPartyForm {
    [self performSegueWithIdentifier:@"PartyFormSegue" sender:self];
}

@end
