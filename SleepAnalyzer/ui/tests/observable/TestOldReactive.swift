//
//  TestOldReactive.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 11.07.25.
//

import SwiftUI

protocol OldReactViewModel {
    var text: String { get set }
}

class OldReactViewModleImpl: OldReactViewModel, ObservableObject {
    @Published var text = "Hello, World!"
}

struct OldReactView: View {

    
    typealias SelfType = OldReactView
    
//    @ObservedObject var viewModel: any OldReactViewModel = OldReactViewModleImpl()
//    @StateObject var viewModel: any OldReactViewModel = OldReactViewModleImpl()
    @State var viewModel: any OldReactViewModel = OldReactViewModleImpl()
    
    var body: some View {
        OldView(text: $viewModel.text)
    }
}

struct OldView: View {
    @Binding  var text: String
    
    var body: some View {
        Text(text)
    }
}

struct TestOldReactive: PreviewProvider {
    
    static var previews: some View {
        OldReactView()
    }
    
}
