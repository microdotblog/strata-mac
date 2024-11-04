//
//  MBMainView.swift
//  Strata
//
//  Created by Manton Reece on 8/29/24.
//

import SwiftUI

struct MBMainView: View {
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
					if let secret_key = MBKeychain.shared.get(key: "Strata: Secret") {
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
			self.fetcNotebooks()
		}
		.onReceive(NotificationCenter.default.publisher(for: .focusSearchField)) { _ in
			isSearchFocused = true
		}
	}

	private func fetcNotebooks() {
		if let token = MBKeychain.shared.get(key: "Strata: Token") {
			guard let url = URL(string: "https://micro.blog/notes/notebooks") else { return }
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
			if let token = MBKeychain.shared.get(key: "Strata: Token") {
				guard let url = URL(string: "https://micro.blog/notes/notebooks/\(notebook_id)") else { return }
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
}
