import SwiftSyntax

public struct ASTLowerer {
    public init() {}

    public func lower(sourceFile: SourceFileSyntax) throws -> ViewNode {
        guard let content = sourceFile.statements
            .compactMap({ $0.item.as(StructDeclSyntax.self) })
            .first(where: { $0.name.text == "ContentView" }),
              let body = content.memberBlock.members
                .compactMap({ $0.decl.as(VariableDeclSyntax.self) })
                .first(where: {
                    $0.bindings.contains {
                        $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body"
                    }
                }),
              let accessor = body.bindings.first?.accessorBlock,
              case .getter(let items) = accessor.accessors,
              let first = items.first,
              let expression = expression(from: first)
        else {
            throw RuntimeDiagnostic("ContentView has no lowerable body.")
        }

        return try lowerExpr(expression)
    }

    private func lowerExpr(_ expression: ExprSyntax) throws -> ViewNode {
        if let call = expression.as(FunctionCallExprSyntax.self) {
            return try lowerCall(call)
        }
        if let conditional = expression.as(IfExprSyntax.self) {
            return try lowerIf(conditional)
        }
        throw RuntimeDiagnostic("Unsupported expression: \(expression.trimmedDescription)")
    }

    private func lowerCall(_ call: FunctionCallExprSyntax) throws -> ViewNode {
        if let member = call.calledExpression.as(MemberAccessExprSyntax.self) {
            if member.declName.baseName.text == "tag",
               let base = member.base,
               let view = try? lowerExpr(base) {
                return view
            }

            guard let base = member.base else {
                throw RuntimeDiagnostic("Modifier missing base")
            }

            let view = try lowerExpr(base)

            switch member.declName.baseName.text {
            case "padding":
                return .modified(view, [.padding])
            case "navigationTitle":
                guard let argument = call.arguments.first,
                      let title = string(argument.expression)
                else {
                    throw RuntimeDiagnostic("navigationTitle needs String")
                }
                return .modified(view, [.navigationTitle(title)])
            case "font":
                guard let argument = call.arguments.first else {
                    throw RuntimeDiagnostic("font needs a token")
                }
                let raw = argument.expression.trimmedDescription
                let tokenName = raw.hasPrefix(".") ? String(raw.dropFirst()) : raw
                guard let token = FontToken(rawValue: tokenName) else {
                    throw RuntimeDiagnostic("Unsupported font token \(raw)")
                }
                return .modified(view, [.font(token)])
            default:
                throw RuntimeDiagnostic(
                    "Unsupported modifier \(member.declName.baseName.text)"
                )
            }
        }

        guard let reference = call.calledExpression.as(DeclReferenceExprSyntax.self) else {
            throw RuntimeDiagnostic("Unsupported call")
        }

        switch reference.baseName.text {
        case "Text":
            guard let argument = call.arguments.first else {
                throw RuntimeDiagnostic("Text needs argument")
            }
            return .text(try textExpr(argument.expression))
        case "VStack":
            return .vStack(try views(call.trailingClosure))
        case "HStack":
            return .hStack(try views(call.trailingClosure))
        case "Form":
            return .form(try views(call.trailingClosure))
        case "List":
            return .list(try views(call.trailingClosure))
        case "NavigationStack":
            return .navigationStack(try views(call.trailingClosure))
        case "Section":
            return .section(
                title: call.arguments.first.flatMap { string($0.expression) },
                children: try views(call.trailingClosure)
            )
        case "Button":
            guard let argument = call.arguments.first else {
                throw RuntimeDiagnostic("Button needs title")
            }
            return .button(
                title: try textExpr(argument.expression),
                action: try actions(call.trailingClosure)
            )
        case "TextField":
            guard call.arguments.count >= 2,
                  let title = string(call.arguments.first!.expression),
                  let binding = binding(call.arguments.dropFirst().first!.expression)
            else {
                throw RuntimeDiagnostic("Bad TextField")
            }
            return .textField(title: title, binding: binding)
        case "Toggle":
            guard call.arguments.count >= 2,
                  let title = string(call.arguments.first!.expression),
                  let binding = binding(call.arguments.dropFirst().first!.expression)
            else {
                throw RuntimeDiagnostic("Bad Toggle")
            }
            return .toggle(title: title, binding: binding)
        case "Picker":
            guard call.arguments.count >= 2,
                  let title = string(call.arguments.first!.expression),
                  let binding = binding(call.arguments.dropFirst().first!.expression)
            else {
                throw RuntimeDiagnostic("Bad Picker")
            }
            return .picker(
                title: title,
                selection: binding,
                options: try options(call.trailingClosure)
            )
        case "ForEach":
            return try lowerForEach(call)
        case "Spacer":
            return .spacer
        default:
            throw RuntimeDiagnostic(
                "Unsupported SwiftUI call \(reference.baseName.text)"
            )
        }
    }

