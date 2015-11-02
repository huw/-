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
    
    var humanPlayer: Int = 0
    var gameModel: Game = Game(decks: 1, players: 1)
    
    override func didMoveToView(view: SKView) {
        humanPlayer = Int(NUMBER_OF_PLAYERS / 2)
        gameModel = Game(decks: NUMBER_OF_DECKS, players: NUMBER_OF_PLAYERS)
        
        /*
        One night I was programming and I suddenly realised the importance of the MVC framework, and just how helpful OSX/Swift is at building it. While this app isn't entirely MVC, I'm trying to work with it.
        
        This class, GameScene, controls all of the visual display of the objects, and adds them to the scene and whatnot. The other class, Game, only loads the data (useful for AI strategy)
        
        We want to lay out the Player class, which controls the positioning of labels and cards, evenly across the bottom of the screen. This class will appropriately handle that.
        
        Then we add the cards in a similar way, but their position is changed later, when they're added to the player's hand.
        */
        
        let baseUnit = 1280 / NUMBER_OF_PLAYERS // = 256 for 5 players
        
        for i in 1...gameModel.players!.count {
            
            if let player = gameModel.players![i - 1] as? Player {
                
                player.position = CGPoint(x: baseUnit * i - (baseUnit / 2), y: 37)
                self.addChild(player)
            }
        }
        
        for card in gameModel.deck {
            self.addChild(card)
        }
        
        /*
        Deal two cards each
        (Traditionally, we shuffle in rounds. So the 1...2 loop comes first)
        */
        
        for _ in 1...2 {
            for i in 1...NUMBER_OF_PLAYERS {
                gameModel.hit(i)
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
        
        if humanPlayer == gameModel.currentPlayer + 1 {
            
            let h = keys["h"]!
            let s = keys["s"]!
            
            // h: Hit, s: Stay
            
            if h || s {
                if h {
                    gameModel.hit()
                } else {
                    gameModel.nextPlayer()
                }
                
                keys["h"] = false
                keys["s"] = false
            }
        } else {
            
            if gameModel.shouldAIHit()! {
                gameModel.hit()
            }
        }
    }
}