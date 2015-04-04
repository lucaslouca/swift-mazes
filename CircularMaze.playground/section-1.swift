//
//  CircularMaze.playground
//
//
//  Created by Lucas Louca on 04/04/15 - www.lucaslouca.com
//
//  Copyright (c) 2015 Lucas Louca. All rights reserved.

import XCPlayground
import SpriteKit
import Foundation

class Maze {
    // Constants
    let TwoPi = CGFloat(2.0 * Double(M_PI))
    
    // View on which we will draw our maze
    var view:UIView!
    
    // Enum indicating the target direction when we are going to generate the path
    enum Direction {
        case LEFT
        case UP
        case RIGHT
        case DOWN
        case UPDIAGONAL
        case NULLNODE
    }
    
    // Sector class represending the sector at a given track and index. A sector consists of
    // an inner(smaller) arc, an outer(bigger) arc and two lines joining the arc end-points.
    // The upper end-point of the inner arc is joined with the upper end-point of the outer arc with a line.
    // Similarly the lower end-point of the inner arc is joined with the lower end-point of the outer arc with a line.
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
    }
    
    /**
    Init method
    
    :param: trackWidth Int indicating the width of a track
    
    :param: innerSpokesPerQuadrant Int indicating the number of spokes per quadrant
    
    :param: screenSize Int indicating the width and hight of the maze, with width = height = screenSize
    */
    init(trackWidth:Int, innerSpokesPerQuadrant:Int, screenSize:Int) {
        var roomRadius:Int = 2 * trackWidth
        var numberOfSectorsPerTrack:[Int] = []
        var numberOfTracks:Int = Int(Int((screenSize - 10 - 2 * roomRadius) / trackWidth) / 2)
        var mazeCenter:Int = Int(screenSize/2)
        
        if (numberOfTracks < 1) {
            return
        }
        
        var sectorCount = 4 * innerSpokesPerQuadrant
        var trackCount = Int(roomRadius/trackWidth)
        var newTrackCount = trackCount
        for _ in 0..<numberOfTracks {
            numberOfSectorsPerTrack.append(sectorCount)
            newTrackCount++
            if (newTrackCount >= trackCount * 2) {
                trackCount = newTrackCount
                sectorCount *= 2
            }
        }
        
        view = generateMazeView(numberOfTracks: numberOfTracks, numberOfSectorsPerTrack: numberOfSectorsPerTrack, screenSize:screenSize, mazeCenter: mazeCenter, roomRadius: roomRadius, trackWidth:trackWidth)
    }
    
    /**
    Returns a UIBezierPath representing a line joining the two points
    from and to.
    
    :param: from CGPoint representing one end-point of the line
    
    :param: from CGPoint representing the other end-point of the line
    
    :return: UIBezierPath representing a line joining the two points
    */
    func drawLine(#from:CGPoint, to:CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(from.x, from.y))
        path.addLineToPoint(CGPointMake(to.x, to.y))
        return path
    }
    
    /**
    Returns a Sector object represending the sector at the given track and index. A sector object consists of
    an inner (smaller) arc, an outer (bigger) arc and two lines joining the arc endpoints (upper end point of inner arc is joined with the upper
    end point of the outer arc by a line. Similarly the lower end point of the inner arc is joined with the lower end point of the outer arc by a line).
    
    The lenght of the lines is computed using cosine and sine functions based on the track and sector number.
    
    Each arc of the sector has an angle ANGLE = TwoPi/#SECTORS_PER_TRACK, starting from an angle sector*ANGLE and ending
    at an angle of (sector*ANGLE) + ANGLE.
    
    :param: trackIndex Int zero-based track index (index 0 is the most inner track)
    
    :param: sectorIndex Int zero-based sector index
    
    :param: numberOfSectorsPerTrack [Int] Array holding the number of arrays in each track
    
    :param: mazeCenter Int indicating the (x,y) center of the maze, with x = y = mazeCenter
    
    :param: roomRadius Int the radius of the inner maze room (this room we don't want to segment)
    
    :param: trackWidth Int indicating the width of a track
    
    :return: Sector representing sector in the circle grid.
    */
    func createSector(#trackIndex:Int, sectorIndex:Int, numberOfSectorsPerTrack:[Int], mazeCenter:Int, roomRadius:Int, trackWidth:Int) -> Sector {
        var result = Sector()
        
        result.angle = CGFloat(Double(TwoPi) / Double(numberOfSectorsPerTrack[trackIndex]))
        result.startAngle = CGFloat(CGFloat(sectorIndex) * result.angle)
        result.endAngle = result.startAngle + result.angle
        
        // Inner Arc
        result.innerRadius = roomRadius + (trackIndex * trackWidth)
        result.innerArcXD = Int(CGFloat(mazeCenter) + CGFloat(roomRadius + trackWidth * trackIndex) * cos(TwoPi * CGFloat(sectorIndex) / CGFloat(numberOfSectorsPerTrack[trackIndex])))
        result.innerArcXU = Int(CGFloat(mazeCenter) + CGFloat(roomRadius + trackWidth * trackIndex) * cos(TwoPi * CGFloat(sectorIndex + 1) / CGFloat(numberOfSectorsPerTrack[trackIndex])))
        result.innerArcYD = Int(CGFloat(mazeCenter) + CGFloat(roomRadius + trackWidth * trackIndex) * sin(TwoPi * CGFloat(sectorIndex) / CGFloat(numberOfSectorsPerTrack[trackIndex])))
        result.innerArcYU = Int(CGFloat(mazeCenter) + CGFloat(roomRadius + trackWidth * trackIndex) * sin(TwoPi * CGFloat(sectorIndex + 1) / CGFloat(numberOfSectorsPerTrack[trackIndex])))
        result.innerArc = UIBezierPath(arcCenter: CGPoint(x: mazeCenter, y: mazeCenter), radius: CGFloat(result.innerRadius), startAngle: result.startAngle, endAngle: result.endAngle, clockwise: true)
        
        // Outer Arc
        result.outerRadius = roomRadius + ((trackIndex + 1) * trackWidth)
        result.outerArcXD = Int(CGFloat(mazeCenter) + CGFloat(roomRadius + trackWidth * (trackIndex + 1)) * cos(TwoPi * CGFloat(sectorIndex) / CGFloat(numberOfSectorsPerTrack[trackIndex])))
        result.outerArcXU = Int(CGFloat(mazeCenter) + CGFloat(roomRadius + trackWidth * (trackIndex + 1)) * cos(TwoPi * CGFloat(sectorIndex + 1) / CGFloat(numberOfSectorsPerTrack[trackIndex])))
        result.outerArcYD = Int(CGFloat(mazeCenter) + CGFloat(roomRadius + trackWidth * (trackIndex + 1)) * sin(TwoPi * CGFloat(sectorIndex) / CGFloat(numberOfSectorsPerTrack[trackIndex])))
        result.outerArcYU = Int(CGFloat(mazeCenter) + CGFloat(roomRadius + trackWidth * (trackIndex + 1)) * sin(TwoPi * CGFloat(sectorIndex + 1) / CGFloat(numberOfSectorsPerTrack[trackIndex])))
        result.outerArc = UIBezierPath(arcCenter: CGPoint(x: mazeCenter, y: mazeCenter), radius: CGFloat(result.outerRadius), startAngle: result.startAngle, endAngle: result.endAngle, clockwise: true)
        
        result.downPath = drawLine(from: CGPoint(x: result.innerArcXD, y: result.innerArcYD), to: CGPoint(x: result.outerArcXD, y: result.outerArcYD))
        result.upPath = drawLine(from: CGPoint(x: result.innerArcXU, y: result.innerArcYU), to: CGPoint(x: result.outerArcXU, y: result.outerArcYU))
        
        return result
    }
    
    /**
    Generates the Sectors for every track and adds them to a separate array for each track. It returns
    an [[Sector]] (array of arrays), where array[t][s] holds the sth Sector of track t.
    
    
    :param: numberOfTracks Int representing the total number of tracks
    
    :param: numberOfSectorsPerTrack [Int] Array holding the number of arrays in each track
    
    :param: mazeCenter Int indicating the (x,y) center of the maze, with x = y = mazeCenter
    
    :param: roomRadius Int the radius of the inner maze room (this room we don't want to segment)
    
    :param: trackWidth Int indicating the width of a track
    
    :return: [[Sector]] array holding every Sector for each track ([track][sector])
    */
    func generateGrid(#numberOfTracks:Int, numberOfSectorsPerTrack:[Int], mazeCenter:Int, roomRadius:Int, trackWidth:Int) -> [[Sector]]  {
        var result:[[Sector]] = []
        for t in 1...numberOfTracks {
            result.append([])
            for s in 0..<numberOfSectorsPerTrack[t - 1] {
                var sector = createSector(trackIndex:(t - 1), sectorIndex:s, numberOfSectorsPerTrack:numberOfSectorsPerTrack, mazeCenter:mazeCenter, roomRadius:roomRadius, trackWidth:trackWidth)
                result[t - 1].append(sector)
            }
        }
        
        return result
    }
    
    /**
    Generates the maze and paints it on a UIView. Returns the UIView once the maze is generated and painted.
    
    
    :param: numberOfTracks Int representing the total number of tracks
    
    :param: numberOfSectorsPerTrack [Int] Array holding the number of arrays in each track
    
    :param: screenSize Int indicating the width and height of the view, with width = height = screenSize
    
    :param: mazeCenter Int indicating the (x,y) center of the maze, with x = y = mazeCenter
    
    :param: roomRadius Int the radius of the inner maze room (this room we don't want to segment)
    
    :param: trackWidth Int indicating the width of a track
    
    :return: UIView view with the painted maze on it
    */
    func generateMazeView(#numberOfTracks:Int, numberOfSectorsPerTrack:[Int], screenSize:Int, mazeCenter:Int, roomRadius:Int, trackWidth:Int) -> UIView {
        var result:UIView!
        
        // Generate circular grid
        var sectorsOfTrack:[[Sector]] = generateGrid(numberOfTracks:numberOfTracks, numberOfSectorsPerTrack:numberOfSectorsPerTrack, mazeCenter:mazeCenter, roomRadius:roomRadius, trackWidth:trackWidth)
        
        // Init array of visited sectors
        var visitedSectors:[[Bool]] = []
        for i in 0...numberOfTracks {
            visitedSectors.append(Array(count: numberOfSectorsPerTrack[numberOfTracks - 1], repeatedValue:false))
        }
        
        // Randomly remove any edges and arcs from the above generated grid
        createPath(&visitedSectors, numberOfSectorsPerTrack:numberOfSectorsPerTrack, sectorsOfTrack:sectorsOfTrack, numberOfTracks:numberOfTracks, trackIndex:0, sectorIndex:0)
        
        // Do the drawing
        let viewSize = CGSize(width: screenSize, height: screenSize)
        result = UIView(frame: CGRect(origin: CGPointZero, size: viewSize))
        result.backgroundColor = UIColor.whiteColor()
        UIGraphicsBeginImageContextWithOptions(viewSize, false, 0)
        UIColor.blackColor().setStroke()
        
        // Draw center
        UIColor.blackColor().setFill()
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: mazeCenter, y: mazeCenter), radius: CGFloat(4), startAngle: 0.0, endAngle: TwoPi, clockwise: true)
        circlePath.stroke()
        circlePath.fill()
        
        // open up start
        var numberOfSectorsInnerTrack = Int(numberOfSectorsPerTrack[0])
        var randomInnerSectorIndex =  Int(UInt32(rand()) % UInt32(numberOfSectorsInnerTrack))
        var randomInnerSector = sectorsOfTrack[0][randomInnerSectorIndex]
        randomInnerSector.innerArc!.removeAllPoints()
        
        // open up end
        var numberOfSectorsOuterTrack = Int(numberOfSectorsPerTrack[numberOfTracks - 1])
        var randomOuterSectorIndex =  Int(UInt32(rand()) % UInt32(numberOfSectorsOuterTrack))
        var randomOuterSector = sectorsOfTrack[numberOfTracks - 1][randomOuterSectorIndex]
        randomOuterSector.outerArc!.removeAllPoints()
        
        // Draw arcs and lines
        for t in 1...numberOfTracks {
            for s in 0..<numberOfSectorsPerTrack[t - 1] {
                var sector = sectorsOfTrack[t - 1][s]
                sector.innerArc!.stroke()
                sector.outerArc!.stroke()
                sector.upPath!.stroke()
                sector.downPath!.stroke()
            }
        }
        
        result.layer.contents = UIGraphicsGetImageFromCurrentImageContext().CGImage
        UIGraphicsEndImageContext()
        
        return result
    }
    
    /**
    Creates a path by visiting all the sectors in the maze grid.
    
    :param: visitedSectors [[Bool]] with [t][s] == true if sector s of track t has already been visited. false otherwise.
    
    :param: numberOfSectorsPerTrack [Int] Array holding the number of arrays in each track
    
    :param: sectorsOfTrack [[Sector]] (array of arrays), where array[t][s] holds the sth Sector of track t.
    
    :param: numberOfTracks Int indicating the total number of tracks
    
    :param: trackIndex Int current track index
    
    :param: sectorIndex Int current sector index
    */
    func createPath(inout visitedSectors:[[Bool]], numberOfSectorsPerTrack:[Int], sectorsOfTrack:[[Sector]], numberOfTracks:Int, trackIndex:Int, sectorIndex:Int) {
        var unvisitedSectorExists = ((sectorIndex > 0 && !visitedSectors[trackIndex][sectorIndex - 1]) || (sectorIndex == 0 && !visitedSectors[trackIndex][sectorIndex - 1 + numberOfSectorsPerTrack[trackIndex]]))
        unvisitedSectorExists = unvisitedSectorExists || ((trackIndex > 0) && (numberOfSectorsPerTrack[trackIndex] == numberOfSectorsPerTrack[trackIndex - 1]) && (!visitedSectors[trackIndex - 1][sectorIndex]))
        unvisitedSectorExists = unvisitedSectorExists || ((trackIndex > 0) && (numberOfSectorsPerTrack[trackIndex] != numberOfSectorsPerTrack[trackIndex - 1]) && (!visitedSectors[trackIndex - 1][sectorIndex / 2]))
        unvisitedSectorExists = unvisitedSectorExists || (sectorIndex < numberOfSectorsPerTrack[trackIndex] - 1 && !visitedSectors[trackIndex][sectorIndex + 1])
        unvisitedSectorExists = unvisitedSectorExists || (sectorIndex == numberOfSectorsPerTrack[trackIndex] - 1 && !visitedSectors[trackIndex][sectorIndex + 1 - numberOfSectorsPerTrack[trackIndex]])
        unvisitedSectorExists = unvisitedSectorExists || ((trackIndex < numberOfTracks - 1) && (numberOfSectorsPerTrack[trackIndex] == numberOfSectorsPerTrack[trackIndex + 1]) && (!visitedSectors[trackIndex + 1][sectorIndex]))
        unvisitedSectorExists = unvisitedSectorExists
            || ((trackIndex < numberOfTracks - 1) && (numberOfSectorsPerTrack[trackIndex] != numberOfSectorsPerTrack[trackIndex + 1]) && ((!visitedSectors[trackIndex + 1][sectorIndex * 2]) || (!visitedSectors[trackIndex + 1][sectorIndex * 2 + 1])))
        
        OUTERWHILE: while (unvisitedSectorExists) {
            // Make a list of up to 5 ways that the trail can be extended.
            INNERWHILE: while (true) {
                var numberOfPossibleDirections:Int = 0
                var direction:[Direction] = Array(count: 5, repeatedValue:Direction.NULLNODE)
                var distance:[Int] = Array(count: 5, repeatedValue:0)
                
                if ((sectorIndex > 0 && !visitedSectors[trackIndex][sectorIndex - 1]) || (sectorIndex == 0 && !visitedSectors[trackIndex][sectorIndex - 1 + numberOfSectorsPerTrack[trackIndex]])) {
                    direction[numberOfPossibleDirections] = .LEFT
                    distance[numberOfPossibleDirections] = 1
                    numberOfPossibleDirections++
                }
                
                if (trackIndex > 0) {
                    if (numberOfSectorsPerTrack[trackIndex] == numberOfSectorsPerTrack[trackIndex - 1]) {
                        if (!visitedSectors[trackIndex - 1][sectorIndex]) {
                            direction[numberOfPossibleDirections] = .DOWN
                            distance[numberOfPossibleDirections] = 1
                            numberOfPossibleDirections++
                        }
                    } else {
                        if (!visitedSectors[trackIndex - 1][sectorIndex / 2]) {
                            direction[numberOfPossibleDirections] = .DOWN
                            distance[numberOfPossibleDirections] = 1
                            numberOfPossibleDirections++
                        }
                    }
                }
                
                if ((sectorIndex < numberOfSectorsPerTrack[trackIndex] - 1 && !visitedSectors[trackIndex][sectorIndex + 1]) || (sectorIndex == numberOfSectorsPerTrack[trackIndex] - 1 && !visitedSectors[trackIndex][sectorIndex + 1 - numberOfSectorsPerTrack[trackIndex]])) {
                    direction[numberOfPossibleDirections] = .RIGHT
                    distance[numberOfPossibleDirections] = 1
                    numberOfPossibleDirections++
                }
                
                if (trackIndex < numberOfTracks - 1) {
                    if (numberOfSectorsPerTrack[trackIndex] == numberOfSectorsPerTrack[trackIndex + 1]) {
                        if (!visitedSectors[trackIndex + 1][sectorIndex]) {
                            direction[numberOfPossibleDirections] = .UP
                            distance[numberOfPossibleDirections] = 1
                            numberOfPossibleDirections++
                        }
                    } else {
                        if (!visitedSectors[trackIndex + 1][sectorIndex * 2]) {
                            direction[numberOfPossibleDirections] = .UP
                            distance[numberOfPossibleDirections] = 1
                            numberOfPossibleDirections++
                        }
                        if (!visitedSectors[trackIndex + 1][sectorIndex * 2 + 1]) {
                            direction[numberOfPossibleDirections] = .UPDIAGONAL
                            distance[numberOfPossibleDirections] = 1
                            numberOfPossibleDirections++
                        }
                    }
                }
                
                // Now that we have got our possible directions for a sector in a track we can
                // randomly pick one and drop the wall
                if (numberOfPossibleDirections > 0) {
                    var random =  Int(UInt32(rand()) % 5)
                    var dir:Direction = direction[Int(random)]
                    var newSectorIndex = sectorIndex
                    var newTrackIndex = trackIndex
                    var fromSectorObj:Sector!
                    var toSectorObj:Sector!
                    
                    if (dir == .LEFT) {
                        newSectorIndex -= distance[random]
                        if (newSectorIndex < 0) {
                            newSectorIndex += numberOfSectorsPerTrack[trackIndex]
                        }
                        
                        fromSectorObj = sectorsOfTrack[trackIndex][sectorIndex]
                        toSectorObj = sectorsOfTrack[newTrackIndex][newSectorIndex]
                        fromSectorObj.downPath!.removeAllPoints()
                        toSectorObj.upPath!.removeAllPoints()
                        
                        visitedSectors[newTrackIndex][newSectorIndex] = true
                        
                        createPath(&visitedSectors, numberOfSectorsPerTrack:numberOfSectorsPerTrack, sectorsOfTrack:sectorsOfTrack, numberOfTracks:numberOfTracks, trackIndex:newTrackIndex, sectorIndex:newSectorIndex)
                        break INNERWHILE
                    }
                    
                    if (dir == .RIGHT) {
                        newSectorIndex += distance[random]
                        if (newSectorIndex >= numberOfSectorsPerTrack[trackIndex]) {
                            newSectorIndex -= numberOfSectorsPerTrack[trackIndex]
                        }
                        
                        fromSectorObj = sectorsOfTrack[trackIndex][sectorIndex]
                        toSectorObj = sectorsOfTrack[newTrackIndex][newSectorIndex]
                        fromSectorObj.upPath!.removeAllPoints()
                        toSectorObj.downPath!.removeAllPoints()
                        
                        
                        visitedSectors[newTrackIndex][newSectorIndex] = true
                        createPath(&visitedSectors, numberOfSectorsPerTrack:numberOfSectorsPerTrack, sectorsOfTrack:sectorsOfTrack, numberOfTracks:numberOfTracks, trackIndex:newTrackIndex, sectorIndex:newSectorIndex)
                        break INNERWHILE
                    }
                    
                    if (dir == .DOWN) {
                        newTrackIndex -= distance[random];
                        if (numberOfSectorsPerTrack[trackIndex] > numberOfSectorsPerTrack[trackIndex - 1]) {
                            newSectorIndex /= 2
                        }
                        
                        fromSectorObj = sectorsOfTrack[trackIndex][sectorIndex]
                        toSectorObj = sectorsOfTrack[newTrackIndex][newSectorIndex]
                        fromSectorObj.innerArc!.removeAllPoints()
                        toSectorObj.outerArc!.removeAllPoints()
                        visitedSectors[newTrackIndex][newSectorIndex] = true
                        createPath(&visitedSectors, numberOfSectorsPerTrack:numberOfSectorsPerTrack, sectorsOfTrack:sectorsOfTrack, numberOfTracks:numberOfTracks, trackIndex:newTrackIndex, sectorIndex:newSectorIndex)
                        break INNERWHILE
                    }
                    
                    if (dir == .UP) {
                        newTrackIndex += distance[random];
                        if (numberOfSectorsPerTrack[trackIndex + 1] > numberOfSectorsPerTrack[trackIndex]) {
                            newSectorIndex *= 2
                        }
                        
                        fromSectorObj = sectorsOfTrack[trackIndex][sectorIndex]
                        toSectorObj = sectorsOfTrack[newTrackIndex][newSectorIndex]
                        fromSectorObj.outerArc!.removeAllPoints()
                        toSectorObj.innerArc!.removeAllPoints()
                        
                        visitedSectors[newTrackIndex][newSectorIndex] = true
                        createPath(&visitedSectors, numberOfSectorsPerTrack:numberOfSectorsPerTrack, sectorsOfTrack:sectorsOfTrack, numberOfTracks:numberOfTracks, trackIndex:newTrackIndex, sectorIndex:newSectorIndex)
                        break INNERWHILE
                    }
                    
                    if (dir == .UPDIAGONAL) {
                        newTrackIndex += distance[random];
                        if (numberOfSectorsPerTrack[trackIndex + 1] > numberOfSectorsPerTrack[trackIndex]) {
                            newSectorIndex = 2 * sectorIndex + 1
                        }
                        
                        fromSectorObj = sectorsOfTrack[trackIndex][sectorIndex]
                        toSectorObj = sectorsOfTrack[newTrackIndex][newSectorIndex]
                        fromSectorObj.outerArc!.removeAllPoints()
                        toSectorObj.innerArc!.removeAllPoints()
                        
                        visitedSectors[newTrackIndex][newSectorIndex] = true
                        createPath(&visitedSectors, numberOfSectorsPerTrack:numberOfSectorsPerTrack, sectorsOfTrack:sectorsOfTrack, numberOfTracks:numberOfTracks, trackIndex:newTrackIndex, sectorIndex:newSectorIndex)
                        break INNERWHILE
                    }
                } else {
                    break OUTERWHILE
                }
                
            } // end of INNERWHILE
        } // end of OUTERWHILE
    }
    
    
}


var maze = Maze(trackWidth: 20, innerSpokesPerQuadrant: 6, screenSize: 400)
XCPShowView("preview", maze.view)



