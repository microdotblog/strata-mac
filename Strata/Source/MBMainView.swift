//
//  MBMainView.swift
//  Strata
//
//  Created by Manton Reece on 8/29/24.
//

import SwiftUI

struct MBMainView: View {
	@State private var isSigninSheet = true
	@State private var isSignOutAlert = false
	@State private var notes: [FeedItem] = []
	@State private var notebooks: [FeedItem] = []
	@State private var searchText = ""
	@FocusState private var isSearchFocused: Bool
	@State private var columnVisibility: NavigationSplitViewVisibility = .all
	@State private var selectedNotebook: FeedItem?

	var currentNotes: [FeedItem] {
		if searchText.isEmpty {
			return notes
		}
		else {
			// ...
			return notes
		}
	}

	var body: some View {
		NavigationSplitView(columnVisibility: $columnVisibility) {
			List(currentNotes.indices, id: \.self) { index in
				let note = currentNotes[index]
				NavigationLink(destination: MBDetailView(note: note)) {
					if let secret_key = MBKeychain.shared.get(key: Constants.Keychain.secret) {
						let without_prefix = secret_key.replacingOccurrences(of: "mkey", with: "")
						let s = MBNote.decryptText(note.contentText, withKey: without_prefix)
						HStack {
							Text(s)
								.lineLimit(3)
								.padding(.horizontal, 5)
								.padding(.vertical, 14)
							Spacer() // pushes the text to the left, taking up full width
						}
					}
				}
				.listRowInsets(EdgeInsets())
				.listRowSeparator(.hidden)
				.padding(0)
				.listRowBackground(index % 2 == 0 ? Color.gray.opacity(0.1) : Color.clear)
			}
			.frame(minWidth: 200)
			.listStyle(PlainListStyle())
			.navigationSplitViewColumnWidth(min: 100, ideal: 200)
		}
		detail: {
		}
		.toolbar {
			ToolbarItem(placement: .navigation) {
				Menu {
					ForEach(notebooks, id: \.id) { notebook in
						Button(notebook.title) {
							self.selectedNotebook = notebook
							self.fetchNotes()
						}
					}
				} label: {
					if let notebook = selectedNotebook {
						Text(notebook.title)
					}
				}
			}

			ToolbarItem(placement: .automatic) {
				TextField("Search", text: $searchText)
					.focused($isSearchFocused)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.frame(width: 200)
			}
			
			ToolbarItem(placement: .automatic) {
				Button(action: {
					newNote()
				}) {
					Label("New Note", systemImage: "square.and.pencil")
				}
			}
		}
		.navigationTitle("")
		.onAppear {
			if self.hasToken() {
				self.isSigninSheet = false
				self.fetcNotebooks()
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .focusSearchField)) { _ in
			isSearchFocused = true
		}
		.onReceive(NotificationCenter.default.publisher(for: .signOut)) { _ in
			self.promptSignOut()
		}
		.onOpenURL { url in
			if let token = url.pathComponents.last {
				print("Got token \(token)")
				self.verifyToken(token) { new_token, error in
					if let new_token = new_token {
						print("New token \(new_token)")
						if !MBKeychain.shared.save(key: Constants.Keychain.token, value: new_token) {
							print("Error saving new token")
						}
						self.fetcNotebooks()
					}
				}
				self.isSigninSheet = false
			}
		}
		.sheet(isPresented: $isSigninSheet) {
			MBSigninView()
		}
		.alert(isPresented: $isSignOutAlert) {
			Alert(
				title: Text("Sign Out"),
				message: Text("Are you sure you want to sign out? This will also clear the saved secret key from this Mac."),
				primaryButton: .default(Text("Sign Out"), action: {
					self.finishSignOut()
				}),
				secondaryButton: .cancel(Text("Cancel"))
			)
		}
	}
	
	private func hasToken() -> Bool {
		if let _ = MBKeychain.shared.get(key: Constants.Keychain.token) {
			return true
		}
		else {
			return false
		}
	}
	
	private func verifyToken(_ token: String, completion: @escaping (String?, String?) -> Void) {
		guard let url = URL(string: "\(Constants.baseURL)/account/verify") else { return }
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

		var components = URLComponents()
		components.queryItems = [
			URLQueryItem(name: "token", value: token),
		]
		request.httpBody = components.query?.data(using: .utf8)

		URLSession.shared.dataTask(with: request) { data, response, error in
			if let data = data {
				do {
					let u = try JSONDecoder().decode(MBUser.self, from: data)
					DispatchQueue.main.async {
						completion(u.token, nil)
					}
				}
				catch {
					print("Failed to decode JSON: \(error)")
				}
			}
		}.resume()
	}
	
	private func fetcNotebooks() {
		if let token = MBKeychain.shared.get(key: Constants.Keychain.token) {
			guard let url = URL(string: "\(Constants.baseURL)/notes/notebooks") else { return }
			var request = URLRequest(url: url)
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
			
			URLSession.shared.dataTask(with: request) { data, response, error in
				if let data = data {
					do {
						let feed = try JSONDecoder().decode(JSONFeed.self, from: data)
						DispatchQueue.main.async {
							self.notebooks = feed.items
							self.selectedNotebook = feed.items.first
							self.fetchNotes()
						}
					}
					catch {
						print("Failed to decode JSON: \(error)")
					}
				}
			}.resume()
		}
	}
	
	private func fetchNotes() {
		if let notebook = self.selectedNotebook {
			let notebook_id = notebook.id
			if let token = MBKeychain.shared.get(key: Constants.Keychain.token) {
				guard let url = URL(string: "\(Constants.baseURL)/notes/notebooks/\(notebook_id)") else { return }
				var request = URLRequest(url: url)
				request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
				
				URLSession.shared.dataTask(with: request) { data, response, error in
					if let data = data {
						do {
							let feed = try JSONDecoder().decode(JSONFeed.self, from: data)
							DispatchQueue.main.async {
								self.notes = feed.items
							}
						}
						catch {
							print("Failed to decode JSON: \(error)")
						}
					}
				}.resume()
			}
		}
	}
	
	private func newNote() {
	}
	
	private func promptSignOut() {
		self.isSignOutAlert = true
	}
	
	private func finishSignOut() {
		if !MBKeychain.shared.delete(key: Constants.Keychain.token) {
			print("Error removing token from keychain.")
		}
		if !MBKeychain.shared.delete(key: Constants.Keychain.secret) {
			print("Error removing secret key from keychain.")
		}

		self.notes = []
		self.notebooks = []
		self.isSigninSheet = true
		self.isSignOutAlert = false
	}
}
