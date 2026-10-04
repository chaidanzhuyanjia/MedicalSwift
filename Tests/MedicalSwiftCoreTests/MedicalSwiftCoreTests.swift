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
 func testPEDTFormPickerComputedConditional()throws{
  let p=try SwiftSubsetParser().parse("""
  import SwiftUI
  struct ContentView: View {
    @State var q1 = 0
    @State var q2 = 0
    var total: Int { q1 + q2 }
    var body: some View {
      Form {
        Section("PEDT demo") {
          Picker("Q1", selection: $q1) {
            Text("0 points").tag(0)
            Text("4 points").tag(4)
          }
          Text("Total: \\(total)")
          if total >= 4 {
            Text("Higher score")
          } else {
            Text("Lower score")
          }
        }
      }
    }
  }
  """)
  XCTAssertEqual(p.state["q1"],.int(0))
  XCTAssertEqual(p.state["q2"],.int(0))
  XCTAssertEqual(p.computed.first?.name,"total")
  guard case .form(let formChildren)=p.root,
        case .section(_,let sectionChildren)=formChildren.first
  else{return XCTFail("Expected Form > Section")}
  XCTAssertEqual(sectionChildren.count,3)
 }

 func testForEachRangeLowering()throws{
  let p=try SwiftSubsetParser().parse("""
  import SwiftUI
  struct ContentView: View {
    @State var count = 3
    var body: some View {
      VStack {
        ForEach(0..<count, id: \\.self) { i in
          Text("Row \\(i)")
        }
      }
    }
  }
  """)
  guard case .vStack(let children)=p.root,
        case .forEachRange(let start,let end,let variable,let template)=children.first
  else{return XCTFail("Expected VStack > ForEach range")}
  XCTAssertEqual(start,0)
  XCTAssertEqual(end,.variable("count"))
  XCTAssertEqual(variable,"i")
  XCTAssertEqual(template.count,1)
 }

 func testArithmeticAssignmentsAndBoolCondition()throws{
  let p=try SwiftSubsetParser().parse("""
  import SwiftUI
  struct ContentView: View {
    @State var value = 2
    @State var enabled = false
    var doubled: Int { value * 2 }
    var body: some View {
      VStack {
        Text("Double: \\(doubled)")
        Button("Add") { value = value + 3 }
        Button("Minus") { value -= 1 }
        Button("Toggle") { enabled.toggle() }
        if enabled == true {
          Text("Enabled")
        } else {
          Text("Disabled")
        }
      }
    }
  }
  """)
  XCTAssertEqual(p.state["value"],.int(2))
  XCTAssertEqual(p.state["enabled"],.bool(false))
  XCTAssertEqual(p.computed.first(where:{$0.name=="doubled"})?.expression,.multiply(.variable("value"),.int(2)))
  guard case .vStack(let children)=p.root else{return XCTFail("Expected VStack")}
  XCTAssertEqual(children.count,5)
 }


 func testStaticArrayForEachLowering()throws{
  let p=try SwiftSubsetParser().parse("""
  import SwiftUI
  struct ContentView: View {
    let items = ["Pain", "Urinary", "QoL"]
    var body: some View {
      List {
        ForEach(items, id: \\.self) { item in
          Text("Item: \\(item)")
        }
      }
    }
  }
  """)
  XCTAssertEqual(
    p.state["items"],
    RuntimeValue.array([
      .string("Pain"), .string("Urinary"), .string("QoL")
    ])
  )
  guard case .list(let children)=p.root,
        case .forEachCollection(let collection,let variable,let template)=children.first
  else{return XCTFail("Expected List > collection ForEach")}
  XCTAssertEqual(collection,Expression.variable("items"))
  XCTAssertEqual(variable,"item")
  XCTAssertEqual(template.count,1)
 }


 func testDoubleArithmeticAndDivision()throws{
  let p=try SwiftSubsetParser().parse("""
  import SwiftUI
  struct ContentView: View {
    @State var dose = 2.5
    var total: Double { dose * 3 }
    var half: Double { total / 2 }
    var body: some View {
      VStack {
        Text("Dose: \\(dose)")
        Text("Total: \\(total)")
        Text("Half: \\(half)")
        Button("Add half") { dose += 0.5 }
        if total >= 9.0 {
          Text("High")
        } else {
          Text("Low")
        }
      }
    }
  }
  """)
  XCTAssertEqual(p.state["dose"],RuntimeValue.double(2.5))
  XCTAssertEqual(
    p.computed.first(where:{$0.name=="total"})?.expression,
    Expression.multiply(.variable("dose"),.int(3))
  )
  XCTAssertEqual(
    p.computed.first(where:{$0.name=="half"})?.expression,
    Expression.divide(.variable("total"),.int(2))
  )
 }


}