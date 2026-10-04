import SwiftUI
public struct NativeRenderer:View{
 @ObservedObject var runtime:ScriptRuntime;let node:ViewNode
 public init(runtime:ScriptRuntime,node:ViewNode?=nil){self.runtime=runtime;self.node=node ?? runtime.root}
 @ViewBuilder public var body:some View{switch node{
 case .text(let e):Text(runtime.string(runtime.evaluate(e)))
 case .button(let t,let a):Button(runtime.string(runtime.evaluate(t))){runtime.execute(a)}
 case .textField(let t,let b):TextField(t,text:runtime.stringBinding(b))
 case .toggle(let t,let b):Toggle(t,isOn:runtime.boolBinding(b))
 case .vStack(let c):VStack(spacing:16){children(c)}
 case .hStack(let c):HStack{children(c)}
 case .form(let c):Form{children(c)}
 case .list(let c):List{children(c)}
 case .navigationStack(let c):NavigationStack{children(c)}
 case .section(let t,let c):if let t{Section(t){children(c)}}else{Section{children(c)}}
 case .picker(let t,let s,let o):Picker(t,selection:runtime.intBinding(s)){ForEach(o,id:\.value){Text($0.title).tag($0.value)}}
 case .conditional(let q,let y,let n):if runtime.test(q){children(y)}else{children(n)}
 case .forEachRange(let start,let endExpr,let variable,let template):
  if case .int(let end)=runtime.evaluate(endExpr){
   ForEach(start..<max(start,end),id:\.self){i in
    children(template.map{$0.substituting(variable:variable,with:i)})
   }
  }
 case .spacer:Spacer()
 case .modified(let base,let mods):ModifiedRenderer(runtime:runtime,base:base,modifiers:mods)
 }}
 @ViewBuilder private func children(_ c:[ViewNode])->some View{ForEach(Array(c.enumerated()),id:\.offset){_,v in NativeRenderer(runtime:runtime,node:v)}}
}
private struct ModifiedRenderer:View{
 @ObservedObject var runtime:ScriptRuntime;let base:ViewNode;let modifiers:[ViewModifier]
 var body:some View{modifiers.reduce(AnyView(NativeRenderer(runtime:runtime,node:base))){view,m in switch m{case .padding:return AnyView(view.padding());case .navigationTitle(let s):return AnyView(view.navigationTitle(s));case .font(let f):let font:Font=f == .title ? .title : f == .headline ? .headline : f == .caption ? .caption : .body;return AnyView(view.font(font))}}}
}
private extension ViewNode{
 func substituting(variable:String,with value:Int)->ViewNode{
  switch self{
  case .text(let e):return .text(e.substituting(variable:variable,with:value))
  case .button(let t,let a):return .button(title:t.substituting(variable:variable,with:value),action:a.map{$0.substituting(variable:variable,with:value)})
  case .textField,.toggle,.picker,.spacer:return self
  case .vStack(let c):return .vStack(c.map{$0.substituting(variable:variable,with:value)})
  case .hStack(let c):return .hStack(c.map{$0.substituting(variable:variable,with:value)})
  case .form(let c):return .form(c.map{$0.substituting(variable:variable,with:value)})
  case .list(let c):return .list(c.map{$0.substituting(variable:variable,with:value)})
  case .navigationStack(let c):return .navigationStack(c.map{$0.substituting(variable:variable,with:value)})
  case .section(let t,let c):return .section(title:t,children:c.map{$0.substituting(variable:variable,with:value)})
  case .conditional(let q,let y,let n):return .conditional(condition:q.substituting(variable:variable,with:value),then:y.map{$0.substituting(variable:variable,with:value)},otherwise:n.map{$0.substituting(variable:variable,with:value)})
  case .forEachRange(let s,let e,let v,let t):
   return .forEachRange(start:s,end:e.substituting(variable:variable,with:value),variable:v,template:t.map{$0.substituting(variable:variable,with:value)})
  case .modified(let b,let m):return .modified(b.substituting(variable:variable,with:value),m)
  }
 }
}
private extension Expression{
 func substituting(variable:String,with value:Int)->Expression{
  switch self{
  case .variable(let n) where n==variable:return .int(value)
  case .add(let a,let b):return .add(a.substituting(variable:variable,with:value),b.substituting(variable:variable,with:value))
  case .interpolated(let p):return .interpolated(p.map{$0.substituting(variable:variable,with:value)})
  default:return self
  }
 }
}
private extension InterpolationPart{
 func substituting(variable:String,with value:Int)->InterpolationPart{
  switch self{
  case .literal:return self
  case .expression(let e):return .expression(e.substituting(variable:variable,with:value))
  }
 }
}
private extension Condition{
 func substituting(variable:String,with value:Int)->Condition{
  switch self{
  case .compare(let l,let op,let r):return .compare(l.substituting(variable:variable,with:value),op,r.substituting(variable:variable,with:value))
  }
 }
}
private extension Statement{
 func substituting(variable:String,with value:Int)->Statement{
  switch self{
  case .increment:return self
  case .assign(let n,let e):return .assign(name:n,value:e.substituting(variable:variable,with:value))
  }
 }
}
