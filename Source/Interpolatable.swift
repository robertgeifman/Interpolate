//
//  Interpolatable.swift
//  Interpolate
//
//  Created by Roy Marmelstein on 10/04/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

#if os(macOS)
import AppKit
#elseif os(iOS) || os(tvOS)
import UIKit
#endif
import QuartzCore

/// Interpolatable protocol. Requires implementation of a vectorize function.
public protocol Interpolatable {
	/// Vectorizes the type and returns and IPValue
	func vectorize() -> IPValue
}

/// Supported interpolatable types.
public enum InterpolatableType {
	case caTransform3D
	case cgAffineTransform
	case cgFloat
	case cgPoint
	case cgRect
	case cgSize
	case colorMonochrome
	case colorRGB// (preferHSB: Bool)
	case colorHSB
#if os(macOS)
	case colorCMYK
#endif
	case double
	case int
	case number
	case edgeInsets
}

// MARK: Interpolatable implementation

extension CATransform3D: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .caTransform3D, vectors: [m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44])
	}
}

extension CGAffineTransform: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .cgAffineTransform, vectors: [a, b, c, d, tx, ty])
	}
}

extension CGFloat: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .cgFloat, vectors: [self])
	}
}

extension CGPoint: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .cgPoint, vectors: [x, y])
	}
}

extension CGRect: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .cgRect, vectors: [origin.x, origin.y, size.width, size.height])
	}
}

extension CGSize: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .cgSize, vectors: [width, height])
	}
}

extension Double: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .double, vectors: [CGFloat(self)])
	}
}

extension Int: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .int, vectors: [CGFloat(self)])
	}
}

extension NSNumber: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .number, vectors: [CGFloat(truncating: self)])
	}
}

#if os(macOS)
extension NSColor: Interpolatable {
	public func vectorize() -> IPValue {
		var components = [CGFloat](repeating: 0, count: numberOfComponents)
		getComponents(&components)

		switch colorSpace.colorSpaceModel {
		case .gray:
			return IPValue(type: .colorMonochrome, vectors: components)
		case .rgb:
			return IPValue(type: .colorRGB, vectors: components)
		case .cmyk:
			return IPValue(type: .colorCMYK, vectors: components)
		default:
			fatalError("Unsupported color space model \(colorSpace.colorSpaceModel) in NSColor.vectorize()")
		}
	}

	public func vectorize(preferHSB: Bool) -> IPValue {
		var components = [CGFloat](repeating: 0, count: numberOfComponents)
		getComponents(&components)

		switch colorSpace.colorSpaceModel {
		case .gray:
			return IPValue(type: .colorMonochrome, vectors: components)
		case .rgb:
			if preferHSB {
				var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
				getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
				return IPValue(type: .colorHSB, vectors: [hue, saturation, brightness, alpha])
			}
			return IPValue(type: .colorRGB, vectors: components)
		case .cmyk:
			return IPValue(type: .colorCMYK, vectors: components)
		default:
			fatalError("Unsupported color space model \(colorSpace.colorSpaceModel) in NSColor.vectorize()")
		}
	}
}

extension NSEdgeInsets: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .edgeInsets, vectors: [top, left, bottom, right])
	}
}
#elseif os(iOS) || os(tvOS)
extension UIColor: Interpolatable {
	public func vectorize() -> IPValue {
		var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
		if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
			return IPValue(type: .colorRGB, vectors: [red, green, blue, alpha])
		}
		
		var white: CGFloat = 0
		if getWhite(&white, alpha: &alpha) {
			return IPValue(type: .colorMonochrome, vectors: [white, alpha])
		}
		
		var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0
		getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
		return IPValue(type: .colorHSB, vectors: [hue, saturation, brightness, alpha])
	}
}

extension UIEdgeInsets: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .edgeInsets, vectors: [top, left, bottom, right])
	}
}
#endif

/// IPValue class. Contains a vectorized version of an Interpolatable type.
open class IPValue {
	let type: InterpolatableType
	var vectors: [CGFloat]
	
	init(value: IPValue) {
		self.vectors = value.vectors
		self.type = value.type
	}
	
	init (type: InterpolatableType, vectors: [CGFloat]) {
		self.vectors = vectors
		self.type = type
	}
	
	func toInterpolatable() -> Interpolatable {
		switch type {
		case .caTransform3D:
			return CATransform3D(m11: vectors[0], m12: vectors[1], m13: vectors[2], m14: vectors[3], m21: vectors[4], m22: vectors[5], m23: vectors[6], m24: vectors[7], m31: vectors[8], m32: vectors[9], m33: vectors[10], m34: vectors[11], m41: vectors[12], m42: vectors[13], m43: vectors[14], m44: vectors[15])
		case .cgAffineTransform:
			return CGAffineTransform(a: vectors[0], b: vectors[1], c: vectors[2], d: vectors[3], tx: vectors[4], ty: vectors[5])
		case .cgFloat:
			return vectors[0]
		case .cgPoint:
			return CGPoint(x: vectors[0], y: vectors[1])
		case .cgRect:
			return CGRect(x: vectors[0], y: vectors[1], width: vectors[2], height: vectors[3])
		case .cgSize:
			return CGSize(width: vectors[0], height: vectors[1])
		case .double:
			return Double(vectors[0])
		case .int:
			return Int(vectors[0])
		case .number:
			return NSNumber(value: Double(vectors[0]))
#if os(macOS)
		case .colorMonochrome:
			return NSColor(calibratedWhite: vectors[0], alpha: vectors[1])
		case .colorRGB:
			return NSColor(calibratedRed: vectors[0], green: vectors[1], blue: vectors[2], alpha: vectors[3])
		case .colorHSB:
			return NSColor(calibratedHue: vectors[0], saturation: vectors[1], brightness: vectors[2], alpha: vectors[3])
		case .colorCMYK:
			return NSColor(deviceCyan: vectors[0], magenta: vectors[1], yellow: vectors[2], black: vectors[3], alpha: vectors[4])
		case .edgeInsets:
			return NSEdgeInsets(top: vectors[0], left: vectors[1], bottom: vectors[2], right: vectors[3])
#else
		case .colorRGB:
			return UIColor(red: vectors[0], green: vectors[1], blue: vectors[2], alpha: vectors[3])
		case .colorMonochrome:
			return UIColor(white: vectors[0], alpha: vectors[1])
		case .colorHSB:
			return UIColor(hue: vectors[0], saturation: vectors[1], brightness: vectors[2], alpha: vectors[3])
		case .edgeInsets:
			return UIEdgeInsets(top: vectors[0], left: vectors[1], bottom: vectors[2], right: vectors[3])
#endif
		}
	}
}
