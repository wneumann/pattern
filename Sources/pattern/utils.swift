//
//  utils.swift
//  
//
//  Created by William D. Neumann on 5/9/21.
//

import Foundation
enum Utils {
  static func hexToData(_ hexStr: String) -> Data {
    var hex = hexStr.lowercased()[...], result = Data()
    if hex.hasPrefix("0x") { hex = hex.dropFirst(2) }
    if !hex.count.isMultiple(of: 2) { hex = "0" + hex }
    while !hex.isEmpty {
      let prefix = hex.prefix(2)
      hex = hex.dropFirst(2)
      guard let byte = UInt8(prefix, radix: 16) else { fatalError("Invalid hex string, contains \(prefix) which is not hexadecimal.") }
      result.append(byte)
    }
    return result
  }
  
  static func hexToAscii(_ hexStr: String) -> String? {
    let data = hexToData(hexStr)
    return String(data: data, encoding: .ascii)
  }

  static func hexToUTF8(_ hexStr: String) -> String? {
    let data = hexToData(hexStr)
    return String(data: data, encoding: .utf8)
  }
}

