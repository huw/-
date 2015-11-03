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

class Game: NSObject, GKGameModel {
    
    let deckCount: Int
    let playerCount: Int
    
    var deck: [Card] = []
    var players: [GKGameModelPlayer]? = []
    var activePlayer = GKGameModelPlayer?()
    var dealer = Player(id: 0)
    var strategist = GKMinmaxStrategist()
    
    // currentPlayer is the _index_ where the activePlayer can be found
    var currentPlayer: Int = 0
    
    // is this a copy? (should we run UI stuff?)
    var isCopy = false
    
    init(decks NUMBER_OF_DECKS: Int, players NUMBER_OF_PLAYERS: Int) {
        
        deckCount = NUMBER_OF_DECKS
        playerCount = NUMBER_OF_PLAYERS
        
        super.init()
        
        /*
        We only really need to look three turns ahead to decide whether hitting is a good idea right now. I'm not really sure if we need to look more than 1 turn ahead, but I guess it makes a difference.
        
        randomSource is a function which determines how we randomly settle situations where the score of a move is equal. We can use a simple random here.
        */
        
        strategist.maxLookAheadDepth = 3
        strategist.randomSource = GKARC4RandomSource()
        strategist.gameModel = self
        
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
        
        players!.append(dealer)
        for i in 0...playerCount - 1 {
            players!.append(Player(id: i + 1))
        }
    }
    
    func hit(playerId: Int) -> Card? {
        
        let player = players![playerId] as! Player
        
        if let card = deck.first {
            
            // This loop will only run if there are cards remaining (Swift optionals!)
            
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
        
        // Again, we'd normally subtract 1 from playerCount, but we have a dealer as well
        if currentPlayer >= playerCount {
            currentPlayer = 0
        } else {
            currentPlayer += 1
        }
        
        activePlayer = players![currentPlayer]
    }
    
    /*func shouldAIHit() -> Bool? {
        
        if let move = strategist.bestMoveForPlayer(activePlayer!) {
            return (move as! Move).hit
        }
        
        return nil
    }*/
    
    func shouldAIHit() -> Bool? {
        
        let player = activePlayer as! Player
        let score = player.score()
        
        /*
        This is a really really long statement, but I kept it in the code because it's efficient and somewhat self-explanatory.
        
        It's split down the middle by an OR, which separates the two clauses for AI player (playerId > 0) and dealer (playerId == 0). The AI Player clause calculates a _rough_ statistical probability for this hit to be dangerous. If it's more likely that the hit will keep them under 21 points, then they hit. If it's not, they don't. Easy.
        
        The dealer has stricter rules. If they have an ace (score["Bonus"]! > 0), then they need to hit if the score is 17 or under (a.k.a. soft 17). Otherwise, they must also hit when their base score is under 17 (and they have no ace).
        */
        
        if (player.playerId > 0 && Double(score["Base"]!) + 6 <= 21) || (player.playerId == 0 && ((score["Bonus"]! > 0 && score["Base"]! + score["Bonus"]! <= 17) || score["Base"]! < 17)) {
            return true
        }
        
        return false
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = Game(decks: deckCount, players: playerCount)
        copy.setGameModel(self)
        copy.isCopy = true
        return copy
    }
    
    func setGameModel(gameModel: GKGameModel) {
        if let game = gameModel as? Game {
            players = game.players
            deck = game.deck
            currentPlayer = game.currentPlayer
            activePlayer = game.players![game.currentPlayer]
        }
    }
    
    func gameModelUpdatesForPlayer(player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
        if let playerObject = player as? Player {
            if playerObject.score()["Base"] < 21 {
                return [Move(hit: true), Move(hit: false)]
            } else {
                return [Move(hit: false)]
            }
        }
        
        return nil
    }
    
    func applyGameModelUpdate(gameModelUpdate: GKGameModelUpdate) {
        if let move = gameModelUpdate as? Move {
            if move.hit {
                hit(currentPlayer)
            }
        }
    }
    
    func scoreForPlayer(player: GKGameModelPlayer) -> Int {
        if let playerObject = player as? Player {
            
            let score = playerObject.score()
            let fullScore = score["Base"]! + score["Bonus"]!
            
            if fullScore <= 21 {
                return fullScore
            } else if score["Base"] <= 21 {
                return score["Base"]!
            }
        }
        
        return 0
    }
}
