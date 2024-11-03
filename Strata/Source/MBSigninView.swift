//
//  MBSigninView.swift
//  Strata
//
//  Created by Manton Reece on 11/2/24.
//

import SwiftUI

struct MBSigninView: View {
	@State private var email: String = ""

	var body: some View {
		VStack {
			Text("Sign in with your Micro.blog account:")
				.padding()

			TextField("Token", text: $email)
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.padding()

			Button("Sign In") {
				print("Token: \(email)")
				saveToken(email)
			}
			.padding()
		}
		.frame(width: 200, height: 200)
	}
	
	private func saveToken(_ token: String) {
//		MBKeychain.shared.save(key: "Strata: Secret", value: "")
		if !MBKeychain.shared.save(key: "Strata: Token", value: token) {
			print("Error saving token")
		}
	}
}

#Preview {
    MBSigninView()
}