    private func views(_ closure: ClosureExprSyntax?) throws -> [ViewNode] {
        guard let closure else {
            throw RuntimeDiagnostic("Expected trailing closure")
        }
        return try closure.statements.map { try lowerItem($0) }
    }

    private func lowerItem(_ item: CodeBlockItemSyntax) throws -> ViewNode {
        guard let expression = expression(from: item) else {
            throw RuntimeDiagnostic(
                "Unsupported declaration in view body: \(item.trimmedDescription)"
            )
        }
        return try lowerExpr(expression)
    }

    private func expression(from item: CodeBlockItemSyntax) -> ExprSyntax? {
        switch item.item {
        case .expr(let expression):
            return expression
        case .stmt(let statement):
            return statement.as(ExpressionStmtSyntax.self)?.expression
        case .decl:
            return nil
        }
    }

    private func lowerForEach(_ call: FunctionCallExprSyntax) throws -> ViewNode {
        guard let first = call.arguments.first,
              let closure = call.trailingClosure
        else {
            throw RuntimeDiagnostic("ForEach needs a range and trailing closure")
        }

        let raw = first.expression.trimmedDescription.replacingOccurrences(
            of: " ",
            with: ""
        )
        let parts = raw.components(separatedBy: "..<")
        guard parts.count == 2, let start = Int(parts[0]) else {
            throw RuntimeDiagnostic("ForEach currently supports Int start..<end")
        }

        let end: Expression
        if let number = Int(parts[1]) {
            end = .int(number)
        } else if !parts[1].isEmpty {
            end = .variable(parts[1])
        } else {
            throw RuntimeDiagnostic("ForEach range end is missing")
        }

        guard let clause = closure.signature?.parameterClause else {
            throw RuntimeDiagnostic("ForEach closure needs one parameter")
        }

        let variable: String
        switch clause {
        case .simpleInput(let parameters):
            guard parameters.count == 1, let parameter = parameters.first else {
                throw RuntimeDiagnostic("ForEach closure needs one parameter")
            }
            variable = parameter.name.text
        case .parameterClause(let parameters):
            guard parameters.parameters.count == 1,
                  let parameter = parameters.parameters.first
            else {
                throw RuntimeDiagnostic("ForEach closure needs one parameter")
            }
            variable = (parameter.secondName ?? parameter.firstName).text
        }

        let template = try closure.statements.map { try lowerItem($0) }
        return .forEachRange(
            start: start,
            end: end,
            variable: variable,
            template: template
        )
    }

    private func lowerIf(_ conditional: IfExprSyntax) throws -> ViewNode {
        guard let first = conditional.conditions.first,
              case .expression(let expression) = first.condition
        else {
            throw RuntimeDiagnostic("Unsupported condition")
        }

        let condition = try lowerCondition(expression)
        let yes = try conditional.body.statements.map { try lowerItem($0) }

        var no: [ViewNode] = []
        if let elseBody = conditional.elseBody,
           case .codeBlock(let block) = elseBody {
            no = try block.statements.map { try lowerItem($0) }
        }

        return .conditional(condition: condition, then: yes, otherwise: no)
    }

    private func lowerCondition(_ expression: ExprSyntax) throws -> Condition {
        let lowerer = ExpressionLowerer()

        if let infix = expression.as(InfixOperatorExprSyntax.self),
           let op = CompareOperator(rawValue: infix.operator.trimmedDescription) {
            return .compare(
                try lowerer.lower(infix.leftOperand),
                op,
                try lowerer.lower(infix.rightOperand)
            )
        }

        if let sequence = expression.as(SequenceExprSyntax.self) {
            let elements = Array(sequence.elements)
            guard elements.count == 3,
                  let op = CompareOperator(
                    rawValue: elements[1].trimmedDescription
                  )
            else {
                throw RuntimeDiagnostic("Unsupported comparison")
            }
            return .compare(
                try lowerer.lower(elements[0]),
                op,
                try lowerer.lower(elements[2])
            )
        }

        throw RuntimeDiagnostic("Unsupported condition")
    }

