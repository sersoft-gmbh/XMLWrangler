@frozen
//@resultBuilder
@_functionBuilder
public enum XMLContentBuilder {
    @inlinable
    public static func buildExpression(_ element: XMLElement.Content.Element) -> XMLElement.Content {
        .init(storage: [element])
    }

    @inlinable
    public static func buildExpression(_ element: XMLElement) -> XMLElement.Content {
        .init(storage: [.element(element)])
    }

    @inlinable
    public static func buildExpression(_ element: String) -> XMLElement.Content {
        .init(storage: [.string(element)])
    }

    @inlinable
    public static func buildExpression<T: XMLElementConvertible>(_ element: T) -> XMLElement.Content {
        .init(storage: [.element(element.xml)])
    }

    @inlinable
    public static func buildBlock() -> XMLElement.Content { .init(storage: []) }

    @inlinable
    public static func buildBlock(_ content: XMLElement.Content) -> XMLElement.Content {
        content
    }

    @inlinable
    public static func buildBlock(_ content: XMLElement.Content...) -> XMLElement.Content {
        .init(storage: content.flatMap(\.storage))
    }

    @inlinable
    public static func buildOptional(_ content: XMLElement.Content?) -> XMLElement.Content {
        content ?? .init(storage: [])
    }

    @inlinable
    public static func buildEither(first: XMLElement.Content) -> XMLElement.Content {
        first
    }

    @inlinable
    public static func buildEither(second: XMLElement.Content) -> XMLElement.Content {
        second
    }

    @inlinable
    public static func buildArray(_ content: [XMLElement.Content]) -> XMLElement.Content {
        .init(storage: content.flatMap(\.storage))
    }

    @inlinable
    public static func buildFinalResult(_ content: XMLElement.Content) -> XMLElement.Content {
        content._compressed(stringSeparator: "\n") // for builder-built strings we use a newline separator
    }
}

extension XMLElement {
    @inlinable
    public init(name: Name, attributes: Attributes = [:], @XMLContentBuilder content: () -> Content) {
        self.init(name: name, attributes: attributes, content: content())
    }
}
