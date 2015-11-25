//
//  Game.swift
//  Blackjack
//
//  Created by Huw on 2015-11-02.
//  Copyright © 2015 Huw. All rights reserved.
//

import SpriteKit
import GameplayKit

class Round {
    
    var deck: [Card] = []
    var players: [Player] = []
    var dealer = Player(id: 0)
    
    var activePlayerIndex: Int = 0
    var activePlayer: Player {
        return players[activePlayerIndex]
    }
    
    var aceRiskFactor = 50
    var dealerHitsOnSoft17 = true
    
    init(players: [Player], dealer: Player) {
        
        // Build the deck. 1 card per rank per suit per deck.
        
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
        
        self.players = players
        self.dealer = dealer
    }
    
    /**
    This convenience initialiser is used on the first run. It builds its own list of players and a dealer, and passes it to the normal initialiser for it to do its thing. It is cleaner to have the first init use a convenience initialiser (when you'd ideally have the first init using the main one), because this way we don't have to regenerate a list of players each time we want to create a new round.
    */
    
    convenience init() {
        var tempPlayers: [Player] = []
        
        for i in 0...NUMBER_OF_PLAYERS - 1 {
            tempPlayers.append(Player(id: i + 1))
        }
        
        self.init(players: tempPlayers, dealer: Player(id: 0))
    }
    
    func hit(player: Player) -> Card? {
        
        if let card = deck.first {
                
            /*
            Add the card to the players hand, then remove the first card from the deck. The conditional at the top asserts that this card _is_ the first one in the deck, so we're safe.
            */
            
            player.hand.append(card)
            
            deck.removeAtIndex(0)
            nextPlayer()
            
            return card
        }
        
        return nil
    }
    
    func nextPlayer() {
        
        if activePlayerIndex >= NUMBER_OF_PLAYERS - 1 {
            activePlayerIndex = 0
        } else {
            activePlayerIndex += 1
        }
    }
    
    /**
    Firstly, we check if the player is counting an ace in their score. If so, then we implement the 'ace risk'—what chance they have of standing if they have this ace. If all these conditions are met, we stand. Otherwise, we continue—which almost always leads to a hit.
     
    Secondly, if they're not counting their ace and their score is 10 or 11, it almost always makes sense to double. So do that.

    Our AI is a card counter. It loops through the cards remaining in the deck (i.e. the cards it can't count), and calculates the average value. If, when adding this average value to our current score, the score is over 21, then we stand. This is the most effective.
     
    This combination of values should almost always lead to the AI defeating the house edge.
    
    - returns
    Three Bools, which correspond to 'hitting', 'standing', and 'doubling down' respectively. To be processed by the player action loop in Scene.
    */

    func AIActionChoice(player: Player) -> (Bool, Bool, Bool) {
        
        if player.isCountingAce && player.score() >= 18 && GKARC4RandomSource().nextUniform() < Float(aceRiskFactor) / 100 {
            return (false, true, false)
        }
        
        if !player.isCountingAce && (player.score() == 10 || player.score() == 11) {
            return (false, false, true)
        }
        
        let originalHand = player.hand
        var average: Float = 0
        
        for card in deck {
            player.hand.append(card)
            
            average += Float(player.scoreBase() + player.scoreBonus())
            
            // Reset the hand
            player.hand = originalHand
        }
        
        average = average / Float(deck.count)
        
        if player.score() + Int(average) <= 21 {
            return (true, false, false)
        } else {
            return (false, true, false)
        }
    }
    
    func isGameOver() -> Bool {
        for player in players {
            
            /*
            If a single player hasn't gone bust or decided to stand, then they can still hit, so we must continue the loop. Otherwise, the game actually is over and we can run that stuff.
            */
            
            if player.stillPlaying {
                return false
            }
        }
        
        return true
    }
}
