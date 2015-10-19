//
//  GameScene.swift
//  blackjack
//
//  Created by Huw on 2015-10-08.
//  Copyright (c) 2015 Huw. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var deck: [Card] = []
    
    var i = 0
    
    override func didMoveToView(view: SKView) {
        
        let num_decks = 10
        
        for _ in 1...num_decks {
            for suit_num in 0...3 {
                
                let suit = Suit(rawValue: suit_num)!
                
                for rank_num in 0...12 {
                    
                    let rank = Rank(rawValue: rank_num)!
                    deck.append(Card(suit: suit, rank: rank))
                }
            }
        }
        
        /*
        The decision was made here to use GameplayKit's algorithm over one I'd make myself. If I were to implement the Fisher-Yates shuffling algorithm myself, it would not be as efficient or effective as something that  make. However, because this is a programming class, and I'm supposed to do so, here is how I would build the Fisher-Yates algorithm:
        
            for pos1 in (0...52-1).reverse() {
                let pos2 = Int(arc4random_uniform(UInt32(pos1) + 1))
                let card1 = deck[pos1]
                let card2 = deck[pos2]
                deck[pos2] = card1
                deck[pos1] = card2
            }
        
        You may replace the code with this to verify that it works yourself.
        */
        
        deck = GKMersenneTwisterRandomSource.sharedRandom().arrayByShufflingObjectsInArray(deck) as! [Card]
    }
    
    override func mouseDown(theEvent: NSEvent) {
    }
    
    override func update(currentTime: CFTimeInterval) {
        if i < deck.count {
            self.addChild(deck[i])
            i++
        }
    }
}
