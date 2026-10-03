import SwiftSyntax
public struct ASTModel{public var state:[String:RuntimeValue]=[:];public var computed:[ComputedProperty]=[]}
public struct ASTModelExtractor{
 public init(){}
 public func extract(from file:SourceFileSyntax)throws->ASTModel{
  guard let content=file.statements.compactMap({$0.item.as(StructDeclSyntax.self)}).first(where:{$0.name.text=="ContentView"}) else{throw RuntimeDiagnostic("Expected ContentView.")}
  var m=ASTModel()
  for member in content.memberBlock.members{
   guard let v=member.decl.as(VariableDeclSyntax.self) else{continue}
   let isState=v.attributes.contains{if case .attribute(let a)=$0{return a.attributeName.trimmedDescription=="State"};return false}
   for b in v.bindings{
    guard let id=b.pattern.as(IdentifierPatternSyntax.self) else{continue};let name=id.identifier.text
    if isState{
     guard let e=b.initializer?.value else{throw RuntimeDiagnostic("@State requires initializer.")}
     if let n=e.as(IntegerLiteralExprSyntax.self),let x=Int(n.literal.text) { m.state[name ] = .int(x)}
     else if let q=e.as(BooleanLiteralExprSyntax.self) { m.state[name ] = .bool(q.literal.text=="true")}
     else if let s=e.as(StringLiteralExprSyntax.self),s.segments.count==1,let x=s.segments.first?.as(StringSegmentSyntax.self) { m.state[name ] = .string(x.content.text)}
     else{throw RuntimeDiagnostic("Unsupported @State initializer.")}
    } else if name != "body",let a=b.accessorBlock,case .getter(let items)=a.accessors,items.count==1,let e=items.first?.item.as(ExprSyntax.self),let x=try? lower(e) { m.computed.append(.init(name:name,expression:x))}
   }
  };return m
 }
 private func lower(_ e:ExprSyntax)throws->Expression{
  if let r=e.as(DeclReferenceExprSyntax.self){return .variable(r.baseName.text)}
  if let n=e.as(IntegerLiteralExprSyntax.self),let x=Int(n.literal.text){return .int(x)}
  if let s=e.as(SequenceExprSyntax.self){let a=Array(s.elements);guard a.count>=3 else{throw RuntimeDiagnostic("Unsupported computed expression")};var out=try lower(a[0]);var i=1;while i+1<a.count{guard a[i].trimmedDescription=="+" else{throw RuntimeDiagnostic("Only + is supported")};out = .add(out,try lower(a[i+1]));i += 2};return out}
  throw RuntimeDiagnostic("Unsupported computed expression")
 }
}