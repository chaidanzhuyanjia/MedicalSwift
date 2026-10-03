import SwiftUI
@MainActor public final class ScriptRuntime:ObservableObject{
 @Published public private(set) var values:[String:RuntimeValue]
 public let root:ViewNode;private let computed:[String:Expression]
 public init(program:ScriptProgram){values=program.state;root=program.root;computed=Dictionary(uniqueKeysWithValues:program.computed.map{($0.name,$0.expression)})}
 public func evaluate(_ e:Expression)->RuntimeValue{switch e{
 case .int(let n):return .int(n);case .bool(let b):return .bool(b);case .string(let s):return .string(s)
 case .variable(let n):if let v=values[n]{return v};if let x=computed[n]{return evaluate(x)};return .string("")
 case .add(let a,let b):let x=evaluate(a),y=evaluate(b);if case .int(let i)=x,case .int(let j)=y{return .int(i+j)};return .string(string(x)+string(y))
 case .interpolated(let p):return .string(p.map{switch $0{case .literal(let s):return s;case .expression(let x):return string(evaluate(x))}}.joined())
 }}
 public func test(_ c:Condition)->Bool{guard case .compare(let l,let op,let r)=c else{return false};let a=evaluate(l),b=evaluate(r);if case .int(let x)=a,case .int(let y)=b{switch op{case .lt:return x<y;case .lte:return x<=y;case .gt:return x>y;case .gte:return x>=y;case .eq:return x==y;case .neq:return x != y}};return false}
 public func execute(_ ss:[Statement]){for s in ss{switch s{case .increment(let n,let d):if case .int(let x)=values[n]{values[n]=.int(x+d)};case .assign(let n,let e):values[n]=evaluate(e)}}}
 public func intBinding(_ n:String)->Binding<Int>{Binding(get:{if case .int(let x)=self.values[n]{return x};return 0},set:{self.values[n]=.int($0)})}
 public func stringBinding(_ n:String)->Binding<String>{Binding(get:{if case .string(let x)=self.values[n]{return x};return ""},set:{self.values[n]=.string($0)})}
 public func boolBinding(_ n:String)->Binding<Bool>{Binding(get:{if case .bool(let x)=self.values[n]{return x};return false},set:{self.values[n]=.bool($0)})}
 public func string(_ v:RuntimeValue)->String{switch v{case .int(let n):return String(n);case .bool(let b):return b ? "true":"false";case .string(let s):return s}}
}