//
//  CreateGif.swift
//  GifConverter
//
//  Created by Rosales,Brian on 8/28/25.
//

import AVFoundation
import SwiftUI
import Foundation


// Custom error used for throwing.
private struct CustomError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Defines aspects of the MOV file that was extracted from.
struct VideoAssets {
    let filePath: URL
    let samplePoints: [CMTime]
    let totalFrames: Int
    let fileProperties: [String: Any]
    let frameProperties: [String: Any]
    let generator: AVAssetImageGenerator
}

/// Is responsible for generating a gif from a MOV or MP4 file. It resizes the images as well as compresses them to the smallest we can make it. Tested on 1920 X 1080 @ 11 secs MOV file.
/// This Converter was able to drop it to 4.2 MB.
/// If anything we should record in 720p for widgets. 1080 might be too high. This would also allow to increase the FPS if desired.
class GIFGenerator {
    /// Will attempt to create a GIF from the provided URL. If it fails it will throw.
    /// - Parameter url: Location of the Mov file
    public func attemptCreatingGIF(url: URL) async throws {
        // Check if the MOV exist and if so attempt to create the GIF
        try await attemptGeneratingGif(from: url, withFrameRate: 15, withDisposalMethod: 2)
    }
    
    /// - Parameters:
    ///   - filePath: location of the Mov file
    ///   - frameRate: The desired Frame Rate
    ///   - disposalMethod: The desired Diposal Method for the GIF
    private func attemptGeneratingGif(
        from filePath: URL,
        withFrameRate frameRate: Double,
        withDisposalMethod disposalMethod: UInt8
    ) async throws {
        guard let videoAsset = try await extractAVAssets(filePath: filePath, frameRate: frameRate) else { return }
        
        // Init the file manager
        let fileManager = FileManager.default
        
        // Set locations to Documents
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        
        // Should remove optional value and error out if not successful
        guard let documentsURL else {
            throw CustomError(message: "Document URL not working")
        }
        
        // Add Folder Name
        let folderURL = documentsURL.appendingPathComponent("movToGifFiles")
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: folderURL.path()) {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        /// The path that will be used to create the first iteration of the GIF.
        let outputPath = folderURL.appendingPathComponent("\(filePath.deletingPathExtension().lastPathComponent).gif").standardizedFileURL
        
        // Generate the first iteration of the GIF
        let didGenerateGif = try await generateGif(
            filePath: filePath,
            folderURL: folderURL,
            videoAsset: videoAsset,
            outputPath: outputPath
        )
        
        guard didGenerateGif else {
            throw CustomError(message: "Gif failed to generate")
        }
        
        // Will check and modify the disposal method of a gif.
        try checkDisposalMethod(filePath: outputPath, disposalMethod: disposalMethod, mediaPath: filePath)
    }
    
