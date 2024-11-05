//
//  MBUser.swift
//  Strata
//
//  Created by Manton Reece on 11/5/24.
//

import Foundation

struct MBUser: Decodable {
	let token: String
	let name: String
	let fullName: String
	let avatar: String
	
	private enum CodingKeys: String, CodingKey {
		case token
		case name
		case fullName = "full_name"
		case avatar
	}
}
