//
//  ChallengeTableViewCell.swift
//  Habitica
//
//  Created by Phillip Thelen on 23/02/2017.
//  Copyright © 2017 Phillip Thelen. All rights reserved.
//

import UIKit

class ChallengeTableViewCell: UITableViewCell {

    @IBOutlet weak var prizeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var leaderLabel: UILabel!
    @IBOutlet weak var memberCountLabel: UILabel!
    @IBOutlet weak var officialBadge: PillView!
    @IBOutlet weak var participatingBadge: PillView!
    @IBOutlet weak var officialParticipatingSpacing: NSLayoutConstraint!
    @IBOutlet weak var badgesHeight: NSLayoutConstraint!
    
    func setChallenge(_ challenge: Challenge) {
        self.prizeLabel.text = challenge.prize?.stringValue
        self.nameLabel.text = challenge.name
        
        self.groupLabel.text = challenge.group?.name
        
        if let leaderName = challenge.leaderName {
            self.leaderLabel.text = "By \(leaderName)".localized
        }
        self.memberCountLabel.text = challenge.memberCount?.stringValue
        
        let official = challenge.official?.boolValue ?? false
        self.officialBadge.isHidden = !official
        self.officialBadge.setNeedsLayout()
        if official {
            officialParticipatingSpacing.constant = 8
        } else {
            officialParticipatingSpacing.constant = 0
        }
    }
}
