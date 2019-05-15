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

////////////////////////////////////////////////////////////
/// Interpolatable protocol. Requires implementation of a vectorize function.
public protocol Interpolatable {
	 /// Vectorizes the type and returns and IPValue
	func vectorize() -> IPValue
}

/// Supported interpolatable types.
public enum InterpolatableType {
	public enum ColorModel {
	case monochrome, rgb, hsb
#if os(macOS)
	// case cmyk
#endif
	}
	case integer
	case float
	case double
	case number
	case offset
	case edgeInsets
	case point
	case size
	case rect
	case vector
	case range
	case transform3D
	case affineTransform
	case scnVector3
	case scnVector4
	case color(ColorModel)
}

extension CATransform3D: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .transform3D, vectors: [
			m11, m12, m13, m14,
			m21, m22, m23, m24,
			m31, m32, m33, m34,
			m41, m42, m43, m44])
	}
}

extension CGAffineTransform: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .affineTransform, vectors: [a, b, c, d, tx, ty])
	}
}

extension CGFloat: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .float, vectors: [self])
	}
}

extension CGPoint: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .point, vectors: [x, y])
	}
}

extension CGRect: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .rect, vectors: [origin.x, origin.y, size.width, size.height])
	}
}

extension CGSize: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .size, vectors: [width, height])
	}
}

extension CGVector: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .vector, vectors: [dx, dy])
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

extension CFRange: Interpolatable {
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
		return IPValue(type: .number, vectors: [CGFloat(truncating: self)])
	}
}

////////////////////////////////////////////////////////////
// MARK:- EdgeInsets
extension EdgeInsets: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .edgeInsets, vectors: [top, left, bottom, right])
	}
}

extension Offset: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .offset, vectors: [horizontal, vertical])
	}
}

////////////////////////////////////////////////////////////
// MARK:- Color
extension CGColor: Interpolatable {
	public func vectorize(using colorModel: InterpolatableType.ColorModel) -> IPValue {
		if let colorSpace = colorSpace, colorSpace.model == .rgb, let components = components {
			return IPValue(type: .color(.rgb), vectors: components)
		} else if let colorSpace = colorSpace, colorSpace.model == .monochrome, let components = components {
			return IPValue(type: .color(.monochrome), vectors: components)
		}

		fatalError("Error vectorizing CGColor \(self)")
	}

	public func vectorize() -> IPValue {
		return vectorize(using: .hsb)
	}
}

#if os(macOS)
extension NSColor: Interpolatable {
	public func vectorize(using colorModel: InterpolatableType.ColorModel) -> IPValue {
		if colorSpace.colorSpaceModel == .rgb {
			var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0

			getRed(&red, green: &green, blue: &blue, alpha: &alpha)
			return IPValue(type: .color(.rgb), vectors: [red, green, blue, alpha])
		} else if colorSpace.colorSpaceModel == .gray {
			var white: CGFloat = 0, alpha: CGFloat = 0

			getWhite(&white, alpha: &alpha)
			return IPValue(type: .color(.monochrome), vectors: [white, alpha])
		}
		
		fatalError("Error vectorizing NSColor \(self)")
	}

	public func vectorize() -> IPValue {
		return vectorize(using: .hsb)
	}
}
#else
extension UIColor: Interpolatable {
	public func vectorize(using colorModel: InterpolatableType.ColorModel) -> IPValue {
		var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
		if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
			return IPValue(type: .color(.rgb), vectors: [red, green, blue, alpha])
		}

		var white: CGFloat = 0
		if getWhite(&white, alpha: &alpha) {
			return IPValue(type: .color(.monochrome), vectors: [white, alpha])
		}

		var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0
		getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

		return IPValue(type: .color(.hsb), vectors: [hue, saturation, brightness, alpha])
	}

	public func vectorize() -> IPValue {
		return vectorize(using: .hsb)
	}
}
#endif

////////////////////////////////////////////////////////////
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
		case .transform3D: return CATransform3D(
			m11: vectors[0], m12: vectors[1], m13: vectors[2], m14: vectors[3],
			m21: vectors[4], m22: vectors[5], m23: vectors[6], m24: vectors[7],
			m31: vectors[8], m32: vectors[9], m33: vectors[10], m34: vectors[11],
			m41: vectors[12], m42: vectors[13], m43: vectors[14], m44: vectors[15])
		case .affineTransform: return CGAffineTransform(
			a: vectors[0], b: vectors[1],
			c: vectors[2], d: vectors[3],
			tx: vectors[4], ty: vectors[5])
		case .float: return vectors[0]
		case .point: return CGPoint(x: vectors[0], y: vectors[1])
		case .rect: return CGRect(x: vectors[0], y: vectors[1], width: vectors[2], height: vectors[3])
		case .size: return CGSize(width: vectors[0], height: vectors[1])
		case .vector: return CGVector(dx: vectors[0], dy: vectors[1])
		case .range: return NSRange(location: Int(vectors[0]), length: Int(vectors[1]))
		case .number: return NSNumber(value: Double(vectors[0]))
		case .double: return Double(vectors[0])
		case .integer: return Int(vectors[0])
#if os(macOS)
		case let .color(colorModel) where colorModel == .rgb: return NSColor(red: vectors[0], green: vectors[1], blue: vectors[2], alpha: vectors[3])
		case let .color(colorModel) where colorModel == .monochrome: return NSColor(white: vectors[0], alpha: vectors[1])
		case let .color(colorModel) where colorModel == .hsb: return NSColor(hue: vectors[0], saturation: vectors[1], brightness: vectors[2], alpha: vectors[3])
#else
		case let .color(colorModel) where colorModel == .rgb: return UIColor(red: vectors[0], green: vectors[1], blue: vectors[2], alpha: vectors[3])
		case let .color(colorModel) where colorModel == .monochrome: return UIColor(white: vectors[0], alpha: vectors[1])
		case let .color(colorModel) where colorModel == .hsb: return UIColor(hue: vectors[0], saturation: vectors[1], brightness: vectors[2], alpha: vectors[3])
#endif // os(macOS)
		case .edgeInsets: return EdgeInsets(top: vectors[0], left: vectors[1], bottom: vectors[2], right: vectors[3])
		case .offset: return Offset(horizontal: vectors[0], vertical: vectors[1])
		case .scnVector3: return SCNVector3(x: vectors[0], y: vectors[1], z: vectors[2])
		case .scnVector4: return SCNVector4(x: vectors[0], y: vectors[1], z: vectors[2], w: vectors[4])
		}
	}
}
