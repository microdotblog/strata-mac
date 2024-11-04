//
//  MBSettingsView.swift
//  Strata
//
//  Created by Manton Reece on 11/3/24.
//

import SwiftUI

struct MBSettingsView: View {
	@State private var secretKey: String = ""
	@State private var oldSecretKey: String = ""

	var body: some View {
		VStack {
			Text("Notes in Micro.blog are encrypted. To sync notes across devices, you will need to save a secret key so the notes can be decrypted later. If you lose your key, you will lose access to your notes too.")
			
			ZStack {
				Rectangle()
					.fill(Color("SettingsFieldBackground"))
					.frame(height: 70)
					.cornerRadius(5)
					.overlay(
						RoundedRectangle(cornerRadius: 5)
							.stroke(Color("SettingsFieldBorder"), lineWidth: 1)
					)
				
				VStack {
					TextField("Secret Key", text: $secretKey, axis: .vertical)
						.textFieldStyle(PlainTextFieldStyle())
						.padding(7)
					
					Spacer()
				}
				.frame(height: 70)
			}
			.padding(.vertical, 5)
			
			HStack {
				Spacer()
				Button(action: {
					print("Secret: \(secretKey)")
					if !MBKeychain.shared.save(key: "Strata: Secret", value: secretKey) {
						print("Error saving secret key")
					}
				}) {
					Text("Save").frame(minWidth: 50)
				}
				.disabled((secretKey == oldSecretKey) || (secretKey.isEmpty))
			}
		}
		.frame(width: 400)
		.padding()
		.onAppear() {
			if let secret_key = MBKeychain.shared.get(key: "Strata: Secret") {
				oldSecretKey = secret_key
				secretKey = secret_key
			}
		}
    }
}
