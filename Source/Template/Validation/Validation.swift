//
//  Validation.swift
//  TemplateKit
//
//  Created by Matias Cudich on 8/10/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import Foundation

public protocol ValidationType {
  func validate(value: Any?) -> Any?
}

public enum Validation: String, ValidationType {
  case string
  case float
  case integer
  case boolean
  case url
  case color
  case selector
  case any

  public func validate(value: Any?) -> Any? {
    switch self {
    case .string:
      if value is String {
        return value
      }
    case .float:
      if value is CGFloat || value is Float {
        return value
      }
      if let stringValue = value as? String {
        return stringValue.float
      }
    case .integer:
      if value is Integer {
        return value
      }
      if let stringValue = value as? String {
        return stringValue.integer
      }
    case .boolean:
      if value is Bool {
        return value
      }
      if let stringValue = value as? String {
        return stringValue.boolean
      }
    case .url:
      if value is URL {
        return value
      }
      if let stringValue = value as? String {
        return stringValue.url
      }
    case .color:
      if value is UIColor {
        return value
      }
      if let stringValue = value as? String {
        return stringValue.color
      }
    case .selector:
      if value is Selector {
        return value
      }
      if let stringValue = value as? String {
        return Selector(stringValue)
      }
    case .any:
      return value
    }

    if value != nil {
      fatalError("Unhandled type!")
    }

    return nil
  }

  static func validate(propertyTypes: [String: ValidationType], properties: [String: Any]) -> [String: Any] {
    var sanitized = [String: Any]()
    for (key, rule) in propertyTypes {
      sanitized[key] = rule.validate(value: properties[key])
    }
    return sanitized
  }
}
