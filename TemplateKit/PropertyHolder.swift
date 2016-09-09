//
//  PropertyHolder.swift
//  TemplateKit
//
//  Created by Matias Cudich on 9/9/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import Foundation

public protocol PropertyHolder {
  var properties: [String: Any] { get set }

  func get<T>(_ key: String) -> T?
}

public extension PropertyHolder {
  public func get<T>(_ key: String) -> T? {
    return properties[key] as? T
  }
}
