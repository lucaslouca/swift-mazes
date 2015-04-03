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
    var up      :Grid<Bool>
    var right   :Grid<Bool>
    var down    :Grid<Bool>
    var left    :Grid<Bool>
    var visited :Grid<Bool>
    
    var done = false
    
    
    init(size: Int) {
        self.size = size
        
        visited = Grid<Bool>(rows: (size+2), columns: (size+2), defaultValue: false)
        up = Grid<Bool>(rows: (size+2), columns: (size+2), defaultValue: true)
        right = Grid<Bool>(rows: (size+2), columns: (size+2), defaultValue: true)
        down = Grid<Bool>(rows: (size+2), columns: (size+2), defaultValue: true)
        left = Grid<Bool>(rows: (size+2), columns: (size+2), defaultValue: true)
        
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
                    up[x,y] = false
                    down[x,y + 1] = false
                    generate(x, y: y + 1)
                    break
                } else if (r == 1 && !visited[x + 1,y]) {
                    right[x,y] = false
                    left[x + 1, y] = false
                    generate(x + 1, y: y)
                    break
                } else if (r == 2 && !visited[x,y - 1]) {
                    down[x,y] = false
                    up[x,y - 1] = false
                    generate(x, y: y - 1)
                    break
                } else if (r == 3 && !visited[x - 1,y]) {
                    left[x,y] = false
                    right[x - 1,y] = false
                    generate(x - 1, y: y)
                    break
                }
            }
        }
        
        up[1,1] = false
        down[1,1] = false
        up[size,size] = false
        down[size,size] = false
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
    
        result.layer.contents = UIGraphicsGetImageFromCurrentImageContext().CGImage
        UIGraphicsEndImageContext()
        return result
    }
}


var maze = Maze(size: 30)

XCPShowView("preview", maze.draw())



