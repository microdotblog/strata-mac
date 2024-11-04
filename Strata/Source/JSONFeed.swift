//
//  JSONFeed.swift
//  Strata
//
//  Created by Manton Reece on 11/3/24.
//

import Foundation

struct JSONFeed: Decodable {
	let items: [FeedItem]
}

struct FeedItem: Identifiable, Decodable {
	let id: Int
	let title: String
	let contentText: String

	private enum CodingKeys: String, CodingKey {
		case id
		case title
		case contentText = "content_text"
	}
}
