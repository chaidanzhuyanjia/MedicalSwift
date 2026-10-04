import Foundation
public struct SourceLocation:Equatable,Sendable{public let line:Int;public let column:Int;public init(line:Int,column:Int){self.line=line;self.column=column}}
public struct RuntimeDiagnostic:Error,LocalizedError,Equatable,Sendable{
 public let message:String;public let location:SourceLocation?
 public init(_ message:String,location:SourceLocation?=nil){self.message=message;self.location=location}
 public var errorDescription:String?{guard let location else{return message};return "Line \(location.line), column \(location.column): \(message)"}
}
