import XCTest
@testable import XMLWrangler

final class XMLElementContent_LookupTests: XCTestCase {
    func testAllElementsAndAllStrings() {
        let content: XWElement.Content = [
            "abc",
            .element(.init(name: "test")),
            "def",
            .element(.init(name: "test2")),
        ]
        XCTAssertEqual(content.allElements, [.init(name: "test"), .init(name: "test2")])
        XCTAssertEqual(content.allStrings, ["abc", "def"])
    }

    func testFindingObjectsShallow() {
        let string: XWElement.Content = [.string("testStr")]
        let source: XWElement.Content = [
            .element(XWElement(name: "test")),
            .element(XWElement(name: "no_test_something")),
            .element(XWElement(name: "whatever")),
            .element(XWElement(name: "test")),
            .element(XWElement(name: "is")),
            .element(XWElement(name: "hereNot")),
            .element(XWElement(name: "no_test_something")),
        ]

        let stringResult = string.find(elementsNamed: "something")
        let cannotFind = source.find(elementsNamed: "not_existent")
        let testResult = source.find(elementsNamed: "test")
        let whateverResult = source.find(elementsNamed: "whatever")

        XCTAssertTrue(stringResult.isEmpty)
        XCTAssertTrue(cannotFind.isEmpty)
        XCTAssertEqual(testResult.count, 2)
        XCTAssertEqual(whateverResult.count, 1)
        XCTAssertEqual(testResult, [XWElement(name: "test"), XWElement(name: "test")])
        XCTAssertEqual(whateverResult, [XWElement(name: "whatever")])
    }

    func testFindingFirstObjectShallow() {
        let string: XWElement.Content = [.string("testStr")]
        let source: XWElement.Content = [
            .element(XWElement(name: "test", content: "value")),
            .element(XWElement(name: "test_something")),
            .element(XWElement(name: "whatever")),
            .element(XWElement(name: "test")),
            .element(XWElement(name: "is")),
            .element(XWElement(name: "here")),
            .element(XWElement(name: "test_something")),
        ]

        let stringResult = string.findFirst(elementNamed: "something")
        let cannotFind = source.findFirst(elementNamed: "not_existent")
        let testResult = source.findFirst(elementNamed: "test")
        let whateverResult = source.findFirst(elementNamed: "whatever")

        XCTAssertNil(stringResult)
        XCTAssertNil(cannotFind)
        XCTAssertNotNil(testResult)
        XCTAssertNotNil(whateverResult)
        XCTAssertEqual(testResult?.content, ["value"])
        XCTAssertTrue(whateverResult?.content.isEmpty ?? false)
    }

    func testFindingLastObjectShallow() {
        let string: XWElement.Content = [.string("testStr")]
        let source: XWElement.Content = [
            .element(XWElement(name: "test")),
            .element(XWElement(name: "test_something")),
            .element(XWElement(name: "whatever")),
            .element(XWElement(name: "test", content: "value")),
            .element(XWElement(name: "is")),
            .element(XWElement(name: "here")),
            .element(XWElement(name: "test_something")),
        ]

        let stringResult = string.findLast(elementNamed: "something")
        let cannotFind = source.findLast(elementNamed: "not_existent")
        let testResult = source.findLast(elementNamed: "test")
        let whateverResult = source.findLast(elementNamed: "whatever")

        XCTAssertNil(stringResult)
        XCTAssertNil(cannotFind)
        XCTAssertNotNil(testResult)
        XCTAssertNotNil(whateverResult)
        XCTAssertEqual(testResult?.content, ["value"])
        XCTAssertTrue(whateverResult?.content.isEmpty ?? false)
    }

