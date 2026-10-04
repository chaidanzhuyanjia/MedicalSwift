import SwiftSyntax
public struct ASTLowerer{
 public init(){}
 public func lower(sourceFile:SourceFileSyntax)throws->ViewNode{
  guard let content=sourceFile.statements.compactMap({$0.item.as(StructDeclSyntax.self)}).first(where:{$0.name.text=="ContentView"}),
        let body=content.memberBlock.members.compactMap({$0.decl.as(VariableDeclSyntax.self)}).first(where:{$0.bindings.contains{$0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text=="body"}}),
        let accessor=body.bindings.first?.accessorBlock,
        case .getter(let items)=accessor.accessors,
        let first=items.first,let expr=first.item.as(ExprSyntax.self)
  else{throw RuntimeDiagnostic("ContentView has no lowerable body.")}
  return try lowerExpr(expr)
 }
 private func lowerExpr(_ e:ExprSyntax)throws->ViewNode{
  if let call=e.as(FunctionCallExprSyntax.self){return try lowerCall(call)}
  if let i=e.as(IfExprSyntax.self){return try lowerIf(i)}
  throw RuntimeDiagnostic("Unsupported expression: \(e.trimmedDescription)")
 }
 private func lowerCall(_ c:FunctionCallExprSyntax)throws->ViewNode{
  if let m=c.calledExpression.as(MemberAccessExprSyntax.self){
   if m.declName.baseName.text=="tag",let base=m.base,let text=try? lowerExpr(base){return text}
   guard let base=m.base else{throw RuntimeDiagnostic("Modifier missing base")}
   let v=try lowerExpr(base)
   switch m.declName.baseName.text{
   case "padding":return .modified(v,[.padding])
   case "navigationTitle":guard let a=c.arguments.first,let s=string(a.expression) else{throw RuntimeDiagnostic("navigationTitle needs String")};return .modified(v,[.navigationTitle(s)])
   default:throw RuntimeDiagnostic("Unsupported modifier")
   }
  }
  guard let ref=c.calledExpression.as(DeclReferenceExprSyntax.self) else{throw RuntimeDiagnostic("Unsupported call")}
  switch ref.baseName.text{
  case "Text":guard let a=c.arguments.first else{throw RuntimeDiagnostic("Text needs argument")};return .text(try textExpr(a.expression))
  case "VStack":return .vStack(try views(c.trailingClosure))
  case "HStack":return .hStack(try views(c.trailingClosure))
  case "Form":return .form(try views(c.trailingClosure))
  case "List":return .list(try views(c.trailingClosure))
  case "NavigationStack":return .navigationStack(try views(c.trailingClosure))
  case "Section":return .section(title:c.arguments.first.flatMap{string($0.expression)},children:try views(c.trailingClosure))
  case "Button":guard let a=c.arguments.first else{throw RuntimeDiagnostic("Button needs title")};return .button(title:try textExpr(a.expression),action:try actions(c.trailingClosure))
  case "TextField":guard c.arguments.count>=2,let t=string(c.arguments.first!.expression),let b=binding(c.arguments.dropFirst().first!.expression) else{throw RuntimeDiagnostic("Bad TextField")};return .textField(title:t,binding:b)
  case "Toggle":guard c.arguments.count>=2,let t=string(c.arguments.first!.expression),let b=binding(c.arguments.dropFirst().first!.expression) else{throw RuntimeDiagnostic("Bad Toggle")};return .toggle(title:t,binding:b)
  case "Picker":guard c.arguments.count>=2,let t=string(c.arguments.first!.expression),let b=binding(c.arguments.dropFirst().first!.expression) else{throw RuntimeDiagnostic("Bad Picker")};return .picker(title:t,selection:b,options:try options(c.trailingClosure))
  case "Spacer":return .spacer
  default:throw RuntimeDiagnostic("Unsupported SwiftUI call \(ref.baseName.text)")
  }
 }
 private func views(_ closure:ClosureExprSyntax?)throws->[ViewNode]{guard let closure else{throw RuntimeDiagnostic("Expected trailing closure")};return try closure.statements.map{try lowerItem($0)}}
 private func lowerItem(_ item:CodeBlockItemSyntax)throws->ViewNode{
  switch item.item{
  case .expr(let e):return try lowerExpr(e)
  case .stmt(let s):
   if let x=s.as(ExpressionStmtSyntax.self){return try lowerExpr(x.expression)}
   throw RuntimeDiagnostic("Unsupported statement: \(item.trimmedDescription)")
  case .decl:
   throw RuntimeDiagnostic("Unsupported declaration in view body: \(item.trimmedDescription)")
  }
 }
 private func lowerIf(_ i:IfExprSyntax)throws->ViewNode{
  guard let first=i.conditions.first,case .expression(let e)=first.condition,let seq=e.as(SequenceExprSyntax.self) else{throw RuntimeDiagnostic("Unsupported condition")}
  let a=Array(seq.elements);guard a.count==3,let op=CompareOperator(rawValue:a[1].trimmedDescription) else{throw RuntimeDiagnostic("Unsupported comparison")}
  let yes=try i.body.statements.map{try lowerItem($0)}
  var no:[ViewNode]=[];if let eb=i.elseBody,case .codeBlock(let b)=eb{no=try b.statements.map{try lowerItem($0)}}
  return .conditional(condition:.compare(try value(a[0]),op,try value(a[2])),then:yes,otherwise:no)
 }
 private func value(_ e:ExprSyntax)throws->Expression{if let n=e.as(IntegerLiteralExprSyntax.self),let x=Int(n.literal.text){return .int(x)};if let r=e.as(DeclReferenceExprSyntax.self){return .variable(r.baseName.text)};throw RuntimeDiagnostic("Unsupported value")}
 private func textExpr(_ e:ExprSyntax)throws->Expression{
  if let s=e.as(StringLiteralExprSyntax.self){var p:[InterpolationPart]=[];for seg in s.segments{if let x=seg.as(StringSegmentSyntax.self){p.append(.literal(x.content.text))}else if let x=seg.as(ExpressionSegmentSyntax.self),let first=x.expressions.first{p.append(.expression(try value(first.expression)))}};return p.count==1 && {if case .literal=p[0]{return true};return false}() ? .string({if case .literal(let s)=p[0]{return s};return ""}()) : .interpolated(p)}
  return try value(e)
 }
 private func string(_ e:ExprSyntax)->String?{guard let s=e.as(StringLiteralExprSyntax.self),s.segments.count==1,let x=s.segments.first?.as(StringSegmentSyntax.self) else{return nil};return x.content.text}
 private func binding(_ e:ExprSyntax)->String?{let s=e.trimmedDescription;return s.hasPrefix("$") ? String(s.dropFirst()):nil}
 private func actions(_ c:ClosureExprSyntax?)throws->[Statement]{guard let c else{return []};return try c.statements.map{let raw=$0.trimmedDescription.replacingOccurrences(of:" ",with:"");let parts=raw.components(separatedBy:"+=");guard parts.count==2,let n=Int(parts[1]) else{throw RuntimeDiagnostic("Only += Int action is supported")};return .increment(name:parts[0],amount:n)}}
 private func options(_ c:ClosureExprSyntax?)throws->[PickerOption]{guard let c else{return []};return try c.statements.map{let raw=$0.trimmedDescription;guard raw.hasPrefix("Text("),let tag=raw.range(of:").tag("),raw.hasSuffix(")"),let q1=raw.firstIndex(of:"\""),let q2=raw[raw.index(after:q1)...].firstIndex(of:"\"") else{throw RuntimeDiagnostic("Bad Picker option")};let title=String(raw[raw.index(after:q1)..<q2]);let ntext=String(raw[tag.upperBound..<raw.index(before:raw.endIndex)]);guard let n=Int(ntext) else{throw RuntimeDiagnostic("Picker tag must be Int")};return .init(title:title,value:n)}}
}