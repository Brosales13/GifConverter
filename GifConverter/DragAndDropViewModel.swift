//
//  DragAndDropViewModel.swift
//  GifConverter
//
//  Created by Rosales,Brian on 9/2/25.
//
import Foundation
import SwiftUI

extension DragAndDropView {
    /// @Observable allows us to remove the need of @Published...
    @Observable class Model {
        /// The media that will converted
        var media: [URL] = []
    
        /// The location of the converted files
        var convertedFiles: [String: URL] = [:]
        
        // MARK: - File copy helper
        
        //TODO: We might not need this
        func copyIntoDocuments(_ sourceURL: URL) throws -> URL {
            let fm = FileManager.default
            let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dest = docs.appendingPathComponent(sourceURL.lastPathComponent)

            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }

            if sourceURL.startAccessingSecurityScopedResource() {
                defer { sourceURL.stopAccessingSecurityScopedResource() }
                try fm.copyItem(at: sourceURL, to: dest)
            } else {
                try fm.copyItem(at: sourceURL, to: dest)
            }
            return dest
        }
        
        func saveImports(urls: [URL]) {
            let mediaLocations: [URL] = urls.compactMap { item in
                do {
                    return try copyIntoDocuments(item)

                } catch {
                    print("Copy failed: \(error)")
                }
                return nil
            }
            
            self.media = mediaLocations
        }
    }
}
