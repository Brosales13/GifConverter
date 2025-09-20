//
//  ContentView.swift
//  GifConverter
//
//  Created by Rosales,Brian on 8/28/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

//TODO: add images with name of files. if pressed it should take us to the location of the file.
struct DragAndDropView: View {
    enum state {
        case loaded
        case loading
        case dragView
    }
    
    /// Keeps track of when to expand and collapse side folder
    @State private var isConvertedFilesExpanded: Bool = true
    
    /// The model for this screen
    @State var model = DragAndDropView.Model()
    
    /// Keeps track of when to show the loading spinner
    @State var showLoadingSpinner: Bool = false
    
    /// Gif Converter
    let gifConverter = GIFGenerator()
    
    
    // MARK: - View
    var body: some View {
        NavigationSplitView {
            List {
                convertedFiles
            }
            .listStyle(.sidebar)
            
        } detail: {
//            if showLoadingSpinner {
//                VStack(spacing: 34) {
//                    Text("Generating GIF...")
//                        .font(.title)
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle())
//                        .scaleEffect(2.0, anchor: .center)
//                }
//            } else {
//                dragAndDrop
//            }
            
            displayGifs
        }
        .toolbar {
            VStack(alignment: .trailing) {
                Button(action: {}, label: {
                    Text("Convert Other Files")
                        .foregroundStyle(.primary)
                })
            }
        }
    }
    
    private var displayGifs: some View {
        List {
            GifCell(image: nil, title: "test1", duration: 3)
            GifCell(image: nil, title: "test2", duration: 5)
        }
    }
    
    private var convertedFiles: some View {
        Section(
            isExpanded: $isConvertedFilesExpanded,
            content: {
                VStack(alignment: .leading) {
                    ForEach(Array(model.convertedFiles), id: \.key) { gifTitle, url in
                        Text(gifTitle)
                    }
                }
            },
            header: {
                HStack() {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.teal)
                    Text("Converted Files")
                }
            }
        )
    }
    
    private var dragAndDrop: some View {
        VStack(spacing: 16) {
            Text("Drag .MOV Files")
                .font(.largeTitle)
            
            Image(systemName: "film")
                .font(.system(size: 60))
            
            Button(action: {
                Task {
                    await createGif()
                }
            }, label: {
                Text("Convert")
            })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dropDestination(for: URL.self) { items, session in
            let urls = items
            let pathExtension: [URL] = urls.compactMap {
                let pathExtension = $0.pathExtension.lowercased()
                print("pathExtension: \(pathExtension)")
                guard pathExtension == "mov" || pathExtension == "mp4" else { return nil }
                return $0
            }
            
            // Save into the app
            model.saveImports(urls: pathExtension)
            
            return true
        }
    }
    
    func createGif() async {
        let importedMedia = model.media
        print("started")
        self.showLoadingSpinner = true
        
        for media in importedMedia {
            do {
                //TODO: Next step is fetching the first frame of video and matching it up some how and returning it here...along with duration, and title...
                try await gifConverter.attemptCreatingGIF(url: media)
            } catch {
                print("error: \(error)")
            }
        }
        
        showLoadingSpinner = false
        print("Completed")
    }
}

// MARK: - Preview
#Preview {
    DragAndDropView()
}
