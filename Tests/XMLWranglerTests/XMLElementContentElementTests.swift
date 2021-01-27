import XCTest
@testable import XMLWrangler

final class XMLElementContentElementTests: XCTestCase {
    func testExpressibleByStringLiteral() {
        let content1: XWElement.Content.Element = "test"
        if case .string(let str) = content1 {
            XCTAssertEqual(str, "test")
        } else {
            XCTFail("Content is not string!")
        }
    }

    func testAppendingString() {
        var content: XWElement.Content = []
        var content2: XWElement.Content = ["hello"]

        content.appendString("_this")
        content2.appendString(" world")

        XCTAssertEqual(content, [.string("_this")])
        XCTAssertEqual(content2, [.string("hello world")])
    }

    @available(*, deprecated)
    func testAppendingString_Deprecated() {
        var content: XWElement.Content = []
        var content2: XWElement.Content = ["hello"]

        content.append(string: "_this")
        content2.append(string: " world")

        XCTAssertEqual(content, [.string("_this")])
        XCTAssertEqual(content2, [.string("hello world")])
    }

    func testAppendingObject() {
        var content: XWElement.Content = []
        let child = XWElement(name: "_this")

        content.appendElement(child)

        XCTAssertEqual(content, [.element(child)])
    }

    @available(*, deprecated)
    func testAppendingObject_Deprecated() {
        var content: XWElement.Content = []
        let child = XWElement(name: "_this")

        content.append(element: child)

        XCTAssertEqual(content, [.element(child)])
    }

    func testAppendingContentOfSequence() {
        var content: XWElement.Content = []
        let child1 = XWElement(name: "one1")
        let child2 = XWElement(name: "two2")
        let child3 = XWElement(name: "three3")

        content.append(contentsOf: [child1, child2, child3])

        XCTAssertEqual(content, [.element(child1), .element(child2), .element(child3)])
    }

    func testAppendingElements() {
        var content: XWElement.Content = []
        let child1 = XWElement(name: "abc1")
        let child2 = XWElement(name: "def2")
        let child3 = XWElement(name: "ghi3")

        content.appendElements(child1, child2, child3)

        XCTAssertEqual(content, [.element(child1), .element(child2), .element(child3)])
    }

    @available(*, deprecated)
    func testAppendingElements_Deprecated() {
        var content: XWElement.Content = []
        let child1 = XWElement(name: "abc1")
        let child2 = XWElement(name: "def2")
        let child3 = XWElement(name: "ghi3")

        content.append(elements: child1, child2, child3)

        XCTAssertEqual(content, [.element(child1), .element(child2), .element(child3)])
    }

    func testCompression() {
        var content1: XWElement.Content = [
            .string("ABC"),
            .string("DEF"),
            .element(XWElement(name: "elem1")),
            .element(XWElement(name: "elem2")),
            .string("GHI"),
            .element(XWElement(name: "elem3")),
            .string("JKL"),
            .string("MNO"),
        ]
        let expectedContent1: XWElement.Content = [
            .string("ABCDEF"),
            .element(XWElement(name: "elem1")),
            .element(XWElement(name: "elem2")),
            .string("GHI"),
            .element(XWElement(name: "elem3")),
            .string("JKLMNO"),
        ]

        var content2: XWElement.Content = [
            .string("AB"),
            .string("CD"),
            .element(XWElement(name: "e1")),
            .element(XWElement(name: "e2")),
            .element(XWElement(name: "e3")),
            .string("EF"),
            .element(XWElement(name: "e4")),
            .element(XWElement(name: "e5")),
            .string("GH"),
            .string("IJ"),
            .string("KL"),
            .element(XWElement(name: "e6")),
            .element(XWElement(name: "e7")),
        ]
        let expectedContent2: XWElement.Content = [
            .string("ABCD"),
            .element(XWElement(name: "e1")),
            .element(XWElement(name: "e2")),
            .element(XWElement(name: "e3")),
            .string("EF"),
            .element(XWElement(name: "e4")),
            .element(XWElement(name: "e5")),
            .string("GHIJKL"),
            .element(XWElement(name: "e6")),
            .element(XWElement(name: "e7")),
        ]

        let compressed1 = content1.compressed()
        content1.compress()
        let compressed2 = content2.compressed()
        content2.compress()

        XCTAssertEqual(content1, expectedContent1)
        XCTAssertEqual(content2, expectedContent2)
        XCTAssertEqual(content1, compressed1)
        XCTAssertEqual(content2, compressed2)
    }

    func testInternalHelpers() {
        let strContent = XWElement.Content.Element.string("ABC")
        let elemtContent = XWElement.Content.Element.element(XWElement(name: "some_element"))

        XCTAssertTrue(strContent.isString)
        XCTAssertFalse(strContent.isElement)
        XCTAssertEqual(strContent.string, "ABC")
        XCTAssertNil(strContent.element)
        XCTAssertFalse(elemtContent.isString)
        XCTAssertTrue(elemtContent.isElement)
        XCTAssertNil(elemtContent.string)
        XCTAssertEqual(elemtContent.element, XWElement(name: "some_element"))
    }
}
