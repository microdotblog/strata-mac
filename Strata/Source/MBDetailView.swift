//
//  MBDetailView.swift
//  Strata
//
//  Created by Manton Reece on 11/3/24.
//

import SwiftUI

struct MBDetailView: View {
	let note: FeedItem
	let notebook: FeedItem
	var text: String = ""

	init(note: FeedItem, notebook: FeedItem) {
		self.note = note
		self.notebook = notebook
		if let secret_key = MBKeychain.shared.get(key: Constants.Keychain.secret) {
			let without_prefix = secret_key.replacingOccurrences(of: "mkey", with: "")
			let s = MBNote.decryptText(note.contentText, withKey: without_prefix)
			self.text = s
		}
	}
	
	var body: some View {
		MBWebView(self.text, note: self.note, notebook: notebook)
	}
}
