//
//  SquareMaze.playground
//
//
//  Created by Lucas Louca on 04/04/15 - www.lucaslouca.com
//
//  Copyright (c) 2015 Lucas Louca. All rights reserved.

import XCPlayground
import SpriteKit

// Class representing a grid, where elements can be accessed using [x,y] subscript syntax
class Grid<T> {
    var matrix:[T]
    var rows:Int
    var columns:Int
    
    init(rows:Int, columns:Int, defaultValue:T) {
        self.rows = rows
        self.columns = columns
        matrix = Array(repeating:defaultValue,count:(rows*columns))
    }
    
    func indexIsValidForRow(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }
    
    subscript(col:Int, row:Int) -> T {
        get{
            assert(indexIsValidForRow(row: row, column: col), "Index out of range")
            return matrix[Int(columns * row + col)]
        }
        set{
            assert(indexIsValidForRow(row: row, column: col), "Index out of range")
            matrix[(columns * row) + col] = newValue
        }
    }
}

// Class representing a Maze
class Maze {
    // Walls. [x,y] is true if there is a wall up/right/down/left of [x,y]
    var up      :Grid<Bool>
    var right   :Grid<Bool>
    var down    :Grid<Bool>
    var left    :Grid<Bool>
    
    // Visited cells
    var visitedCells :Grid<Bool>
    
    // View on which we will draw our maze
    var view:UIView!
    
    /**
    Init method.
    
    :param: gridSize Int indicating the width and hight of the maze in number of cells, with width = height = gridSize
    :param: screenSize Int indicating the width and hight of the view, with width = height = screenSize
    */
    init(gridSize: Int, screenSize: Int) {
        
        visitedCells = Grid<Bool>(rows: (gridSize+2), columns: (gridSize+2), defaultValue: false)
        up = Grid<Bool>(rows: (gridSize+2), columns: (gridSize+2), defaultValue: true)
        right = Grid<Bool>(rows: (gridSize+2), columns: (gridSize+2), defaultValue: true)
        down = Grid<Bool>(rows: (gridSize+2), columns: (gridSize+2), defaultValue: true)
        left = Grid<Bool>(rows: (gridSize+2), columns: (gridSize+2), defaultValue: true)
        
        // Initialize perimeter as already visited
        for x in 0..<gridSize+2 {
            visitedCells[x,0] = true
            visitedCells[x,gridSize+1] = true
        }
        
        for y in 0..<gridSize+2 {
            visitedCells[0,y] = true
            visitedCells[gridSize+1,y] = true
        }
        
        dropWalls(x: 1, y:1, gridSize:gridSize);
        
        view = drawView(gridSize:gridSize, screenSize:screenSize)
    }
    
    /**
    Visit every cell in the maze grid by picking a random unvisited cell each time. "Drop" the
    wall between the source and the destination node by marking the appropriate position in the
    corresponding wall grids as false.
    
    :param: x Int x position in the grid of the destination node
    :param: y Int y position in the grid of the destination node
    :param: gridSize Int indicating the width and hight of the maze in number of cells, with width = height = gridSize
    */
    func dropWalls(x:Int, y:Int, gridSize: Int) {
        visitedCells[x,y] = true;
        
        // Loop while we have unvisited cells
        while (!visitedCells[x,y + 1] || !visitedCells[x + 1,y] || !visitedCells[x,y - 1] || !visitedCells[x - 1,y]) {
            
            // Choose a random destination cell
            while (true) {
                let r =  UInt32(arc4random()) % 4
                if (r == 0 && !visitedCells[x,y + 1]) {
                    up[x,y] = false
                    down[x,y + 1] = false
                    dropWalls(x: x, y: y + 1, gridSize:gridSize)
                    break
                } else if (r == 1 && !visitedCells[x + 1,y]) {
                    right[x,y] = false
                    left[x + 1, y] = false
                    dropWalls(x: x + 1, y: y, gridSize:gridSize)
                    break
                } else if (r == 2 && !visitedCells[x,y - 1]) {
                    down[x,y] = false
                    up[x,y - 1] = false
                    dropWalls(x: x, y: y - 1, gridSize:gridSize)
                    break
                } else if (r == 3 && !visitedCells[x - 1,y]) {
                    left[x,y] = false
                    right[x - 1,y] = false
                    dropWalls(x: x - 1, y: y, gridSize:gridSize)
                    break
                }
            }
        }
        
        // Open up the start and end
        up[1,1] = false
        down[1,1] = false
        up[gridSize,gridSize] = false
        down[gridSize,gridSize] = false
    }
    
    /**
    Draws a line that connects the two end-points from and to.
    
    :param: from CGPoint first end-point of the line
    :param: to CGPoint y second end-point of the line
    :param: resizeFactor CGFloat scalar with which from and to should be multiplied with
    */
    func drawLine(from:CGPoint, to:CGPoint, resizeFactor:CGFloat) {
        let path = UIBezierPath()
		path.move(to: CGPoint(x:from.x*resizeFactor, y:from.y*resizeFactor))
		path.addLine(to: CGPoint(x:to.x*resizeFactor, y:to.y*resizeFactor))
        UIColor.black.setStroke()
        path.stroke()
    }
    
    /**
    Draws the maze on a UIView and returns the view
    
    :param: gridSize Int indicating the width and hight of the maze in number of cells, with width = height = gridSize
    :param: screenSize Int indicating the width and hight of the view, with width = height = screenSize
    
    :return: UIView containing the drawn maze
    */
    func drawView(gridSize:Int, screenSize:Int) -> UIView {
        let viewSize = CGSize(width: screenSize, height: screenSize)
        let result:UIView = UIView(frame: CGRect(origin: CGPoint.zero, size: viewSize))
        result.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
        UIGraphicsBeginImageContextWithOptions(viewSize, false, 0)
        
    let resizeFactor = viewSize.width/CGFloat(gridSize + 2)
        
        for x in 1..<gridSize+1 {
            for y in 1..<gridSize+1 {
                
                if (down[x,y]) {
                    drawLine(from: CGPoint(x:x,y:y), to: CGPoint(x:x+1,y:y), resizeFactor:resizeFactor)
                }
                
                if (up[x,y]) {
                    drawLine(from: CGPoint(x:x,y:y+1), to: CGPoint(x:x+1,y:y+1), resizeFactor:resizeFactor)
                }
                
                if (left[x,y]) {
                    drawLine(from: CGPoint(x:x,y:y), to: CGPoint(x:x,y:y+1), resizeFactor:resizeFactor)
                }
                if (right[x,y]) {
                    drawLine(from: CGPoint(x:x+1,y:y), to: CGPoint(x:x+1,y:y+1), resizeFactor:resizeFactor)
                }
                
            }
        }
        
        result.layer.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        return result
    }
}


var maze = Maze(gridSize: 30, screenSize: 300)
XCPlaygroundPage.currentPage.liveView = maze.view




