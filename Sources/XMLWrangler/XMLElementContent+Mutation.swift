extension XMLElement.Content {
    @usableFromInline
    mutating func _appendString<S: StringProtocol>(_ string: S, separator: @autoclosure () -> Character?) {
        if !storage.isEmpty,
           case let lastIndex = storage.index(endIndex, offsetBy: -1),
           case .string(let str) = storage[lastIndex] {
            var newString = str
            if let separator = separator() {
                newString.append(separator)
            }
            storage[lastIndex] = .string(newString + string)
        } else {
            storage.append(.string(String(string)))
        }
    }

    @usableFromInline
    mutating func _append(_ element: Element,
                          autoCompress: Bool,
                          stringSeparator: @autoclosure () -> Character?) {
        guard autoCompress, case .string(let str) = element else {
            storage.append(element)
            return
        }
        _appendString(str, separator: stringSeparator())
    }

    /// Appends either a new `.string` element, or if the last one is already `.string`, appends `string` to the last one.
    /// - Parameter string: The string to append.
    @inlinable
    public mutating func appendString(_ string: Element.StringPart) {
        _appendString(string, separator: nil)
    }

    /// Appends either a new `.string` element, or if the last one is already `.string`, appends `string` to the last one.
    /// - Parameter string: The string to append.
    @inlinable
    @available(*, deprecated, message: "Use appendString(_:)", renamed: "appendString(_:)")
    public mutating func append(string: Element.StringPart) { appendString(string) }

    /// Appends an element wrapped as `.element`.
    /// - Parameter element: The element to append wrapped in `.element`.
    @inlinable
    public mutating func appendElement(_ element: XMLElement) {
        storage.append(.element(element))
    }

    /// Appends an element wrapped as `.element`.
    /// - Parameter element: The element to append wrapped in `.element`.
    @inlinable
    @available(*, deprecated, message: "Use appendElement(_:)", renamed: "appendElement(_:)")
    public mutating func append(element: XMLElement) {
        appendElement(element)
    }

    /// Appends the xml element of a convertible type.
    /// - Parameter convertible: The type conforming to `XMLElementConvertible`.
    @inlinable
    public mutating func append<Convertible: XMLElementConvertible>(elementOf convertible: Convertible) {
        appendElement(convertible.xml)
    }

    /// Appends the contents of a sequcence of elements wrapped as `.element`.
    /// - Parameter elements: The sequence of elements to append wrapped in `.element`.
    @inlinable
    public mutating func append<S: Sequence>(contentsOf elements: S) where S.Element == XMLElement {
        storage.append(contentsOf: elements.lazy.map { .element($0) })
    }

    /// Appends the one or more elements wrapped as `.element`.
    /// - Parameter elements: The elements to append wrapped in `.element`.
    @inlinable
    public mutating func appendElements(_ elements: XMLElement...) {
        append(contentsOf: elements)
    }

    /// Appends the one or more elements wrapped as `.element`.
    /// - Parameter elements: The elements to append wrapped in `.element`.
    @inlinable
    @available(*, deprecated, message: "Use appendElements(_:)", renamed: "appendElements(_:)")
    public mutating func append(elements: XMLElement...) {
        append(contentsOf: elements)
    }

    @usableFromInline
    mutating func _compress(stringSeparator: Character?) {
        var currentIndex = storage.startIndex
        while let nextIndex = storage.index(currentIndex, offsetBy: 1, limitedBy: storage.endIndex) {
            defer { currentIndex = nextIndex }
            guard case .string(var newStr) = storage[currentIndex] else { continue }
            while nextIndex < storage.endIndex, case .string(let nextStr) = storage[nextIndex] {
                if let char = stringSeparator {
                    newStr.append(char)
                }
                newStr += nextStr
                storage.remove(at: nextIndex) // TODO: this might be a performance problem
            }
            storage[currentIndex] = .string(newStr)
        }
    }

    @usableFromInline
    func _compressed(stringSeparator: Character?) -> Self {
        var compressed = self
        compressed._compress(stringSeparator: stringSeparator)
        return compressed
    }

    /// Merges consecutive `.string` elements into one.
    @inlinable
    public mutating func compress() {
        _compress(stringSeparator: nil)
    }

    /// Returns a compressed version of `self`, where all consecutive `.string` elements were merged into one.
    /// - Returns: A compressed version of `self`.
    /// - SeeAlso: `compress()`
    @inlinable
    public func compressed() -> Self {
        _compressed(stringSeparator: nil)
    }
}
