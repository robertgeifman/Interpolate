//
//  DisplayLink.swift
//  LoopyAnimation
//
//  Created by Robert Geifman on 23/12/18.
//  Copyright © 2018 Robert Geifman. All rights reserved.
//

#if os(OSX)
import AppKit
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

///////////////////////////////////////////////////////////
final class DisplayLink {
#if os(macOS)
	typealias Action = (CVDisplayLink, UnsafePointer<CVTimeStamp>, UnsafePointer<CVTimeStamp>) -> Void
	var displayLink: CVDisplayLink?
#else
	typealias Action = (CADisplayLink, TimeInterval, TimeInterval) -> Void
	var displayLink: CADisplayLink?

	@objc
	func displayLinkCallback(displayLink: CADisplayLink) {
		action(displayLink, displayLink.timestamp, displayLink.targetTimeStamp)
	}
#endif // !os(macOS)
	let action: Action
	init(action: @escaping Action) {
		self.action = action
	}

	func start() {
		stop()
#if os(macOS)
		var newDisplayLink: CVDisplayLink?
		if kCVReturnSuccess == CVDisplayLinkCreateWithActiveCGDisplays(&newDisplayLink) {
			CVDisplayLinkSetOutputCallback(newDisplayLink!, { displayLink, inNow, inOutputTime, _, _, context in
				let object = Unmanaged<DisplayLink>.fromOpaque(context!).takeUnretainedValue()
				object.action(displayLink, inNow, inOutputTime)
				return kCVReturnSuccess
			}, Unmanaged.passUnretained(self).toOpaque())
			CVDisplayLinkStart(newDisplayLink!)
			self.displayLink = newDisplayLink
		} else {
			self.displayLink = nil
		}
#else
		self.displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
		self.displayLink?.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
#endif
	}

	func stop() {
#if os(macOS)
		if let displayLink = self.displayLink {
			CVDisplayLinkStop(displayLink)
		}
#else
		self.displayLink?.invalidate()
#endif
		self.displayLink = nil
	}
}
