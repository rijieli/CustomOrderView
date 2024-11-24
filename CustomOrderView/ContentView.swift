//
//  ContentView.swift
//  CustomOrderView
//
//  Created by Roger on 2024/11/24.
//

import SwiftUI

enum MenuItem: String, Identifiable, CaseIterable {
    case one
    case two
    case three
    case four
    case five
    case six

    var id: String { self.rawValue }
}

struct ContentView: View {
    @State var items = MenuItem.allCases
    @State var draggedItem: MenuItem?
    @GestureState var longPressState = false
    @State var draggingItemOffsetY = 0.0

    let coordinateSpace = CoordinateSpace.named("ContentView")
    let cellHeight = 56.0

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element) {
                        idx, item in
                        itemCell(item)
                            .opacity(item == draggedItem ? 0 : 1)
                            .contentShape(.rect)
                            .overlay(alignment: .bottom) {
                                if idx != items.indices.last {
                                    Color.primary.opacity(0.05)
                                        .frame(height: 1)
                                        .padding(.leading, 16)
                                }
                            }
                            .gesture(mixedGesture(of: item))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .overlay {
                if let draggedItem {
                    GeometryReader { proxy in
                        itemCell(draggedItem)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .scaleEffect(1.03)
                            .offset(y: draggingItemOffsetY - cellHeight / 2)
                            .id(draggedItem)
                    }
                }
            }
            .coordinateSpace(name: coordinateSpace)
            .padding(20)
            .animation(nil, value: draggedItem)
            .animation(.interactiveSpring(), value: items)
            .animation(.interactiveSpring(), value: draggingItemOffsetY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    /// NOTE: DragGesture minimumDistance 0 is required
    func mixedGesture(of item: MenuItem) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .sequenced(
                before: DragGesture(
                    minimumDistance: 0,
                    coordinateSpace: .named(coordinateSpace)
                )
            )
            .updating($longPressState) { value, state, _ in
                switch value {
                case .first(_):
                    // When using sequenced gesture, this block never be called
                    break
                case .second(true, nil):
                    // This is the **real time** when dragging start
                    guard let index = items.firstIndex(of: item) else {
                        break
                    }
                    state = true
                    draggedItem = item
                    draggingItemOffsetY =
                        cellHeight * CGFloat(index + 1) - (cellHeight / 2)
                case .second(true, let drag):
                    // This block will be change items order when dragging
                    guard let drag else { break }
                    draggingItemOffsetY = drag.location.y

                    // Calculate the target index based on drag position
                    let targetIndex = Int(
                        (drag.location.y) / cellHeight)
                    guard targetIndex >= 0,
                        targetIndex < items.count
                    else { break }

                    // Get the current index of the selected item
                    guard
                        let currentIndex = items.firstIndex(
                            of: item)
                    else { break }

                    // Only update if the indices are different
                    if targetIndex != currentIndex {
                        withAnimation {
                            let item = items.remove(
                                at: currentIndex)
                            items.insert(
                                item, at: targetIndex)
                        }
                    }
                case .second(false, _):
                    break
                }
            }
            .onEnded { value in
                switch value {
                case .first(true):
                    draggedItem = nil
                    draggingItemOffsetY = 0
                case .second(true, _):
                    draggedItem = nil
                    draggingItemOffsetY = 0
                default:
                    break
                }
            }
    }

    func itemCell(_ item: MenuItem) -> some View {
        Text(item.rawValue.capitalized)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .trailing) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(item == draggedItem ? .primary : .gray)
            }
            .padding(.horizontal, 20)
            .frame(height: cellHeight)
            .background {
                Color(uiColor: .secondarySystemBackground)
            }
            .foregroundStyle(.primary)
            .transition(.opacity)
    }
}
