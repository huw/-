//
//  GameScene.swift
//  blackjack
//
//  Created by Huw on 2015-10-08.
//  Copyright (c) 2015 Huw. All rights reserved.
//

import SpriteKit
import GameplayKit

var keys = [
    "h": false,
    "s": false
]

class GameScene: SKScene {
    
    let NUMBER_OF_DECKS = 1
    let NUMBER_OF_PLAYERS = 5
    
    var deck: [Card] = []
    var players: [Player] = []
    
    override func didMoveToView(view: SKView) {
        
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
        
        /*
        How this works:
        
        The player is the 'base node' here. It subclasses SKNode, which means it has a position and inherits some of those basic properties, but it doesn't need to display so we don't give it anything like SKSpriteNode etc.
        
        What we _do_ get, is that all things attached to it are positioned relatively to it all. The base position of the player is where the points label sits. Most of the rest of the positioning is in the Player() class anyway.
        
        This way, when we deal cards we can place them relatively around the screen.
        */
        
        let baseUnit = 1280 / NUMBER_OF_PLAYERS // = 256 for 5 players
        
        for i in 1...NUMBER_OF_PLAYERS {
            let player = Player()
            
            player.position = CGPoint(x: baseUnit * i - (baseUnit / 2), y: 37)
            
            players.append(player)
            self.addChild(player)
        }
        
        
        // Deal two cards each
        // (Traditionally, we shuffle in rounds. So the 1...2 loop comes first)
        for _ in 1...2 {
            for player in players {
                hit(player)
            }
        }
    }
    
    func hit(player: Player) {
        if let card = deck.first {
            
            // This loop will only run if there are cards remaining (Swift optionals!)
            
            /*
            Parallelograms tesselate. For this one, every 70 pixels we move up, we have to move it 18 pixels right so that they line up properly. We when subtract 72 pixels horizontally from all of them, so that they roughly center around the scoreboard. Roughly.
            */
            
            let dy = 70 * (player.hand.count + 1)
            let dx = 18 * (player.hand.count + 1) - 72
            card.position = CGPoint(x: dx, y: dy)
            
            /*
            Add the card to the players hand, then remove the first card from the deck. The conditional at the top asserts that this card _is_ the first one in the deck, so we're safe.
            */
            
            player.hand.append(card)
            deck.removeAtIndex(0)
            player.addChild(card)
            
            // Update scores
            let scores = player.score()
            player.baseLabel.text = "\(scores["Base"]!) points"
            
            if scores["Bonus"] > 0 && scores["Bonus"] <= 21 {
                player.bonusLabel.text = "(\(scores["Base"]! + scores["Bonus"]!) points with ace)"
            }
        }
    }
    
    override func keyDown(e: NSEvent) {
        if let key = e.charactersIgnoringModifiers {
            if keys[key] != nil {
                keys[key] = true
            }
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        let humanPlayer = players[Int(NUMBER_OF_PLAYERS / 2)]
        
        let h = keys["h"]!
        let s = keys["s"]!
        
        if h {
            if humanPlayer.score()["Base"] < 21 {
                hit(humanPlayer)
            }
            keys["h"] = false
        } else if s {
            keys["s"] = false
        }
    }
}
