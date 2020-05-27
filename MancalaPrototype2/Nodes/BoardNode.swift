///
///  BoardNode.swift
///  MancalaPrototype2
///
///  Created by Alexander Scott Beaty on 7/30/19.
/// ============LICENSE_START=======================================================
/// Copyright (c) 2018 Razeware LLC
/// Modification Copyright © 2019 Alexander Scott Beaty. All rights reserved.
/// Modification License:
/// SPDX-License-Identifier: Apache-2.0
/// =================================================================================
/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SpriteKit

/**
 Creates the Mancala GameBoard SKSpriteNode representation in the GameScene.
 
 Based on code from the tutorial found at https:www.raywenderlich.com/7544-game-center-for-ios-building-a-turn-based-game#
 By Ryan Ackerman
 */
final class BoardNode: SKNode {
    static let boardPointNodeName = "boardPoint"
    
    private enum NodeLayer: CGFloat {
        case background = 10
        case line = 20
        case point = 30
    }
    
    private let sideLength: CGFloat
    private let halfNumberOfPits: CGFloat
    var player1LineNode: SKNode? = nil
    var player2LineNode: SKNode? = nil

    /// Creates the ```containerNode``` for the board, creates the board point nodes on the ```containerNode``` and adds it to the scene.
    ///
    /// - Important: initializing the BoardNode does not load TokenNodes onto itself. You must do that separately using BoardNode.node(at:named:) and other helper functions in the GameScene
    /// - Parameters:
    ///   - sideLength: the width on the screen fitted on the parent SKScene
    ///   - halfNumPits: exactly 1/2 the length of the game board, as a ```CircularLinkedList``` or ```model.pits```. (should be 14 / 2 = 7)
    init(sideLength: CGFloat, halfNumPits: Int) {
        self.sideLength = sideLength
        halfNumberOfPits = CGFloat(halfNumPits)
        
        super.init()
        
        let size = CGSize(width: sideLength, height: sideLength/2)
        
        let containerNode = SKSpriteNode(
            color: .clear,
            size: CGSize(
                width: size.width,
                height: size.height
            )
        )
        
        containerNode.zPosition = NodeLayer.background.rawValue
        createBoardPoints(on: containerNode)
        
        name = "BoardNodeName"
        addChild(containerNode)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Translates a GameModel.GridCoordinate into a point relative to the BoardNode and returns the node at that a point. Original purpose of this method is to load TokenNodes onto the BoardNode during setup of the GameScene.
    ///
    /// - Important: This method has not been tested outside of its primary purpose for loading TokenNodes onto the BoardNode
    ///
    /// - Returns: An SKNode if the ```gridCoordinate``` resolves to the node with a name matching ```nodeName```
    /// - Parameters:
    ///   - gridCoordinate: should be a ```PitNode.coordP1``` or ```coordP1```
    ///   - nodeName: if this method is used to load TokenNodes onto the BoardNode, then use BoardNode.boardPointNodeName
    func node(at gridCoordinate: GameModel.GridCoordinate, named nodeName: String) -> SKNode? {
       
        // The max length on the relative X axis for either - or + direction
        let halfSide = sideLength / 2
        // The max height on the relative Y axis for either - or + direction
        let halfHeight = sideLength / 4
        // The distance between pits on the board's X axis
        let pitDistance = sideLength / halfNumberOfPits
        
        let adjustedXCoord = (CGFloat(gridCoordinate.x.rawValue) * pitDistance)
        let adjustedYCoord = (CGFloat(gridCoordinate.y.rawValue) * halfHeight)
        
        let relativeGridPoint = CGPoint(x: adjustedXCoord - halfSide, y: adjustedYCoord - halfHeight)
        
        let node = atPoint(relativeGridPoint)
        return node.name == nodeName ? node : nil
    }
    
    /// Creates a "skeleton" of boardPointNodes on the BoardNode frame. These nodes will allow TokenNodes to be fit onto them in the future.
    /// - Parameter node: should be the ```containerNode``` of this BoardNode
    private func createBoardPoints(on node: SKSpriteNode) {
        let lineWidth: CGFloat = 3
        // Because the relative Cartesian coordinates of the BoardNode begin in the center, we need to take half the width and height to get the min and max for the X an Y axis respectively
        // The max length on the relative X axis for either - or + direction
        let halfBoardWidth = node.size.width / 2
        // The max height on the relative Y axis for either - or + direction
        let halfBoardHeigth = node.size.height / 2
        let boardPointSize = CGSize(width: 24, height: 24)
        // The distance between pits on the board's X axis
        let pitDistance = node.size.width / halfNumberOfPits
        
        // These pits are listed in counter-clockwise order, starting at Player 2's base (from Player 1's perspective),
        // although Player 1 and 2 are hypothetical at this point
        let relativeBoardPositions = [
            // The base on the left
            CGPoint(x: -halfBoardWidth, y: 0),
            // The first pit on the bottom half of the board
            CGPoint(x: -halfBoardWidth + pitDistance * 1, y: -halfBoardHeigth),
            // The second pit on the bottom half of the board
            CGPoint(x: -halfBoardWidth + pitDistance * 2, y: -halfBoardHeigth),
            CGPoint(x: -halfBoardWidth + pitDistance * 3, y: -halfBoardHeigth),
            CGPoint(x: halfBoardWidth - pitDistance * 3, y: -halfBoardHeigth),
            CGPoint(x: halfBoardWidth - pitDistance * 2, y: -halfBoardHeigth),
            CGPoint(x: halfBoardWidth - pitDistance * 1, y: -halfBoardHeigth),
            // The base on the right
            CGPoint(x: halfBoardWidth, y: 0),
            // The first pit on the top half of the board.
            // It is directly above "Pit 6" on the Y axis, on the right-half of the board.
            CGPoint(x: halfBoardWidth - pitDistance * 1, y: halfBoardHeigth),
            CGPoint(x: halfBoardWidth - pitDistance * 2, y: halfBoardHeigth),
            CGPoint(x: halfBoardWidth - pitDistance * 3, y: halfBoardHeigth),
            CGPoint(x: -halfBoardWidth + pitDistance * 3, y: halfBoardHeigth),
            CGPoint(x: -halfBoardWidth + pitDistance * 2, y: halfBoardHeigth),
            CGPoint(x: -halfBoardWidth + pitDistance * 1, y: halfBoardHeigth),
        ]
        
        for (index, position) in relativeBoardPositions.enumerated() {
            let boardPointNode = SKShapeNode(ellipseOf: boardPointSize)
            // Draw a circular node and place it at the next point in the list of relativeBoardPositions
            boardPointNode.zPosition = NodeLayer.point.rawValue
            boardPointNode.name = BoardNode.boardPointNodeName
            boardPointNode.lineWidth = lineWidth
            boardPointNode.position = position
            boardPointNode.fillColor = .background
            boardPointNode.strokeColor = .white
            
            node.addChild(boardPointNode)
            
            // Get the next position in the relativeBoardPositions list
            let lineIndex = index < relativeBoardPositions.count - 1 ? index + 1 : 0
            let nextPosition = relativeBoardPositions[lineIndex]
            
            // Draw a line between this boardPointNode we just added to the next position
            let path = CGMutablePath()
            path.move(to: position)
            path.addLine(to: nextPosition)
            // Create the lineNode and center it, then add it to the BoardNode
            let lineNode = SKShapeNode(path: path, centered: true)
            lineNode.position = CGPoint(
                x: (position.x + nextPosition.x) / 2,
                y: (position.y + nextPosition.y) / 2
            )
            // Store the lineNodes that are on opposite sides of the board, so they can be referenced later to place "player labels" on the GameScene
            if index == Int(halfNumberOfPits) - 4 {
                player1LineNode = lineNode
            } else if index == Int(halfNumberOfPits) * 2 - 4 {
                player2LineNode = lineNode
            }
            
            lineNode.strokeColor = boardPointNode.strokeColor
            lineNode.zPosition = NodeLayer.line.rawValue
            lineNode.lineWidth = lineWidth
            
            node.addChild(lineNode)
        }
    }
}
