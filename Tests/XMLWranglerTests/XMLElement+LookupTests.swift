import XCTest
@testable import XMLWrangler

final class XMLElement_LookupTests: XCTestCase {
    private struct StringInitializable: Equatable {
        let strValue: String
        init(str: String) { strValue = str }
    }

    private struct NotStringInitializable {
        init?(str: String) { nil }
    }

    private struct StringRepresentable: RawRepresentable, Equatable {
        let rawValue: String
        init(rawValue: String) { self.rawValue = rawValue }
    }

    private struct StringConvertible: LosslessStringConvertible, Equatable {
        let description: String
        init(_ description: String) { self.description = description }
    }

    private enum StringConvertibleAndRepresentable: RawRepresentable, LosslessStringConvertible, Equatable {
        case rawValue(String)
        case description(String)

        var stringValue: String {
            switch self {
            case .rawValue(let rawValue): return rawValue
            case .description(let description): return description
            }
        }

        var rawValue: String { stringValue }
        var description: String { stringValue }

        init(rawValue: String) { self = .rawValue(rawValue) }
        init(_ description: String) { self = .description(description) }
    }

    private struct StringRepresentableWithNotConvertibleRawValue: RawRepresentable, Equatable {
        struct RawValue: LosslessStringConvertible, Equatable {
            var description: String { "How on earth did you get here?" }
            init?(_ description: String) { nil }
        }

        let rawValue: RawValue
        init(rawValue: RawValue) { self.rawValue = rawValue }
    }

    private struct AttributeExpressible: ExpressibleByXMLAttributeContent {
        let xmlAttributeContent: XWElement.Attributes.Content
    }

    private struct AttributeExpressibleAndRaw: RawRepresentable, ExpressibleByXMLAttributeContent {
        typealias RawValue = String

        let rawValue: RawValue

        init(rawValue: RawValue) { self.rawValue = rawValue }
    }

    private struct AttributeExpressibleAndLossLess: LosslessStringConvertible, ExpressibleByXMLAttributeContent {
        let description: String

        init(_ description: String) { self.description = description }
    }

    private struct AttributeExpressibleAndBoth: RawRepresentable, LosslessStringConvertible, ExpressibleByXMLAttributeContent {
        typealias RawValue = String

        let rawValue: RawValue
        var description: String { rawValue }

        init(rawValue: RawValue) { self.rawValue = rawValue }
        init(_ description: String) { self.init(rawValue: description) }
    }

    private struct ElementExpressible: ExpressibleByXMLElement {
        let element: XWElement

        init(xml: XWElement) throws { element = xml }
    }

    let sut = XWElement(name: "root", attributes: ["version": "2.3.4"], elements: [
        XWElement(name: "member", elements: [XWElement(name: "kind", content: "value")]),
        XWElement(name: "empty_member", attributes: ["active": "true", "id": "5"]),
        XWElement(name: "bigger", attributes: ["date": "2018-01-03"], elements: [
            XWElement(name: "children", elements: [
                XWElement(name: "child", elements: [
                    XWElement(name: "void"),
                    XWElement(name: "texts", content: [
                        .element(XWElement(name: "not_filled")),
                        .string("Huh?"),
                        .element(XWElement(name: "nested_text", content: "This is a text")),
                        .string("More text"),
                    ]),
                ]),
                XWElement(name: "child", content: "with not much content"),
                XWElement(name: "child"),
            ]),
            XWElement(name: "again_not_much", attributes: ["value": "124.56"]),
            XWElement(name: "stringy", content: [
                .string("Some text"),
                .element(XWElement(name: "an_object")),
                .string("More text"),
            ]),
            XWElement(name: "not_stringy"),
        ]),
        XWElement(name: "big", elements: [
            XWElement(name: "boring"),
            XWElement(name: "pets", elements: [
                XWElement(name: "dog", attributes: ["name": "Fifi"]),
                XWElement(name: "dog", attributes: ["name": "Fred"]),
                XWElement(name: "dog", attributes: ["name": "Pete"]),
                XWElement(name: "dog", attributes: ["name": "Max"]),
            ]),
        ]),
        XWElement(name: "simple", elements: XWElement(name: "simple_child")),
        XWElement(name: "repeating", attributes: ["repeat_count": "1"]),
        XWElement(name: "repeating", attributes: ["repeat_count": "2"]),
        XWElement(name: "repeating", attributes: ["repeat_count": "3"]),
        XWElement(name: "last"),
    ])

