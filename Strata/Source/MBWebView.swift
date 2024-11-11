//
//  MBWebView.swift
//  Strata
//
//  Created by Manton Reece on 8/29/24.
//

import SwiftUI
import WebKit

struct MBWebView: NSViewRepresentable {
//	let webView: WKWebView
	let webDelegate: MBWebDelegate
	let text: String
	let note: MBNote
	let notebook: MBNotebook
	
	init(_ text: String, note: MBNote, notebook: MBNotebook) {
		self.webDelegate = MBWebDelegate(noteID: String(note.id), notebookID: String(notebook.id))
		self.text = text
		self.note = note
		self.notebook = notebook
	}
	
	func makeNSView(context: Context) -> WKWebView {
		let config = WKWebViewConfiguration()
		let webview = WKWebView(frame: .zero, configuration: config)
		webview.allowsBackForwardNavigationGestures = false
		webview.allowsLinkPreview = true
		webview.navigationDelegate = self.webDelegate
		return webview
	}
	
	func updateNSView(_ webView: WKWebView, context: Context) {
		if let url = Bundle.main.url(forResource: "micro_editor", withExtension: "html") {
			webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
				self.webDelegate.loadNoteText(self.text, webView: webView)
			}
		}
	}
}

class MBWebDelegate: NSObject, WKNavigationDelegate {
	let noteID: String?
	let notebookID: String?
	var lastText: String = ""

	init(noteID: String, notebookID: String) {
		self.noteID = noteID
		self.notebookID = notebookID
	}
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		self.startEditingTimer(webView: webView)
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
	
	func getNoteText(webView: WKWebView, completion: @escaping (String) -> Void) {
		let js = "document.getElementById(\"editor\").innerText"
		webView.evaluateJavaScript(js) { result, error in
			if let s = result as? String {
				if s != self.lastText {
					self.lastText = s
					completion(s)
				}
			}
		}
	}
	
	func startEditingTimer(webView: WKWebView) {
		Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
			self.getNoteText(webView: webView) { text in
				self.saveNote(plainText: text)
			}
		}
	}
	
	func saveNote(plainText: String) {
		// to avoid bugs, for now don't let note be cleared
		let s = plainText.replacingOccurrences(of: "\n", with: "")
		if s.count == 0 {
			return
		}

		if let secret_key = MBKeychain.shared.get(key: Constants.Keychain.secret) {
			let without_prefix = secret_key.replacingOccurrences(of: "mkey", with: "")
			let s = MBNoteUtils.encryptText(plainText, withKey: without_prefix)
			self.saveNote(encryptedText: s)
		}
	}
	
	func saveNote(encryptedText: String) {
		if let token = MBKeychain.shared.get(key: Constants.Keychain.token) {
			guard let url = URL(string: "\(Constants.baseURL)/notes") else { return }
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
			request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
			
			var components = URLComponents()
			components.queryItems = [
				URLQueryItem(name: "id", value: self.noteID),
				URLQueryItem(name: "notebook_id", value: self.notebookID),
				URLQueryItem(name: "text", value: encryptedText),
				URLQueryItem(name: "is_encrypted", value: "1")
			]
			request.httpBody = components.query?.data(using: .utf8)
			
			URLSession.shared.dataTask(with: request) { data, response, error in
				if let error = error {
					print("Error: \(error.localizedDescription)")
					return
				}
				
				if let httpResponse = response as? HTTPURLResponse {
					print("HTTP Status Code: \(httpResponse.statusCode)")
				}
				
				if let data = data, let responseString = String(data: data, encoding: .utf8) {
					print("Response: \(responseString)")
				}
			}.resume()
		}
	}
}
