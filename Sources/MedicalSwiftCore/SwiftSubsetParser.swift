import SwiftParser
import SwiftSyntax
public struct SwiftSubsetParser{
 public init(){}
 public func parse(_ source:String)throws->ScriptProgram{
  let tree=Parser.parse(source:source);guard !tree.statements.isEmpty else{throw RuntimeDiagnostic("Empty Swift source")}
  let indexer=SyntaxIndexer(viewMode:.sourceAccurate);indexer.walk(tree)
  guard indexer.index.contentViewFound,indexer.index.bodyPropertyFound else{throw RuntimeDiagnostic("Expected ContentView with body.")}
  let model=try ASTModelExtractor().extract(from:tree)
  return .init(state:model.state,computed:model.computed,root:try ASTLowerer().lower(sourceFile:tree))
 }
}