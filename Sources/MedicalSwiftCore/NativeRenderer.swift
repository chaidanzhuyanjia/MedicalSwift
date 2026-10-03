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
 case .spacer:Spacer()
 case .modified(let base,let mods):ModifiedRenderer(runtime:runtime,base:base,modifiers:mods)
 }}
 @ViewBuilder private func children(_ c:[ViewNode])->some View{ForEach(Array(c.enumerated()),id:\.offset){_,v in NativeRenderer(runtime:runtime,node:v)}}
}
private struct ModifiedRenderer:View{
 @ObservedObject var runtime:ScriptRuntime;let base:ViewNode;let modifiers:[ViewModifier]
 var body:some View{modifiers.reduce(AnyView(NativeRenderer(runtime:runtime,node:base))){view,m in switch m{case .padding:return AnyView(view.padding());case .navigationTitle(let s):return AnyView(view.navigationTitle(s));case .font(let f):let font:Font=f == .title ? .title : f == .headline ? .headline : f == .caption ? .caption : .body;return AnyView(view.font(font))}}}
}