    func testFindingObjectsRecursive() {
        let string: XWElement.Content = [.string("testStr")]
        let source: XWElement.Content = [
            .element(XWElement(name: "test_something",
                               attributes: ["some": "is"],
                               elements: XWElement(name: "test", content: "value"))),
            .element(XWElement(name: "test_it")),
            .element(XWElement(name: "is", elements: [
                XWElement(name: "add", elements: [
                    XWElement(name: "some", elements: [
                        XWElement(name: "deeper"),
                        XWElement(name: "levels", elements: [
                            XWElement(name: "deeper"),
                            XWElement(name: "can this work"),
                            XWElement(name: "whatever"),
                        ]),
                    ]),
                    XWElement(name: "test"),
                    XWElement(name: "deeper"),
                ]),
                XWElement(name: "deeper"),
            ])),
            .element(XWElement(name: "here")),
            .element(XWElement(name: "test_something")),
        ]

        let stringResult = string.find(elementsNamed: "something", recursive: true)
        let cannotFind = source.find(elementsNamed: "not_existent", recursive: true)
        let testResult = source.find(elementsNamed: "test", recursive: true)
        let whateverResult = source.find(elementsNamed: "whatever", recursive: true)

        XCTAssertTrue(stringResult.isEmpty)
        XCTAssertTrue(cannotFind.isEmpty)
        XCTAssertEqual(testResult.count, 2)
        XCTAssertEqual(whateverResult.count, 1)
        XCTAssertEqual(testResult, [XWElement(name: "test", content: "value"), XWElement(name: "test")])
        XCTAssertEqual(whateverResult, [XWElement(name: "whatever")])
    }

    func testFindingFirstObjectRecursive() {
        let string: XWElement.Content = [.string("some_string")]
        let source: XWElement.Content = [
            .element(XWElement(name: "test_something",
                               elements: XWElement(name: "test",
                                                   attributes: ["is": "not"],
                                                   content: "value"))),
            .element(XWElement(name: "test_it")),
            .element(XWElement(name: "is", elements: [
                XWElement(name: "add_that", elements: [
                    XWElement(name: "to_some", elements: [
                        XWElement(name: "deeper"),
                        XWElement(name: "levels", elements: [
                            XWElement(name: "deeper_and"),
                            XWElement(name: "whatever", content: "this is deep down"),
                        ]),
                    ]),
                    XWElement(name: "test"),
                    XWElement(name: "deeper again"),
                    XWElement(name: "whatever", content: "not so deep"),
                    XWElement(name: "deeper"),
                ]),
                XWElement(name: "deeper again"),
                XWElement(name: "deeper"),
            ])),
            .element(XWElement(name: "here_is")),
            .element(XWElement(name: "test_something")),
        ]

        let stringResult = string.findFirst(elementNamed: .init("something"), recursive: true)
        let cannotFind = source.findFirst(elementNamed: "not_existent", recursive: true)
        let testResult = source.findFirst(elementNamed: "test", recursive: true)
        let whateverResult = source.findFirst(elementNamed: "whatever", recursive: true)

        XCTAssertNil(stringResult)
        XCTAssertNil(cannotFind)
        XCTAssertNotNil(testResult)
        XCTAssertNotNil(whateverResult)
        XCTAssertEqual(testResult?.content, ["value"])
        // Make sure we only recurse lazily. We don't want to go into the deepest abyss if we can stay in shallower waters.
        XCTAssertEqual(whateverResult?.content, ["not so deep"])
    }

    func testFindingLastObjectRecursive() {
        let string: XWElement.Content = [.string("testStr")]
        let source: XWElement.Content = [
            .element(XWElement(name: "test_something",
                               elements: XWElement(name: "test", content: "value"))),
            .element(XWElement(name: "test_it")),
            .element(XWElement(name: "is", elements: [
                XWElement(name: "add", elements: [
                    XWElement(name: "some", elements: [
                        XWElement(name: "deeper", attributes: ["again": "here"]),
                        XWElement(name: "levels", elements: [
                            XWElement(name: "deeper"),
                            XWElement(name: "whatever", content: "deep down no one reaches"),
                        ]),
                    ]),
                    XWElement(name: "whatever", content: "not so deep"),
                    XWElement(name: "lost we are"),
                    XWElement(name: "deeper"),
                ]),
                XWElement(name: "deeper"),
                XWElement(name: "help me"),
            ])),
            .element(XWElement(name: "here", elements: XWElement(name: "test"))),
            .element(XWElement(name: "test_something")),
        ]

        let stringResult = string.findLast(elementNamed: "something", recursive: true)
        let cannotFind = source.findLast(elementNamed: "not_existent", recursive: true)
        let testResult = source.findLast(elementNamed: "test", recursive: true)
        let whateverResult = source.findLast(elementNamed: "whatever", recursive: true)

        XCTAssertNil(stringResult)
        XCTAssertNil(cannotFind)
        XCTAssertNotNil(testResult)
        XCTAssertNotNil(whateverResult)
        XCTAssertTrue(testResult?.content.isEmpty ?? false)
        // Make sure we only recurse lazily. We don't want to go into the deepest abyss if we can stay in shallower waters.
        XCTAssertEqual(whateverResult?.content, ["not so deep"])
    }
}
