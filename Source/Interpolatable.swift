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

////////////////////////////////////////////////////////////
/// Supported interpolatable types.
public enum InterpolatableType {
	public enum ColorModel {
	case hsb
#if os(macOS)
	case cmyk
#endif // os(macOS)
	}
	case `nil`
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
		return IPValue(type: .scnVector3, vectors: [CGFloat(x), CGFloat(y), CGFloat(z)])
	}
}

extension SCNVector4: Interpolatable {
	public func vectorize() -> IPValue {
		return IPValue(type: .scnVector4, vectors: [CGFloat(x), CGFloat(y), CGFloat(z), CGFloat(w)])
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
extension CGColor {
	// borrowed from GNUStep implementation of NSColor
	public static func rgbFrom(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
		let hue = min(1, max(0, hue))
		let saturation = min(1, max(0, saturation))
		let brightness = min(1, max(0, brightness))

		let intensity = Int(hue * 6)
		let factor = CGFloat(Int(hue * 6) - intensity)
		let m = brightness * (1 - saturation)
		let n = brightness * (1 - saturation * factor)
		let k = m - n + brightness
		switch intensity {
		case 1: return (red: n, green: brightness, blue: m)
		case 2: return (red: m, green: brightness, blue: k)
		case 3: return (red: m, green: n, blue: brightness)
		case 4: return (red: k, green: m, blue: brightness)
		case 5: return (red: brightness, green: m, blue: n)
		default: return (red: brightness, green: k, blue: m)
		}
	}

	public static func rgbFrom(white: CGFloat) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
		return (red: white, green: white, blue: white)
	}

	public static func hsbFrom(red: CGFloat, green: CGFloat, blue: CGFloat) -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
		let r = min(1, max(0, red))
		let g = min(1, max(0, green))
		let b = min(1, max(0, blue))

		if r == g, r == b {
			return (hue: 0, saturation: 0, brightness: r)
		}

		var brightness = (r > g ? r : g)
		brightness = (b > brightness ? b : brightness)
		var temp = (r < g ? r : g)
		temp = (b < temp ? b : temp)
		let diff = brightness - temp

		var hue: CGFloat
		if brightness == r { hue = (g - b)/diff }
		else if brightness == g { hue = (b - r)/diff + 2 }
		else { hue = (r - g)/diff + 4 }

		if hue < 0 { hue += 6 }

		return (hue: hue/6, saturation: diff/brightness, brightness: brightness)
	}

	public static func hsbFrom(white: CGFloat) -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
		return (hue: 0, saturation: 0, brightness: white)
	}

	internal static func hsbComponentsFrom(components: [CGFloat]?) -> [CGFloat]? {
		guard let components = components else { return nil }
		if components.count == 4 {
			let r = min(1, max(0, components[0]))
			let g = min(1, max(0, components[1]))
			let b = min(1, max(0, components[2]))

			if r == g, r == b {
				return [0, 0, r, components[3]]
			}

			var brightness = (r > g ? r : g)
			brightness = (b > brightness ? b : brightness)
			var temp = (r < g ? r : g)
			temp = (b < temp ? b : temp)
			let diff = brightness - temp

			var hue: CGFloat
			if brightness == r { hue = (g - b)/diff }
			else if brightness == g { hue = (b - r)/diff + 2 }
			else { hue = (r - g)/diff + 4 }

			if hue < 0 { hue += 6 }

			return [hue/6, diff/brightness, brightness, components[3]]
		} else if components.count == 2 {
			return [0, 0, components[0], components[1]]
		}
		return nil
	}

	public func vectorize() -> IPValue {
		if let colorSpace = colorSpace {
			if colorSpace.model == .rgb || colorSpace.model == .monochrome {
				if let hsb = CGColor.hsbComponentsFrom(components: components) {
					return IPValue(type: .color(.hsb), vectors: hsb)
				}
			}
#if os(macOS)
			if colorSpace.model == .cmyk, let cmyk = components {
				return IPValue(type: .color(.cmyk), vectors: cmyk)
			}
#endif
		}
		assertionFailure("Error vectorizing CGolor \(self)")
		return IPValue(type: .color(.hsb), vectors: [0, 1, 1, 0.5]) // returning red 50% transparent color for debugging purposes
	}
}

extension Color: Interpolatable {
	public func vectorize() -> IPValue {
		var components = [CGFloat](repeating: 0, count: numberOfComponents)
		getComponents(&components)
		if colorSpace.colorSpaceModel == .rgb || colorSpace.colorSpaceModel == .gray,
			let hsb = CGColor.hsbComponentsFrom(components: components) {
			return IPValue(type: .color(.hsb), vectors: hsb)
		} else if colorSpace.colorSpaceModel == .cmyk {
			return IPValue(type: .color(.cmyk), vectors: components)
		}
		assertionFailure("Error vectorizing NSColor \(self)")
		return IPValue(type: .color(.hsb), vectors: [0, 1, 1, 0.5]) // returning red 50% transparent color for debugging purposes
	}
}
