//
//  TemplateTests.swift
//  TemplateKit
//
//  Created by Matias Cudich on 9/27/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import XCTest
@testable import TemplateKit

struct FakeModel: Model {}

class TemplateTests: XCTestCase {
  func testParseTemplate() {
    let template = Bundle(for: TemplateTests.self).url(forResource: "SimpleTemplate", withExtension: "xml")!
    let xmlTemplate = try! XMLDocumentParser(data: Data(contentsOf: template)).parse()
    let styleSheet = StyleSheet(string: xmlTemplate.styleElements.first!.value!)
    let parsed = Template(elementProvider: xmlTemplate.componentElement!, styleSheet: styleSheet)
    let element = try! parsed.makeElement(with: FakeModel()) as! ElementData<DefaultProperties>
    XCTAssertEqual(UIColor.red, element.properties.core.style.backgroundColor)
  }
}
