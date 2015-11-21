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
    "s": false,
    "d": false,
    "=": false,
    "-": false,
    "t": false
]

let NUMBER_OF_DECKS = 1
let NUMBER_OF_PLAYERS = 5

class Scene: SKScene {
    
    var thisRound = Round()
    
    let humanPlayerIndex = Int(round(Float(NUMBER_OF_PLAYERS) / 2)) - 1
    var humanPlayer: Player {
        return thisRound.players[humanPlayerIndex]
    }
    
    var isFirstRoundOver = false
    let playerHighlightArrow = SKSpriteNode(imageNamed: "Triangle")
    
    /**
    This will evenly space out the players along the bottom of the screen, depending on how many there are. It will also add the dealer to the top right corner, and add the cards to the screen (although they're all off-screen until players hit). We also let the player know who they are with a little arrow.
    */
    
    func layOutGame() {
        let baseUnit = 1280 / NUMBER_OF_PLAYERS // = 256px for 5 players
        
        for player in thisRound.players {

            player.cash = 500
            player.position = CGPoint(x: baseUnit * (player.id - 1) + (baseUnit / 2), y: 37)
            
            self.addChild(player)
        }
        
        playerHighlightArrow.position = CGPoint(x: humanPlayer.position.x - 20, y: humanPlayer.position.y + 200)
        playerHighlightArrow.size = CGSize(width: 85, height: 40)
        self.addChild(playerHighlightArrow)
        
        thisRound.dealer.position = CGPoint(x: 100, y: 650)
        self.addChild(thisRound.dealer)
        
        deal()
    }
    
    /**
    This should only be called on a game that has already laid out. It takes the current list of players and dealer, and re-adds them to a new game. It then 'resets' each player and dealer, which resets their labels and removes their hands. Then we remove all of the cards from the display, and re-add the new ones from the deck.
    */
    
    func resetGame() {
        let dealer = thisRound.dealer
        let playerList = thisRound.players
        
        thisRound = Round(players: playerList, dealer: dealer)
        
        thisRound.dealer.reset()
        for player in thisRound.players {
            player.reset()
        }
        
        // Remove and re-add cards (because they're children of player nodes)
        for child in children {
            if let card = child as? Card {
                card.removeFromParent()
            }
        }
        
        deal()
    }
    
    /**
    Place bets, and add hit for each player and the dealer as necessary. We only hit once for the dealer, because we have no need for a hole card. However, we try to emulate what a real deal would look like here. By running the `for 1...2` loop on the outside, it emulates the way shuffling is done in rounds. By using `.reverse()`, we emulate the way dealing is usually done from the dealer's left to the dealer's right (which is our right to left).
    */
    
    func deal() {
        
        for player in thisRound.players {
            if player.cash >= 25 {
                player.cash -= 25
            }
        }
        
        for _ in 1...2 {
            for player in thisRound.players.reverse() {
                if !player.bankrupt {
                    hit(player)
                }
            }
        }
        
        hit(thisRound.dealer)
    }
    
    override func didMoveToView(view: SKView) {
        layOutGame()
    }
    
    /**
    This is where we add the cards to the view, and update the player's scores. The gameplay of the hitting procedure is stored in the Round class.
     
    Our cards are parallelograms, and parallelograms tesselate. For this one, every 70 pixels we move up, we have to move it 18 pixels right so that they line up properly. We when subtract 72 pixels horizontally from all of them, so that they roughly center around the scoreboard. Roughly. We also have a special case for the dealer, who resides at the top of the board. For them, we're laying out the cards horizontally, so it's a little easier to align them
    */
    
    func hit(player: Player) {
        if let card = thisRound.hit(player) {
            
            let dx: CGFloat
            let dy: CGFloat
            if player == thisRound.dealer {
                
                dx = 138 * CGFloat(player.hand.count) + 20
                dy = 0
            } else {
                
                dx = 18 * CGFloat(player.hand.count) - 72
                dy = 70 * CGFloat(player.hand.count)
            }
            
            card.position = CGPoint(x: player.position.x + dx, y: player.position.y + dy)
            self.addChild(card)
        }
        
        if !player.bust {
            player.baseLabel.text = "\(player.scoreBase()) points"
        } else {
            player.baseLabel.text = "0 points"
        }
        
        if player.scoreBonus() > 0 && player.scoreBase() + 10 <= 21 {
            player.bonusLabel.text = "(\(player.score()) points with ace)"
        } else {
            player.bonusLabel.text = ""
        }
    }
    
