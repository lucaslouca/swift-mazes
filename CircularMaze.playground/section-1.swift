import XCPlayground
import SpriteKit
import Foundation

class Matrix<T> {
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

class Sector {
    var innerArcXU:Int = 0
    var innerArcXD:Int = 0
    var innerArcYU:Int = 0
    var innerArcYD:Int = 0
    var innerRadius:Int = 0
    var innerArc:UIBezierPath?
    
    var outerArcXU:Int = 0
    var outerArcXD:Int = 0
    var outerArcYU:Int = 0
    var outerArcYD:Int = 0
    var outerRadius:Int = 0
    var outerArc:UIBezierPath?
    
    var upPath:UIBezierPath?
    var downPath:UIBezierPath?
    
    var angle:CGFloat = 0
    var startAngle:CGFloat = 0
    var endAngle:CGFloat = 0
    var track:Int = 0
}

class Maze {
    var tempTotal = 0
    var tempCount = 0
    
    let innerSectoresPerQuadrant = 4
    let wallThickness = 6
    let trackWidth = 20
    let roomRad:Int // center-inner circle
    let screenSize = 400
    var sectorsPerTrack:[Int] = [] // number of sectors per track
    var sectorsOfTrack:[[Sector]] = [] // actual sector objects for each track
    var tracks:Int
    var visited:[[Bool]] = []
    var center:Int = 0
    var mazeView:UIView!
    
    enum Direction {
        case LEFT
        case UP
        case RIGHT
        case DOWN
        case UPDIAGONAL
        case NULLNODE
    }
    init() {
        roomRad = 2 * trackWidth
        
        tracks = Int(Int((screenSize - 10 - 2 * roomRad) / trackWidth) / 2);
        if (tracks < 1) {
            return
        }
        
        var trackCount = Int(roomRad/trackWidth);
        var newTrackCount = trackCount
        var sectorCount = 4 * innerSectoresPerQuadrant
        for i in 0..<tracks {
            sectorsPerTrack.append(sectorCount)
            newTrackCount++
            if (newTrackCount >= trackCount * 2) {
                trackCount = newTrackCount
                sectorCount *= 2
            }
        }
        
        
        for i in 0...tracks {
            visited.append(Array(count: sectorsPerTrack[tracks - 1], repeatedValue:false))
            sectorsOfTrack.append([])
        }
        
    }
    
    func drawLine(#from:CGPoint, to:CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(from.x, from.y))
        path.addLineToPoint(CGPointMake(to.x, to.y))
        return path
    }
    
