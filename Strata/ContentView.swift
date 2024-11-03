//
//  ContentView.swift
//  Strata
//
//  Created by Manton Reece on 8/29/24.
//

import SwiftUI

struct ContentView: View {
	@State private var notes: [FeedItem] = []

	var body: some View {
		NavigationSplitView {
			List(notes) { note in
				NavigationLink(destination: DetailView(note: note)) {
					Text(note.contentText)
				}
			}
			.frame(minWidth: 200)
			.listStyle(SidebarListStyle())
		}
		detail: {
		}
		.onAppear {
			fetchNotes()
		}
	}
	
	private func fetchNotes() {
		if let token = MBKeychain.shared.get(key: "Strata: Token") {
			guard let url = URL(string: "https://micro.blog/notes/notebooks/1") else { return }
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

struct DetailView: View {
	let note: FeedItem
	
	var body: some View {
		MBWebView()
	}
}

struct FeedItem: Identifiable, Decodable {
	let id = UUID()
	let title: String
	let contentText: String

	private enum CodingKeys: String, CodingKey {
		case title
		case contentText = "content_text"
	}
}

struct JSONFeed: Decodable {
	let items: [FeedItem]
}

#Preview {
    ContentView()
}
