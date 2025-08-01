//
//  TestObservable.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 25.06.25.
//

import SwiftUI
import Combine

protocol MicroModel: ObservableObject {
    var counter: Int { get set }
    var counterPublisher: PassthroughSubject<Int, Never> { get }
    var counterCurrentValuePublisher: CurrentValueSubject<Int, Never> { get }
}

@Observable class MicroModelImpl: MicroModel {
    var counterPublisher = PassthroughSubject<Int, Never>()
    var counterCurrentValuePublisher = CurrentValueSubject<Int, Never>(0)
    
    var counter: Int = 0 {
        didSet {
            counterPublisher.send(counter)
            counterCurrentValuePublisher.send(counter)
        }
    }
}

protocol TestObservable: ObservableObject {
    var name: String { get set }
    var length: Int { get }
    var model: any MicroModel { get set }
    
    func incCounter()
}

@Observable class TestObservableImpl: TestObservable {
    
    var model: any MicroModel
    
    //big deal!!!
    @ObservationIgnored @Published var name: String = ""
    
    var length: Int = 0
    
    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []
    
    init(name: String = "", model: any MicroModel = MicroModelImpl()) {
        self.name = name
        self.model = model
        $name
            .sink { [weak self] value in
                self?.length = value.count
                self?.model.counter += 1
            }
            .store(in: &cancellables)
        
        model.counterPublisher
            .sink { [weak self] value in
                self?.length = value
            }
            .store(in: &cancellables)
        
        model.counterCurrentValuePublisher
            .sink { [weak self] value in
                self?.length = value
            }
            .store(in: &cancellables)
    }
    
    func incCounter() {
        model.counter += 10
    }
}

struct TestObservableContentView: View {
    @State var observable: any TestObservable = TestObservableImpl.init()
    
    var body: some View {
        VStack (alignment: .center) {
            Text("Model Counter: \(observable.model.counter)")
            Text("Name Length: \(observable.length)")
            Text("Name: \(observable.name)")
            TextField("Name", text: $observable.name)
                .multilineTextAlignment(.center)
            Button("Increment model counter") {
                observable.incCounter()
            }
        }
        .padding()
    }
}

struct TestObservableContentView_Previews: PreviewProvider {
    static var previews: some View {
        TestObservableContentView()
    }
}
