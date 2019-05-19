//
//  ViewController.swift
//  MancalaPrototype
//
//  Created by Alexander Scott Beaty on 3/14/19.
//  Copyright © 2019 Alexander Scott Beaty. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var gameboardImage: UIImageView!
    @IBOutlet var plr1pit1: UIButton!
    @IBOutlet var plr1pit2: UIButton!
    @IBOutlet var plr1pit3: UIButton!
    @IBOutlet var plr1pit4: UIButton!
    @IBOutlet var plr1pit5: UIButton!
    @IBOutlet var plr1pit6: UIButton!
    @IBOutlet var plr1BASE: UIButton!
    @IBOutlet var plr2pit1: UIButton!
    @IBOutlet var plr2pit2: UIButton!
    @IBOutlet var plr2pit3: UIButton!
    @IBOutlet var plr2pit4: UIButton!
    @IBOutlet var plr2pit5: UIButton!
    @IBOutlet var plr2pit6: UIButton!
    @IBOutlet var plr2BASE: UIButton!
    
    @IBOutlet var playerTurnTextView: UITextView!
    @IBOutlet var gameInfoTextView: UITextView!

    var pitButtons: [UIButton]!
    
    let player1 = MancalaPlayer(player: 1)
    let player2 = MancalaPlayer(player: 2)
    var activePlayer: MancalaPlayer!
    var sum1 = 0
    var sum2 = 0
    var playerTurn = 1
    let gameboard = CircularLinkedList<PitNode>()
    let buttonCircList = CircularLinkedList<UIButton>()
    var selectedIndex = 6
    var updateButtonImages = -1
    var playerTurnText = ""
    var gameText = ""
    var delayed = false
    var willOverlap = false
    var overlapDifference = 0
    var playerInitiated = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        pitButtons = [plr2BASE, plr1pit1, plr1pit2, plr1pit3, plr1pit4, plr1pit5, plr1pit6, plr1BASE,
                      plr2pit1, plr2pit2, plr2pit3, plr2pit4, plr2pit5, plr2pit6]
        buildButtonCircList(pitButtons)
        activePlayer = player1
        buildGameboard(gameboard)
        updatePitsFrom(findButtonIn(buttonCircList, at: selectedIndex), with: activePlayer.findPit(String(selectedIndex), gameboard), fullBoard: true)
        printBoard(gameboard)
        playerTurnText += "Player \(playerTurn) 's turn. Choose a pit # 1-6 \r"
        playerTurnText += "Chose a pit from your side that is not empty "
        print(playerTurnText)
        playerTurnTextView.text = playerTurnText
        //set bonus tturn text field nil
        playerTurnText = ""
    }
    
    // MARK: - play functions
    @IBAction func clickPit(_ sender: UIButton) {
        let player = sender.tag / 10
        let pit = sender.tag % 10
        selectedIndex = findSelected(button: sender, in: pitButtons)
        play(player, String(pit))
    }
    
    func play (_ player: Int,_ pit: String ){
        
        willOverlap = false
        overlapDifference = 0
        
        if player != activePlayer.player || pit == "BASE" {
            return
        }
        
        updateButtonImages = activePlayer.fillHoles(pit, gameboard)
        gameInfoTextView.text = nil
        gameInfoTextView.text = activePlayer.gameInfoText
        
        if -1 == updateButtonImages {
            //break if empty chosen pits
            return
            
        } else if updateButtonImages > 13 { //overlapping move
            overlapDifference = updateButtonImages - 13
            updateButtonImages = 12
            playerInitiated = activePlayer.player
            willOverlap = true
            if let preOverlapBoard = activePlayer.copiedBoard {
                updatePitsFrom(findButtonIn(buttonCircList, at: selectedIndex), with: activePlayer.findPit(pit, preOverlapBoard), fullBoard: false)
            }
            
        } else{
            if activePlayer.captured <= 0 {//normal move, no capture
                gameInfoTextView.text = nil
                gameInfoTextView.text = activePlayer.gameInfoText
                updatePitsFrom(findButtonIn(buttonCircList, at: selectedIndex), with: activePlayer.findPit(pit, gameboard), fullBoard: false)
                
                // animate capture
            } else if let preCapPit = activePlayer.preCapturePit, let preCapBoard = activePlayer.copiedBoard  {
                updateButtonImages -= 1
                updatePitsFrom(findButtonIn(buttonCircList, at: selectedIndex), with: activePlayer.findPit(pit, preCapBoard), fullBoard: false)
                
                animateCaptureFrom(preCapPit, with: activePlayer.findPit(preCapPit.name, gameboard))
            }
        }
        
        var bonus_count = 0
        var bonus = false
        bonus = activePlayer.bonusTurn
    
        repeat {
            playerTurn = (playerTurn == 1) ? 2 : 1//change turn
            activePlayer = (playerTurn == 1) ? player1 : player2//change players
            bonus_count += 1 //to switch back if bonus true
        } while (bonus_count < 2 && bonus)
    
        sum1 = player1.sumPlayerSide(gameboard)
        sum2 = player2.sumPlayerSide(gameboard)
    
        print("Player 1 remaining = \(sum1) \nPlayer 2 remaining = \(sum2) \n \n")
        print("After fill holes \n\n")
        printBoard(gameboard)
//        if let preCapBoard = activePlayer.copiedBoard {
//            print("\n preCapBoard \n")
//            printBoard(preCapBoard)
//        }
        if 0 == sum1 || 0 == sum2 {
            determineWinner(sum1, sum2)
        } else {
            playerTurnText = ""
            playerTurnText += "Player  \(playerTurn) 's turn. Choose a pit # 1-6 \r"
            playerTurnText += "Chose a pit from your side that is not empty \r"
            print(playerTurnText)
            playerTurnTextView.text = playerTurnText
        }
    
    }
    
    func determineWinner(_ sum1: Int, _ sum2: Int){
        var winner = -1
        
        print("game over \n")
        
        let iter_base_1 = player1.findPit("BASE", gameboard)
        let iter_base_2 = player2.findPit("BASE", gameboard)
        
        if let pit_base1 = *iter_base_1, let pit_base2 = *iter_base_2 {
            
            print("Player 1 beads in base = \(pit_base1.beads) \nPlayer 2 beads in base = \(pit_base2.beads) \n\n")
            
            if 0 == sum1{
                pit_base1.beads += sum2
            } else {
                pit_base2.beads += sum1}
            
            if pit_base1.beads == pit_base2.beads {
                //tie
                winner = 0
            } else if pit_base1.beads > pit_base2.beads {
                winner = 1
            } else {
                winner = 2 }
            
            print("Final totals are \n Player 1 = \(pit_base1.beads) \n Player 2 =  \(pit_base2.beads) \n\n")
            
            
            if 0 != winner {
                print("The winner is player \(winner)! Good work. :) \n")
            } else {
                print("Tie game! Way to go. :|\n")
            }
            
        } else {
            print("pit_base 1 or 2 was nil")
        }
    }
    
    func buildGameboard(_ gameboard: CircularLinkedList<PitNode> ) {
        
        for player in 1...2 {
            for pit in 1...7 {
                
                let pitN = PitNode()
                pitN.player = player
                
                if 7 == pit {
                    pitN.beads = 0
                    pitN.name = "BASE"
                } else {
                    pitN.beads = 4
                    pitN.name = String(pit)
                }
                //place pit in gameboard
                gameboard.enqueue(pitN)
            }
        }
    }
    
    func buildButtonCircList(_ buttons: [UIButton]){
        
        for button in buttons{
            buttonCircList.enqueue(button)
        }
    }
    
    func printBoard(_ gameboard: CircularLinkedList<PitNode>) {
        
        let myIter = gameboard.circIter
        
        ++myIter
        
        for _ in 1...14 {
            
            if let tempPit = *myIter {
                print("player:  \(tempPit.player)  pit name: \(tempPit.name) num beads: \(tempPit.beads)")
            } else {
                print("myIter could not get pit")
            }
            ++myIter
        }
        print("")
    }
    
    // MARK: - animation functions
    /*
     must pass in board iterator from a MancalaPlayer
     pre-advanced to correct pit
     */
    func updatePitsFrom(_ myButtonIter: LinkedListIterator<UIButton>, with myBoardIter: LinkedListIterator<PitNode>, fullBoard: Bool){
        
        var inHand = updateButtonImages
        
        if fullBoard {
            inHand = 13
        }
        
        var i = 0
        while i <= inHand {
            if let _pit = *myBoardIter, let button = *myButtonIter {
                

                //skip opponent's base
                if _pit.player != activePlayer.player && _pit.name == "BASE" && !fullBoard{
                    
                    ++myBoardIter
                    ++myButtonIter
                    continue
                }
                
                if let pitImage = getPitImageFor(_pit.beads) {
                    if !fullBoard {
                        animatePit(i, button, pitImage)
                    } else {
                        button.setImage(pitImage, for: .normal)
                    }
                } else {
                    button.setImage(nil, for: UIControl.State.normal)
                    button.setTitle(String(_pit.beads), for: UIControl.State.normal)
                }
                
                ++myBoardIter
                ++myButtonIter
                }
            i += 1
            }//end while
        
        
        if willOverlap {
            willOverlap = false
            updateButtonImages = overlapDifference
            
            if let overlapPit = *myBoardIter {
                let currentBoardIter = activePlayer.findPit(overlapPit.name, gameboard)
                let delayInSec = (11 + overlapDifference)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayInSec) * 0.2) { [weak self] in
                    guard let self = self else {
                        return
                    }
                    /*
                     We are recursively calling update pits because we overlapped, so play has moved to the next player, but our animation was delayed by DispatchQueue. Therefore, we have to temporarily switch players or the animation will skip the initiating player's base. If the overlapping move resulted in a bonus turn, then it is still the initiating player's turn and we don't want to switch
                     */
                    var switchBack = false
                    if self.activePlayer.player != self.playerInitiated {
                        self.switchActivePlayer()
                        switchBack = true
                    }
                    
                    self.updatePitsFrom(myButtonIter, with: currentBoardIter, fullBoard: false)
                    
                    //switch back players if needed
                    if switchBack {
                        self.switchActivePlayer()
                    }

                }
            }
        }
    }
    
    func animateCaptureFrom(_ pit: PitNode,  with myBoardIter: LinkedListIterator<PitNode>){
        
        guard var capturePit = Int(pit.name) else {
            return
        }
        
        let endingIndex = -1*(capturePit - 14)
        let startIndex = capturePit
        
        if pit.player == 2 {
            capturePit += 7
        }
        
        let myButtonIter = findButtonIn(buttonCircList, at: capturePit)
    
        if let button = *myButtonIter, let pitImage = getPitImageFor(pit.beads)  {
            animatePit(updateButtonImages+1, button, pitImage)
        }
        
        for _ in startIndex...endingIndex - 1 {
            ++myBoardIter
            ++myButtonIter
        }
        
        if updateButtonImages > 6 { //wrap-around capture
            let delayInSeconds = Double(updateButtonImages+1)  * 0.2
            delayed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) { [weak self] in
                guard let self = self else {
                    return
                }
                self.animateStealFromPit(with: myBoardIter, and: myButtonIter, delay: 1){_ in
                    self.animateBasePit(delay: 2)
                }
            }
        } else {
                //    normal capture
                animateStealFromPit(with: myBoardIter, and: myButtonIter, delay: updateButtonImages+2) {_ in
                animateBasePit(delay: updateButtonImages+3)
            }
        }
        
    }
    
    func animateStealFromPit(with myBoardIter: LinkedListIterator<PitNode>, and myButtonIter: LinkedListIterator<UIButton>, delay: Int, completion: (_ delay: Int) -> Void){
        if let stealFromPit = *myBoardIter, let button = *myButtonIter {
            if let pitImage = getPitImageFor(stealFromPit.beads) {
                animatePit(delay, button, pitImage)
            }
        }
        completion(delay)
    }
    
    func animateBasePit(delay: Int){
        
        if delayed == true {
            switchActivePlayer()
        }
        let baseIter = activePlayer.findPit("BASE", gameboard)
        let index = activePlayer.player == 1 ? 7 : 0
        let buttonIterBase = findButtonIn(buttonCircList, at: index)
        
        if let base_pit = *baseIter, let button = *buttonIterBase {
            if let pitImage = getPitImageFor(base_pit.beads) {
                animatePit(delay, button, pitImage)
            } else {
                button.setImage(nil, for: UIControl.State.normal)
                button.setTitle(String(base_pit.beads), for: UIControl.State.normal)
            }
        }
        if delayed == true {
            switchActivePlayer()
            delayed = false
        }
    }
    
    func switchActivePlayer(){

        activePlayer = activePlayer.player == 2 ? player1 : player2//change players
    }
    
    
    func findButtonIn(_ buttonCircList: CircularLinkedList<UIButton>, at index: Int) -> LinkedListIterator<UIButton>{
        
        let myIter = buttonCircList.circIter
        
        for _ in 0...index {//
             ++myIter
         }
        
        return myIter
    }
    
    func animatePit(_ index: Int, _ button: UIButton, _ pitImage: UIImage){
        let animationDuration = 0.2
        
        UIView.animate(withDuration: animationDuration,
                       delay: animationDuration * Double(index),
                       options: [],
                       animations: {
                            button.alpha = 0
                        }, completion: {_ in
                            button.setImage(pitImage, for: .normal)
                            button.alpha = 1
                        })
    }
    
    func findSelected(button: UIButton, in buttons: [UIButton]) -> Int {
        //print(button.tag)
        if let i = buttons.firstIndex(of: button) {
            return i
        }

        return -1
    }
    
    
    func getPitImageFor(_ beads: Int) -> UIImage? {
        
        switch beads {
        case 0:
            return UIImage(named: "mancala images/Mancala_hole_(0)")
        case 1:
            return UIImage(named: "mancala images/Mancala_hole_(1)")
        case 2:
            return UIImage(named: "mancala images/Mancala_hole_(2)")
        case 3:
            return UIImage(named: "mancala images/Mancala_hole_(3)")
        case 4:
            return UIImage(named: "mancala images/Mancala_hole_(4)")
        case 5:
            return UIImage(named: "mancala images/Mancala_hole_(5)")
        case 6:
            return UIImage(named: "mancala images/Mancala_hole_(6)")
        case 7:
            return UIImage(named: "mancala images/Mancala_hole_(7)")
        case 8:
            return UIImage(named: "mancala images/Mancala_hole_(8)")
        case 9:
            return UIImage(named: "mancala images/Mancala_hole_(9)")
        case 10:
            return UIImage(named: "mancala images/Mancala_hole_(10)")
        case 11:
            return UIImage(named: "mancala images/Mancala_hole_(11)")
        case 12:
            return UIImage(named: "mancala images/Mancala_hole_(12)")
        case 13:
            return UIImage(named: "mancala images/Mancala_hole_(13)")
        case 14:
            return UIImage(named: "mancala images/Mancala_hole_(14)")
        case 15:
            return UIImage(named: "mancala images/Mancala_hole_(15)")
        case 16:
            return UIImage(named: "mancala images/Mancala_hole_(16)")
        case 17:
            return UIImage(named: "mancala images/Mancala_hole_(17)")
        case 18:
            return UIImage(named: "mancala images/Mancala_hole_(18)")
        case 19:
            return UIImage(named: "mancala images/Mancala_hole_(19)")
        default:
            return nil

        }
        
    }

}//EoC

