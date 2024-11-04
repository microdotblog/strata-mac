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
		WindowGroup {
			MBMainView()
		}
		.commands {
			CommandGroup(replacing: .textEditing) {
				Button("Find") {
					focusSearchField()
				}
				.keyboardShortcut("f", modifiers: .command)
			}
		}

		WindowGroup {
			MBSigninView()
		}
		.handlesExternalEvents(matching: ["signin"])
		.commands {
			CommandGroup(replacing: .newItem) {
				Button("Sign In...") {
					openSignInWindow()
				}
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
}
