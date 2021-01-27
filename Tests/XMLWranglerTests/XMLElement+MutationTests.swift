import XCTest
@testable import XMLWrangler

fileprivate extension XWElement.Content.Element {
    var _element: XWElement! {
        get { element }
        set { self = .element(newValue) }
    }
}

final class XMLElement_MutationTests: XCTestCase {
    private var sut: XWElement!
    
    override func setUp() {
        super.setUp()
        sut = XWElement(name: "Root",
                        elements: [
                            XWElement(name: "Child1", attributes: ["some": "value"], elements: XWElement(name: "Child1.1")),
                            XWElement(name: "Child2", elements: XWElement(name: "Child2.1", attributes: [.init("other"): "value"])),
                        ])
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testAppendingString() {
        var element = XWElement(name: "s")
        var element2 = XWElement(name: "test2", stringContent: "hello")

        element.appendString("_this")
        element2.appendString(" world")

        XCTAssertEqual(element.content, [.string("_this")])
        XCTAssertEqual(element2.content, [.string("hello world")])
    }

    @available(*, deprecated)
    func testAppendingString_Deprecated() {
        var element = XWElement(name: "s")
        var element2 = XWElement(name: "test2", stringContent: "hello")

        element.append(string: "_this")
        element2.append(string: " world")

        XCTAssertEqual(element.content, [.string("_this")])
        XCTAssertEqual(element2.content, [.string("hello world")])
    }

    func testAppendingElement() {
        var element = XWElement(name: "x")
        let child = XWElement(name: "_this")
        element.appendElement(child)
        XCTAssertEqual(element.content, [.element(child)])
    }

    @available(*, deprecated)
    func testAppendingElement_Deprecated() {
        var element = XWElement(name: "x")
        let child = XWElement(name: "_this")
        element.append(element: child)
        XCTAssertEqual(element.content, [.element(child)])
    }

    func testAppendingElementConvertible() {
        struct Convertible: XMLElementConvertible {
            let xml: XWElement
        }
        var element = XWElement(name: "base")
        let child = XWElement(name: "child")
        element.append(elementOf: Convertible(xml: child))
        XCTAssertEqual(element.content, [.element(child)])
    }

    func testAppendingContentOfSequence() {
        var element = XWElement(name: "a")
        let child1 = XWElement(name: "_this1")
        let child2 = XWElement(name: "_this2")
        let child3 = XWElement(name: "_this3")

        element.append(contentsOf: [child1, child2, child3])

        XCTAssertEqual(element.content, [.element(child1), .element(child2), .element(child3)])
    }

    func testAppendingElements() {
        var element = XWElement(name: "b")
        let child1 = XWElement(name: "_this1")
        let child2 = XWElement(name: "_this2")
        let child3 = XWElement(name: "_this3")

        element.appendElements(child1, child2, child3)

        XCTAssertEqual(element.content, [.element(child1), .element(child2), .element(child3)])
    }

    @available(*, deprecated)
    func testAppendingElements_Deprecated() {
        var element = XWElement(name: "b")
        let child1 = XWElement(name: "_this1")
        let child2 = XWElement(name: "_this2")
        let child3 = XWElement(name: "_this3")

        element.append(elements: child1, child2, child3)

        XCTAssertEqual(element.content, [.element(child1), .element(child2), .element(child3)])
    }
    
    func testMutatingAccessToElementAtInvalidPathThrows() {
        XCTAssertThrowsError(try sut.withMutatingAccess(toElementAt: "Child1", "InexistentChild", do: { _ in XCTFail("Should not be called!") })) {
            XCTAssert($0, is: .missingChild(element: sut.content[0]._element, childName: "InexistentChild"))
        }
    }
    
    func testMutatingAccessToElementAtPath() throws {
        var expectedResult: XWElement = sut
        expectedResult.content[0]._element.content[0]._element.appendElement(XWElement(name: "TestMutating"))
        try sut.withMutatingAccess(toElementAt: ["Child1", "Child1.1"], do: { $0.appendElement(XWElement(name: "TestMutating")) })
        XCTAssertEqual(sut, expectedResult)
    }
    
    func testMutatingAccessToElementAtVariadicPath() throws {
        var expectedResult: XWElement = sut
        expectedResult.content[0]._element.content[0]._element.appendElement(XWElement(name: "TestVariadicMutating"))
        try sut.withMutatingAccess(toElementAt: "Child1", "Child1.1", do: { $0.appendElement(XWElement(name: "TestVariadicMutating")) })
        XCTAssertEqual(sut, expectedResult)
    }
    
    func testReplacingElementAtPath() throws {
        let oldElement = sut.content[0]._element.content[0]._element
        var expectedResult: XWElement = sut
        expectedResult.content[0]._element.content[0]._element = XWElement(name: "Test")
        let replacedElement = try sut.replace(elementAt: ["Child1", "Child1.1"], with: XWElement(name: "Test"))
        XCTAssertEqual(sut, expectedResult)
        XCTAssertEqual(replacedElement, oldElement)
    }
    
    func testReplacingElementAtVariadicPath() throws {
        let oldElement = sut.content[0]._element.content[0]._element
        var expectedResult: XWElement = sut
        expectedResult.content[0]._element.content[0]._element = XWElement(name: "TestVariadic")
        let replacedElement = try sut.replace(elementAt: "Child1", "Child1.1", with: XWElement(name: "TestVariadic"))
        XCTAssertEqual(sut, expectedResult)
        XCTAssertEqual(replacedElement, oldElement)
    }
    
    func testRemovingElementAtEmptyPath() {
        XCTAssertNil(try sut.remove(elementAt: []))
    }
    
    func testRemovingInexistentElementAtPath() {
        XCTAssertNil(try sut.remove(elementAt: ["Child1", "DoesNotExist"]))
    }
    
    func testRemovingElementAtPath() throws {
        var expectedResult: XWElement = sut
        let expectedReturnValue = expectedResult.content[0]._element.content.remove(at: 0)._element
        let removed = try sut.remove(elementAt: ["Child1", "Child1.1"])
        XCTAssertEqual(sut, expectedResult)
        XCTAssertEqual(removed, expectedReturnValue)
    }
    
    func testRemovingElementAtVariadicPath() throws {
        var expectedResult: XWElement = sut
        let expectedReturnValue = expectedResult.content[0]._element.content.remove(at: 0)._element
        let removed = try sut.remove(elementAt: "Child1", "Child1.1")
        XCTAssertEqual(sut, expectedResult)
        XCTAssertEqual(removed, expectedReturnValue)
    }
}