    func createSector(#track:Int, sector:Int) -> Sector {
        let twoPi = 2.0 * Double(M_PI)
        center = Int(screenSize/2)
        
        var sectorObject = Sector()
        
        sectorObject.track = track
        sectorObject.angle = CGFloat(twoPi / Double(sectorsPerTrack[track]))
        sectorObject.startAngle = CGFloat(CGFloat(sector) * sectorObject.angle)
        sectorObject.endAngle = sectorObject.startAngle + sectorObject.angle
        
        sectorObject.innerRadius = roomRad + (track * trackWidth)
        sectorObject.innerArcXD = Int(CGFloat(center) + CGFloat(roomRad + trackWidth * track) * cos(6.28318530718 * CGFloat(sector) / CGFloat(sectorsPerTrack[track])))
        
        sectorObject.innerArcXU = Int(CGFloat(center) + CGFloat(roomRad + trackWidth * track) * cos(6.28318530718 * CGFloat(sector + 1) / CGFloat(sectorsPerTrack[track])))
        sectorObject.innerArcYD = Int(CGFloat(center) + CGFloat(roomRad + trackWidth * track) * sin(6.28318530718 * CGFloat(sector) / CGFloat(sectorsPerTrack[track])))
        sectorObject.innerArcYU = Int(CGFloat(center) + CGFloat(roomRad + trackWidth * track) * sin(6.28318530718 * CGFloat(sector + 1) / CGFloat(sectorsPerTrack[track])))
        
        
        sectorObject.outerRadius = roomRad + ((track+1) * trackWidth)
        sectorObject.outerArcXD = Int(CGFloat(center) + CGFloat(roomRad + trackWidth * (track + 1)) * cos(6.28318530718 * CGFloat(sector) / CGFloat(sectorsPerTrack[track])))
        sectorObject.outerArcXU = Int(CGFloat(center) + CGFloat(roomRad + trackWidth * (track + 1)) * cos(6.28318530718 * CGFloat(sector + 1) / CGFloat(sectorsPerTrack[track])))
        sectorObject.outerArcYD = Int(CGFloat(center) + CGFloat(roomRad + trackWidth * (track + 1)) * sin(6.28318530718 * CGFloat(sector) / CGFloat(sectorsPerTrack[track])))
        sectorObject.outerArcYU = Int(CGFloat(center) + CGFloat(roomRad + trackWidth * (track + 1)) * sin(6.28318530718 * CGFloat(sector + 1) / CGFloat(sectorsPerTrack[track])))
        
        
        sectorObject.innerArc = UIBezierPath(arcCenter: CGPoint(x: center, y: center), radius: CGFloat(sectorObject.innerRadius), startAngle: sectorObject.startAngle, endAngle: sectorObject.endAngle, clockwise: true)
        sectorObject.outerArc = UIBezierPath(arcCenter: CGPoint(x: center, y: center), radius: CGFloat(sectorObject.outerRadius), startAngle: sectorObject.startAngle, endAngle: sectorObject.endAngle, clockwise: true)
        
        sectorObject.downPath = drawLine(from: CGPoint(x: sectorObject.innerArcXD, y: sectorObject.innerArcYD), to: CGPoint(x: sectorObject.outerArcXD, y: sectorObject.outerArcYD))
        
        sectorObject.upPath = drawLine(from: CGPoint(x: sectorObject.innerArcXU, y: sectorObject.innerArcYU), to: CGPoint(x: sectorObject.outerArcXU, y: sectorObject.outerArcYU))
        
        
        return sectorObject
    }
    
    
    func generateGrid() {
        for t in 1...tracks {
            for s in 0..<sectorsPerTrack[t - 1] {
                tempTotal++
                var sector = createSector(track:(t - 1), sector:s)
                sectorsOfTrack[t - 1].append(sector)
            }
        }
    }
    
    
    func generateMaze() -> UIView {
        generateGrid()
        
        let viewSize = CGSize(width: screenSize, height: screenSize)
        mazeView = UIView(frame: CGRect(origin: CGPointZero, size: viewSize))
        mazeView.backgroundColor = UIColor.whiteColor()
        UIGraphicsBeginImageContextWithOptions(viewSize, false, 0)
        
        // Randomly any edges and arcs
        createPath(&visited, sectorsPerTrack:sectorsPerTrack, numberOfTracks:tracks, track:0, sector:0)
        
        
        UIColor.blackColor().setStroke()
        
        // Draw center
        UIColor.blackColor().setFill()
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: center, y: center), radius: CGFloat(4), startAngle: 0.0, endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        circlePath.stroke()
        circlePath.fill()
        
        
        // open up start and end
        var numberOfSectorsInnerTrack = Int(sectorsPerTrack[0])
        var randomInnerSectorIndex =  Int(UInt32(rand()) % UInt32(numberOfSectorsInnerTrack))
        var randomInnerSector = sectorsOfTrack[0][randomInnerSectorIndex]
        randomInnerSector.innerArc!.removeAllPoints()
        
        // open up end
        var numberOfSectorsOuterTrack = Int(sectorsPerTrack[tracks - 1])
        var randomOuterSectorIndex =  Int(UInt32(rand()) % UInt32(numberOfSectorsOuterTrack))
        var randomOuterSector = sectorsOfTrack[tracks - 1][randomOuterSectorIndex]
        randomOuterSector.outerArc!.removeAllPoints()
        
