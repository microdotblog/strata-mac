//
//  MBWebView.swift
//  Strata
//
//  Created by Manton Reece on 8/29/24.
//

import SwiftUI
import WebKit

struct MBWebView: NSViewRepresentable {
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
		// make the web view
		let config = WKWebViewConfiguration()
		let webview = WKWebView(frame: .zero, configuration: config)
		webview.allowsBackForwardNavigationGestures = false
		webview.allowsLinkPreview = true
		webview.navigationDelegate = self.webDelegate

		// load our basic HTML and JS
		self.webDelegate.loadHTML(webview)

		return webview
	}
	
	func updateNSView(_ webView: WKWebView, context: Context) {
		self.webDelegate.isLoaded(webView: webView) { is_loaded in
			if is_loaded {
				self.webDelegate.loadNoteText(self.text, webView: webView)
				self.webDelegate.loadBackground(self.notebook.lightColor, webView: webView)
			}
			else {
				// if not yet loaded, give it a little more time
				DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
					self.webDelegate.loadNoteText(self.text, webView: webView)
					self.webDelegate.loadBackground(self.notebook.lightColor, webView: webView)
				}
			}
		}
	}
}

class MBWebDelegate: NSObject, WKNavigationDelegate {
	var noteID: String?
	let notebookID: String?
	var lastText: String = ""

	init(noteID: String, notebookID: String) {
		self.noteID = noteID
		self.notebookID = notebookID
	}
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		self.startEditingTimer(webView: webView)
	}

	func isLoaded(webView: WKWebView, completion: @escaping (Bool) -> Void) {
		let js = "document.getElementById('editor') != null";
		webView.evaluateJavaScript(js) { result, error in
			if let is_loaded = result as? Bool {
				completion(is_loaded)
			}
			else {
				completion(false)
			}
		}
	}

	func loadHTML(_ webView: WKWebView) {
		if let url = Bundle.main.url(forResource: "micro_editor", withExtension: "html") {
			webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
		}
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
	
	func loadBackground(_ color: String, webView: WKWebView) {
		var js: String
		
		js = "document.getElementById(\"editor\").style.backgroundColor = \"\(color)\"";
		webView.evaluateJavaScript(js) { result, error in
		}

		js = "document.body.style.backgroundColor = \"\(color)\"";
		webView.evaluateJavaScript(js) { result, error in
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
		print("Saving note with ID: \(String(describing: self.noteID))")
		
		if let token = MBKeychain.shared.get(key: Constants.Keychain.token) {
			guard let url = URL(string: "\(Constants.baseURL)/notes") else { return }
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
			request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
			
			var components = URLComponents()
			components.queryItems = [
				URLQueryItem(name: "notebook_id", value: self.notebookID),
				URLQueryItem(name: "text", value: encryptedText),
				URLQueryItem(name: "is_encrypted", value: "1")
			]

			if let note_id = self.noteID {
				if (note_id != "") && (note_id != "0") {
					let new_item = URLQueryItem(name: "id", value: note_id)
					components.queryItems?.append(new_item)
				}
			}

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
					do {
						let item = try JSONDecoder().decode(FeedItem.self, from: data)
						self.noteID = String(item.id)
						print("Updating with ID: \(item.id)")
					}
					catch {
						print("Failed to decode JSON: \(error)")
					}
				}
			}.resume()
		}
	}
}
