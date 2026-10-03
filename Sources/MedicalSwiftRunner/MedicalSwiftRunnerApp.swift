import SwiftUI
import MedicalSwiftCore
@main struct MedicalSwiftRunnerApp:App{var body:some Scene{WindowGroup{RunnerHomeView()}}}
struct RunnerHomeView:View{
 @State private var source=""" 
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
 """
 @State private var runtime:ScriptRuntime?
 @State private var error:String?
 var body:some View{NavigationStack{TextEditor(text:$source).font(.system(.body,design:.monospaced)).padding().navigationTitle("MedicalSwift").toolbar{Button{run()}label:{Label("Run",systemImage:"play.fill")}}.navigationDestination(isPresented:Binding(get:{runtime != nil},set:{if !$0{runtime=nil}})){if let runtime{NativeRenderer(runtime:runtime)}}.alert("Cannot run",isPresented:Binding(get:{error != nil},set:{if !$0{error=nil}})){Button("OK"){error=nil}}message:{Text(error ?? "")}}}
 private func run(){do{runtime=ScriptRuntime(program:try SwiftSubsetParser().parse(source))}catch{self.error=error.localizedDescription}}
}