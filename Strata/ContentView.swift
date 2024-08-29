//
//  ContentView.swift
//  Strata
//
//  Created by Manton Reece on 8/29/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
		NavigationSplitView {
			List {
				NavigationLink(destination: DetailView(item: "Item 1")) {
					Text("Item 1")
				}
				NavigationLink(destination: DetailView(item: "Item 2")) {
					Text("Item 2")
				}
			}
			.frame(minWidth: 200)
			.listStyle(SidebarListStyle())
		} detail: {
		}
    }
}

struct DetailView: View {
	var item: String
	
	var body: some View {
		MBWebView()
	}
}

#Preview {
    ContentView()
}
