import UIKit
import SwiftBox

public class BoxNode: ViewNode<BoxView> {
  private lazy var children = [Node]()

  override init() {
    super.init()
  }
}

extension BoxNode: ContainerNode {
  public func add(child: Node) {
    children.append(child)

    guard let boxView = view as? BoxView else { return }

    boxView.add(view: child.view)
  }
}

public class BoxView: View {
  public static var propertyTypes: [String : Validator] {
    return [
      "flexDirection": Validation.flexDirection()
    ]
  }

  public weak var propertyProvider: PropertyProvider?

  public var calculatedFrame: CGRect?

  public var flexDirection: FlexDirection? {
    return propertyProvider?.get("flexDirection")
  }

  public var flex: CGFloat? {
    return propertyProvider?.get("flex")
  }

  private lazy var renderedView = UIView()
  private lazy var children = [View]()

  public required init() {}

  func add(view: View) {
    children.append(view)
  }

  public func render() -> UIView {
    // TODO(mcudich): Diff and be smarter about touching the UI tree here.
    for child in children {
      let childView = child.render()
      childView.frame = child.calculatedFrame ?? CGRect.zero
      renderedView.addSubview(childView)
    }

    return renderedView
  }

  public func sizeThatFits(_ size: CGSize) -> CGSize {
    let layout = flexNode.layout(withMaxWidth: size.width)

    apply(layout: layout)

    return layout.frame.size
  }

  private func apply(layout: Layout) {
    for (index, layout) in layout.children.enumerated() {
      let child = children[index]
      child.calculatedFrame = layout.frame
      if let child = child as? BoxView {
        child.apply(layout: layout)
      }
    }
  }
}

public enum FlexDirection {
  case row
  case column

  var value: SwiftBox.Direction {
    switch self {
    case .column:
      return SwiftBox.Direction.column
    case .row:
      return SwiftBox.Direction.row
    }
  }
}

typealias FlexNode = SwiftBox.Node

extension View {
  var flexSize: CGSize {
    let resolve: ((CGFloat?) -> CGFloat) = { value in
      if let value = value, !value.isNaN {
        return value
      }
      return FlexNode.Undefined
    }

    let width: CGFloat? = resolve(propertyProvider?.get("width"))
    let height: CGFloat? = resolve(propertyProvider?.get("height"))

    return CGSize(width: width ?? FlexNode.Undefined, height: height ?? FlexNode.Undefined)
  }
}

protocol FlexNodeProvider {
  var flexNode: FlexNode { get }
}

extension BoxView: FlexNodeProvider {
  var flexNode: FlexNode {
    let flexNodes: [FlexNode] = children.map {
      guard let flexNodeProvider = $0 as? FlexNodeProvider else {
        fatalError("Child in a Box node must implement the FlexNodeProvider protocol")
      }

      return flexNodeProvider.flexNode
    }
    return FlexNode(size: flexSize, children: flexNodes, direction: flexDirection?.value ?? .row, margin: Edges(), padding: Edges(), wrap: false, justification: .flexStart, selfAlignment: .auto, childAlignment: .stretch, flex: flex ?? 0)
  }
}

extension TextView: FlexNodeProvider {
  var flexNode: FlexNode {
    let measure: ((CGFloat) -> CGSize) = { [weak self] width in
      let effectiveWidth = width.isNaN ? CGFloat.greatestFiniteMagnitude : width
      return self?.sizeThatFits(CGSize(width: effectiveWidth, height: CGFloat.greatestFiniteMagnitude)) ?? CGSize.zero
    }
    return FlexNode(measure: measure)
  }
}

extension ImageView: FlexNodeProvider {
  var flexNode: FlexNode {
    return FlexNode(size: flexSize)
  }
}
