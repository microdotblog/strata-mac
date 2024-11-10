//
//  MBNotebook.swift
//  Strata
//
//  Created by Manton Reece on 11/8/24.
//

import Foundation

struct MBNotebook: BlackbirdModel {
	@BlackbirdColumn var id: Int
	@BlackbirdColumn var name: String
	@BlackbirdColumn var lightColor: String
	@BlackbirdColumn var darkColor: String
	
	init() {
		self.id = 0
		self.name = ""
		self.lightColor = ""
		self.darkColor = ""
	}
	
	static func find_or_create(id: Int, database: Blackbird.Database) async throws -> MBNotebook? {
		var notebook = try await MBNotebook.read(from: database, id: id)
		if notebook == nil {
			notebook = MBNotebook()
			notebook?.id = id
		}
		
		return notebook
	}
}
