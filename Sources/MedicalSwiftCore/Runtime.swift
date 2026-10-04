import SwiftUI

@MainActor
public final class ScriptRuntime: ObservableObject {
    @Published public private(set) var values: [String: RuntimeValue]

    public let root: ViewNode
    private let computed: [String: Expression]

    public init(program: ScriptProgram) {
        values = program.state
        root = program.root
        computed = Dictionary(
            uniqueKeysWithValues: program.computed.map { ($0.name, $0.expression) }
        )
    }

    public func evaluate(_ expression: Expression) -> RuntimeValue {
        switch expression {
        case .int(let value):
            return .int(value)
        case .bool(let value):
            return .bool(value)
        case .string(let value):
            return .string(value)
        case .variable(let name):
            if let value = values[name] {
                return value
            }
            if let expression = computed[name] {
                return evaluate(expression)
            }
            return .string("")
        case .add(let left, let right):
            let lhs = evaluate(left)
            let rhs = evaluate(right)
            if case .int(let a) = lhs, case .int(let b) = rhs {
                return .int(a + b)
            }
            return .string(string(lhs) + string(rhs))
        case .subtract(let left, let right):
            guard case .int(let a) = evaluate(left),
                  case .int(let b) = evaluate(right)
            else {
                return .int(0)
            }
            return .int(a - b)
        case .multiply(let left, let right):
            guard case .int(let a) = evaluate(left),
                  case .int(let b) = evaluate(right)
            else {
                return .int(0)
            }
            return .int(a * b)
        case .interpolated(let parts):
            return .string(
                parts.map {
                    switch $0 {
                    case .literal(let value):
                        return value
                    case .expression(let expression):
                        return string(evaluate(expression))
                    }
                }.joined()
            )
        }
    }

    public func test(_ condition: Condition) -> Bool {
        switch condition {
        case .compare(let left, let op, let right):
            let lhs = evaluate(left)
            let rhs = evaluate(right)

            switch op {
            case .eq:
                return lhs == rhs
            case .neq:
                return lhs != rhs
            case .lt, .lte, .gt, .gte:
                guard case .int(let a) = lhs, case .int(let b) = rhs else {
                    return false
                }
                switch op {
                case .lt: return a < b
                case .lte: return a <= b
                case .gt: return a > b
                case .gte: return a >= b
                case .eq, .neq: return false
                }
            }
        }
    }

    public func execute(_ statements: [Statement]) {
        for statement in statements {
            switch statement {
            case .increment(let name, let amount):
                if case .int(let value) = values[name] {
                    values[name] = .int(value + amount)
                }
            case .assign(let name, let expression):
                values[name] = evaluate(expression)
            case .toggle(let name):
                if case .bool(let value) = values[name] {
                    values[name] = .bool(!value)
                }
            }
        }
    }

    public func intBinding(_ name: String) -> Binding<Int> {
        Binding(
            get: {
                if case .int(let value) = self.values[name] {
                    return value
                }
                return 0
            },
            set: { self.values[name] = .int($0) }
        )
    }

    public func stringBinding(_ name: String) -> Binding<String> {
        Binding(
            get: {
                if case .string(let value) = self.values[name] {
                    return value
                }
                return ""
            },
            set: { self.values[name] = .string($0) }
        )
    }

    public func boolBinding(_ name: String) -> Binding<Bool> {
        Binding(
            get: {
                if case .bool(let value) = self.values[name] {
                    return value
                }
                return false
            },
            set: { self.values[name] = .bool($0) }
        )
    }

    public func string(_ value: RuntimeValue) -> String {
        switch value {
        case .int(let number): return String(number)
        case .bool(let boolean): return boolean ? "true" : "false"
        case .string(let string): return string
        }
    }
}
