import XCTest
#if canImport(FoundationXML)
import FoundationXML
#endif
@testable import XMLWrangler

final class ParserTests: XCTestCase {
    private struct Expressible: ExpressibleByXMLElement {
        let element: XWElement

        init(xml: XWElement) throws {
            element = xml
        }
    }

    private let testRoot: XWElement = {
        var root = XWElement(name: "root", attributes: ["some": "key"])
        root.appendElement(XWElement(name: "first"))
        root.appendElement(XWElement(name: "second", content: "something"))
        root.appendElement(XWElement(name: "third", elements: [
            XWElement(name: "third_one"),
            XWElement(name: "third_two", attributes: ["third_some": "value"]),
            XWElement(name: "third_three", attributes: ["third_some": "value"], content: "test this right")
        ]))
        root.appendElement(XMLElement(name: "fourth", content: "Some <CDATA> value"))
        return root
    }()

    private let xml1 = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root some=\"key\"><first/><second>something</second><third><third_one/><third_two third_some=\"value\"/><third_three third_some=\"value\">test this right</third_three></third><fourth><![CDATA[Some <CDATA> value]]></fourth></root>"
    private let xml2 = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root some=\"key\">\n<first/>\n<second>something</second>\n<third>\n<third_one/>\n<third_two third_some=\"value\"/>\n<third_three third_some=\"value\">test this right</third_three>\n</third>\n<fourth>\n<![CDATA[Some <CDATA> value]]>\n</fourth>\n</root>\n"
    private let xml3 = "<?xml version='1.0' encoding='UTF-8'?><root some='key'><first/><second>something</second><third><third_one/><third_two third_some='value'/><third_three third_some='value'>test this right</third_three></third><fourth><![CDATA[Some <CDATA> value]]></fourth></root>"
    private let xml4 = "<?xml version='1.0' encoding='UTF-8'?>\n<root some='key'>\n<first/>\n<second>something</second>\n<third>\n<third_one/>\n<third_two third_some='value'/>\n<third_three third_some='value'>test this right</third_three>\n</third>\n<fourth>\n<![CDATA[Some <CDATA> value]]>\n</fourth>\n</root>\n"

    func testParsingError() {
        let invalidXML = "<>Totally not valid XML<!>"
        let parser = Parser(string: invalidXML)

        XCTAssertThrowsError(try parser.parse()) {
            switch $0 {
            case is Parser.UnknownError:
                XCTAssertTrue($0 is Parser.UnknownError)
            case is Parser.MissingRootElementError:
                XCTAssertTrue($0 is Parser.MissingRootElementError)
            case let nsError as NSError:
                XCTAssertEqual(nsError.domain, XMLParser.errorDomain)
            }
        }
    }

    func testSuccessfulParsing() {
        let parser1 = Parser(string: xml1)
        let parser2 = Parser(string: xml2)
        let parser3 = Parser(string: xml3)
        let parser4 = Parser(string: xml4)

        XCTAssertEqual(try parser1.parse(), testRoot)
        XCTAssertEqual(try parser2.parse(), testRoot)
        XCTAssertEqual(try parser3.parse(), testRoot)
        XCTAssertEqual(try parser4.parse(), testRoot)
    }

    func testRepetitiveParsing() throws {
        let parser = Parser(string: xml1)
        let start1 = DispatchTime.now().uptimeNanoseconds
        let run1 = try parser.parse()
        let duration1 = DispatchTime.now().uptimeNanoseconds - start1
        let start2 = DispatchTime.now().uptimeNanoseconds
        let run2 = try parser.parse()
        let duration2 = DispatchTime.now().uptimeNanoseconds - start2

        XCTAssertEqual(run1, run2)
        // The second run's gotta be much faster since we return the previously parsed object directly.
        XCTAssertLessThan(duration2, duration1)
    }

    func testMixedContentParsing() {
        let mixedContentXML = """
                            <?xml version="1.0" encoding="UTF-8"?>
                            <rootElement>
                            This is a text, here to check,
                            if newlines work correctly.
                            <childElement>I'm just sitting here</childElement>
                            <childElement/>
                            Again to check the works,
                            we add some newlines.
                            <otherElement/>
                            </rootElement>
                            """
        let expectedElement = XWElement(name: "rootElement", content: [
            .string("This is a text, here to check,\nif newlines work correctly."),
            .element(XWElement(name: "childElement", content: "I'm just sitting here")),
            .element(XWElement(name: "childElement")),
            .string("Again to check the works,\nwe add some newlines."),
            .element(XWElement(name: "otherElement"))
        ])
        let parser = Parser(string: mixedContentXML)
        XCTAssertEqual(try parser.parse(), expectedElement)
    }

    func testParsingAndConverting() {
        let parser = Parser(string: xml1)
        XCTAssertEqual(try parser.parseAndConvert(to: Expressible.self).element, testRoot)
    }
}
