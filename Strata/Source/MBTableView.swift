//
//  MBTableView.swift
//  Strata
//
//  Created by Manton Reece on 11/12/24.
//

import SwiftUI



struct MBTableView: NSViewRepresentable {
	@Binding var data: [MBNote]
	@Binding var selection: MBNote?

	func makeNSView(context: Context) -> NSScrollView {
		let table = NSTableView()
		table.usesAlternatingRowBackgroundColors = true
		table.style = .fullWidth
		table.selectionHighlightStyle = .regular
		table.headerView = nil
		table.usesAutomaticRowHeights = true
		
		let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column"))
		column.title = "Data"
		table.addTableColumn(column)

		table.dataSource = context.coordinator
		table.delegate = context.coordinator

		let scrollview = NSScrollView()
		scrollview.documentView = table
		scrollview.hasVerticalScroller = true
		return scrollview
	}

	func updateNSView(_ nsView: NSScrollView, context: Context) {
		if let tableView = nsView.documentView as? NSTableView {
			context.coordinator.data = data
			tableView.reloadData()
		}
	}

	func makeCoordinator() -> MBTableCoordinator {
		MBTableCoordinator(data: data) { selectedRow in
			self.selection = self.data[selectedRow]
		}
	}

	class MBTableCoordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
		var data: [MBNote]
		var onSelectionChanged: (Int) -> Void

		init(data: [MBNote], onSelectionChanged: @escaping (Int) -> Void) {
			self.data = data
			self.onSelectionChanged = onSelectionChanged
		}

		func numberOfRows(in tableView: NSTableView) -> Int {
			self.data.count
		}

		func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
			let identifier = NSUserInterfaceItemIdentifier("NoteCell")
			if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSHostingView<MBNoteCell> {
				self.configure(cell, forRow: row)
				return cell
			}

			let cell_view = MBNoteCell(self.data[row].cellText)
			let hosting_view = NSHostingView(rootView: cell_view)
			hosting_view.identifier = identifier
			self.configure(hosting_view, forRow: row)
			
			return hosting_view
		}

		func tableViewSelectionDidChange(_ notification: Notification) {
			if let table = notification.object as? NSTableView {
				let row = table.selectedRow
				if row != -1 {
					self.onSelectionChanged(row)
				}
			}
		}
		
		private func configure(_ cell: NSHostingView<MBNoteCell>, forRow row: Int) {
			var cell_view = cell.rootView
			cell_view.text = self.data[row].cellText
		}
	}
}
