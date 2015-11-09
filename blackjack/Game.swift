//
//  Game.swift
//  Blackjack
//
//  Created by Huw on 2015-11-02.
//  Copyright © 2015 Huw. All rights reserved.
//

import Foundation

//
//  GameScene.swift
//  blackjack
//
//  Created by Huw on 2015-10-08.
//  Copyright (c) 2015 Huw. All rights reserved.
//

import SpriteKit
import GameplayKit

class Move: NSObject, GKGameModelUpdate {
    var value: Int = 0
    let hit: Bool
    
    init(hit: Bool) {
        self.hit = hit
    }
}

class Game {
    
    let deckCount: Int
    let playerCount: Int
    
    var deck: [Card] = []
    var players: [Player] = []
    var activePlayer: Player
    var dealer = Player(id: 0)
    
    // currentPlayer is the _index_ where the activePlayer can be found
    var currentPlayer: Int = 0
    
    // is this a copy? (should we run UI stuff?)
    var isCopy = false
    
    init(decks NUMBER_OF_DECKS: Int, players NUMBER_OF_PLAYERS: Int) {
        
        deckCount = NUMBER_OF_DECKS
        playerCount = NUMBER_OF_PLAYERS
        
        // Build the deck. 1 card per rank per suit per deck.
        
        for _ in 1...deckCount {
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
        
        // Build the list of players. Other layout stuff happens in the view controller.
        for i in 0...playerCount - 1 {
            players.append(Player(id: i + 1))
        }
        
        activePlayer = players[currentPlayer]
    }
    
    func hit(player: Player) -> Card? {
        
        if let card = deck.first {
            
            // This loop will only run if there are cards remaining (Swift optionals!)
            
            /*
            Add the card to the players hand, then remove the first card from the deck. The conditional at the top asserts that this card _is_ the first one in the deck, so we're safe.
            */
            
            player.hand.append(card)
            
            // If the score is over 21, score()["Base"] will return zero. Thus the player is bust.
            player.bust = player.score()["Base"]! == 0
            
            deck.removeAtIndex(0)
            nextPlayer()
            
            return card
        }
        
        return nil
    }
    
    func nextPlayer() {
        if currentPlayer >= playerCount - 1 {
            currentPlayer = 0
        } else {
            currentPlayer += 1
        }
        
        activePlayer = players[currentPlayer]
    }

    func shouldAIHit() -> Bool? {
        
        let score = activePlayer.score()
        
        /*
        The average of the possible card values comes out to be something like 6.53. If we add the average to the current score, and it comes out to be more than 21, then we don't want to hit, because that means that there's a greater probability of failure.
        */
        
        return score["Base"]! != 0 && Double(score["Base"]!) + 6 <= 21
    }
    
    func isGameOver() -> Bool {
        for player in players {
            
            /*
            If a single player hasn't gone bust or decided to stand, then they can still hit, so we must continue the loop. Otherwise, the game actually is over and we can run that stuff.
            */
            
            if !player.bust && !player.standing {
                return false
            }
        }
        
        return true
    }
}
