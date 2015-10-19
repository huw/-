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
    
    /**
    - returns
    An appropriate value to be used with Rank.scalar() to determine the position of a card's character in the Unicode table.
    */
    
    func scalar() -> UInt32 {
        return 0x10 * UInt32(rawValue)
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
    
    /**
    For most, we want to add 1 to its declaration order, because there's an empty slot at the front of each row in the Unicode table (except for the Spades row, which has a card back). Once we pass the Jack, though, there's a 'Knight' card, which we can't use. So we add two there.
    
    - returns
    An appropriate hexadecimal number to be used in combination with a Suit.scalar() to determine the position of the card's character in the unicode table.
    */
    
    func scalar() -> UInt32 {
        let addition: Int
        
        if rawValue <= 10 {
            addition = 1
        } else {
            addition = 2
        }
        
        return UInt32(rawValue + addition)
    }
}

class Card: SKSpriteNode {
    
    let suit: Suit
    let rank: Rank
    let labelNode = SKLabelNode(fontNamed: "San Francisco Display")
    var scalar: UInt32 = 0x1F0A0 // "🂠"
    
    init(suit: Suit, rank: Rank) {
        self.suit = suit
        self.rank = rank
        
        super.init(texture: nil, color: SKColor.whiteColor(), size: CGSize(width: 82, height: 110))
        
        /*
        I'm determined not to write things that a computer could clearly and properly do. So for the displaying of the cards, I've not only opted to use the set contained within Unicode, but I also don't think I should have to have a huge dictionary or `switch` to store all of them. There's a better way—every Unicode character (as it should) has a number assigned to it, in hexadecimal. Using some pretty easy math, we can print out the appropriate Unicode character by calling some functions within out enums.
        Here, we start with the character 0x1F0A0, which is an empty card back. When the suit and rank are specified, we can add their scalars to 0x1F0A0 and now we have the cards we want. For reference, I'm using the table at https://en.wikipedia.org/wiki/Playing_cards_in_Unicode#Block
        */
        
        scalar += suit.scalar() + rank.scalar()
        labelNode.text = String(UnicodeScalar(scalar))
        
        /*
        So we can give the card a background, we must first define the card as an empty background. Then, we add an SKLabelNode as a child of this background, which holds all of the important details
        */

        labelNode.fontSize = 140
        labelNode.position = CGPoint(x: 0, y: -45.5)
        
        self.position = CGPoint(x: GKRandomSource.sharedRandom().nextIntWithUpperBound(1280), y: GKRandomSource.sharedRandom().nextIntWithUpperBound(800-110))
        
        if suit == .Hearts || suit == .Diamonds {
            labelNode.fontColor = SKColor.redColor()
        } else {
            labelNode.fontColor = SKColor.blackColor()
        }
        
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