        // Draw arcs and lines
        for t in 1...tracks {
            for s in 0..<sectorsPerTrack[t - 1] {
                var sector = sectorsOfTrack[t - 1][s]
                sector.innerArc!.stroke()
                sector.outerArc!.stroke()
                sector.upPath!.stroke()
                sector.downPath!.stroke()
            }
        }
        
        mazeView.layer.contents = UIGraphicsGetImageFromCurrentImageContext().CGImage
        UIGraphicsEndImageContext()
        
        return mazeView
    }
    
    func createPath(inout visited:[[Bool]], sectorsPerTrack:[Int], numberOfTracks:Int, track:Int, sector:Int) {
        tempCount++
        //println("track \(track)   sector \(sector)")
        
        var exist = ((sector > 0 && !visited[track][sector - 1]) || (sector == 0 && !visited[track][sector - 1 + sectorsPerTrack[track]]))
        exist = exist || ((track > 0) && (sectorsPerTrack[track] == sectorsPerTrack[track - 1]) && (!visited[track - 1][sector]))
        exist = exist || ((track > 0) && (sectorsPerTrack[track] != sectorsPerTrack[track - 1]) && (!visited[track - 1][sector / 2]))
        exist = exist || (sector < sectorsPerTrack[track] - 1 && !visited[track][sector + 1])
        exist = exist || (sector == sectorsPerTrack[track] - 1 && !visited[track][sector + 1 - sectorsPerTrack[track]])
        exist = exist || ((track < numberOfTracks - 1) && (sectorsPerTrack[track] == sectorsPerTrack[track + 1]) && (!visited[track + 1][sector]))
        exist = exist
            || ((track < numberOfTracks - 1) && (sectorsPerTrack[track] != sectorsPerTrack[track + 1]) && ((!visited[track + 1][sector * 2]) || (!visited[track + 1][sector * 2 + 1])))
        
        OUTERWHILE: while (exist) {
            // Make a list of up to 5 ways that the trail can be extended.
            INNERWHILE: while (true) {
                var options:Int = 0
                var direction:[Direction] = Array(count: 5, repeatedValue:Direction.NULLNODE)
                var distance:[Int] = Array(count: 5, repeatedValue:0)
                
                if ((sector > 0 && !visited[track][sector - 1]) || (sector == 0 && !visited[track][sector - 1 + sectorsPerTrack[track]])) {
                    direction[options] = Direction.LEFT
                    distance[options] = 1
                    options++
                }
                
                if (track > 0) {
                    if (sectorsPerTrack[track] == sectorsPerTrack[track - 1]) {
                        if (!visited[track - 1][sector]) {
                            direction[options] = Direction.DOWN
                            distance[options] = 1
                            options++
                        }
                    } else {
                        if (!visited[track - 1][sector / 2]) {
                            direction[options] = Direction.DOWN
                            distance[options] = 1
                            options++
                        }
                    }
                }
                
                if ((sector < sectorsPerTrack[track] - 1 && !visited[track][sector + 1]) || (sector == sectorsPerTrack[track] - 1 && !visited[track][sector + 1 - sectorsPerTrack[track]])) {
                    direction[options] = Direction.RIGHT
                    distance[options] = 1
                    options++
                }
                
                if (track < numberOfTracks - 1) {
                    if (sectorsPerTrack[track] == sectorsPerTrack[track + 1]) {
                        if (!visited[track + 1][sector]) {
                            direction[options] = Direction.UP
                            distance[options] = 1
                            options++
                        }
                    } else {
                        if (!visited[track + 1][sector * 2]) {
                            direction[options] = Direction.UP
                            distance[options] = 1
                            options++
                        }
                        if (!visited[track + 1][sector * 2 + 1]) {
                            direction[options] = Direction.UPDIAGONAL
                            distance[options] = 1
                            options++
                        }
                    }
                }
                
                // Not that we have got our possible directions for a sector in a track we can
                // randomly pick one and drop the wall
                
                if (options > 0) {
                    var r =  Int(UInt32(rand()) % 5)
                    var dir = direction[Int(r)]
                    var newSector = sector
                    var newTrack = track
                    
                    
                    if (dir == Direction.LEFT) {
                        newSector -= distance[r]
                        var cycle = false
                        if (newSector < 0) {
                            newSector += sectorsPerTrack[track]
                            cycle = true
                        }
                        
                        var fromSectorObj = sectorsOfTrack[track][sector]
                        var toSectorObj = sectorsOfTrack[newTrack][newSector]
                        
                        fromSectorObj.downPath!.removeAllPoints()
                        toSectorObj.upPath!.removeAllPoints()
                        
                        visited[newTrack][newSector] = true
                        
                        createPath(&visited, sectorsPerTrack:sectorsPerTrack, numberOfTracks:numberOfTracks, track:newTrack, sector:newSector)
                        break INNERWHILE
                    }
                    
                    if (dir == Direction.RIGHT) {
                        newSector += distance[r]
                        var cycle = false
                        if (newSector >= sectorsPerTrack[track]) {
                            newSector -= sectorsPerTrack[track]
                            cycle = true
                        }
                        
                        var fromSectorObj = sectorsOfTrack[track][sector]
                        var toSectorObj = sectorsOfTrack[newTrack][newSector]
                        
                        fromSectorObj.upPath!.removeAllPoints()
                        toSectorObj.downPath!.removeAllPoints()
                        
                        
                        visited[newTrack][newSector] = true
                        createPath(&visited, sectorsPerTrack:sectorsPerTrack, numberOfTracks:numberOfTracks, track:newTrack, sector:newSector)
                        break INNERWHILE
                    }
                    
                    if (dir == Direction.DOWN) {
                        newTrack -= distance[r];
                        if (sectorsPerTrack[track] > sectorsPerTrack[track - 1]) {
                            newSector /= 2
                        }
                        
                        var fromSectorObj = sectorsOfTrack[track][sector]
                        var toSectorObj = sectorsOfTrack[newTrack][newSector]
                        fromSectorObj.innerArc!.removeAllPoints()
                        toSectorObj.outerArc!.removeAllPoints()
                        visited[newTrack][newSector] = true
                        createPath(&visited, sectorsPerTrack:sectorsPerTrack, numberOfTracks:numberOfTracks, track:newTrack, sector:newSector)
                        break INNERWHILE
                    }
                    
                    if (dir == Direction.UP) {
                        newTrack += distance[r];
                        if (sectorsPerTrack[track + 1] > sectorsPerTrack[track]) {
                            newSector *= 2
                        }
                        
                        var fromSectorObj = sectorsOfTrack[track][sector]
                        var toSectorObj = sectorsOfTrack[newTrack][newSector]
                        fromSectorObj.outerArc!.removeAllPoints()
                        toSectorObj.innerArc!.removeAllPoints()
                        
                        visited[newTrack][newSector] = true
                        createPath(&visited, sectorsPerTrack:sectorsPerTrack, numberOfTracks:numberOfTracks, track:newTrack, sector:newSector)
                        break INNERWHILE
                    }
                    
                    if (dir == Direction.UPDIAGONAL) {
                        newTrack += distance[r];
                        if (sectorsPerTrack[track + 1] > sectorsPerTrack[track]) {
                            newSector = 2 * sector + 1
                        }
                        var fromSectorObj = sectorsOfTrack[track][sector]
                        var toSectorObj = sectorsOfTrack[newTrack][newSector]
                        fromSectorObj.outerArc!.removeAllPoints()
                        toSectorObj.innerArc!.removeAllPoints()
                        
                        visited[newTrack][newSector] = true
                        createPath(&visited, sectorsPerTrack:sectorsPerTrack, numberOfTracks:numberOfTracks, track:newTrack, sector:newSector)
                        break INNERWHILE
                    }
                } else {
                    break OUTERWHILE
                }
                
            } // end of while(true)
        } // end of while(exist)
    }
    
    
}


var maze = Maze()

XCPShowView("preview", maze.generateMaze())



