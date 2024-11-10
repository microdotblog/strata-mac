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
	@State private var isDownloading = false
	@State private var notes: [MBNote] = []
	@State private var notebooks: [MBNotebook] = []
	@State private var searchText = ""
	@FocusState private var isSearchFocused: Bool
	@State private var columnVisibility: NavigationSplitViewVisibility = .all
	@State private var selectedNotebook: MBNotebook?

	var body: some View {
		NavigationSplitView(columnVisibility: $columnVisibility) {
			List(self.notes) { note in
				if let notebook = self.selectedNotebook {
					NavigationLink(destination: MBDetailView(note: note, notebook: notebook)) {
						HStack {
							Text(note.text)
								.lineLimit(3)
								.padding(.horizontal, 5)
								.padding(.vertical, 14)
							Spacer() // pushes the text to the left, taking up full width
						}
					}
					.listRowInsets(EdgeInsets())
					.listRowSeparator(.hidden)
					.padding(0)
				}
			}
			.frame(minWidth: 200)
			.listStyle(PlainListStyle())
			.navigationSplitViewColumnWidth(min: 200, ideal: 200)
			.alternatingRowBackgrounds()
			.toolbar(removing: .sidebarToggle)
			.toolbar {
				ToolbarItem(placement: .automatic) {
					Spacer()
				}
				ToolbarItem(placement: .automatic) {
					if isDownloading {
						ProgressView()
							.scaleEffect(0.5)
					}
				}
			}
		}
		detail: {
			if !self.hasSecretKey() {
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
		.toolbar {
			ToolbarItem(placement: .navigation) {
				Menu {
					ForEach(self.notebooks, id: \.id) { notebook in
						Button(notebook.name) {
							self.selectedNotebook = notebook
							self.fetchNotes()
						}
					}
				} label: {
					if let notebook = selectedNotebook {
						Text(notebook.name)
					}
				}
			}

			ToolbarItem(placement: .automatic) {
				TextField("Search", text: $searchText)
					.focused($isSearchFocused)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.frame(width: 200)
					.onChange(of: searchText) { oldValue, newValue in
						Task {
							try await self.runSearch(newValue)
						}
					}
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
			self.loadNotes()
			if self.hasToken() {
				self.isSigninSheet = false
				self.fetchNotebooks()
			}
		}
		.onChange(of: columnVisibility, initial: true) { oldVal, newVal in
			if newVal == .detailOnly {
				// hack to always show sidebar again
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
					self.columnVisibility = .all
				}
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .focusSearchField)) { _ in
			isSearchFocused = true
		}
		.onReceive(NotificationCenter.default.publisher(for: .refreshNotes)) { _ in
			self.fetchNotebooks()
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
						self.fetchNotebooks()
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

	func runSearch(_ query: String) async throws {
		var new_notes: [MBNote] = []
		if query.count >= 3 {
			if let db = StrataDatabase.shared.getDatabase() {
				new_notes = try await MBNote.read(from: db, sqlWhere: "notebookID = ? text LIKE ? ORDER BY updatedAt DESC", self.selectedNotebook?.id, "%\(query)%")
			}
		}
		else {
			new_notes = try await self.allNotes()
		}
		
		await MainActor.run {
			self.notes = new_notes
		}
	}
	
	func allNotes() async throws -> [MBNote] {
		if let db = StrataDatabase.shared.getDatabase() {
			let new_notes = try await MBNote.read(from: db, matching: \.$notebookID == self.selectedNotebook?.id, orderBy: .ascending(\.$updatedAt))
			return new_notes
		}
		else {
			return []
		}
	}
	
	func loadNotes() {
		Task {
			var notebooks: [MBNotebook] = []
			if let db = StrataDatabase.shared.getDatabase() {
				notebooks = try await MBNotebook.read(from: db)
			}
			
			if notebooks.count > 0 {
				self.selectedNotebook = notebooks.first
				let notes = try await self.allNotes()
				DispatchQueue.main.async {
					self.notebooks = notebooks
					self.notes = notes
				}
			}
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

	private func hasSecretKey() -> Bool {
		if let _ = MBKeychain.shared.get(key: Constants.Keychain.secret) {
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
	
	private func fetchNotebooks() {
		if let token = MBKeychain.shared.get(key: Constants.Keychain.token) {
			guard let url = URL(string: "\(Constants.baseURL)/notes/notebooks") else { return }
			var request = URLRequest(url: url)
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
			
			URLSession.shared.dataTask(with: request) { data, response, error in
				if let data = data {
					do {
						let feed = try JSONDecoder().decode(JSONFeed.self, from: data)
						DispatchQueue.main.async {
							var notebooks: [MBNotebook] = []
							for item in feed.items {
								var notebook = MBNotebook()
								notebook.id = item.id
								notebook.name = item.title
								notebooks.append(notebook)
							}
							self.notebooks = notebooks
							self.selectedNotebook = notebooks.first
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
							
							Task {
								if let path = StrataDatabase.getPath() {
									let db = try Blackbird.Database(path: path)
									var notes: [MBNote] = []
									for item in feed.items {
										if var n = try await MBNote.find_or_create(id: item.id, database: db) {
											if n.text.count == 0 {
												n.setEncrypted(item.contentText)
											}
											n.notebookID = notebook_id
											try await n.write(to: db)
											notes.append(n)
										}
									}

									await MainActor.run { [notes] in
										self.notes = notes
									}
								}
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
