//
//  SaveLoadManager.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-05-01.
//
import SwiftUI
import UniformTypeIdentifiers

struct FinacctFile: FileDocument {
    static var readableContentTypes: [UTType] { [.finacct, .data] }
    static var writableContentTypes: [UTType] { [.finacct, .data] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = fileData
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}