    func gameOver() -> Bool {
        
        /*
        If all of the players are bankrupt, then kill the game (i.e. return false so no more of this loop can run)
        */
        
        var numBankrupt = 0
        
        for player in thisRound.players {
            if player.bankrupt {
                numBankrupt += 1
            }
        }
        
        if numBankrupt == NUMBER_OF_PLAYERS {
            return false
        }
            
        let dealer = thisRound.dealer
        
        /*
        Now that the game's over, we find out what the dealer's final score is.
        Basically, the dealer keeps hitting so long as they haven't gone bust, and their score is under 17. If they get a soft 17, then their action is determined by the flag that the user has set.
        */
        
        while !dealer.bust && (dealer.score() < 17 || (dealer.score() == 17 && dealer.scoreBase() > 0 && thisRound.dealerHitsOnSoft17)) {
            
            hit(thisRound.dealer)
        }
        
        let dealerScore = dealer.score()
        
        if dealer.bust {
            
            for player in thisRound.players {
                if player.standing && !player.bust && !player.bankrupt {
                    
                    player.cash += 50
                    
                    if player.blackjack {
                        
                        player.cash += 25
                        displayMessage(player, "+$75")
                    } else {
                        displayMessage(player, "+$50")
                    }
                }
            }
        } else {
            
            for player in thisRound.players {
            
                let playerScore = player.score()
                
                /*
                Here's how we figure out who's won:
                
                playerBonus will be equal to the player's base score if adding their bonus goes over 21 (calculated in Player.score()). So we don't need to test if playerBonus is going to be legit, because that's already happened.
                
                We also need to test for blackjacks, which beat anything that's not a blackjack. We start by storing a boolean value of whether the player or dealer has a blackjack in a constant. A blackjack can only occur if the player/dealer got 21 points with 2 cards.
                
                Once this is done, the player will always win (even in the case of a 21 tie) if they got a blackjack and the dealer didn't, _or_ the usual condition.
                If both of them blackjacked, it's a tie. However, in the other case, it's only a tie if the dealer _hasn't_ blackjacked as well.
                Otherwise, the dealer wins the rest of the cases.
                */
                
                if (player.blackjack && !dealer.blackjack) || playerScore > dealerScore {

                    player.cash += 50
                    
                    if player.blackjack {
                        
                        player.cash += 25
                        displayMessage(player, "+$75")
                    } else {
                        displayMessage(player, "+$50")
                    }
                    
                } else if (player.blackjack && dealer.blackjack) || (!dealer.blackjack && playerScore == dealerScore) {

                    player.cash += 25
                    displayMessage(player, "+$25")
                }
            }
        }

        resetGame()
        
        return true
    }

    /**
    This function will display a message on the screen that floats up the screen and disappears over a second. The message will simultaneously move upward and fade, before detaching itself from its parent.
    
    -accepts
    node: An SKNode to attach the message to (the message will take its position as its inital position)
    message: Any string
    */
    
    func displayMessage(node: SKNode, _ message: String) {
        
        let label = SKLabelNode(fontNamed: "San Francisco Display Bold")
        label.text = message
        
        let moveUpAndFade = SKAction.group([SKAction.moveByX(0, y: 50, duration: 0.7), SKAction.fadeOutWithDuration(0.7)])
        let selfDestruct = SKAction.removeFromParent()
        
        node.addChild(label)
        label.runAction(SKAction.sequence([moveUpAndFade, selfDestruct]))
    }
    
    override func keyDown(e: NSEvent) {
        if let key = e.charactersIgnoringModifiers {
            if keys[key] != nil {
                keys[key] = true
            }
        }
    }
    
    /**
    The update loop determines the player actions. If the current player is still in the game, then we determine what move they should make (either based on AI or human input). If they're not, we move on and test to see if the game is over.
     
    The player is also able to customise the AI of the other players and dealer. When they press certain keys, we also change values and update labels accordingly.
    */
    
    override func update(currentTime: NSTimeInterval) {
        
        if keys["t"]! {
            thisRound.dealerHitsOnSoft17 = !thisRound.dealerHitsOnSoft17
            
            if thisRound.dealerHitsOnSoft17 {
                (childNodeWithName("Dealer Hit") as! SKLabelNode).text = "DEALER HITS ON SOFT 17"
            } else {
                (childNodeWithName("Dealer Hit") as! SKLabelNode).text = "DEALER STANDS ON SOFT 17"
            }
            
            keys["t"] = false
        }
        
        if keys["-"]! || keys["="]! {
            
            if keys["-"]! && thisRound.aceRiskFactor > 0 {
                thisRound.aceRiskFactor -= 10
            } else if keys["="]! && thisRound.aceRiskFactor < 100 {
                thisRound.aceRiskFactor += 10
            }
            
            (childNodeWithName("Ace Risk") as! SKLabelNode).text = "Ace Risk: \(thisRound.aceRiskFactor)%"
            
            keys["-"] = false
            keys["="] = false
        }
        
        while !humanPlayer.stillPlaying || (keys["s"]! || keys["h"]! || keys["d"]! || humanPlayer.score() == 21) {
            let player = thisRound.activePlayer
            
            if player.stillPlaying {
                
                let hitting: Bool
                let standing: Bool
                let doubling: Bool
                    
                if player == humanPlayer {
                    
                    // Automatic win, so stand
                    if player.score() == 21 {
                        
                        hitting = false
                        standing = true
                        doubling = false
                    } else {
                        
                        hitting = keys["h"]!
                        standing = keys["s"]!
                        doubling = keys["d"]!
                    }
                    
                    keys["h"] = false
                    keys["s"] = false
                    keys["d"] = false
                } else {
                    
                    (hitting, standing, doubling) = thisRound.AIActionChoice(player)
                }
                
                if standing {
                    
                    player.standing = true
                    thisRound.nextPlayer()
                } else if hitting {
                    
                    hit(player)
                } else if doubling {
                    
                    player.standing = true
                    hit(player)
                }
                
            } else {
                
                thisRound.nextPlayer()
                
                if thisRound.isGameOver() {
                    gameOver()
                    
                    if !isFirstRoundOver {
                        
                        let fadeOut = SKAction.sequence([SKAction.fadeOutWithDuration(0.7), SKAction.removeFromParent()])
                        
                        childNodeWithName("Action Label")!.runAction(fadeOut)
                        childNodeWithName("Ace Risk Label")!.runAction(fadeOut)
                        childNodeWithName("Dealer Hit Label")!.runAction(fadeOut)
                        playerHighlightArrow.runAction(fadeOut)
                        
                        isFirstRoundOver = true
                    }
                    
                    break
                }
            }
        }
    }
}