    let stringContentSUT = XWElement(name: "string_content", content: "we have content")
    let noStringContentSUT = XWElement(name: "no_string_content")

    // MARK: - Lookup
    // MARK: Single element
    func testExistingElementLookupAtPath() throws {
        let target = try sut.element(at: ["bigger", "children", "child", "void"])
        XCTAssertEqual(target, XWElement(name: "void"))
    }

    func testNonExistingElementLookupAtPath() {
        XCTAssertThrowsError(try sut.element(at: ["simple", "simple_child", "nope"])) {
            XCTAssert($0, is: .missingChild(element: XWElement(name: "simple_child"), childName: "nope"))
        }
    }

    func testExistingElementLookupAtVariadicPath() throws {
        let target = try sut.element(at: "bigger", "children", "child", "void")
        XCTAssertEqual(target, XWElement(name: "void"))
    }

    func testNonExistingElementLookupAtVariadicPath() {
        XCTAssertThrowsError(try sut.element(at: "simple", "simple_child", "nope")) {
            XCTAssert($0, is: .missingChild(element: XWElement(name: "simple_child"), childName: "nope"))
        }
    }

    // MARK: List of elements
    func testExistingElementsLookup() throws {
        let elements = try sut.elements(named: "repeating")
        XCTAssertEqual(elements.count, 3)
        XCTAssertEqual(elements, [XWElement(name: "repeating", attributes: ["repeat_count": "1"]),
                                  XWElement(name: "repeating", attributes: ["repeat_count": "2"]),
                                  XWElement(name: "repeating", attributes: ["repeat_count": "3"])])
    }

    func testNonExistingElementsLookup() throws {
        let elements = try sut.elements(named: "nope")
        XCTAssertTrue(elements.isEmpty)
    }

    // MARK: - Attributes
    // MARK: Retrieval
    func testExistingAttributeLookup() throws {
        let attribute = try sut.attribute(for: "version")
        XCTAssertEqual(attribute, "2.3.4")
    }

    func testNonExistingAttributeLookup() {
        XCTAssertThrowsError(try sut.attribute(for: "nope")) {
            XCTAssert($0, is: .missingAttribute(element: sut, key: "nope"))
        }
    }

    // MARK: Conversion
    func testNonExistingAttributeConversion() {
        XCTAssertThrowsError(try sut.convertedAttribute(for: "nope", converter: { StringInitializable(str: $0.rawValue) })) {
            XCTAssert($0, is: .missingAttribute(element: sut, key: "nope"))
        }
    }

    func testExistingAttributeConversion() throws {
        let attribute = try sut.convertedAttribute(for: "version", converter: { StringInitializable(str: $0.rawValue) })
        XCTAssertEqual(attribute, StringInitializable(str: "2.3.4"))
    }

    func testFailedExistingAttributeConversion() {
        XCTAssertThrowsError(try sut.convertedAttribute(for: "version", converter: { NotStringInitializable(str: $0.rawValue) })) {
            XCTAssert($0, is: .cannotConvertAttribute(element: sut, key: "version", content: "2.3.4", type: NotStringInitializable.self))
        }
    }

    func testFailedRawRepresentableAttributeConversion() {
        XCTAssertThrowsError(try sut.convertedAttribute(for: "version", converter: { StringRepresentableWithNotConvertibleRawValue(rawValueDescription: $0.rawValue) })) {
            XCTAssert($0, is: .cannotConvertAttribute(element: sut, key: "version", content: "2.3.4", type: StringRepresentableWithNotConvertibleRawValue.self))
        }
    }

