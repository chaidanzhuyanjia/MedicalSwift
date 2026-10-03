import XCTest
import SwiftParser
@testable import MedicalSwiftCore
final class MedicalSwiftCoreTests:XCTestCase{
 func testCounter()throws{
  let p=try SwiftSubsetParser().parse("""
  import SwiftUI
  struct ContentView: View {
    @State var count = 0
    var body: some View {
      VStack {
        Text("Count: \\(count)")
        Button("Tap me") { count += 1 }
      }
    }
  }
  """)
  XCTAssertEqual(p.state["count"],.int(0))
  guard case .vStack(let c)=p.root else{return XCTFail("Expected VStack")}
  XCTAssertEqual(c.count,2)
 }
 func testASTStateAndComputed()throws{
  let tree=Parser.parse(source:"""
  struct ContentView: View {
    @State var q1 = 1
    @State var q2 = 2
    var total: Int { q1 + q2 }
    var body: some View { Text("x") }
  }
  """)
  let m=try ASTModelExtractor().extract(from:tree)
  XCTAssertEqual(m.state["q1"],.int(1));XCTAssertEqual(m.computed.first?.name,"total")
 }
}