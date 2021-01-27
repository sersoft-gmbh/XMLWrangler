extension XMLElement.Content {
    /// Returns the elements of all `.element(_)`s in the receiver.
    @inlinable
    public var allElements: [XMLElement] { storage.compactMap(\.element) }

    /// Returns the strings of all `.string(_)`s in the receiver.
    @inlinable
    public var allStrings: [Element.StringPart] { storage.compactMap(\.string) }

    @usableFromInline
    internal typealias LazyStorageAllSequence<T> = LazyMapSequence<LazyFilterSequence<LazyMapSequence<Storage, Optional<T>>>, T>

    @inlinable
    internal var lazyAllElements: LazyStorageAllSequence<XMLElement> {
        storage.lazy.compactMap(\.element)
    }

//    @inlinable
//    internal var lazyAllString: LazyStorageAllSequence<Element.StringPart> {
//        storage.lazy.compactMap(\.string)
//    }

    /// Searches for elements which match a given predicate. Optionally also recursive.
    /// - Parameters:
    ///   - recursive: If `true` the search will recurse down the tree. `false` by default.
    ///   - predicate: The predicate to apply on elements. If it returns `true` the element will be included in the result.
    /// - Returns: The elements for which the `predicate` returned `true`. May be empty if the `predicate` never returned `true`.
    /// - Throws: Any error that is thrown by the `predicate`.
    /// - Note: `.string(_)` content elements are skipped.
    @usableFromInline
    internal func find(recursive: Bool = false, elementsMatching predicate: (XMLElement) throws -> Bool) rethrows -> [XMLElement] {
        let elements = lazyAllElements
        let matches = try elements.filter(predicate)
        guard recursive else { return matches }
        return try matches + elements.flatMap { try $0.content.find(recursive: recursive, elementsMatching: predicate) }
    }

    /// Finds the first occurence of an element that matches a given predicate.
    /// - Parameters:
    ///   - recursive: If `true` the search will recurse down the tree. `false` by default.
    ///   - predicate: The predicate to apply on elements until it returns `true`.
    /// - Returns: The first element for which `predicate` returned `true`. `nil` if no element matched.
    /// - Throws: Any error that is thrown by the `predicate`.
    /// - Note: If `recursive` is `true`, recursion nevertheless happens lazily.
    ///         This means that one level is searched completely before recursing down into the next deeper level.
    /// - Note: `.string(_)` content elements are skipped.
    @usableFromInline
    internal func findFirst(recursive: Bool = false, elementMatching predicate: (XMLElement) throws -> Bool) rethrows -> XMLElement? {
        let elements = lazyAllElements
        let match = try elements.first(where: predicate)
        guard recursive else { return match }
        return try match ?? elements.lazy.compactMap {
            try $0.content.findFirst(recursive: recursive, elementMatching: predicate)
        }.first
    }

    /// Finds the last occurence of an element that matches a given predicate.
    /// - Parameters:
    ///   - recursive: If `true` the search will recurse down the tree. `false` by default.
    ///   - predicate: The predicate to apply on elements starting at the end until it returns `true`.
    /// - Returns: The last element for which `predicate` returned `true`. `nil` if no element matched.
    /// - Throws: Any error that is thrown by the `predicate`.
    /// - Note: If `recursive` is `true`, recursion nevertheless happens lazily.
    ///         This means that one level is searched completely before recursing down into the next deeper level.
    /// - Note: `.string(_)` content elements are skipped.
    @usableFromInline
    internal func findLast(recursive: Bool = false, elementMatching predicate: (XMLElement) throws -> Bool) rethrows -> XMLElement? {
        let elements = lazyAllElements.reversed()
        let match = try elements.first(where: predicate)
        guard recursive else { return match }
        return try match ?? elements.lazy.compactMap {
            try $0.content.findLast(recursive: recursive, elementMatching: predicate)
        }.first
    }

    /// Searches for elements with a given name. Optionally also recursive.
    /// - Parameters:
    ///   - name: The name with which to search for elements.
    ///   - recursive: If `true` the search will recurse down the tree. `false` by default.
    /// - Returns: The found elements in the order they were found in the tree. May be empty if nothing was found.
    /// - Note: `.string(_)` content elements are skipped.
    @inlinable
    public func find(elementsNamed name: XMLElement.Name, recursive: Bool = false) -> [XMLElement] {
        find(recursive: recursive) { $0.name == name }
    }

    /// Finds the first occurence of an element with a given name.
    /// - Parameters:
    ///   - name: The name with which to search for the first element.
    ///   - recursive: If `true` the search will recurse down the tree. `false` by default.
    /// - Returns: The first element that's been found. `nil` if no element was found.
    /// - Note: If `recursive` is `true`, recursion nevertheless happens lazily.
    ///         This means that one level is searched completely before recursing down into the next deeper level.
    /// - Note: `.string(_)` content elements are skipped.
    @inlinable
    public func findFirst(elementNamed name: XMLElement.Name, recursive: Bool = false) -> XMLElement? {
        findFirst(recursive: recursive) { $0.name == name }
    }

    /// Finds the last occurence of an element with a given name.
    /// - Parameters:
    ///   - name: The name with which to search for the last element.
    ///   - recursive: If `true` the search will recurse down the tree. `false` by default.
    /// - Returns: The first element that's been found. `nil` if no element was found.
    /// - Note: If `recursive` is `true`, recursion nevertheless happens lazily.
    ///         This means that one level is searched completely before recursing down into the next deeper level.
    /// - Note: `.string(_)` content elements are skipped.
    @inlinable
    public func findLast(elementNamed name: XMLElement.Name, recursive: Bool = false) -> XMLElement? {
        findLast(recursive: recursive) { $0.name == name }
    }
}
