//
//  AppDelegate.swift
//  blackjack
//
//  Created by Huw on 2015-10-08.
//  Copyright (c) 2015 Huw. All rights reserved.
//


import Cocoa
import SpriteKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var skView: SKView!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        /* Pick a size for the scene */
        if let scene = GameScene(fileNamed:"Game") {
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            self.skView!.presentScene(scene)
            
            self.skView!.showsFPS = true
            self.skView!.showsNodeCount = true
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}
