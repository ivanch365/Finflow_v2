//
//  FilterView.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//

import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var start: Date
    @Binding var end: Date
    @Binding var isFiltering: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("From") {
                    DatePicker("Start Date", selection: $start, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.graphical)
                }
                Section("To") {
                    DatePicker("End Date", selection: $end, in: start..., displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("Filter by Date")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        isFiltering = true
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
