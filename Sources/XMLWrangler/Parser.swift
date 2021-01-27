import struct Foundation.Data
import class Foundation.NSObject
#if canImport(FoundationXML)
import class FoundationXML.XMLParser
import protocol FoundationXML.XMLParserDelegate
#else
import class Foundation.XMLParser
import protocol Foundation.XMLParserDelegate
#endif

/// Responsible for parsing XMLs.
public final class Parser: ParserDelegate {
    private let xmlParser: XMLParser
    private lazy var delegate = Delegate(delegate: self)

    private var parsedRoot: XMLElement?
    private var elementStack: [XMLElement] = []

    /// Creates a new instance using the given `Data`.
    ///
    /// - Parameter data: The XML data to parse.
    public init(data: Data) {
        xmlParser = XMLParser(data: data)
    }

    /// Creates a new instance using the given string.
    ///
    /// - Parameter string: An XML string.
    @inlinable
    public convenience init(string: String) {
        self.init(data: Data(string.utf8))
    }

    /// Tries to parse the associated XML data. The parsing is only performed once.
    ///
    /// - Returns: The parsed element.
    /// - Throws: Any error reported by `XMLParser`. `Parser.UnknownError` if parsing failed but no error reported. `MissingRootElementError` if parsing succeeded but no root element was parsed.
    public func parse() throws -> XMLElement {
        // We only parse things once...
        if let element = parsedRoot { return element }
        xmlParser.delegate = delegate
        defer { xmlParser.delegate = nil }
        guard xmlParser.parse() else { throw xmlParser.parserError ?? UnknownError() }
        guard let element = parsedRoot else { throw MissingRootElementError() }
        return element
    }

    /// Tries to parse the associated XML data and convert it to the given target by using it's conformance to `ExpressibleByXMLElement`.
    /// - Parameter target: The target type to convert to.
    /// - Throws: Any error thrown by `parse` or `ExpressibleByXMLElement.init(xml:)` of `Target.`
    /// - Returns: The parsed element converted to the given target.
    /// - SeeAlso: `Parser.parse()` and `ExpressibleByXMLElement`.
    @inlinable
    public func parseAndConvert<Target: ExpressibleByXMLElement>(to target: Target.Type = Target.self) throws -> Target {
        try parse().converted(to: target)
    }

    // MARK: - Helpers
    private func stripTrailingNewlinesAndWhitespaces(of element: inout XMLElement) {
        guard !element.content.isEmpty,
              case let idx = element.content.indexBeforeEndIndex,
              case .string(let str) = element.content[idx]
        else { return }
        let stripped = str.dropLast(str.reversed().prefix(while: { $0.isWhitespace || $0.isNewline }).count)
        element.content[idx] = .string(String(stripped))
    }

    // MARK: - ParserDelegate
    fileprivate func parser(_ parser: XMLParser,
                            didStartElement elementName: String,
                            namespaceURI: String?,
                            qualifiedName qName: String?,
                            attributes attributeDict: [String: String]) {
        elementStack.append(.init(name: .init(rawValue: elementName), attributes: attributeDict.asAttributes))
    }

    fileprivate func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard var lastElem = elementStack.popLast() else { return } // This shouldn't happen
        stripTrailingNewlinesAndWhitespaces(of: &lastElem)
        if var parent = elementStack.popLast() {
            stripTrailingNewlinesAndWhitespaces(of: &parent)
            parent.appendElement(lastElem)
            elementStack.append(parent)
        } else {
            parsedRoot = lastElem
        }
    }

    fileprivate func parser(_ parser: XMLParser, foundCharacters string: String) {
        // We currently ignore whitespace only text. Let's hope we never miss something important this way. :)
        guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              var currentElem = elementStack.popLast()
        else { return }
        if currentElem.content.isEmpty || currentElem.content.last?.isElement == true {
            // For first strings (either after elements or generally first content), we strip leading newlines.
            let leftTrimmed = string.drop(while: { $0.isNewline || $0.isWhitespace })
            currentElem.content.append(.string(String(leftTrimmed)))
        } else {
            currentElem.appendString(string.trimmingCharacters(in: .whitespaces))
        }
        elementStack.append(currentElem)
    }

    fileprivate func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard var currentElem = elementStack.popLast() else { return }
        // TODO: Do we need to support CDATA seperately?
        currentElem.appendString(String(decoding: CDATABlock, as: UTF8.self))
        elementStack.append(currentElem)
    }
}

// MARK: - Unknown Parsing Error
extension Parser {
    /// Describes an unknown error.
    /// Used if parsing fails, but the XMLParser of Foundation does not report an error.
    public struct UnknownError: Error, CustomStringConvertible {
        public var description: String { "An unknown parsing error occurred!" }
    }

    /// Describes a failure that caused no element to be parsed.
    /// Used if parsing succeeds, but no element was parsed.
    public struct MissingRootElementError: Error, CustomStringConvertible {
        public var description: String { "Parsing did not yield an element! Please check that the XML is valid!" }
    }
}

// MARK: - Delegate forwarding
fileprivate protocol ParserDelegate: class {
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String])
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    func parser(_ parser: XMLParser, foundCharacters string: String)
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data)
    //   func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error)
    //   func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error)
}

extension Parser {
    fileprivate final class Delegate<ForwardingDelegate: ParserDelegate>: NSObject, XMLParserDelegate {
        private unowned let delegate: ForwardingDelegate

        init(delegate: ForwardingDelegate) {
            self.delegate = delegate
        }

        #if canImport(ObjectiveC)
        @objc dynamic func parser(_ parser: XMLParser,
                                  didStartElement elementName: String,
                                  namespaceURI: String?,
                                  qualifiedName qName: String?,
                                  attributes attributeDict: [String: String] = [:]) {
            delegate.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
        }

        @objc dynamic func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            delegate.parser(parser, didEndElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
        }

        @objc dynamic func parser(_ parser: XMLParser, foundCharacters string: String) {
            delegate.parser(parser, foundCharacters: string)
        }

        @objc dynamic func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            delegate.parser(parser, foundCDATA: CDATABlock)
        }
        #else
        func parser(_ parser: XMLParser,
                    didStartElement elementName: String,
                    namespaceURI: String?,
                    qualifiedName qName: String?,
                    attributes attributeDict: [String: String] = [:]) {
            delegate.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            delegate.parser(parser, didEndElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            delegate.parser(parser, foundCharacters: string)
        }

        func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            delegate.parser(parser, foundCDATA: CDATABlock)
        }
        #endif
    }
}
