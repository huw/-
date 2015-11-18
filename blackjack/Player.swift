//
//  Player.swift
//  Blackjack
//
//  Created by Huw on 2015-10-26.
//  Copyright © 2015 Huw. All rights reserved.
//

import SpriteKit
import GameplayKit

class Player: SKNode {
    var hand: [Card] = []
    var cash = 0
    var standing = false
    
    /*
    These three are only returned when the variable is needed. They're computed properties. This means we can use existing class properties in the definition for a class property, _and_ they don't need to look like functions. A lot of them are just shorthands for pretty simple stuff.
    */
    
    var bankrupt: Bool {
        return cash <= 0
    }
    
    var blackjack: Bool {
        return score() == 21 && hand.count == 2
    }
    
    var bust: Bool {
        return scoreBase() > 21
    }
    
    var stillPlaying: Bool {
        return !standing && !bust && !bankrupt
    }
    
    var baseLabel = SKLabelNode()
    var bonusLabel = SKLabelNode()
    var cashLabel = SKLabelNode()
    
    // Required by GameplayKit. Must be unique.
    let id: Int
    
    init(id: Int) {
        self.id = id
        
        super.init()
        
        baseLabel.fontName = "San Francisco Display"
        
        // bonusLabel should be smaller and a little faded
        bonusLabel.fontName = "San Francisco Display Medium"
        bonusLabel.fontSize = 14
        bonusLabel.fontColor = SKColor(red: 1, green: 1, blue: 1, alpha: 0.7)
        bonusLabel.position = CGPoint(x: 0, y: -18)
        
        cashLabel.fontName = "San Francisco Display Bold"
        cashLabel.fontSize = 14
        cashLabel.position = CGPoint(x: 0, y: -34)
        
        if self.id != 0 {
            cashLabel.text = "$\(500)"
        }
        
        self.addChild(baseLabel)
        self.addChild(bonusLabel)
        self.addChild(cashLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
    The three score functions are useful for navigating the really iffy field of these 'Ace can be worth 1 or 11 points depending on my mood' things. The first one will return the player's score if they counted an Ace as 1 point. The second returns the amount to _add_ if Aces are worth 11. Neither of these two functions make considerations for the score being over 21 points, because the second one isn't able to do that without calling the first again.
    
    scoreBonus() is nifty, because we can only count a single ace as worth 11 points. So it only needs to determine if there _is_ an ace in the hand or not.
     
    score() will return the player's combined score, with considerations for whether the score is above 21 or not.
    */
    
    func scoreBase() -> Int {
        var total = 0
        
        for card in hand {
            switch card.rank {
            case .Jack, .Queen, .King:
                total += 10
            default:
                total += card.rank.rawValue + 1
            }
        }
        
        return total
    }
    
    func scoreBonus() -> Int {
        for card in hand {
            if card.rank == .Ace {
                return 10
            }
        }
        
        return 0
    }
    
    func score() -> Int {
        let score = scoreBase()
        let scoreWithBonus = score + scoreBonus()
        
        if score > 21 {
            return 0
        } else if scoreWithBonus > 21 {
            return score
        }
        
        return scoreWithBonus
    }
    
    /*
    Keep in mind that reset() is where we update the player's cash label. We only need to do it once at the end of the round, so we may as well do it here.
    */
    
    func reset() {
        hand.removeAll()
        standing = false
        if bankrupt {
            cashLabel.text = ""
        } else {
            cashLabel.text = "$\(cash)"
        }
        baseLabel.text = "0 points"
        bonusLabel.text = ""
    }
}