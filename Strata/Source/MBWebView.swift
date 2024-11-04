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
	let webDelegate: MBWebDelegate
	let text: String
	
	init(_ text: String) {
		let config = WKWebViewConfiguration()
		self.webView = WKWebView(frame: .zero, configuration: config)
		self.webDelegate = MBWebDelegate()
		self.text = text
	}
	
	func makeNSView(context: Context) -> WKWebView {
		webView.allowsBackForwardNavigationGestures = false
		webView.allowsLinkPreview = true
		webView.navigationDelegate = webDelegate
		return webView
	}
	
	func updateNSView(_ webView: WKWebView, context: Context) {
		if let url = Bundle.main.url(forResource: "micro_editor", withExtension: "html") {
			webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				webDelegate.loadNoteText(self.text, webView: webView)
			}
		}
	}
}

class MBWebDelegate: NSObject, WKNavigationDelegate {
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
	}

	func loadNoteText(_ text: String, webView: WKWebView) {
		var s = text
		s = s.replacingOccurrences(of: "<", with: "&lt;")
		s = s.replacingOccurrences(of: "\"", with: "\\\"")
		s = s.replacingOccurrences(of: "\n", with: "\\n")

		let js = "document.getElementById(\"editor\").innerText = \"\(s)\";"
		webView.evaluateJavaScript(js) { result, error in
			if let error = error {
				print("JavaScript error: \(error)")
			}
		}
	}
}
