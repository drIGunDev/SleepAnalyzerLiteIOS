//
//  ArchiveView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.06.25.
//

import SwiftUI
import SwiftInjectLite

struct ArchiveView: View {
    
    @State private var archiveViewModel = InjectionRegistry.inject(\.archiveViewModel)
    
    @State private var itemToDelete: UpdatableWrapper<SeriesDTO>? = nil
    @State private var itemToScale: UpdatableWrapper<SeriesDTO>? = nil
    @State private var isTabbarVisible = true
    @State private var invalidateAllItems = false
    @State private var scaleDialogParams: ScaleDialogParams = .init()
    
    @State private var isScaleDialogPresented = false
    
    @State private var isScaleBulckDialogPresented = false
    @State private var isProgressStarted = false
    @State private var progressMessage: String? = nil
    @State private var progressValue: Double = 0.0
    @State private var isBulckScalingCanceled = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(Color.mainBackground).edgesIgnoringSafeArea(.all)
                List {
                    ForEach(archiveViewModel.seriesArray, id: \.wrappedValue.id) { series in
                        ZStack(alignment: .center) {
                            ArchiveCellView(series: series.wrappedValue)
                                .id(series.presentationId.uuidString + invalidateAllItems.description)
                            NavigationLink (value: series.wrappedValue) { EmptyView() }.opacity(0.0)
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(
                                action: { self.itemToDelete = series },
                                label: { Label("Delete", systemImage: "trash.fill") }
                            )
                            .tint(.red)
                            Button(
                                action: { self.itemToScale = series; isScaleDialogPresented.toggle() },
                                label: { Label("Scale", systemImage: "scale.3d") }
                            )
                            .tint(.green)
                        }
                        .alert(
                            "Do you want to delete this series?",
                            isPresented: Binding(get: { self.itemToDelete != nil }, set: { _ in self.itemToDelete = nil }),
                            presenting: "",
                            actions: { _ in
                                Button("Delete", role: .destructive) { archiveViewModel.delete(series: self.itemToDelete!) }
                                Button("Cancel", role: .cancel) { }
                            },
                            message: { _ in Text("This action cannot be undone.")}
                        )
                    }
                    .listRowSeparator(.hidden)
                }
                .navigationDestination(for: SeriesDTO.self) { series in
                    DetailView(series: series, isTabbarVisible: $isTabbarVisible)
                }
                .onAppear(perform: archiveViewModel.fetchAll)
                .popup(
                    isPresented: $isScaleDialogPresented,
                    dialog: ScaleDialog(
                        scaleDialogParams: $scaleDialogParams,
                        cancelAction: { isScaleDialogPresented.toggle() },
                        okAction: {
                            isScaleDialogPresented.toggle()
                            
                            archiveViewModel.repository
                                .rescaleHR(
                                    seriesId: self.itemToScale!.wrappedValue.id,
                                    renderParams: .init(),
                                    rescaleParams: AppSettings.shared.toRescaleParams()
                                ) { isOk in
                                    if isOk {
                                        self.itemToScale?.invalidateId()
                                    }
                                }
                        }
                    ),
                    horizontalPadding: UIConfig.popupHorizontalPadding
                )
                .popup(
                    isPresented: $isScaleBulckDialogPresented,
                    dialog: ScaleDialog(
                        scaleDialogParams: $scaleDialogParams,
                        cancelAction: { isScaleBulckDialogPresented.toggle() },
                        okAction: {
                            isScaleBulckDialogPresented.toggle()
                            isProgressStarted.toggle()
                            
                            archiveViewModel.repository
                                .rescaleAllHR(
                                    renderParams: .init(),
                                    rescaleParams: AppSettings.shared.toRescaleParams(),
                                    progress: { index, count in
                                        self.progressMessage = "Scaling \(index)/\(count)"
                                        progressValue = Double(index) / Double(count)
                                    },
                                    cancel: { isBulckScalingCanceled },
                                    completion: {
                                        isProgressStarted = false
                                        isBulckScalingCanceled = false
                                        invalidateAllItems.toggle()
                                        progressValue = 0
                                    }
                                )
                        }
                    ),
                    horizontalPadding: UIConfig.popupHorizontalPadding
                )
                .popup(
                    isPresented: $isProgressStarted,
                    dialog: ProgressDialog(
                        title: "Scaling ...",
                        message: $progressMessage,
                        progress: $progressValue,
                        cancelAction: { isBulckScalingCanceled.toggle() }
                    ),
                    horizontalPadding: UIConfig.popupHorizontalPadding
                )
                .toolbar(isTabbarVisible ? .visible : .hidden, for: .tabBar)
                .navigationTitle(Text("Archive"))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("Rescale all"){ isScaleBulckDialogPresented.toggle() })
                .listStyle(PlainListStyle())
            }
        }
    }
}
