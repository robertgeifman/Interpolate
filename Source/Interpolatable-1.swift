//
//  Interpolatable.swift
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
import SceneKit

/// Interpolatable protocol. Requires implementation of a vectorize function.
public protocol Interpolatable {
	 /// Vectorizes the type and returns and IPValue
	func vectorize() -> IPValue
}

/// Supported interpolatable types.
public enum InterpolatableType: Int {
	case caTransform3D
	case cgAffineTransform
	case cgFloat
	case cgPoint
	case cgRect
	case cgSize
	case cgVector
	case colorHSB
	case colorMonochrome
	case colorRGB
	case range
	case integer
	case edgeInsets
	case scnVector3
	case scnVector4
#if !os(macOS)
	case offset
#endif
	case nsNumber
	case double
	case float
}

extension CATransform3D: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .caTransform3D, vectors: [
			m11, m12, m13, m14,
			m21, m22, m23, m24,
			m31, m32, m33, m34,
			m41, m42, m43, m44])
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

extension CGVector: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .cgVector, vectors: [dx, dy])
	}
}

extension SCNVector3: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .scnVector3, vectors: [x, y, z])
	}
}

extension SCNVector4: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .scnVector4, vectors: [x, y, z, w])
	}
}

extension NSRange: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .range, vectors: [CGFloat(location), CGFloat(length)])
	}
}

extension Int: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .integer, vectors: [CGFloat(self)])
	}
}

extension Double: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .double, vectors: [CGFloat(self)])
	}
}

extension Float: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .float, vectors: [CGFloat(self)])
	}
}

extension NSNumber: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .nsNumber, vectors: [CGFloat(truncating: self)])
	}
}

extension CGColor: Interpolatable {
	public func vectorize() -> IPValue {
		if let colorSpace = colorSpace, colorSpace.model == .rgb, let components = components {
			return IPValue(type: .colorRGB, vectors: components)
		} else if let colorSpace = colorSpace, colorSpace.model == .monochrome, let components = components {
			return IPValue(type: .colorMonochrome, vectors: components)
		}

		fatalError("Error vectorizing CGColor \(self)")
	}
}

#if os(macOS)
extension NSColor: Interpolatable {
	public func vectorize() -> IPValue {
		if colorSpace.colorSpaceModel == .rgb {
			var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0

			getRed(&red, green: &green, blue: &blue, alpha: &alpha)
			return IPValue(type: .colorRGB, vectors: [red, green, blue, alpha])
		} else if colorSpace.colorSpaceModel == .gray {
			var white: CGFloat = 0, alpha: CGFloat = 0

			getWhite(&white, alpha: &alpha)
			return IPValue(type: .colorMonochrome, vectors: [white, alpha])
		}
		
		fatalError("Error vectorizing NSColor \(self)")
	}
}

extension NSEdgeInsets: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .edgeInsets, vectors: [top, left, bottom, right])
	}
}
#else
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

extension UIOffset: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .offset, vectors: [horizontal, vertical])
	}
}
#endif //

/// IPValue class. Contains a vectorized version of an Interpolatable type.
final public class IPValue {
	let type: InterpolatableType
	final var vectors: [CGFloat]

	public init(value: IPValue) {
		self.vectors = value.vectors
		self.type = value.type
	}

	public init (type: InterpolatableType, vectors: [CGFloat]) {
		self.vectors = vectors
		self.type = type
	}

	final public func toInterpolatable() -> Interpolatable {
		switch type {
		case .caTransform3D: return CATransform3D(
			m11: vectors[0], m12: vectors[1], m13: vectors[2], m14: vectors[3],
			m21: vectors[4], m22: vectors[5], m23: vectors[6], m24: vectors[7],
			m31: vectors[8], m32: vectors[9], m33: vectors[10], m34: vectors[11],
			m41: vectors[12], m42: vectors[13], m43: vectors[14], m44: vectors[15])
		case .cgAffineTransform: return CGAffineTransform(
			a: vectors[0], b: vectors[1],
			c: vectors[2], d: vectors[3],
			tx: vectors[4], ty: vectors[5])
		case .cgFloat: return vectors[0]
		case .cgPoint: return CGPoint(x: vectors[0], y: vectors[1])
		case .cgRect: return CGRect(x: vectors[0], y: vectors[1], width: vectors[2], height: vectors[3])
		case .cgSize: return CGSize(width: vectors[0], height: vectors[1])
		case .cgVector: return CGVector(dx: vectors[0], dy: vectors[1])
		case .range: return NSRange(location: Int(vectors[0]), length: Int(vectors[1]))
		case .nsNumber: return NSNumber(value: Double(vectors[0]))
		case .double: return Double(vectors[0])
		case .float: return Float(vectors[0])
		case .integer: return Int(vectors[0])
#if os(macOS)
		case .colorRGB: return NSColor(red: vectors[0], green: vectors[1], blue: vectors[2], alpha: vectors[3])
		case .colorMonochrome: return NSColor(white: vectors[0], alpha: vectors[1])
		case .colorHSB: return NSColor(hue: vectors[0], saturation: vectors[1], brightness: vectors[2], alpha: vectors[3])
		case .edgeInsets: return NSEdgeInsets(top: vectors[0], left: vectors[1], bottom: vectors[2], right: vectors[3])
#else
		case .colorRGB: return UIColor(red: vectors[0], green: vectors[1], blue: vectors[2], alpha: vectors[3])
		case .colorMonochrome: return UIColor(white: vectors[0], alpha: vectors[1])
		case .colorHSB: return UIColor(hue: vectors[0], saturation: vectors[1], brightness: vectors[2], alpha: vectors[3])
		case .edgeInsets: return UIEdgeInsets(top: vectors[0], left: vectors[1], bottom: vectors[2], right: vectors[3])
		case .offset: return UIOffset(horizontal: vectors[0], vertical: vectors[1])
#endif // os(macOS)
		case .scnVector3: return SCNVector3(x: vectors[0], y: vectors[1], z: vectors[2])
		case .scnVector4: return SCNVector4(x: vectors[0], y: vectors[1], z: vectors[2], w: vectors[4])
		}
	}
}
