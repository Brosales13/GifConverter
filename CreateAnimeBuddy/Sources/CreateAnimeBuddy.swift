// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Foundation

//TODO: Will need to delete later and instead import Anime Buddies so that its scalable
enum AnimationType: String, Codable, CaseIterable {
    case idle
    case dance
    case dance2
    case panic
    case beam
    case vibe
    case happy
    case silly
    case sleepy
    case mad
    case freakOut
}

// This actually Might be modified and not shared with the project itself
private struct CreateCharacterConfiguration: Codable {
    // Character Name
    let name: String
    
    // Class Type
    let classType: String
    
    // Whether membership is needed to use character
    let membershipNeeded: Bool
    
    // Dictionary of character outfits with an array of animations types in their string form
    let characterOutfits: [String: [String]]?
    
    // Dictionary of CharacterOutfits tied with their video links for home page
    let videoLinks: [String: String]
    
    // The current outfit that is selected or defaulted too.
    let currentOutfit: String
    
    // Determines whether or not to show the character on production.
    let onProduction: Bool
    
    // Determines the order of the characters when displaying to users
    let priority: Int
    
    // Is the unique ID given to every character
    let characterId: Int
    
    
    init(
        name: String,
        classType: String,
        membershipNeeded: Bool,
        characterOutfits: [String: [String]]? = nil,
        videoLinks: [String: String] = [:],
        currentOutfit: String = "",
        onProduction: Bool = false,
        priority: Int = 0,
        characterId: Int
    ) {
        self.name = name
        self.classType = classType
        self.membershipNeeded = membershipNeeded
        self.characterOutfits = characterOutfits
        self.currentOutfit = currentOutfit
        self.videoLinks = videoLinks
        self.onProduction = onProduction
        self.priority = priority
        self.characterId = characterId
    }
}

// CreateAnimeBuddy, is a command line tool that allow firebase database to be
// updated with a new characters info. This does not add or update firebase storage.
struct CreateAnimeBuddy: ParsableCommand {
    func run() throws {
        guard let name = name else { return }
        
        let outfits = characterOutFits(characterName: name)
        
        guard !outfits.isEmpty else { return }
        
        let characterOutfits = pickAnimations(characterOutfits: outfits)
        
        let videoLinks = videoLinks(characterOutfits: outfits)
        
        let classType = classType()
        
        let onProduction =  isProd()
        
        let isMemberShipNeeded: Bool = isMemberShipNeeded
        
        let finalResult: CreateCharacterConfiguration = .init(
            name: name,
            classType: classType,
            membershipNeeded: isMemberShipNeeded,
            characterOutfits: characterOutfits,
            videoLinks: videoLinks,
            // Should I do this here?
            priority: 0,
            // Character Id is the number of characters existing + 1
            characterId: 0
        )
        
        print()
        print("------------")
        print("Final Result: \(finalResult)")
        
    }
    
    private var name: String? {
        print()
        print()
        print("------------")
        print("Insert Name of Character:")
        print("------------")
        print()
        if let characterName = readLine(), characterName != "" {
            print("characterName: \(characterName)")
            return characterName
        } else {
            print("Restart and pick another name")
            return nil
        }
    }
    
    private var isMemberShipNeeded: Bool {
        print()
        print()
        print("------------")
        print("Does this character need premium membership?")
        print("1. True, 2. False")
        print("------------")
        print()
        if let isMembershipNeeded = readLine(), isMembershipNeeded != "" {
            let result: Bool = {
                let isMembershipNeeded = isMembershipNeeded.replacingOccurrences(of: " ", with: "")
                if isMembershipNeeded == "1" {
                    return true
                } else {
                    return false
                }
            }()
            
            print("isMembershipNeeded: \(result)")
            return result
        } else {
            print("No response was given properly so defaulted to False")
            return false
        }
    }
    
    private func characterOutFits(characterName: String) -> [String] {
        print()
        print()
        print("------------")
        print("Now Create a list of outfit you want. Separate the names by a comma")
        print("No need to add the character name to it, the system will do that :)")
        print("Example: punk, crazy")
        print("------------")
        print()
        if let outfits = readLine(), outfits != "" {
            // Get the given outfits
            let result = outfits.components(separatedBy: ",")
            
            /// Create the new outfits names
            let newOutfits = result.map { outfit in
                // Create outfit name
                let outfitName = "\(characterName.lowercased())-\(outfit.lowercased())"
                // removes the extra white space
                return outfitName.replacingOccurrences(of: " ", with: "")
            }
            
            print("Outfits: \(newOutfits)")
            return newOutfits
        } else {
            print("No outfits created. Please Restart.")
            return []
        }
    }
    
    private func classType() -> String {
        print()
        print("------------")
        print("What class type?")
        if let classType = readLine() {
            print("Class Type: Civilian: \(classType)")
            return classType
        } else {
            print("Class Type: Civilian")
            return "Civilian"
        }
    }
    
    private func isProd() {
        print()
        print("------------")
        print("Should this be in production?")
        print("1. True, 2. False")
        if let isProd = readLine(), isProd != "" {
            let result: Bool = {
                let isProd = isProd.replacingOccurrences(of: " ", with: "")
                if isProd == "1" {
                    return true
                } else {
                    return false
                }
            }()
            
            print("isProd: \(result)")
        }
    }
    
    private func videoLinks(characterOutfits: [String]) -> [String: String] {
        print("")
        print("------------")
        // Need to create a dictionary based on the link provided
        var videoLinks: [String: String] = [:]
        _ = characterOutfits.map({ outfit in
            print()
            print("Please provide video link for: \(outfit)")
            if let videoLink = readLine(), videoLink != "" {
                // Add the outfit and its link to the dictionary
                videoLinks[outfit] = videoLink
            }
        })
        
        print("------------")
        print("Links Attached:")
        
        return videoLinks
    }
    
    private func pickAnimations(characterOutfits: [String]) -> [String: [String]] {
        var attachedAnimations: [String: [String]] = [:]
        print()
        print()
        print("------------")
        print("Here's the list of Animations.")
        print("Pick the ones you want like this: 1, 2, 3..")
        print()
        print("Animations:")
        print("------------")
        var counter: Int = 1
        // List of animations which are tied to its ID.
        var animations: [Int: String] = [:]
        
        // Create the list of animations
        AnimationType.allCases.forEach({
            print("\(counter).\($0.rawValue)")
            animations[counter] = $0.rawValue
            counter += 1
        })
        
        // Loop through all character outfits
        _ = characterOutfits.map {
            print("------------")
            print("Choose the animation for this outfit: \($0)")
            if let userChoice = readLine(), userChoice != "" {
                let arrayOfUserChoice: [String] = userChoice.components(separatedBy: ",")
                // removes extra space if there is any
                let removeSpace: [String] = arrayOfUserChoice.map { $0.replacingOccurrences(of: " ", with: "") }
                // Create the list of numbers from the string provided
                let listOfNumbers: [Int] = removeSpace.map { Int($0) ?? 0 }
                // Fetch the animations that correspond to the number created
                let listOfAnimations: [String] = listOfNumbers.sorted().map { animations[$0] ?? "" }
                // Add the animations to 'attachedAnimation'
                attachedAnimations[$0] = listOfAnimations
                print("Current Animations: \(attachedAnimations)")
            }
        }
        
        return attachedAnimations
    }
}

CreateAnimeBuddy.main()
