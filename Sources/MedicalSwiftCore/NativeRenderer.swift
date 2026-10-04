import SwiftUI

public struct NativeRenderer: View {
    @ObservedObject var runtime: ScriptRuntime
    let node: ViewNode

    public init(runtime: ScriptRuntime, node: ViewNode? = nil) {
        self.runtime = runtime
        self.node = node ?? runtime.root
    }

    @ViewBuilder
    public var body: some View {
        switch node {
        case .text(let expression):
            Text(runtime.string(runtime.evaluate(expression)))
        case .button(let title, let action):
            Button(runtime.string(runtime.evaluate(title))) {
                runtime.execute(action)
            }
        case .textField(let title, let binding):
            TextField(title, text: runtime.stringBinding(binding))
        case .toggle(let title, let binding):
            Toggle(title, isOn: runtime.boolBinding(binding))
        case .vStack(let children):
            VStack(spacing: 16) { render(children) }
        case .hStack(let children):
            HStack { render(children) }
        case .form(let children):
            Form { render(children) }
        case .list(let children):
            List { render(children) }
        case .navigationStack(let children):
            NavigationStack { render(children) }
        case .section(let title, let children):
            if let title {
                Section(title) { render(children) }
            } else {
                Section { render(children) }
            }
        case .picker(let title, let selection, let options):
            Picker(title, selection: runtime.intBinding(selection)) {
                ForEach(options, id: \.value) {
                    Text($0.title).tag($0.value)
                }
            }
        case .conditional(let condition, let yes, let no):
            if runtime.test(condition) {
                render(yes)
            } else {
                render(no)
            }
        case .forEachRange(let start, let endExpression, let variable, let template):
            if case .int(let end) = runtime.evaluate(endExpression) {
                ForEach(start..<max(start, end), id: \.self) { value in
                    render(
                        template.map {
                            $0.substituting(
                                variable: variable,
                                with: .int(value)
                            )
                        }
                    )
                }
            }
        case .forEachCollection(let collection, let variable, let template):
            if case .array(let values) = runtime.evaluate(collection) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                    render(
                        template.map {
                            $0.substituting(
                                variable: variable,
                                with: value
                            )
                        }
                    )
                }
            }
        case .spacer:
            Spacer()
        case .modified(let base, let modifiers):
            ModifiedRenderer(
                runtime: runtime,
                base: base,
                modifiers: modifiers
            )
        }
    }

    @ViewBuilder
    private func render(_ children: [ViewNode]) -> some View {
        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
            NativeRenderer(runtime: runtime, node: child)
        }
    }
}

private struct ModifiedRenderer: View {
    @ObservedObject var runtime: ScriptRuntime
    let base: ViewNode
    let modifiers: [ViewModifier]

    var body: some View {
        modifiers.reduce(AnyView(NativeRenderer(runtime: runtime, node: base))) {
            view, modifier in
            switch modifier {
            case .padding:
                return AnyView(view.padding())
            case .navigationTitle(let title):
                return AnyView(view.navigationTitle(title))
            case .font(let token):
                let font: Font =
                    token == .title ? .title :
                    token == .headline ? .headline :
                    token == .caption ? .caption :
                    .body
                return AnyView(view.font(font))
            }
        }
    }
}

private extension ViewNode {
    func substituting(variable: String, with value: RuntimeValue) -> ViewNode {
        switch self {
        case .text(let expression):
            return .text(expression.substituting(variable: variable, with: value))
        case .button(let title, let action):
            return .button(
                title: title.substituting(variable: variable, with: value),
                action: action.map {
                    $0.substituting(variable: variable, with: value)
                }
            )
        case .textField, .toggle, .picker, .spacer:
            return self
        case .vStack(let children):
            return .vStack(children.map {
                $0.substituting(variable: variable, with: value)
            })
        case .hStack(let children):
            return .hStack(children.map {
                $0.substituting(variable: variable, with: value)
            })
        case .form(let children):
            return .form(children.map {
                $0.substituting(variable: variable, with: value)
            })
        case .list(let children):
            return .list(children.map {
                $0.substituting(variable: variable, with: value)
            })
        case .navigationStack(let children):
            return .navigationStack(children.map {
                $0.substituting(variable: variable, with: value)
            })
        case .section(let title, let children):
            return .section(
                title: title,
                children: children.map {
                    $0.substituting(variable: variable, with: value)
                }
            )
        case .conditional(let condition, let yes, let no):
            return .conditional(
                condition: condition.substituting(
                    variable: variable,
                    with: value
                ),
                then: yes.map {
                    $0.substituting(variable: variable, with: value)
                },
                otherwise: no.map {
                    $0.substituting(variable: variable, with: value)
                }
            )
        case .forEachRange(let start, let end, let innerVariable, let template):
            return .forEachRange(
                start: start,
                end: end.substituting(variable: variable, with: value),
                variable: innerVariable,
                template: template.map {
                    $0.substituting(variable: variable, with: value)
                }
            )
        case .forEachCollection(let collection, let innerVariable, let template):
            return .forEachCollection(
                collection: collection.substituting(variable: variable, with: value),
                variable: innerVariable,
                template: template.map {
                    $0.substituting(variable: variable, with: value)
                }
            )
        case .modified(let base, let modifiers):
            return .modified(
                base.substituting(variable: variable, with: value),
                modifiers
            )
        }
    }
}

private extension Expression {
    func substituting(variable: String, with value: RuntimeValue) -> Expression {
        switch self {
        case .variable(let name) where name == variable:
            switch value {
            case .int(let number): return .int(number)
            case .bool(let boolean): return .bool(boolean)
            case .string(let string): return .string(string)
            case .array: return self
            }
        case .add(let left, let right):
            return .add(
                left.substituting(variable: variable, with: value),
                right.substituting(variable: variable, with: value)
            )
        case .subtract(let left, let right):
            return .subtract(
                left.substituting(variable: variable, with: value),
                right.substituting(variable: variable, with: value)
            )
        case .multiply(let left, let right):
            return .multiply(
                left.substituting(variable: variable, with: value),
                right.substituting(variable: variable, with: value)
            )
        case .interpolated(let parts):
            return .interpolated(
                parts.map {
                    $0.substituting(variable: variable, with: value)
                }
            )
        default:
            return self
        }
    }
}

private extension InterpolationPart {
    func substituting(variable: String, with value: RuntimeValue) -> InterpolationPart {
        switch self {
        case .literal:
            return self
        case .expression(let expression):
            return .expression(
                expression.substituting(variable: variable, with: value)
            )
        }
    }
}

private extension Condition {
    func substituting(variable: String, with value: RuntimeValue) -> Condition {
        switch self {
        case .compare(let left, let op, let right):
            return .compare(
                left.substituting(variable: variable, with: value),
                op,
                right.substituting(variable: variable, with: value)
            )
        }
    }
}

private extension Statement {
    func substituting(variable: String, with value: RuntimeValue) -> Statement {
        switch self {
        case .increment:
            return self
        case .assign(let name, let expression):
            return .assign(
                name: name,
                value: expression.substituting(
                    variable: variable,
                    with: value
                )
            )
        case .toggle:
            return self
        }
    }
}
