//
//  MBDetailPlaceholder.swift
//  Strata
//
//  Created by Manton Reece on 11/12/24.
//

import SwiftUI

struct MBDetailPlaceholder: View {
    var body: some View {
		VStack {
			HStack {
				Image(systemName: "lock")
				Text("Notes locked")
			}
			.padding(.vertical, 5)

			SettingsLink {
				Text("Settings...")
					.frame(minWidth: 80)
			}
		}
    }
}

