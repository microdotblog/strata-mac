//
//  MBSigninView.swift
//  Strata
//
//  Created by Manton Reece on 11/2/24.
//

import SwiftUI

struct MBSigninView: View {
	@State private var email: String = ""
	@State private var isSending = false
	@State private var statusMessage = ""

	var body: some View {
		VStack {
			Image(nsImage: NSApplication.shared.applicationIconImage)
				.resizable()
				.frame(width: 64, height: 64)
				.padding(.vertical, 12)

			Text("Strata for Mac uses your Micro.blog account to sync notes between devices.")
				.frame(maxWidth: 300, alignment: .leading)
				.lineLimit(3)

			Text("Sign in with your Micro.blog account email address:")
				.frame(maxWidth: 300, alignment: .leading)
				.lineLimit(3)
				.padding(.vertical, 10)

			TextField("Email", text: $email)
				.textFieldStyle(RoundedBorderTextFieldStyle())
			
			HStack {
				if !statusMessage.isEmpty {
					Text(statusMessage)
				}
				else if isSending {
					ProgressView()
						.progressViewStyle(CircularProgressViewStyle())
						.scaleEffect(0.5)
				}
				Spacer()
				Button(action: {
					isSending = true
					submitEmail(email)
				}) {
					Text("Sign In").frame(minWidth: 50)
				}
				.keyboardShortcut(.defaultAction)
			}
			.padding(.vertical, 10)
		}
		.frame(width: 300)
		.padding()
	}
	
	private func submitEmail(_ email: String) {
		guard let url = URL(string: "\(Constants.baseURL)/account/signin") else { return }

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

		var components = URLComponents()
		components.queryItems = [
			URLQueryItem(name: "email", value: email),
			URLQueryItem(name: "app_name", value: "Strata"),
			URLQueryItem(name: "redirect_url", value: "strata://signin/"),
		]
		request.httpBody = components.query?.data(using: .utf8)
		
		URLSession.shared.dataTask(with: request) { data, response, error in
			if let error = error {
				print("Error: \(error.localizedDescription)")
				return
			}

			if let response = response as? HTTPURLResponse, response.statusCode == 200 {
				self.statusMessage = "Success! Sign-in email sent."
			}
			else {
				self.statusMessage = "Error signing in."
			}
		}.resume()
	}
	
	private func saveToken(_ token: String) {
		if !MBKeychain.shared.save(key: Constants.Keychain.token, value: token) {
			print("Error saving token")
		}
	}
}
