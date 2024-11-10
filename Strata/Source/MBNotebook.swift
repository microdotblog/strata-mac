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
}
