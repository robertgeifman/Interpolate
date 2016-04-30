//
//  Interpolate.swift
//  Interpolate
//
//  Created by Roy Marmelstein on 10/04/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import Foundation

public protocol Interpolation {
    
    var current: IPValue { get set }
    var progress: CGFloat { get set }
    var apply: (Interpolatable -> ()) { get set }
    var diffVectors: [CGFloat] { get set }

    func stop()
    func calculateDiff(from: IPValue, to: IPValue) -> [CGFloat]
}


extension Interpolation {

    public func calculateDiff(from: IPValue, to: IPValue) -> [CGFloat] {
        var diffArray = [CGFloat]()
        let vectorCount = from.vectors.count
        for index in 0..<vectorCount {
            let vectorDiff = to.vectors[index] - from.vectors[index]
            diffArray.append(vectorDiff)
        }
        return diffArray
    }

}