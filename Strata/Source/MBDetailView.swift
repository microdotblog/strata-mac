//
//  MBDetailView.swift
//  Strata
//
//  Created by Manton Reece on 11/3/24.
//

import SwiftUI

struct MBDetailView: View {
	let note: MBNote
	let notebook: FeedItem

	init(note: MBNote, notebook: FeedItem) {
		self.note = note
		self.notebook = notebook
	}
	
	var body: some View {
		MBWebView(self.note.text, note: self.note, notebook: notebook)
	}
}