    func testAttributeConversionWithStdlibProtocols() throws {
        let rawRep: StringRepresentable = try sut.convertedAttribute(for: "version")
        XCTAssertEqual(rawRep, StringRepresentable(rawValue: "2.3.4"))
        let lossLess: StringConvertible = try sut.convertedAttribute(for: "version")
        XCTAssertEqual(lossLess, StringConvertible("2.3.4"))
        let both: StringConvertibleAndRepresentable = try sut.convertedAttribute(for: "version")
        XCTAssertEqual(both, .rawValue("2.3.4"))
    }

    func testConvertibleAttribute() throws {
        let pure: AttributeExpressible = try sut.convertedAttribute(for: "version")
        XCTAssertEqual(pure.xmlAttributeContent, "2.3.4")
        let andRaw: AttributeExpressibleAndRaw = try sut.convertedAttribute(for: "version")
        XCTAssertEqual(andRaw.rawValue, "2.3.4")
        let andLossLess: AttributeExpressibleAndLossLess = try sut.convertedAttribute(for: "version")
        XCTAssertEqual(andLossLess.description, "2.3.4")
        let andBoth: AttributeExpressibleAndBoth = try sut.convertedAttribute(for: "version")
        XCTAssertEqual(andBoth.rawValue, "2.3.4")
    }

    // MARK: - String Content
    // MARK: Retrieval
    func testNonExistingStringContentLookup() {
        XCTAssertThrowsError(try noStringContentSUT.stringContent()) {
            XCTAssert($0, is: .missingStringContent(element: noStringContentSUT))
        }
    }

    func testExistingStringContentLookup() throws {
        let content = try stringContentSUT.stringContent()
        XCTAssertEqual(content, "we have content")
    }

    // MARK: Conversion
    func testNonExistingStringContentConversion() {
        XCTAssertThrowsError(try noStringContentSUT.convertedStringContent(converter: StringInitializable.init)) {
            XCTAssert($0, is: .missingStringContent(element: noStringContentSUT))
        }
    }

    func testExistingStringContentConversion() throws {
        let content = try stringContentSUT.convertedStringContent(converter: StringInitializable.init)
        XCTAssertEqual(content, StringInitializable(str: "we have content"))
    }

    func testFailedExistingStringContentConversion() {
        XCTAssertThrowsError(try stringContentSUT.convertedStringContent(converter: NotStringInitializable.init)) {
            XCTAssert($0, is: .cannotConvertStringContent(element: stringContentSUT, stringContent: "we have content", type: NotStringInitializable.self))
        }
    }

    func testFailedRawRepresentableExistingStringContentConversion() {
        XCTAssertThrowsError(try stringContentSUT.convertedStringContent(converter: StringRepresentableWithNotConvertibleRawValue.init)) {
            XCTAssert($0, is: .cannotConvertStringContent(element: stringContentSUT, stringContent: "we have content", type: StringRepresentableWithNotConvertibleRawValue.self))
        }
    }

    func testRawRepresentableStringContentConversion() throws {
        let content: StringRepresentable = try stringContentSUT.convertedStringContent()
        XCTAssertEqual(content, StringRepresentable(rawValue: "we have content"))
    }

    func testLosslessStringConvertibleStringContentConversion() throws {
        let content: StringConvertible = try stringContentSUT.convertedStringContent()
        XCTAssertEqual(content, StringConvertible("we have content"))
    }

    func testRawRepresentableLosslessStringConvertibleStringContentConversion() throws {
        let content: StringConvertibleAndRepresentable = try stringContentSUT.convertedStringContent()
        XCTAssertEqual(content, .rawValue("we have content"))
    }

    func testConvertingElement() {
        XCTAssertEqual(try sut.converted(to: ElementExpressible.self).element, sut)
        XCTAssertEqual(try [sut, stringContentSUT, noStringContentSUT].converted(to: ElementExpressible.self).map(\.element),
                       [sut, stringContentSUT, noStringContentSUT])
    }
}
