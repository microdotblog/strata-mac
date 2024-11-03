//
//  MBSettingsView.swift
//  Strata
//
//  Created by Manton Reece on 11/3/24.
//

import SwiftUI

struct MBSettingsView: View {
	@State private var secretKey: String = ""

	var body: some View {
		VStack {
			Text("Notes in Micro.blog are encrypted. To sync notes across devices, you will need to save a secret key so the notes can be decrypted later. If you lose your key, you will lose access to your notes too.")
			
			TextField("Secret Key", text: $secretKey)
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.padding()

			Button("Save") {
				print("Secret: \(secretKey)")
				if !MBKeychain.shared.save(key: "Strata: Secret", value: secretKey) {
					print("Error saving secret key")
				}
			}
		}
		.frame(width: 400)
		.padding()
		.onAppear() {
			if let secret_key = MBKeychain.shared.get(key: "Strata: Secret") {
				secretKey = secret_key
			}
		}
    }
}
