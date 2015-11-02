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
    var strategist = GKMinmaxStrategist()
    
    var currentPlayer: Int
    
    init(decks NUMBER_OF_DECKS: Int, players NUMBER_OF_PLAYERS: Int) {
        
        deckCount = NUMBER_OF_DECKS
        playerCount = NUMBER_OF_PLAYERS
        currentPlayer = playerCount - 1
        
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
        
        for i in 1...playerCount {
            players!.append(Player(id: i))
        }
    }
    
    func hit(var playerId: Int = -1) {
        
        if playerId == -1 {
            playerId = activePlayer!.playerId
        }
        
        let player = players![playerId - 1] as! Player
        
        if let card = deck.first {
            
            // This loop will only run if there are cards remaining (Swift optionals!)
            
            /*
            Parallelograms tesselate. For this one, every 70 pixels we move up, we have to move it 18 pixels right so that they line up properly. We when subtract 72 pixels horizontally from all of them, so that they roughly center around the scoreboard. Roughly.
            */
            
            let dx = 18 * (CGFloat(player.hand.count) + 1) - 72
            let dy = 70 * (CGFloat(player.hand.count) + 1)
            card.position = CGPoint(x: player.position.x + dx, y: player.position.y + dy)
            
            /*
            Add the card to the players hand, then remove the first card from the deck. The conditional at the top asserts that this card _is_ the first one in the deck, so we're safe.
            */
            
            player.hand.append(card)
            deck.removeAtIndex(0)
            
            // Update score labels
            let scores = player.score()
            player.baseLabel.text = "\(scores["Base"]!) points"
            
            if scores["Bonus"] > 0 && scores["Bonus"] <= 21 {
                player.bonusLabel.text = "(\(scores["Base"]! + scores["Bonus"]!) points with ace)"
            }
            
            nextPlayer()
        }
    }
    
    func nextPlayer() {
        if currentPlayer >= playerCount - 1 {
            currentPlayer = 0
        } else {
            currentPlayer += 1
        }
        
        activePlayer = players![currentPlayer]
    }
    
    func shouldAIHit() -> Bool? {
        
        if let move = strategist.bestMoveForPlayer(activePlayer!) as? Move {
            return move.hit
        } else {
            return true
        }
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = Game(decks: deckCount, players: playerCount)
        copy.setGameModel(self)
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
            if playerObject.score()["Base"] >= 21 {
                return nil
            }
            return [Move(hit: true), Move(hit: false)]
        }
        
        return nil
    }
    
    func applyGameModelUpdate(gameModelUpdate: GKGameModelUpdate) {
        if let move = gameModelUpdate as? Move {
            if move.hit {
                hit()
            }
            nextPlayer()
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
