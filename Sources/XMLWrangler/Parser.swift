import struct Foundation.Data
import class Foundation.NSObject
import class Foundation.XMLParser
import protocol Foundation.XMLParserDelegate

public final class Parser: ParserDelegate {
   private let xmlParser: XMLParser
   private let delegate = Delegate()

   private var parsedRoot: Element?
   private var elementStack: [Element] = []

   public init(data: Data) {
      xmlParser = XMLParser(data: data)
      delegate.delegate = self
      xmlParser.delegate = delegate
   }

   public convenience init?(string: String) {
      guard let data = string.data(using: .utf8) else { return nil }
      self.init(data: data)
   }

   public func parse() throws -> Element {
      // We only parse things once...
      if let object = parsedRoot { return object }

      if !xmlParser.parse(), let error = xmlParser.parserError {
         throw error
      }
      guard let obj = parsedRoot else { fatalError("Wow, we parsed successfully, but have no object?!") }
      return obj
   }

   // MARK: - ParserDelegate
   fileprivate func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
      let elem = Element(name: elementName, attributes: attributeDict.asAttributes)
      elementStack.append(elem)
   }

   fileprivate func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
      guard let lastElem = elementStack.popLast() else { return } // This shouldn't happen
      if var parent = elementStack.popLast() {
         parent.content.append(object: lastElem)
         elementStack.append(parent)
      } else {
         parsedRoot = lastElem
      }
   }

   fileprivate func parser(_ parser: XMLParser, foundCharacters string: String) {
      guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
      guard var currentElem = elementStack.popLast() else { return }
      currentElem.content.append(string: string)
      elementStack.append(currentElem)
   }

   fileprivate func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
      guard let string = String(data: CDATABlock, encoding: .utf8) else { return }
      guard var currentElem = elementStack.popLast() else { return }
      currentElem.content.append(string: string)
      elementStack.append(currentElem)
   }
}

// MARK: - Delegate forwarding
fileprivate protocol ParserDelegate: class {
   func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String])
   func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
   func parser(_ parser: XMLParser, foundCharacters string: String)
   func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data)
//   func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error)
//   func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error)
}

fileprivate extension Parser {
   fileprivate final class Delegate: NSObject, XMLParserDelegate {
      weak var delegate: ParserDelegate?

      @objc dynamic func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
         delegate?.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
      }

      @objc dynamic func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
         delegate?.parser(parser, didEndElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
      }

      @objc dynamic func parser(_ parser: XMLParser, foundCharacters string: String) {
         delegate?.parser(parser, foundCharacters: string)
      }

      @objc dynamic func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
         delegate?.parser(parser, foundCDATA: CDATABlock)
      }
   }
}

fileprivate extension Dictionary where Key == XMLWrangler.Element.AttributeKey.RawValue {
    var asAttributes: [XMLWrangler.Element.AttributeKey: Value] {
        return .init(uniqueKeysWithValues: map { (.init(rawValue: $0.key), $0.value) })
    }
}