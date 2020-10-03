//  FileManager-Extension.swift --- Translated into Swift by Yusuke Terada on 03 Oct 2020
//  Original Work: NSFileManager-Extension.m --- Created by Matt Gallagher on 06 May 2010
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

import Foundation

extension FileManager {
    @objc var applicationSupportDirectory: String? {
        let executableName = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        
        do {
            let result = try self.findOrCreateDirectory(searchPathDirectory: .applicationSupportDirectory,
                                                        inDomain: .userDomainMask,
                                                        appendPathComponent: executableName)
            return result
        } catch {
            print("Unable to find or create application support directory.")
            return nil
        }
    }
    
    func findOrCreateDirectory(searchPathDirectory: SearchPathDirectory,
                                        inDomain domainMask: SearchPathDomainMask,
                                        appendPathComponent appendComponent: String) throws -> String? {
        //
        // Search for the path
        //
        let paths = NSSearchPathForDirectoriesInDomains(searchPathDirectory, domainMask, true)
        
        //
        // Normally only need the first path returned
        // Append the extra path component
        //
        guard let resolvedPath = (paths.first as NSString?)?.appendingPathComponent(appendComponent) else {
            return nil
        }
        
        //
        // Create the path if it doesn't exist
        //
        do {
            try self.createDirectory(atPath: resolvedPath,
                                     withIntermediateDirectories: true,
                                     attributes: nil)
        } catch {
            throw error
        }
        
        //
        // If we've made it this far, we have a success
        //
        return resolvedPath
    }
}
