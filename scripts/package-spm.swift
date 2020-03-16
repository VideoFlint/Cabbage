#!/usr/bin/swift
//
//  package-spm.swift
//  scripts
//
//  Created by Krunoslav Zaher on 12/26/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

/**
 This script packages normal Rx* structure into `Sources` directory.

 * creates and updates links to normal project structure
 * builds unit tests `main.swift`

 Unfortunately, Swift support for Linux, libdispatch and package manager are still quite unstable,
 so certain class of unit tests is excluded for now.

 */

// It is kind of ironic that we need to additionally package for package manager :/

let fileManager = FileManager.default

let allowedExtensions = [
    ".swift",
    ".h",
    ".m",
    ".c",
]

func isExtensionAllowed(_ path: String) -> Bool {
    return (allowedExtensions.map { path.hasSuffix($0) }).reduce(false) { $0 || $1 }
}

func checkExtension(_ path: String) throws {
    if !isExtensionAllowed(path) {
        throw NSError(domain: "Security", code: -1, userInfo: ["path" : path])
    }
}

func packageRelativePath(_ paths: [String], targetDirName: String, excluded: [String] = []) throws {
    let targetPath = "Sources/\(targetDirName)"

    print("Checking " + targetPath)

    for file in try fileManager.contentsOfDirectory(atPath: targetPath).sorted { $0 < $1 }  {
        if file != "include" && file != ".DS_Store" {
            print("Checking extension \(file)")
            try checkExtension(file)

            print("Cleaning \(file)")
            try fileManager.removeItem(atPath: "\(targetPath)/\(file)")
        }
    }

    for sourcePath in paths {
        var isDirectory: ObjCBool = false
        print("loop sourcePath: \(sourcePath)")
        fileManager.fileExists(atPath: sourcePath, isDirectory: &isDirectory)

        let files: [String] = isDirectory.boolValue ? fileManager.subpaths(atPath: sourcePath)!
            : [sourcePath]

        for file in files {
            if !isExtensionAllowed(file) {
                print("Skipping \(file)")
                continue
            }

            if excluded.contains(file) {
                print("Skipping \(file)")
                continue
            }

            let fileRelativePath = isDirectory.boolValue ? "\(sourcePath)/\(file)" : file

            let destinationURL = NSURL(string: "../../\(fileRelativePath)")!

            let fileName = (file as NSString).lastPathComponent
            let atURL = NSURL(string: "file:///\(fileManager.currentDirectoryPath)/\(targetPath)/\(fileName)")!

            if fileName.hasSuffix(".h") {
                let sourcePath = NSURL(string: "file:///" + fileManager.currentDirectoryPath + "/" + sourcePath + "/" + file)!
                //throw NSError(domain: sourcePath.description, code: -1, userInfo: nil)
                try fileManager.copyItem(at: sourcePath as URL, to: atURL as URL)
            }
            else {
                print("Linking \(fileName) [\(atURL)] -> \(destinationURL)")
                try fileManager.createSymbolicLink(at: atURL as URL, withDestinationURL: destinationURL as URL)
            }
        }
    }
}


try packageRelativePath([
    "Cabbage/Sources"
], targetDirName: "Cabbage")
