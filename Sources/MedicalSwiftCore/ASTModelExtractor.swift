import SwiftSyntax

public struct ASTModel {
    public var state: [String: RuntimeValue] = [:]
    public var computed: [ComputedProperty] = []
}

public struct ASTModelExtractor {
    public init() {}

    public func extract(from file: SourceFileSyntax) throws -> ASTModel {
        guard let content = file.statements
            .compactMap({ $0.item.as(StructDeclSyntax.self) })
            .first(where: { $0.name.text == "ContentView" })
        else {
            throw RuntimeDiagnostic("Expected ContentView.")
        }

        var model = ASTModel()
        let expressionLowerer = ExpressionLowerer()

        for member in content.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            let isState = variable.attributes.contains {
                if case .attribute(let attribute) = $0 {
                    return attribute.attributeName.trimmedDescription == "State"
                }
                return false
            }

            for binding in variable.bindings {
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }

                let name = identifier.identifier.text

                if isState {
                    guard let initializer = binding.initializer?.value else {
                        throw RuntimeDiagnostic("@State requires initializer.")
                    }

                    let expression = try expressionLowerer.lower(initializer)
                    switch expression {
                    case .int(let value):
                        model.state[name] = .int(value)
                    case .bool(let value):
                        model.state[name] = .bool(value)
                    case .string(let value):
                        model.state[name] = .string(value)
                    default:
                        throw RuntimeDiagnostic("@State initializer must be an Int, Bool, or String literal.")
                    }
                } else if name != "body",
                          let accessorBlock = binding.accessorBlock,
                          case .getter(let items) = accessorBlock.accessors,
                          items.count == 1,
                          let expression = expression(from: items.first!) {
                    model.computed.append(
                        .init(
                            name: name,
                            expression: try expressionLowerer.lower(expression)
                        )
                    )
                }
            }
        }

        return model
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
}
