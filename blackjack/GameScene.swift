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
        humanPlayer = Int(round(Float(NUMBER_OF_PLAYERS) / 2)) - 1
        
        gameModel = Game(decks: NUMBER_OF_DECKS, players: NUMBER_OF_PLAYERS)
        
        /*
        One night I was programming and I suddenly realised the importance of the MVC framework, and just how helpful OSX/Swift is at building it. While this app isn't entirely MVC, I'm trying to work with it.
        
        This class, GameScene, controls all of the visual display of the objects, and adds them to the scene and whatnot. The other class, Game, only loads the data (useful for AI strategy)
        
        We want to lay out the Player class, which controls the positioning of labels and cards, evenly across the bottom of the screen. This class will appropriately handle that.
        
        Then we add the cards in a similar way, but their position is changed later, when they're added to the player's hand.
        */
        
        let baseUnit = 1280 / NUMBER_OF_PLAYERS // = 256 for 5 players
        
        for i in 0...NUMBER_OF_PLAYERS - 1 {
            
            let player = gameModel.players[i]
            
            player.position = CGPoint(x: baseUnit * (i) + (baseUnit / 2), y: 37)
            self.addChild(player)
        }
        
        gameModel.dealer.position = CGPoint(x: 100, y: 650)
        self.addChild(gameModel.dealer)
        
        for card in gameModel.deck {
            self.addChild(card)
        }
        
        // Steal $25 from each player
        for player in gameModel.players {
            player.cash -= 25
        }
        
        /*
        Deal two cards each
        (Traditionally, we shuffle in rounds. So the 1...2 loop comes first)
        
        ALSO, the dealer deals from left to right (our right to left), so we can emulate that in the code by reversing the loop.
        */
        
        for _ in 1...2 {
            for i in (0...NUMBER_OF_PLAYERS - 1).reverse() {
                hit(i)
            }
        }
        
        // Deal to the dealer. We don't bother with hole cards.
        hit(-1)
    }
    
    func hit(playerId: Int) {
        
        let player: Player
        if playerId == -1 {
            player = gameModel.dealer
        } else {
            player = gameModel.players[playerId]
        }
        
        // This clause is where we cause the game model to hit the player
        if let card = gameModel.hit(player) {
            
            /*
            Parallelograms tesselate. For this one, every 70 pixels we move up, we have to move it 18 pixels right so that they line up properly. We when subtract 72 pixels horizontally from all of them, so that they roughly center around the scoreboard. Roughly.
            
            We also have a special case for the dealer, who resides at the top of the board. For them, we're laying out the cards horizontally, so it's a little easier to align them
            */
            
            let dx: CGFloat
            let dy: CGFloat
            if playerId == -1 {
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
        
        if scores["Bonus"] > 0 {
            player.bonusLabel.text = "(\(scores["Base"]! + scores["Bonus"]!) points with ace)"
        } else {
            player.bonusLabel.text = ""
        }
    }
    
    func gameOver() {
        
        let dealer = gameModel.dealer
        let dealerScore = dealer.score()
        let dealerBonus = dealerScore["Base"]! + dealerScore["Bonus"]!
        
        /*
        Now that the game's over, we find out what the dealer's final score is.
        Basically, the dealer keeps hitting so long as they haven't gone bust, and their score is under 17. If they get a soft 17, we don't consider it—we're just using their base score for now.
        */
        while !dealer.bust && dealerScore["Base"]! < 17 {
            
            hit(-1)
        }
        
        for player in gameModel.players {
            
            /*
            If the dealer has gone bust, then the player wins if they're still standing and haven't gone bust themselves.
            */
            
            if dealer.bust {
                
                if player.standing && !player.bust {
                    
                    // A blackjack will pay 3:2
                    // So a $25 bet will return $75
                    if player.blackjack() {
                        player.cash += 25
                    }
                    player.cash += 50
                }
            } else {

                let playerBonus = player.score()["Base"]! + player.score()["Bonus"]!
                
                /*
                Here's how we figure out who's won:
                
                playerBonus will be equal to the player's base score if adding their bonus goes over 21 (calculated in Player.score()). So we don't need to test if playerBonus is going to be legit, because that's already happened.
                
                We also need to test for blackjacks, which beat anything that's not a blackjack. We start by storing a boolean value of whether the player or dealer has a blackjack in a constant. A blackjack can only occur if the player/dealer got 21 points with 2 cards.
                
                Once this is done, the player will always win (even in the case of a 21 tie) if they got a blackjack and the dealer didn't, _or_ the usual condition.
                If both of them blackjacked, it's a tie. However, in the other case, it's only a tie if the dealer _hasn't_ blackjacked as well.
                Otherwise, the dealer wins the rest of the cases.
                */
                
                if (player.blackjack() && !dealer.blackjack()) || playerBonus > dealerBonus {
                    // The player has won
                    if player.blackjack() {
                        player.cash += 25
                    }
                    player.cash += 50
                    
                } else if (player.blackjack() && dealer.blackjack()) || (!dealer.blackjack() && playerBonus == dealerBonus) {
                    // We have tied. Return bet.
                    player.cash += 25
                    
                } else {
                    // The dealer has won
                    
                }
            }
            
            player.reset()
        }
        
        // Reset everything.
        dealer.reset()
        
        for child in children {
            if let card = child as? Card {
                card.removeFromParent()
            }
        }
        
        let playerList = gameModel.players
        
        gameModel = Game(decks: NUMBER_OF_DECKS, players: NUMBER_OF_PLAYERS)
        
        gameModel.players = playerList
        gameModel.dealer = dealer
        
        for card in gameModel.deck {
            self.addChild(card)
        }
        
        // Steal $25 from each player
        for player in gameModel.players {
            player.cash -= 25
        }
        
        // Redeal
        for _ in 1...2 {
            for i in (0...NUMBER_OF_PLAYERS - 1).reverse() {
                hit(i)
            }
        }
        
        hit(-1)
    }
    
    override func keyDown(e: NSEvent) {
        if let key = e.charactersIgnoringModifiers {
            if keys[key] != nil {
                keys[key] = true
            }
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        /*
        Here we determine what happens on this update (usually once per frame or something).
        
        First we make sure that the player's allowed to move—they must not be standing _or_ bust.
        
        When the human player is the current player, we test for keypresses. Then we make the right action, depending on whether they wanted to hit or stand.
        
        If it's not the human player, we run `shouldAIHit()` to determine if the current player should make the hit, and act appropriately.
        */
        
        let player = gameModel.activePlayer
        
        if !player.standing && !player.bust {
            if humanPlayer == gameModel.currentPlayer {
                
                let h = keys["h"]!
                let s = keys["s"]!
                
                // h: Hit, s: Stand
                
                if h || s {
                    
                    if h {
                        
                        hit(humanPlayer)
                    } else {
                        
                        player.standing = true
                        gameModel.nextPlayer()
                    }
                    
                    keys["h"] = false
                    keys["s"] = false
                }
            } else if gameModel.shouldAIHit()! {
                
                hit(gameModel.currentPlayer)
            } else {

                player.standing = true
                gameModel.nextPlayer()
            }
        } else {
            gameModel.nextPlayer()
        }
        
        if gameModel.currentPlayer == 0 {
            
            if gameModel.isGameOver() {
                
                gameOver()
            }
        }
    }
}