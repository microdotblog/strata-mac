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
		}

//		WindowGroup {
//			MBSigninView()
//		}
//		.windowResizability(.contentSize)
//		.handlesExternalEvents(matching: ["signin"])
//		.commands {
//			CommandGroup(replacing: .newItem) {
//				Button("Sign In...") {
//					openSignInWindow()
//				}
//			}
//		}
		
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
