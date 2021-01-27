import XCTest
@testable import XMLWrangler

final class SerializationTests: XCTestCase {
    func testDocumentEncodingDescription() {
        XCTAssertEqual(String(describing: DocumentEncoding.ascii), "ascii")
        XCTAssertEqual(String(describing: DocumentEncoding.utf8), "utf-8")
        XCTAssertEqual(String(describing: DocumentEncoding.utf16), "utf-16")
    }

    func testEscapableContentQuotesDescription() {
        XCTAssertEqual(String(describing: EscapableContent.Quotes.single), "Single quotes")
        XCTAssertEqual(String(describing: EscapableContent.Quotes.double), "Double quotes")
    }

    func testEscapableContentDescription() {
        XCTAssertEqual(String(describing: EscapableContent.attribute(quotes: .single)), "Attribute enclosed in single quotes")
        XCTAssertEqual(String(describing: EscapableContent.attribute(quotes: .double)), "Attribute enclosed in double quotes")
        XCTAssertEqual(String(describing: EscapableContent.text), "Text")
        XCTAssertEqual(String(describing: EscapableContent.cdata), "CDATA")
        XCTAssertEqual(String(describing: EscapableContent.comment), "Comment")
        XCTAssertEqual(String(describing: EscapableContent.processingInstruction), "Processing instruction")
    }

    func testEscapingStrings() {
        let testString = "\"some_kind_of' < string & others > or this"
        
        let expectedAttributeSingle = "\"some_kind_of&apos; &lt; string &amp; others > or this"
        let expectedAttributeDouble = "&quot;some_kind_of' &lt; string &amp; others > or this"
        let expectedText = "\"some_kind_of' &lt; string &amp; others > or this"
        let expectedCDATA = testString
        let expectedComment = testString
        let expectedProcessingInstruction = testString
        
        var attributeSingle = testString
        var attributeDouble = testString
        var text = testString
        var cdata = testString
        var comment = testString
        var processingInstructions = testString
        
        attributeSingle.escape(content: .attribute(quotes: .single))
        attributeDouble.escape(content: .attribute(quotes: .double))
        text.escape(content: .text)
        cdata.escape(content: .cdata)
        comment.escape(content: .comment)
        processingInstructions.escape(content: .processingInstruction)
        
        // Non-Mutating
        XCTAssertEqual(testString.escaped(content: .attribute(quotes: .single)), expectedAttributeSingle)
        XCTAssertEqual(testString.escaped(content: .attribute(quotes: .double)), expectedAttributeDouble)
        XCTAssertEqual(testString.escaped(content: .text), expectedText)
        XCTAssertEqual(testString.escaped(content: .cdata), expectedCDATA)
        XCTAssertEqual(testString.escaped(content: .comment), expectedComment)
        XCTAssertEqual(testString.escaped(content: .processingInstruction), expectedProcessingInstruction)
        // Mutating
        XCTAssertEqual(attributeSingle, expectedAttributeSingle)
        XCTAssertEqual(attributeDouble, expectedAttributeDouble)
        XCTAssertEqual(text, expectedText)
        XCTAssertEqual(cdata, expectedCDATA)
        XCTAssertEqual(comment, expectedComment)
        XCTAssertEqual(processingInstructions, expectedProcessingInstruction)
    }

    private let testRoot: XWElement = {
        XWElement(name: "root", attributes: ["some": "key"]) {
            XWElement(name: "first")
            XWElement(name: "second", content: "something")
            XWElement(name: "third", elements: [
                XWElement(name: "third_one"),
                XWElement(name: "third_two", attributes: ["third_some": "value"]),
                XWElement(name: "third_three", attributes: ["third_some": "value"], content: "test this right"),
            ])
        }
    }()

    private let mixedContentRoot = XWElement(name: "root") {
        "Some text is here to check."
        "Which even contains newlines."
        XWElement(name: "child", content: "I'm not of much relevance")
        XWElement(name: "child")
        "Again we have some more text here."
        "Let's see how this will end."
        XWElement(name: "other")
    }

    func testXMLSerialization() {
        let str1 = String(xml: testRoot)
        let expected1 = "<root some=\"key\"><first/><second>something</second><third><third_one/><third_two third_some=\"value\"/><third_three third_some=\"value\">test this right</third_three></third></root>"
        
        let str2 = String(xml: testRoot, options: [.pretty])
        let expected2 = "<root some=\"key\">\n<first/>\n<second>something</second>\n<third>\n<third_one/>\n<third_two third_some=\"value\"/>\n<third_three third_some=\"value\">test this right</third_three>\n</third>\n</root>"
        
        let str3 = String(xml: testRoot, options: [.singleQuoteAttributes])
        let expected3 = "<root some='key'><first/><second>something</second><third><third_one/><third_two third_some='value'/><third_three third_some='value'>test this right</third_three></third></root>"
        
        let str4 = String(xml: testRoot, options: [.pretty, .singleQuoteAttributes])
        let expected4 = "<root some='key'>\n<first/>\n<second>something</second>\n<third>\n<third_one/>\n<third_two third_some='value'/>\n<third_three third_some='value'>test this right</third_three>\n</third>\n</root>"
        
        XCTAssertEqual(str1, expected1)
        XCTAssertEqual(str2, expected2)
        XCTAssertEqual(str3, expected3)
        XCTAssertEqual(str4, expected4)
    }

