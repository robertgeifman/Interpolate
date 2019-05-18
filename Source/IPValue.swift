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

	final public func toInterpolatable() -> Interpolatable? {
		switch type {
		case .nil: return nil
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
		case let .color(colorModel):
			switch colorModel {
#if os(macOS)
			case .cmyk: return Color(deviceCyan: vectors[0], magenta: vectors[1], yellow: vectors[2], black: vectors[3], alpha: vectors[4])
#endif // os(macOS)
			case .hsb: fallthrough
			default: return Color(hue: vectors[0], saturation: vectors[1], brightness: vectors[2], alpha: vectors[3])
			}
		case .edgeInsets: return EdgeInsets(top: vectors[0], left: vectors[1], bottom: vectors[2], right: vectors[3])
		case .offset: return Offset(horizontal: vectors[0], vertical: vectors[1])
		case .scnVector3: return SCNVector3(x: vectors[0], y: vectors[1], z: vectors[2])
		case .scnVector4: return SCNVector4(x: vectors[0], y: vectors[1], z: vectors[2], w: vectors[4])
		}
	}
}