    /// - Parameters:
    ///   - filePath: The file path in which the mov files is located
    ///   - frameRate: Frame Rate
    private func extractAVAssets(filePath: URL, frameRate: Double) async throws -> VideoAssets? {
        // Fetch video from file path
        let asset = AVURLAsset(url: filePath)
        
        // Get the duration of the video
        guard let duration = try? await asset.load(.duration).seconds else {
            throw CustomError(message: "Couldn't get video duration")
        }
        
        // The amount of frames in a video
        let totalFrames: Int = Int(duration * frameRate)
        
        
        // Time between frames given duration and frame rate
        let frameDelay: Double = 1 / frameRate
        let range = 0 ..< totalFrames
        
        // Is this the time when a frame should be showing up at?
        let samplePoints: [CMTime] = range.map {
            let timeMarker = frameDelay * Double($0)
            let time = CMTime(seconds: timeMarker, preferredTimescale: Int32(NSEC_PER_SEC))
            return time
        }
        
        // Setting up Image Generator
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.maximumSize = CGSize(width: 1920, height: 1080)
        
        // Set up resulting image
        let fileProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0,
            ]
        ]
        
        // Properties for a single frame
        let frameProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime: frameDelay
            ]
        ]
        
        return .init(
            filePath: filePath,
            samplePoints: samplePoints,
            totalFrames: totalFrames,
            fileProperties: fileProperties,
            frameProperties: frameProperties,
            generator: generator,
        )
    }
    
    private func generateGif(
        filePath: URL,
        folderURL: URL,
        videoAsset: VideoAssets,
        outputPath: URL
    ) async throws -> Bool {
        
        // Creating CGImageDestination URL
        guard let destination = CGImageDestinationCreateWithURL(
            outputPath as CFURL,
            UTType.gif.identifier as CFString,
            videoAsset.totalFrames,
            nil
        ) else {
            throw CustomError(message: "Failed to create CGImageDestination with URL")
        }
        
        // Setting CGImageDestination Properties
        CGImageDestinationSetProperties(destination, videoAsset.fileProperties as CFDictionary)
        
        /// Fetch the images that are stored in the videoAssets
        let cgiImages = await fetchCGIImages(samplePoint: videoAsset.samplePoints, generator: videoAsset.generator)
        
        // resize the images that were retrieved
        let resizedImages: [CGImage]  = resizeCGImage(cgiImages, to: .init(width: 320, height: 180))
        
        // Compress Images to the
        let compressedImages = try compressCGImage(images: resizedImages, quality: 0)
        
        // Loop through compressed Images and create the first gif
        _ = compressedImages.map({ image in
            // Creates the very first Gif without any specific disposal method
            CGImageDestinationAddImage(destination, image, videoAsset.frameProperties as CFDictionary)
        })
        
        // Returns true if the image destination successfully finalized the images, or false if an error occurred.
        let didFinalizeImages = CGImageDestinationFinalize(destination)
        
        guard didFinalizeImages else {
            throw CustomError(message: "Failed to finalize Image")
        }
        
        return true
    }
    
    private func checkDisposalMethod(filePath: URL, disposalMethod: UInt8, mediaPath: URL) throws {
        // Check incoming disposal Method is an existing standard
        guard disposalMethod < 7  else {
            throw CustomError(message: "Not a valid disposal method")
        }
        
        // Attempt to convert the data
        guard var data = NSData(contentsOfFile: filePath.relativePath) as? Data else {
            throw CustomError(message: "Couldn't get bytes from file")
        }
        
        for (i, byte) in data.enumerated() where byte == 33 && data[i + 1] == 249 {
            //            print("Before: \(data[i + 3])")
            let mask: UInt8 = (7 << 2)
            data[i + 3] = (data[i + 3] & ~mask) | ((disposalMethod << 2) & mask)
            //            print("After: \(data[i + 3])")
            break
        }
        
        //Remove files that were used to create and modified.
        removeFile(url: filePath)
        removeFile(url: mediaPath)
        
        do {
            let fileManager = FileManager.default
            
            // The URL that shows the path to document tab on mac
            let appSupportDir = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            let gifName = filePath.deletingPathExtension().lastPathComponent
            
            let folderName = "movToGifFiles"
            
            // The location in which the final gif will be saved
            let gifLocation = appSupportDir.appendingPathComponent("\(folderName)/\(gifName).gif").path()
            
            let result = fileManager.createFile(atPath: gifLocation, contents: data, attributes: nil)
            
            if !result {
                throw CustomError(message: "Couldn't save file")
            }
            
        } catch {
            throw CustomError(message: "Couldn't get create a directory for the file")
        }
    }
    
    private func fetchCGIImages(samplePoint: [CMTime], generator: AVAssetImageGenerator) async -> [CGImage] {
        var images: [CGImage] = []
        
        for i in samplePoint {
            if let result = await generateCGIImages(samplePoint: i, generator: generator) {
                images.append(result)
            }
        }
        return images
    }
    
    private func generateCGIImages(samplePoint: CMTime, generator: AVAssetImageGenerator) async -> CGImage? {
        await withCheckedContinuation { continuation in
            generator.generateCGImageAsynchronously(for: samplePoint, completionHandler: { cgimage, CMTime, error in
                continuation.resume(returning: cgimage)
            })
        }
    }
    
    // resize the image
    func resizeCGImage(_ images: [CGImage], to size: CGSize) -> [CGImage] {
        let resizedImages: [CGImage] = images.compactMap { image in
            guard let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: image.bitsPerComponent,
                bytesPerRow: 0,
                space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: image.bitmapInfo.rawValue
            ) else {
                return nil
            }
            
            context.interpolationQuality = .high
            context.draw(image, in: CGRect(origin: .zero, size: size))
            return context.makeImage()
        }
        return resizedImages
    }
    
    /// An api that allows to compress the size of an array of CGImages
    /// - Parameters:
    ///   - images: An array of CGImages
    ///   - quality: The amount we want to compress the image. Range 0.0 - 1.0
    /// - Returns: [CGImage]
    func compressCGImage(images: [CGImage], quality: CGFloat) throws -> [CGImage] {
        let compressedImages: [CGImage] = images.compactMap { image in
            // 1. Create a mutable data object to store the compressed image
            guard let mutableData = CFDataCreateMutable(nil, 0) else {
                return nil
            }
            
            // 2. Create an image destination for the PNG format to be able to support alpha channels
            guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.png.identifier as CFString, 1, nil) else {
                return nil
            }
            
            // 3. Set the compression quality option
            let options: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: quality
            ]
            
            // 4. Add the CGImage to the destination with options
            CGImageDestinationAddImage(destination, image, options as CFDictionary)
            
            // 5. Finalize the image destination and return the compressed data
            if CGImageDestinationFinalize(destination) {
                let imageData = mutableData as Data
                
                // NSImage is legit!
                return NSImage(data: imageData)?.cgImage
                
            } else {
                return nil
            }
        }
        
        return compressedImages
    }
    
    private func removeFile(url: URL) {
        // Delete the video from disk
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Extensions

extension NSImage {
    var cgImage: CGImage? {
        var rect = CGRect(origin: .zero, size: self.size)
        return self.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }
}

extension CGImage {
    var nsImage: NSImage {
        NSImage(cgImage: self, size: NSSize(width: self.width, height: self.height))
    }
}

