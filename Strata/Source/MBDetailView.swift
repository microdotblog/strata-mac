//
//  MBDetailView.swift
//  Strata
//
//  Created by Manton Reece on 11/3/24.
//

import SwiftUI

struct MBDetailView: View {
	let note: MBNote
	let notebook: MBNotebook

	init(notebook: MBNotebook) {
		self.note = MBNote()
		self.notebook = notebook
	}
	
	init(note: MBNote, notebook: MBNotebook) {
		self.note = note
		self.notebook = notebook
	}
	
	var body: some View {
		MBWebView(self.note.text, note: self.note, notebook: self.notebook)
	}
}
