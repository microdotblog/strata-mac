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
	let datePublished: String?
	let dateModified: String?
	let microblog: FeedMicroblog

	private enum CodingKeys: String, CodingKey {
		case id
		case title
		case contentText = "content_text"
		case datePublished = "date_published"
		case dateModified = "date_modified"
		case microblog = "_microblog"
	}
	
	func parseDate(_ string: String) -> Date? {
		// 2010-02-07T14:04:00-05:00
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"
		let d = formatter.date(from: string)
		return d
	}
}

struct FeedMicroblog: Decodable {
	let colors: FeedColors?
}

struct FeedColors: Decodable {
	let light: String
	let dark: String
}
