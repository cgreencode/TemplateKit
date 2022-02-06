//
//  App.swift
//  Example
//
//  Created by Matias Cudich on 8/31/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import Foundation
import TemplateKit

class App: Node {
  public weak var owner: Node?
  public var currentInstance: BaseNode?
  public var currentElement: Element?
  public var properties: [String : Any]
  public var state: Any? = State()

  struct State {
    var counter = 0
    var showCounter = false
  }

  private var appState: State {
    get {
      return state as! State
    }
    set {
      state = newValue
    }
  }

  required init(properties: [String : Any], owner: Node?) {
    self.properties = properties
    self.owner = owner
  }

  func render() -> Element {
    return Element(ElementType.box, ["width": CGFloat(320), "height": CGFloat(500), "paddingTop": CGFloat(60)], [
      Element(ElementType.text, ["text": "add", "onTap": #selector(App.incrementCounter)]),
      Element(ElementType.text, ["text": "remove", "onTap": #selector(App.decrementCounter)]),
      Element(ElementType.box, [:], getItems())
    ])
  }

  func getItems() -> [Element] {
    return (0..<appState.counter).map {
      return Element(ElementType.text, ["text": "\($0)"])
    }.reversed()
  }

  @objc func incrementCounter() {
    updateState {
      appState.counter += 1
      return appState
    }
  }

  @objc func decrementCounter() {
    updateState {
      appState.counter -= 1
      return appState
    }
  }
}
