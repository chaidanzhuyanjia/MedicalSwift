import SwiftParser
import SwiftSyntax

struct ExpressionLowerer {
    func lower(_ expression: ExprSyntax) throws -> Expression {
        if let reference = expression.as(DeclReferenceExprSyntax.self) {
            return .variable(reference.baseName.text)
        }

        if let integer = expression.as(IntegerLiteralExprSyntax.self),
           let value = Int(integer.literal.text) {
            return .int(value)
        }

        if let boolean = expression.as(BooleanLiteralExprSyntax.self) {
            return .bool(boolean.literal.text == "true")
        }

        if let string = expression.as(StringLiteralExprSyntax.self),
           string.segments.count == 1,
           let segment = string.segments.first?.as(StringSegmentSyntax.self) {
            return .string(segment.content.text)
        }

        if let infix = expression.as(InfixOperatorExprSyntax.self) {
            return try combine(
                try lower(infix.leftOperand),
                operator: infix.operator.trimmedDescription,
                try lower(infix.rightOperand)
            )
        }

        if let sequence = expression.as(SequenceExprSyntax.self) {
            return try lowerSequence(sequence)
        }

        throw RuntimeDiagnostic("Unsupported expression: \(expression.trimmedDescription)")
    }

    func lowerSource(_ source: String) throws -> Expression {
        let tree = Parser.parse(source: "let __medicalswift_expr = \(source)")
        guard let declaration = tree.statements.first?.item.as(VariableDeclSyntax.self),
              let binding = declaration.bindings.first,
              let expression = binding.initializer?.value
        else {
            throw RuntimeDiagnostic("Could not parse expression: \(source)")
        }
        return try lower(expression)
    }

    private func lowerSequence(_ sequence: SequenceExprSyntax) throws -> Expression {
        let elements = Array(sequence.elements)
        guard elements.count >= 3, elements.count % 2 == 1 else {
            throw RuntimeDiagnostic("Unsupported expression sequence")
        }

        var values: [Expression] = [try lower(elements[0])]
        var operators: [String] = []

        var index = 1
        while index + 1 < elements.count {
            let op = elements[index].trimmedDescription
            guard ["+", "-", "*"].contains(op) else {
                throw RuntimeDiagnostic("Unsupported operator \(op)")
            }
            operators.append(op)
            values.append(try lower(elements[index + 1]))
            index += 2
        }

        var i = 0
        while i < operators.count {
            if operators[i] == "*" {
                values[i] = .multiply(values[i], values[i + 1])
                values.remove(at: i + 1)
                operators.remove(at: i)
            } else {
                i += 1
            }
        }

        var result = values[0]
        for (offset, op) in operators.enumerated() {
            result = try combine(result, operator: op, values[offset + 1])
        }
        return result
    }

    private func combine(
        _ left: Expression,
        operator op: String,
        _ right: Expression
    ) throws -> Expression {
        switch op {
        case "+": return .add(left, right)
        case "-": return .subtract(left, right)
        case "*": return .multiply(left, right)
        default: throw RuntimeDiagnostic("Unsupported operator \(op)")
        }
    }
}
