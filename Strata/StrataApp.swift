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
			ContentView()
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
	}
	
	func openSignInWindow() {
		if let url = URL(string: "strata://signin") {
			NSWorkspace.shared.open(url)
		}
	}
}
