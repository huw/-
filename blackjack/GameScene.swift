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
        
        // humanPlayer is the _index_ where the human can be found in gameModel.players
        humanPlayer = Int(round(Float(NUMBER_OF_PLAYERS) / 2))
        
        gameModel = Game(decks: NUMBER_OF_DECKS, players: NUMBER_OF_PLAYERS)
        
        /*
        One night I was programming and I suddenly realised the importance of the MVC framework, and just how helpful OSX/Swift is at building it. While this app isn't entirely MVC, I'm trying to work with it.
        
        This class, GameScene, controls all of the visual display of the objects, and adds them to the scene and whatnot. The other class, Game, only loads the data (useful for AI strategy)
        
        We want to lay out the Player class, which controls the positioning of labels and cards, evenly across the bottom of the screen. This class will appropriately handle that.
        
        Then we add the cards in a similar way, but their position is changed later, when they're added to the player's hand.
        */
        
        let baseUnit = 1280 / NUMBER_OF_PLAYERS // = 256 for 5 players
        
        for i in 1...NUMBER_OF_PLAYERS {
            
            if let player = gameModel.players![i] as? Player {
                
                player.position = CGPoint(x: baseUnit * (i-1) + (baseUnit / 2), y: 37)
                self.addChild(player)
            }
        }
        
        gameModel.dealer.position = CGPoint(x: 100, y: 650)
        self.addChild(gameModel.dealer)
        
        for card in gameModel.deck {
            self.addChild(card)
        }
        
        /*
        Deal two cards each
        (Traditionally, we shuffle in rounds. So the 1...2 loop comes first)
        
        We'd normally subtract 1 from NUMBER_OF_PLAYERS, but we're also dealing with the dealer here. So think of it as `NUMBER_OF_PLAYERS - 1 + 1`
        */
        
        for _ in 1...2 {
            for i in 0...NUMBER_OF_PLAYERS {
                hit(i)
            }
        }
    }
    
    func hit(playerId: Int) {
        
        let player = gameModel.players![playerId] as! Player
        
        // This clause is where we cause the game model to hit the player
        if let card = gameModel.hit(playerId) {
            
            /*
            Parallelograms tesselate. For this one, every 70 pixels we move up, we have to move it 18 pixels right so that they line up properly. We when subtract 72 pixels horizontally from all of them, so that they roughly center around the scoreboard. Roughly.
            
            We also have a special case for the dealer, who resides at the top of the board. For them, we're laying out the cards horizontally, so it's a little easier to align them
            */
            
            let dx: CGFloat
            let dy: CGFloat
            if playerId == 0 {
                dx = 138 * CGFloat(player.hand.count) + 20
                dy = 0
            } else {
                dx = 18 * CGFloat(player.hand.count) - 72
                dy = 70 * CGFloat(player.hand.count)
            }
            
            card.position = CGPoint(x: player.position.x + dx, y: player.position.y + dy)
        }
        
        // Update score labels
        let scores = player.score()
        player.baseLabel.text = "\(scores["Base"]!) points"
        
        if scores["Bonus"] > 0 && scores["Bonus"] <= 21 {
            player.bonusLabel.text = "(\(scores["Base"]! + scores["Bonus"]!) points with ace)"
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
        
        if humanPlayer == gameModel.currentPlayer {
            
            let h = keys["h"]!
            let s = keys["s"]!
            
            // h: Hit, s: Stay
            
            if h || s {
                
                if h && (gameModel.activePlayer as! Player).score()["Base"] < 21 {
                    hit(humanPlayer)
                } else {
                    gameModel.nextPlayer()
                }
                
                keys["h"] = false
                keys["s"] = false
            }
        } else if gameModel.shouldAIHit()! {
            
            hit(gameModel.currentPlayer)
        } else {

            gameModel.nextPlayer()
        }
    }
}