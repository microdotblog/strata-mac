//
//  StrataDatabase.swift
//  Strata
//
//  Created by Manton Reece on 11/7/24.
//

import Foundation

class StrataDatabase {
	class func getPath() -> String? {
		let fm = FileManager.default
		if let support_folder = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
			let strata_folder = support_folder.appendingPathComponent("Strata")
			if !fm.fileExists(atPath: strata_folder.path) {
				do {
					try fm.createDirectory(at: strata_folder, withIntermediateDirectories: true, attributes: nil)
				}
				catch {
					print("Error creating Strata folder: \(error)")
					return nil
				}
			}
			
			return strata_folder.appendingPathComponent("Strata.db").path(percentEncoded: false)
		}
		
		return nil
	}
}
