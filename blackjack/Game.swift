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
    var players: [Player] = []
    
    override func didMoveToView(view: SKView) {
        
        let NUMBER_OF_DECKS = 1
        let NUMBER_OF_PLAYERS = 5
        
        // A swift shorthand for making a repeated array
        players = [Player](count: NUMBER_OF_PLAYERS, repeatedValue: Player())
        
        for _ in 1...NUMBER_OF_DECKS {
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
        
        // Deal two cards each
        for _ in 1...2 {
            for player in players {
                hit(player)
            }
        }
    }
    
    func hit(player: Player) {
        if let card = deck.first {
            
            // This loop will only run if there are cards remaining (Swift optionals!)
            
            player.hand.append(card)
            deck.removeAtIndex(0)
            self.addChild(card)
        }
    }
}