    private func textExpr(_ expression: ExprSyntax) throws -> Expression {
        if let string = expression.as(StringLiteralExprSyntax.self) {
            var parts: [InterpolationPart] = []
            let lowerer = ExpressionLowerer()

            for segment in string.segments {
                if let text = segment.as(StringSegmentSyntax.self) {
                    parts.append(.literal(text.content.text))
                } else if let interpolation = segment.as(ExpressionSegmentSyntax.self),
                          let first = interpolation.expressions.first {
                    parts.append(
                        .expression(
                            try lowerer.lower(first.expression)
                        )
                    )
                }
            }

            if parts.count == 1, case .literal(let literal) = parts[0] {
                return .string(literal)
            }
            return .interpolated(parts)
        }

        return try ExpressionLowerer().lower(expression)
    }

    private func string(_ expression: ExprSyntax) -> String? {
        guard let string = expression.as(StringLiteralExprSyntax.self),
              string.segments.count == 1,
              let segment = string.segments.first?.as(StringSegmentSyntax.self)
        else {
            return nil
        }
        return segment.content.text
    }

    private func binding(_ expression: ExprSyntax) -> String? {
        let source = expression.trimmedDescription
        return source.hasPrefix("$") ? String(source.dropFirst()) : nil
    }

    private func actions(_ closure: ClosureExprSyntax?) throws -> [Statement] {
        guard let closure else { return [] }
        return try closure.statements.map { try action($0) }
    }

    private func action(_ item: CodeBlockItemSyntax) throws -> Statement {
        let raw = item.trimmedDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        if raw.hasSuffix(".toggle()") {
            let name = String(raw.dropLast(".toggle()".count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                throw RuntimeDiagnostic("toggle() needs a state variable")
            }
            return .toggle(name: name)
        }

        for op in ["+=", "-=", "="] {
            if op == "=" && (
                raw.contains("==")
                || raw.contains(">=")
                || raw.contains("<=")
                || raw.contains("!=")
            ) {
                continue
            }

            guard let range = raw.range(of: op) else { continue }

            let name = String(raw[..<range.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let rhsSource = String(raw[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !name.isEmpty, !rhsSource.isEmpty else {
                throw RuntimeDiagnostic("Malformed action \(raw)")
            }

            let rhs = try ExpressionLowerer().lowerSource(rhsSource)

            switch op {
            case "+=":
                if case .int(let amount) = rhs {
                    return .increment(name: name, amount: amount)
                }
                return .assign(name: name, value: .add(.variable(name), rhs))
            case "-=":
                return .assign(
                    name: name,
                    value: .subtract(.variable(name), rhs)
                )
            case "=":
                return .assign(name: name, value: rhs)
            default:
                break
            }
        }

        throw RuntimeDiagnostic(
            "Supported actions are assignment, +=, -=, and Bool.toggle(): \(raw)"
        )
    }

    private func options(_ closure: ClosureExprSyntax?) throws -> [PickerOption] {
        guard let closure else { return [] }

        return try closure.statements.map {
            let raw = $0.trimmedDescription

            guard raw.hasPrefix("Text("),
                  let tag = raw.range(of: ").tag("),
                  raw.hasSuffix(")"),
                  let firstQuote = raw.firstIndex(of: "\""),
                  let secondQuote = raw[raw.index(after: firstQuote)...]
                    .firstIndex(of: "\"")
            else {
                throw RuntimeDiagnostic("Bad Picker option")
            }

            let title = String(
                raw[raw.index(after: firstQuote)..<secondQuote]
            )
            let numberText = String(
                raw[tag.upperBound..<raw.index(before: raw.endIndex)]
            )

            guard let number = Int(numberText) else {
                throw RuntimeDiagnostic("Picker tag must be Int")
            }

            return .init(title: title, value: number)
        }
    }
}
