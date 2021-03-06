//
//  Interpolate.swift
//  Interpolate
//
//  Created by Roy Marmelstein on 10/04/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import QuartzCore

////////////////////////////////////////////////////////////
public protocol InterpolationFunction {
	/// Applies interpolation function to a given progress value.
	/// - parameter progress: Actual progress value. CGFloat
	/// - returns: Adjusted progress value. CGFloat.
	func apply(_ progress: CGFloat) -> CGFloat
}

////////////////////////////////////////////////////////////
/// Interpolate class. Responsible for conducting interpolations.
open class Interpolate {
	// MARK: Properties and variables
	/// Progress variable. Takes a value between 0.0 and 1,0. CGFloat. Setting it triggers the apply closure.
	open var progress: CGFloat = 0.0 {
		didSet {
			// We make sure progress is between 0.0 and 1.0
			progress = max(0, min(progress, 1.0))
			internalProgress = self.internalAdjustedProgress(progress)
			let valueForProgress = internalProgress * (valuesCount - 1)
			let diffVectorIndex = max(Int(ceil(valueForProgress)) - 1, 0)
			let diffVector = diffVectors[diffVectorIndex]
			let originValue = values[diffVectorIndex]
			let adjustedProgress = valueForProgress - CGFloat(diffVectorIndex)
			for index in 0 ..< vectorCount {
				current.vectors[index] = originValue.vectors[index] + diffVector[index] * adjustedProgress
			}
			if let value = current.toInterpolatable() {
				apply?(value)
			}
		}
	}

	fileprivate var current: IPValue
	fileprivate let values: [IPValue]
	fileprivate var valuesCount: CGFloat { return CGFloat(values.count) }
	fileprivate var vectorCount: Int { return current.vectors.count }
	fileprivate var duration: CGFloat = 0.2
	fileprivate var diffVectors = [[CGFloat]]()
	fileprivate let function: InterpolationFunction
	fileprivate var internalProgress: CGFloat = 0.0
	fileprivate var targetProgress: CGFloat = 0.0
	fileprivate var apply: ((Interpolatable) -> Void)?
	fileprivate var displayLink: DisplayLink?
	// Animation completion handler, called when animate function stops.
	fileprivate var animationCompletion:(() -> Void)?

	// MARK: Lifecycle

	/// Initialises an Interpolate object.
	/// - parameter values:   Array of interpolatable objects, in order.
	/// - parameter apply:    Apply closure.
	/// - parameter function: Interpolation function (Basic / Spring / Custom).
	/// - returns: an Interpolate object.
	public init<T: Interpolatable>(values: [T], function: InterpolationFunction = BasicInterpolation.linear, apply: @escaping ((T) -> Void)) {
		assert(values.count >= 2, "You should provide at least two values")
		self.values = values.map { $0.vectorize() }
		self.function = function

		self.current = IPValue(value: self.values[0])
		self.apply = { _ = ($0 as? T).flatMap(apply) }
		self.diffVectors = calculateDiff(self.values)
	}

	/// Initialises an Interpolate object.
	/// - parameter from:     Source interpolatable object.
	/// - parameter to:       Target interpolatable object.
	/// - parameter apply:    Apply closure.
	/// - parameter function: Interpolation function (Basic / Spring / Custom).
	/// - returns: an Interpolate object.
	public convenience init<T: Interpolatable>(from: T, to: T, function: InterpolationFunction = BasicInterpolation.linear, apply: @escaping ((T) -> Void)) {
		self.init(values: [from, to], function: function, apply: apply)
	}

	// MARK: Internal
	/// Calculates diff between two IPValues.
	/// - parameter from: Source IPValue.
	/// - parameter to:   Target IPValue.
	/// - returns: Array of diffs. CGFloat
	fileprivate func calculateDiff(_ values: [IPValue]) -> [[CGFloat]] {
		var valuesDiffArray = [[CGFloat]]()
		for i in 0..<(values.count - 1) {
			var diffArray = [CGFloat]()
			let from = values[i]
			let to = values[i + 1]
			for index in 0 ..< from.vectors.count {
				let vectorDiff = to.vectors[index] - from.vectors[index]
				diffArray.append(vectorDiff)
			}
			valuesDiffArray.append(diffArray)
		}
		return valuesDiffArray
	}

	/// Adjusted progress using interpolation function.
	/// - parameter progressValue: Actual progress value. CGFloat.
	/// - returns: Adjusted progress value. CGFloat.
	fileprivate func internalAdjustedProgress(_ progressValue: CGFloat) -> CGFloat {
		return function.apply(progressValue)
	}

	/// Invalidates the apply function
	open func invalidate() {
		self.apply = nil
	}

	// MARK: Animation
	/// Animates to a targetProgress with a given duration.
	/// - parameter targetProgress: Target progress value. Optional. If left empty assumes 1.0.
	/// - parameter duration:       Duration in seconds. CGFloat.
	/// - parameter completion:     Completion handler. Optional.
	open func animate(_ targetProgress: CGFloat = 1.0, duration: CGFloat, completion: (() -> Void)? = nil) {
		self.targetProgress = targetProgress
		self.duration = duration
		self.animationCompletion = completion
		self.displayLink?.stop()
		self.displayLink? = DisplayLink(action: next)
		self.displayLink?.start()
	}

	/// Stops animation.
	open func stopAnimation() {
		self.displayLink?.stop()
		self.animationCompletion?()
	}

	/// Next function used by animation(). Increments progress based on the duration.
	fileprivate func next() {
		let direction: CGFloat = (targetProgress > progress) ? 1.0 : -1.0
		progress += 1 / (self.duration * 60) * direction
		if (direction > 0 && progress >= targetProgress) || (direction < 0 && progress <= targetProgress) {
			progress = targetProgress
			stopAnimation()
		}
	}
#if os(macOS)
	@objc
	fileprivate func next(displayLink: CVDisplayLink, timeStamp: UnsafePointer<CVTimeStamp>, targetTimeStamp: UnsafePointer<CVTimeStamp>) {
		next()
	}
#else
	fileprivate func next(displayLink: CADisplayLink, timeStamp: TimeInterval, targetTimeStamp: TimeInterval) -> Void {
		next()
	}
#endif
}
