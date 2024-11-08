//
//  Note.swift
//  Strata
//
//  Created by Manton Reece on 11/7/24.
//

import Foundation

struct MBNote: BlackbirdModel {
	@BlackbirdColumn var id: Int
	@BlackbirdColumn var notebookID: Int
	@BlackbirdColumn var text: String
	@BlackbirdColumn var sharedURL: URL?
	@BlackbirdColumn var isEncrypted: Bool
	@BlackbirdColumn var isShared: Bool
	@BlackbirdColumn var isSharing: Bool
	@BlackbirdColumn var isUnsharing: Bool
	@BlackbirdColumn var createdAt: Date?
	@BlackbirdColumn var updatedAt: Date?
	
	init() {
		self.id = 0
		self.notebookID = 0
		self.text = ""
		self.isEncrypted = true
		self.isShared = false
		self.isSharing = false
		self.isUnsharing = false		
	}
}