    func testXMLDocumentSerialization() {
        let str1 = String(xmlDocumentRoot: testRoot, version: Version(major: 1), encoding: .utf8)
        let expected1 = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root some=\"key\"><first/><second>something</second><third><third_one/><third_two third_some=\"value\"/><third_three third_some=\"value\">test this right</third_three></third></root>"
        
        let str2 = String(xmlDocumentRoot: testRoot, version: Version(major: 1), encoding: .utf8, options: [.pretty])
        let expected2 = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root some=\"key\">\n<first/>\n<second>something</second>\n<third>\n<third_one/>\n<third_two third_some=\"value\"/>\n<third_three third_some=\"value\">test this right</third_three>\n</third>\n</root>"
        
        let str3 = String(xmlDocumentRoot: testRoot, version: Version(major: 1), encoding: .utf8, options: [.singleQuoteAttributes])
        let expected3 = "<?xml version='1.0' encoding='UTF-8'?><root some='key'><first/><second>something</second><third><third_one/><third_two third_some='value'/><third_three third_some='value'>test this right</third_three></third></root>"
        
        let str4 = String(xmlDocumentRoot: testRoot, version: Version(major: 1), encoding: .utf8, options: [.pretty, .singleQuoteAttributes])
        let expected4 = "<?xml version='1.0' encoding='UTF-8'?>\n<root some='key'>\n<first/>\n<second>something</second>\n<third>\n<third_one/>\n<third_two third_some='value'/>\n<third_three third_some='value'>test this right</third_three>\n</third>\n</root>"
        
        let str5 = String(xmlDocumentRoot: testRoot, version: Version(major: 1), encoding: .utf16)
        let expected5 = "<?xml version=\"1.0\" encoding=\"UTF-16\"?><root some=\"key\"><first/><second>something</second><third><third_one/><third_two third_some=\"value\"/><third_three third_some=\"value\">test this right</third_three></third></root>"
        
        let str6 = String(xmlDocumentRoot: testRoot, version: Version(major: 1), encoding: .ascii)
        let expected6 = "<?xml version=\"1.0\" encoding=\"ASCII\"?><root some=\"key\"><first/><second>something</second><third><third_one/><third_two third_some=\"value\"/><third_three third_some=\"value\">test this right</third_three></third></root>"
        
        XCTAssertEqual(str1, expected1)
        XCTAssertEqual(str2, expected2)
        XCTAssertEqual(str3, expected3)
        XCTAssertEqual(str4, expected4)
        XCTAssertEqual(str5, expected5)
        XCTAssertEqual(str6, expected6)
    }

    func testMixedContentSerialization() {
        let str1 = String(xml: mixedContentRoot)
        let expected1 = "<root>Some text is here to check.\nWhich even contains newlines.<child>I'm not of much relevance</child><child/>Again we have some more text here.\nLet's see how this will end.<other/></root>"
        
        let str2 = String(xml: mixedContentRoot, options: [.pretty])
        let expected2 = "<root>\nSome text is here to check.\nWhich even contains newlines.\n<child>I'm not of much relevance</child>\n<child/>\nAgain we have some more text here.\nLet's see how this will end.\n<other/>\n</root>"
        
        let str3 = String(xml: mixedContentRoot, options: [.singleQuoteAttributes])
        let expected3 = "<root>Some text is here to check.\nWhich even contains newlines.<child>I'm not of much relevance</child><child/>Again we have some more text here.\nLet's see how this will end.<other/></root>"
        
        let str4 = String(xml: mixedContentRoot, options: [.pretty, .singleQuoteAttributes])
        let expected4 = "<root>\nSome text is here to check.\nWhich even contains newlines.\n<child>I'm not of much relevance</child>\n<child/>\nAgain we have some more text here.\nLet's see how this will end.\n<other/>\n</root>"
        
        XCTAssertEqual(str1, expected1)
        XCTAssertEqual(str2, expected2)
        XCTAssertEqual(str3, expected3)
        XCTAssertEqual(str4, expected4)
    }

    private struct Convertible: XMLElementConvertible {
        let xml: XWElement
    }

    func testConvertibleSerialization() {
        XCTAssertEqual(String(xmlOf: Convertible(xml: mixedContentRoot)), String(xml: mixedContentRoot))
        XCTAssertEqual(String(xmlDocumentRootWith: Convertible(xml: testRoot)), String(xmlDocumentRoot: testRoot))
    }
}
