//
//  MBDetailView.swift
//  Strata
//
//  Created by Manton Reece on 11/3/24.
//

import SwiftUI

struct MBDetailView: View {
	let note: FeedItem
	var text: String = ""

	init(note: FeedItem) {
		self.note = note
		if let secret_key = MBKeychain.shared.get(key: "Strata: Secret") {
			let without_prefix = secret_key.replacingOccurrences(of: "mkey", with: "")
			let s = MBNote.decryptText(note.contentText, withKey: without_prefix)
			self.text = s
		}
	}
	
	var body: some View {
		if let secret_key = MBKeychain.shared.get(key: "Strata: Secret") {
			let without_prefix = secret_key.replacingOccurrences(of: "mkey", with: "")
			let s = MBNote.decryptText(note.contentText, withKey: without_prefix)
			MBWebView(s)
		}
	}
}
