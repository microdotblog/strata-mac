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
	
	mutating func setEncrypted(_ encrypted: String) {
		if let secret_key = MBKeychain.shared.get(key: Constants.Keychain.secret) {
			let without_prefix = secret_key.replacingOccurrences(of: "mkey", with: "")
			self.text = MBNoteUtils.decryptText(encrypted, withKey: without_prefix)
		}
	}
	
	static func find_or_create(id: Int, database: Blackbird.Database) async throws -> MBNote? {
		var note = try await MBNote.read(from: database, id: id)
		if note == nil {
			note = MBNote()
			note?.id = id
		}
		
		return note
	}
}
