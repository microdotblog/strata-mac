//
//  StrataApp.swift
//  Strata
//
//  Created by Manton Reece on 8/29/24.
//

import SwiftUI

@main
struct StrataApp: App {
	var body: some Scene {
		Window("Strata", id: "main") {
			MBMainView()
		}
		.commands {
			CommandGroup(replacing: .newItem) {
				Button("New Note") {
					self.makeNewNote()
				}
				.keyboardShortcut("N", modifiers: .command)
			}

			CommandGroup(after: CommandGroupPlacement.saveItem) {
				Divider()
				
				Button("Sign Out") {
					self.signOut()
				}
			}
			
			CommandGroup(replacing: .textEditing) {
				Button("Find") {
					focusSearchField()
				}
				.keyboardShortcut("f", modifiers: .command)
			}

			CommandGroup(replacing: .sidebar) {
				Button("Notes") {
				}
				.keyboardShortcut("1", modifiers: .command)

				Button("Bookmarks") {
				}
				.keyboardShortcut("2", modifiers: .command)

				Button("Highlights") {
				}
				.keyboardShortcut("3", modifiers: .command)

				Divider()

				Button("Refresh") {
					NotificationCenter.default.post(name: .refreshNotes, object: nil)
				}
				.keyboardShortcut("R", modifiers: [ .command, .shift ])

				Divider()
			}
		}
		
		Settings {
			MBSettingsView()
		}
	}
	
	func openSignInWindow() {
		if let url = URL(string: "strata://signin") {
			NSWorkspace.shared.open(url)
		}
	}

	func focusSearchField() {
		NotificationCenter.default.post(name: .focusSearchField, object: nil)
	}
	
	func makeNewNote() {
		NotificationCenter.default.post(name: .makeNewNote, object: nil)
	}
	
	func signOut() {
		NotificationCenter.default.post(name: .signOut, object: nil)
	}
}
