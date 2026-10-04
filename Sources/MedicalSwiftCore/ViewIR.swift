import Foundation

public indirect enum ViewNode: Equatable, Sendable {
    case text(Expression)
    case button(title: Expression, action: [Statement])
    case textField(title: String, binding: String)
    case toggle(title: String, binding: String)
    case vStack([ViewNode])
    case hStack([ViewNode])
    case form([ViewNode])
    case list([ViewNode])
    case navigationStack([ViewNode])
    case section(title: String?, children: [ViewNode])
    case picker(title: String, selection: String, options: [PickerOption])
    case conditional(condition: Condition, then: [ViewNode], otherwise: [ViewNode])
    case spacer
    case forEachRange(start: Int, end: Expression, variable: String, template: [ViewNode])
    case forEachCollection(collection: Expression, variable: String, template: [ViewNode])
    case modified(ViewNode, [ViewModifier])
}

public enum ViewModifier: Equatable, Sendable {
    case padding
    case navigationTitle(String)
    case font(FontToken)
}

public enum FontToken: String, Equatable, Sendable {
    case title, headline, body, caption
}

public struct PickerOption: Equatable, Sendable {
    public let title: String
    public let value: Int

    public init(title: String, value: Int) {
        self.title = title
        self.value = value
    }
}

public indirect enum Expression: Equatable, Sendable {
    case int(Int)
    case bool(Bool)
    case string(String)
    case variable(String)
    case interpolated([InterpolationPart])
    case add(Expression, Expression)
    case subtract(Expression, Expression)
    case multiply(Expression, Expression)
}

public enum InterpolationPart: Equatable, Sendable {
    case literal(String)
    case expression(Expression)
}

public enum Condition: Equatable, Sendable {
    case compare(Expression, CompareOperator, Expression)
}

public enum CompareOperator: String, Equatable, Sendable {
    case lt = "<"
    case lte = "<="
    case gt = ">"
    case gte = ">="
    case eq = "=="
    case neq = "!="
}

public enum Statement: Equatable, Sendable {
    case increment(name: String, amount: Int)
    case assign(name: String, value: Expression)
    case toggle(name: String)
}

public struct ComputedProperty: Equatable, Sendable {
    public let name: String
    public let expression: Expression

    public init(name: String, expression: Expression) {
        self.name = name
        self.expression = expression
    }
}

public struct ScriptProgram: Equatable, Sendable {
    public var state: [String: RuntimeValue]
    public var computed: [ComputedProperty]
    public var root: ViewNode

    public init(
        state: [String: RuntimeValue],
        computed: [ComputedProperty] = [],
        root: ViewNode
    ) {
        self.state = state
        self.computed = computed
        self.root = root
    }
}

public enum RuntimeValue: Equatable, Sendable {
    case int(Int)
    case bool(Bool)
    case string(String)
    case array([RuntimeValue])
}
