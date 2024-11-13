//
//  MBMainView.swift
//  Strata
//
//  Created by Manton Reece on 8/29/24.
//

import SwiftUI

// aeeiii
var gWindow: NSWindow?

struct MBMainView: View {
	@State private var isSigninSheet = true
	@State private var isSignOutAlert = false
	@State private var isDownloading = false
	@State private var notebooks: [MBNotebook] = []
	@State private var currentNotes: [MBNote] = []
	@State private var allNotes: [MBNote] = []
	@State private var searchText = ""
	@State private var columnVisibility: NavigationSplitViewVisibility = .all
	@State private var selectedNotebook: MBNotebook?
	@State private var selectedNote: MBNote?

	var body: some View {
		NavigationSplitView(columnVisibility: $columnVisibility) {
			MBTableView(data: $currentNotes, selection: $selectedNote)
			.frame(minWidth: 200)
			.navigationSplitViewColumnWidth(min: 200, ideal: 200)
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
			if self.hasSecretKey() {
				if let notebook = self.selectedNotebook {
					if let note = self.selectedNote {
						MBDetailView(note: note, notebook: notebook)
					}
					else {
						MBDetailView(notebook: notebook)
					}
				}
			}
			else {
				MBDetailPlaceholder()
			}
		}
		.toolbar {
			ToolbarItem(placement: .navigation) {
				Menu {
					ForEach(self.notebooks, id: \.id) { notebook in
						Button(notebook.name) {
							self.selectedNote = nil
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
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.frame(width: 200)
					.onChange(of: searchText) { oldValue, newValue in
						self.runSearch(newValue)
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
			self.findAndFocusSearch()
		}
		.onReceive(NotificationCenter.default.publisher(for: .refreshNotes)) { _ in
			self.fetchNotebooks()
		}
		.onReceive(NotificationCenter.default.publisher(for: .makeNewNote)) { _ in
			self.newNote()
		}
		.onReceive(NotificationCenter.default.publisher(for: .signOut)) { _ in
			self.promptSignOut()
		}
		.onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
			if let window = notification.object as? NSWindow {
				gWindow = window
			}
		}
		.onOpenURL { url in
			if let token = url.pathComponents.last {
				self.verifyToken(token) { new_token, error in
					if let new_token = new_token {
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

	func runSearch(_ query: String) {
		var new_notes: [MBNote] = []
		if query.count >= 3 {
			new_notes = self.allNotes.filter { $0.text.localizedCaseInsensitiveContains(query) }
		}
		else {
			new_notes = self.allNotes
		}
		
		self.currentNotes = new_notes
	}

	private func findAndFocusSearch() {
		guard let toolbar = gWindow?.toolbar else { return }
  
		// iterate through items looking for text field
		for item in toolbar.items {
			if let view = item.view {
				for host in view.subviews {
					for sub in host.subviews {
						let t = String(describing: type(of: sub))
						if t == "AppKitTextField" {
							sub.becomeFirstResponder()
							break
						}
					}
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
			
			self.isDownloading = true

			URLSession.shared.dataTask(with: request) { data, response, error in
				if let data = data {
					do {
						let feed = try JSONDecoder().decode(JSONFeed.self, from: data)
						
						Task {
							if let path = StrataDatabase.getPath() {
								let db = try Blackbird.Database(path: path)

								var notebooks: [MBNotebook] = []
								for item in feed.items {
									if var notebook = try await MBNotebook.find_or_create(id: item.id, database: db) {
										notebook.id = item.id
										notebook.name = item.title
										if let colors = item.microblog.colors {
											notebook.lightColor = colors.light
											notebook.darkColor = colors.dark
										}
//										try await notebook.write(to: db)
										notebooks.append(notebook)
									}
								}
								
								await MainActor.run { [notebooks] in
									self.selectedNote = nil
									self.notebooks = notebooks
									self.selectedNotebook = notebooks.first
									self.fetchNotes()
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
	
	private func fetchNotes() {
		if let notebook = self.selectedNotebook {
			let notebook_id = notebook.id
			if let token = MBKeychain.shared.get(key: Constants.Keychain.token) {
				guard let url = URL(string: "\(Constants.baseURL)/notes/notebooks/\(notebook_id)") else { return }
				var request = URLRequest(url: url)
				request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
				
				self.isDownloading = true

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
											n.fromFeedItem(item)
											n.notebookID = notebook_id
//											try await n.write(to: db)
											notes.append(n)
										}
									}

									await MainActor.run { [notes] in
										self.allNotes = notes
										self.currentNotes = notes
										self.isDownloading = false
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
		let new_note = MBNote()
		self.allNotes.insert(new_note, at: 0)
		self.currentNotes = self.allNotes
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

		self.currentNotes = []
		self.allNotes = []
		self.notebooks = []
		self.isSigninSheet = true
		self.isSignOutAlert = false
		
		Task {
			if let path = StrataDatabase.getPath() {
				let db = try Blackbird.Database(path: path)
				try await MBNote.query(in: db, "DELETE FROM $T")
				try await MBNotebook.query(in: db, "DELETE FROM $T")
			}
		}
	}
}
