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
    
    func node(at gridCoordinate: GameModel.GridCoordinate, named nodeName: String) -> SKNode? {
       
        let halfSide = sideLength / 2
        let halfHeight = sideLength / 4
        let pitDistance = sideLength / halfNumberOfPits
        
        let adjustedXCoord = (CGFloat(gridCoordinate.x.rawValue) * pitDistance)
        let adjustedYCoord = (CGFloat(gridCoordinate.y.rawValue) * halfHeight)
        
        let relativeGridPoint = CGPoint(x: adjustedXCoord - halfSide, y: adjustedYCoord - halfHeight)
        
        let node = atPoint(relativeGridPoint)
        return node.name == nodeName ? node : nil
    }
    
    private func createBoardPoints(on node: SKSpriteNode) {
        let lineWidth: CGFloat = 3
        let halfBoardWidth = node.size.width / 2
        let halfBoardHeigth = node.size.height / 2
        let boardPointSize = CGSize(width: 24, height: 24)
        let pitDistance = node.size.width / halfNumberOfPits
        
        let relativeBoardPositions = [
            CGPoint(x: -halfBoardWidth, y: 0),
            CGPoint(x: -halfBoardWidth + pitDistance * 1, y: -halfBoardHeigth),
            CGPoint(x: -halfBoardWidth + pitDistance * 2, y: -halfBoardHeigth),
            CGPoint(x: -halfBoardWidth + pitDistance * 3, y: -halfBoardHeigth),
            CGPoint(x: halfBoardWidth - pitDistance * 3, y: -halfBoardHeigth),
            CGPoint(x: halfBoardWidth - pitDistance * 2, y: -halfBoardHeigth),
            CGPoint(x: halfBoardWidth - pitDistance * 1, y: -halfBoardHeigth),
            CGPoint(x: halfBoardWidth, y: 0),
            CGPoint(x: halfBoardWidth - pitDistance * 1, y: halfBoardHeigth),
            CGPoint(x: halfBoardWidth - pitDistance * 2, y: halfBoardHeigth),
            CGPoint(x: halfBoardWidth - pitDistance * 3, y: halfBoardHeigth),
            CGPoint(x: -halfBoardWidth + pitDistance * 3, y: halfBoardHeigth),
            CGPoint(x: -halfBoardWidth + pitDistance * 2, y: halfBoardHeigth),
            CGPoint(x: -halfBoardWidth + pitDistance * 1, y: halfBoardHeigth),
        ]
        
        for (index, position) in relativeBoardPositions.enumerated() {
            let boardPointNode = SKShapeNode(ellipseOf: boardPointSize)
            
            boardPointNode.zPosition = NodeLayer.point.rawValue
            boardPointNode.name = BoardNode.boardPointNodeName
            boardPointNode.lineWidth = lineWidth
            boardPointNode.position = position
            boardPointNode.fillColor = .background
            boardPointNode.strokeColor = .white
            
            node.addChild(boardPointNode)
            
            
            let lineIndex = index < relativeBoardPositions.count - 1 ? index + 1 : 0
            let nextPosition = relativeBoardPositions[lineIndex]
            
            let path = CGMutablePath()
            path.move(to: position)
            path.addLine(to: nextPosition)
            
            let lineNode = SKShapeNode(path: path, centered: true)
            lineNode.position = CGPoint(
                x: (position.x + nextPosition.x) / 2,
                y: (position.y + nextPosition.y) / 2
            )
            
            lineNode.strokeColor = boardPointNode.strokeColor
            lineNode.zPosition = NodeLayer.line.rawValue
            lineNode.lineWidth = lineWidth
            
            node.addChild(lineNode)
        }
    }
}
