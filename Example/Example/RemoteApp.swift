//
//  RemoteApp.swift
//  Example
//
//  Created by Matias Cudich on 9/8/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import Foundation
import TemplateKit

class RemoteApp: Component {
  static let location = URL(string: "http://localhost:8000/App.xml")!
  public weak var owner: Component?
  public var currentInstance: Node?
  public var currentElement: Element?
  public var properties: [String : Any]
  public var state: Any? = State()
  public var context: Context?

  fileprivate var todoCount = 0

  struct State {
    var counter = 0
    var showCounter = false
    var flipped = false
  }

  private var appState: State {
    get {
      return state as! State
    }
    set {
      state = newValue
    }
  }

  required init(properties: [String : Any], owner: Component?) {
    self.properties = properties
    self.owner = owner
  }

  func render() -> Element {
    let context = getContext()
    return try! context.templateService.element(withLocation: RemoteApp.location, properties: ["width": Float(320), "height": Float(568), "count": "\(appState.counter)", "incrementCounter": #selector(RemoteApp.incrementCounter)])
  }

  @objc func incrementCounter() {
    updateState {
      appState.counter += 1
      return appState
    }
  }
}
