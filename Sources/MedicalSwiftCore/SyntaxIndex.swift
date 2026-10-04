import SwiftSyntax
public struct SyntaxIndex:Sendable{public var contentViewFound=false;public var bodyPropertyFound=false;public var stateProperties:[String]=[]}
public final class SyntaxIndexer:SyntaxVisitor{
 public private(set) var index=SyntaxIndex()
 public override func visit(_ node:StructDeclSyntax)->SyntaxVisitorContinueKind{if node.name.text=="ContentView"{index.contentViewFound=true};return .visitChildren}
 public override func visit(_ node:VariableDeclSyntax)->SyntaxVisitorContinueKind{
  let state=node.attributes.contains{if case .attribute(let a)=$0{return a.attributeName.trimmedDescription=="State"};return false}
  for b in node.bindings{if let id=b.pattern.as(IdentifierPatternSyntax.self){if id.identifier.text=="body"{index.bodyPropertyFound=true};if state{index.stateProperties.append(id.identifier.text)}}}
  return .visitChildren
 }
}