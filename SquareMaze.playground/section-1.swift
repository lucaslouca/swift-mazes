import XCPlayground
import SpriteKit

class Grid<T> {
    var matrix:[T]
    var rows:Int;
    var columns:Int;
    
    init(rows:Int, columns:Int, defaultValue:T) {
        self.rows = rows
        self.columns = columns
        matrix = Array(count:(rows*columns),repeatedValue:defaultValue)
    }
    
    func indexIsValidForRow(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }
    
    subscript(col:Int, row:Int) -> T {
        get{
            assert(indexIsValidForRow(row, column: col), "Index out of range")
            return matrix[Int(columns * row + col)]
        }
        set{
            assert(indexIsValidForRow(row, column: col), "Index out of range")
            matrix[(columns * row) + col] = newValue
        }
    }
}

class Maze {
    var size = 0
    
    // is there a wall to north of cell i, j
    var north   :Grid<Bool>
    var east    :Grid<Bool>
    var south   :Grid<Bool>
    var west    :Grid<Bool>
    var visited :Grid<Bool>
    
    var done = false
    
    
    init(size: Int) {
        self.size = size
        
        visited = Grid<Bool>(rows: (size+2), columns: (size+2), defaultValue: false)
        north = Grid<Bool>(rows: (size+2), columns: (size+2), defaultValue: true)
        east = Grid<Bool>(rows: (size+2), columns: (size+2), defaultValue: true)
        south = Grid<Bool>(rows: (size+2), columns: (size+2), defaultValue: true)
        west = Grid<Bool>(rows: (size+2), columns: (size+2), defaultValue: true)
        
        // Initialize border cells as already visited
        for x in 0..<size+2 {
            visited[x,0] = true
            visited[x,size+1] = true
        }
        
        for y in 0..<size+2 {
            visited[0,y] = true
            visited[size+1,y] = true
        }
        
       generate(1, y:1);
    }
    
    
    func generate(x:Int, y:Int) {
        visited[x,y] = true;
        
        // while there is an unvisited neighbor
        while (!visited[x,y + 1] || !visited[x + 1,y] || !visited[x,y - 1] || !visited[x - 1,y]) {
            
            // pick random neighbor
            while (true) {
                var r =  UInt32(rand()) % 4
                if (r == 0 && !visited[x,y + 1]) {
                    north[x,y] = false
                    south[x,y + 1] = false
                    generate(x, y: y + 1)
                    break
                } else if (r == 1 && !visited[x + 1,y]) {
                    east[x,y] = false
                    west[x + 1, y] = false
                    generate(x + 1, y: y)
                    break
                } else if (r == 2 && !visited[x,y - 1]) {
                    south[x,y] = false
                    north[x,y - 1] = false
                    generate(x, y: y - 1)
                    break
                } else if (r == 3 && !visited[x - 1,y]) {
                    west[x,y] = false
                    east[x - 1,y] = false
                    generate(x - 1, y: y)
                    break
                }
            }
        }
        
        north[1,1] = false
        south[1,1] = false
        north[size,size] = false
        south[size,size] = false
    }

    
    func drawLine(#from:CGPoint, to:CGPoint, resizeFactor:CGFloat) {
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(from.x*resizeFactor, from.y*resizeFactor))
        path.addLineToPoint(CGPointMake(to.x*resizeFactor, to.y*resizeFactor))
        UIColor.blackColor().setStroke()
        path.stroke()
    }
    
    func draw() -> UIView {
        let viewSize = CGSize(width: 300, height: 300)
        let result:UIView = UIView(frame: CGRect(origin: CGPointZero, size: viewSize))
        result.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
        UIGraphicsBeginImageContextWithOptions(viewSize, false, 0)
        
        var resizeFactor = viewSize.width/CGFloat(size + 2)
        
        for x in 1..<size+1 {
            for y in 1..<size+1 {
                
                if (south[x,y]) {
                    drawLine(from: CGPoint(x:x,y:y), to: CGPoint(x:x+1,y:y), resizeFactor:resizeFactor)
                }
                
                if (north[x,y]) {
                    drawLine(from: CGPoint(x:x,y:y+1), to: CGPoint(x:x+1,y:y+1), resizeFactor:resizeFactor)
                }
                
                if (west[x,y]) {
                    drawLine(from: CGPoint(x:x,y:y), to: CGPoint(x:x,y:y+1), resizeFactor:resizeFactor)
                }
                if (east[x,y]) {
                    drawLine(from: CGPoint(x:x+1,y:y), to: CGPoint(x:x+1,y:y+1), resizeFactor:resizeFactor)
                }

            }
        }
    
        result.layer.contents = UIGraphicsGetImageFromCurrentImageContext().CGImage
        UIGraphicsEndImageContext()
        return result
    }
}


//var maze = Maze(size: 20)

//XCPShowView("preview", maze.draw())



