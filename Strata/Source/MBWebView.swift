//
//  MBWebView.swift
//  Strata
//
//  Created by Manton Reece on 8/29/24.
//

import SwiftUI
import WebKit

struct MBWebView: NSViewRepresentable {	
	let webView: WKWebView
	
	init() {
		let config = WKWebViewConfiguration()
		webView = WKWebView(frame: .zero, configuration: config)
	}
	
	func makeNSView(context: Context) -> WKWebView {
		webView.allowsBackForwardNavigationGestures = false
		webView.allowsLinkPreview = true
		return webView
	}
	
	func updateNSView(_ webView: WKWebView, context: Context) {
		if let url = Bundle.main.url(forResource: "micro_editor", withExtension: "html") {
			webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
		}
	}
}
