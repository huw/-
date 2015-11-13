//
//  Player.swift
//  Blackjack
//
//  Created by Huw on 2015-10-26.
//  Copyright © 2015 Huw. All rights reserved.
//

import SpriteKit
import GameplayKit

class Player: SKNode, GKGameModelPlayer {
    var hand: [Card] = []
    var cash = 500
    var standing = false
    var bust = false
    
    var baseLabel = SKLabelNode()
    var bonusLabel = SKLabelNode()
    var cashLabel = SKLabelNode()
    
    // Required by GameplayKit. Must be unique.
    let playerId: Int
    
    init(id: Int) {
        playerId = id
        
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
        cashLabel.text = "$\(cash - 25)"
        
        self.addChild(baseLabel)
        self.addChild(bonusLabel)
        self.addChild(cashLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
    Player.score() mostly uses the already-in-place enums for ranking, which is convenient. It iterates through each card in the player's hand, and adds it to an appropriate total. When it encounters an Ace, it adds +1 to the base score, and if it's the first Ace, +10 to a 'bonus' score which can be used later.
     
    - returns
    A dictionary ([String: Int]) with "Base" and "Bonus" scores. "Base" is the player's score with all Aces counted as 1, and "Bonus" is how much to add to "Base" if the first Ace is counted as 11.
    */
    
    func score() -> [String: Int] {
        
        var total = ["Base": 0, "Bonus": 0]
        
        for card in hand {
            switch card.rank {
            case .Jack, .Queen, .King:
                total["Base"]! += 10
            case .Ace:
                
                /*
                This bit is a little tricky, but it's actually kinda neat. We do the normal test for Jacks, Queens and Kings above, but what about handling Aces? Well, if you think about it (although it was never expressly stated as a rule), you can only count the _first_ ace as 11. Once you count a second Ace as 11, then you're over the limit. It's kinda beautiful, because it's a constraint that doesn't need to be said, but instead it's implied by the rules!
                
                So if our "Bonus" section is empty and we've hit an Ace, then we can add 10 points!
                
                You'll notice this isn't 11 points—"Bonus" is the amount to _add_ if we're counting it as 11. If we're counting it as 1, though, then we use a special statement (`fallthrough`) that automatically runs the next case, regardless as to if its true or not. We can do this, because adding 1 to `card.rank.rawValue` will provide the right number for everything except the picture cards (see Card.swift).
                */
                
                if total["Bonus"]! == 0 {
                    total["Bonus"]! += 10
                }
                
                fallthrough
            default:
                total["Base"]! += card.rank.rawValue + 1
            }
        }
        
        // Give the player 0 if they've gone bust
        if total["Base"] > 21 {
            return ["Base": 0, "Bonus": 0]
        } else if total["Base"]! + total["Bonus"]! > 21 {
            return ["Base": total["Base"]!, "Bonus": 0]
        }
        
        return total
    }
    
    func blackjack() -> Bool {
        let playerScore = score()
        return (playerScore["Base"]! + playerScore["Bonus"]!) == 21 && hand.count == 2
    }
    
    func reset() {
        hand.removeAll()
        standing = false
        bust = false
        cashLabel.text = "$\(cash)"
    }
}