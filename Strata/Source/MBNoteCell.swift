//
//  MBNoteCell.swift
//  Strata
//
//  Created by Manton Reece on 11/12/24.
//

import SwiftUI

struct MBNoteCell: View {
	var text: String

	init(_ text: String) {
		self.text = text
	}
	
	var body: some View {
		HStack {
			Text(self.text)
				.lineLimit(3)
				.padding(.horizontal, 5)
				.padding(.vertical, 14)
			Spacer() // pushes the text to the left, taking up full width
		}
	}
}
