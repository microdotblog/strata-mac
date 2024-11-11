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
	@State private var isFinishedSave = false
	@State private var isCloudChecked = true

	var body: some View {
		VStack {
			Text("Notes in Micro.blog are encrypted. To sync notes across devices, you will need to save a secret key so the notes can be decrypted later. If you lose your key, you will lose access to your notes too.")
				.lineLimit(3)
			
			HStack {
				Toggle("Save secret key to iCloud", isOn: $isCloudChecked)
				Spacer()
			}.padding(.vertical, 7)
			
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
				
				if isFinishedSave {
					Image(systemName: "checkmark.circle.fill")
						.frame(minHeight: 20)
				}
				
				Button(action: {
					self.secretKey = ""
					self.oldSecretKey = ""
					if !MBKeychain.shared.delete(key: Constants.Keychain.secret) {
						print("Error removing secret key")
					}
				}) {
					Text("Delete Key").frame(minWidth: 55)
				}
				.disabled(secretKey.isEmpty)

				Button(action: {
					self.isFinishedSave = true
					if MBKeychain.shared.save(key: Constants.Keychain.secret, value: secretKey) {
						NotificationCenter.default.post(name: .refreshNotes, object: nil)
					}
					else {
						print("Error saving secret key")
					}
				}) {
					Text("Save").frame(minWidth: 55)
				}
				.disabled((secretKey == oldSecretKey) || (secretKey.isEmpty))
			}
		}
		.frame(width: 400)
		.padding()
		.onAppear() {
			self.isFinishedSave = false
			if let secret_key = MBKeychain.shared.get(key: Constants.Keychain.secret) {
				oldSecretKey = secret_key
				secretKey = secret_key
			}
		}
    }
}
