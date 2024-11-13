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
		if let table = nsView.documentView as? NSTableView {
			if context.coordinator.anyChanges(data: self.data) {
				context.coordinator.data = self.data
				table.reloadData()
			}
			
			if let selected_note = self.selection {
				context.coordinator.selectNote(selected_note, table: table)
			}
		}
	}

	func makeCoordinator() -> MBTableCoordinator {
		MBTableCoordinator(data: data) { selectedRow in
			if selectedRow < self.data.count {
				self.selection = self.data[selectedRow]
			}
		}
	}

	class MBTableCoordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
		var data: [MBNote]
		var onSelectionChanged: (Int) -> Void

		init(data: [MBNote], onSelectionChanged: @escaping (Int) -> Void) {
			self.data = data
			self.onSelectionChanged = onSelectionChanged
		}

		func anyChanges(data: [MBNote]) -> Bool {
			return data != self.data
		}
		
		func selectNote(_ note: MBNote, table: NSTableView) {
			guard let index = self.data.firstIndex(of: note) else { return }
			
			let current_selection = table.selectedRowIndexes
			if !current_selection.contains(index) {
				table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
			}
		}
		
		func numberOfRows(in tableView: NSTableView) -> Int {
			return self.data.count
		}

		func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
			let identifier = NSUserInterfaceItemIdentifier("NoteCell\(row)")
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
