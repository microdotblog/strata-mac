//
//  Constants.swift
//  Strata
//
//  Created by Manton Reece on 11/3/24.
//

import Foundation

extension Notification.Name {
	static let focusSearchField = Notification.Name("focusSearchField")
	static let signOut = Notification.Name("signOut")
	static let refreshNotes = Notification.Name("refreshNotes")
}

struct Constants {
	static let baseURL = "https://micro.blog"

	struct Keychain {
		static let token = "Strata: Token"
		static let secret = "Strata: Secret"
	}
}
