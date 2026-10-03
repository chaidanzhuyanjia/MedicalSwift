import Foundation
public indirect enum ViewNode:Equatable,Sendable{
 case text(Expression),button(title:Expression,action:[Statement])
 case textField(title:String,binding:String),toggle(title:String,binding:String)
 case vStack([ViewNode]),hStack([ViewNode]),form([ViewNode]),list([ViewNode]),navigationStack([ViewNode])
 case section(title:String?,children:[ViewNode]),picker(title:String,selection:String,options:[PickerOption])
 case conditional(condition:Condition,then:[ViewNode],otherwise:[ViewNode]),spacer
 case modified(ViewNode,[ViewModifier])
}
public enum ViewModifier:Equatable,Sendable{case padding,navigationTitle(String),font(FontToken)}
public enum FontToken:String,Equatable,Sendable{case title,headline,body,caption}
public struct PickerOption:Equatable,Sendable{public let title:String;public let value:Int;public init(title:String,value:Int){self.title=title;self.value=value}}
public indirect enum Expression:Equatable,Sendable{case int(Int),bool(Bool),string(String),variable(String),interpolated([InterpolationPart]),add(Expression,Expression)}
public enum InterpolationPart:Equatable,Sendable{case literal(String),expression(Expression)}
public enum Condition:Equatable,Sendable{case compare(Expression,CompareOperator,Expression)}
public enum CompareOperator:String,Equatable,Sendable{case lt="<",lte="<=",gt=">",gte=">=",eq="==",neq="!="}
public enum Statement:Equatable,Sendable{case increment(name:String,amount:Int),assign(name:String,value:Expression)}
public struct ComputedProperty:Equatable,Sendable{public let name:String;public let expression:Expression;public init(name:String,expression:Expression){self.name=name;self.expression=expression}}
public struct ScriptProgram:Equatable,Sendable{public var state:[String:RuntimeValue];public var computed:[ComputedProperty];public var root:ViewNode;public init(state:[String:RuntimeValue],computed:[ComputedProperty]=[],root:ViewNode){self.state=state;self.computed=computed;self.root=root}}
public enum RuntimeValue:Equatable,Sendable{case int(Int),bool(Bool),string(String)}
