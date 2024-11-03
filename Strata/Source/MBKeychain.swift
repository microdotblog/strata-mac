//
//  MBKeychain.swift
//  Strata
//
//  Created by Manton Reece on 11/2/24.
//

import Foundation
import Security

class MBKeychain {
	static let shared = MBKeychain() // singleton
	
	private init() {} // prevent instantiation outside of this class
	
	func save(key: String, value: String) -> Bool {
		guard let data = value.data(using: .utf8) else { return false }
		
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecValueData as String: data
		]
		
		SecItemDelete(query as CFDictionary) // Delete any existing item with the same key
		let status = SecItemAdd(query as CFDictionary, nil)
		
		return status == errSecSuccess
	}
	
	func get(key: String) -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecReturnData as String: kCFBooleanTrue!,
			kSecMatchLimit as String: kSecMatchLimitOne
		]
		
		var result: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		
		guard status == errSecSuccess, let data = result as? Data else {
			return nil
		}
		
		return String(data: data, encoding: .utf8)
	}
	
	func delete(key: String) -> Bool {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key
		]
		
		let status = SecItemDelete(query as CFDictionary)
		
		return status == errSecSuccess
	}
}
