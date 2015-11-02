//
//  Card.swift
//  Blackjack
//
//  Created by Huw on 2015-10-16.
//  Copyright © 2015 Huw. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit

/**
This, and `Rank`, inherit from Int because Swift automatically assigns each a value in the order that they are declared. With this, we can iterate over the enum to get a list of the possible cases.
*/

enum Suit: Int {
    case Spades, Hearts, Diamonds, Clubs
    
    /**
    - returns
    Unicode value for the suit (♠, ♥, ♦, ♣)
    */
    
    func symbol() -> Character {
        switch self {
        case Spades:
            return "♠"
        case Hearts:
            return "♥"
        case Diamonds:
            return "♦"
        case Clubs:
            return "♣"
        }
    }
}

enum Rank: Int {
    case Ace, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King
    
    /**
    This is one of my favourite functions. Because each case is assigned a `rawValue` based on its declaration order, we don't have to write cases saying that `Two = "2"`, or however it's done. Instead, we can simply get the raw value, and add 1 to it. Convert that to a String, and we're done!
    
    - returns
    String value to identify the rank of the card (2...10, J, Q, K, A)
    */
    
    func value() -> String {
        switch self {
        case Ace:
            return "A"
        case Jack:
            return "J"
        case Queen:
            return "Q"
        case King:
            return "K"
        default:
            return String(rawValue + 1)
        }
    }
}

class Card: SKSpriteNode {
    
    let suit: Suit
    let rank: Rank
    let labelNode = SKLabelNode()
    
    init(suit: Suit, rank: Rank) {
        self.suit = suit
        self.rank = rank
        
        super.init(texture: SKTexture(imageNamed: "Card Back"), color: SKColor.blackColor(), size: CGSize(width: 128, height: 60))
        
        self.position = CGPoint(x: 9999, y: 9999)
        
        labelNode.fontName = "San Francisco Display"
        labelNode.fontSize = 50
        labelNode.position = CGPoint(x: 0, y: -20)
        labelNode.text = "\(self.rank.value())\(self.suit.symbol())"
        self.addChild(labelNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
    Each card should have a more readable value when printed. The default for SKSpriteNode will reveal its texture, size, and color—but this isn't useful. I mostly just want to see the cards. Instead, we can print out a nice value for the rank and suit of each card, the functions for which we define in `Rank` and `Card`.
    
    - returns
    The value returned by Rank.value(), next to the value returned by Suit.symbol(), e.g. `K♣`, or `10♠`.
    */
    
    override var description: String {
        return "\(self.rank.value())\(self.suit.symbol())"
    }
}