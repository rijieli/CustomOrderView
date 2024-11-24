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
    @State var selected: MenuItem?
    @GestureState var longPress = false
    @State var draggingItemPosition: CGPoint = .zero

    let coordinateSpace = CoordinateSpace.named("ContentView")
    let cellHeight = 60.0

    var body: some View {
        ZStack {
            ScrollView {
                ForEach(items) { item in
                    itemCell(item)
                        .opacity(item == selected ? 0 : 1)
                        .contentShape(.rect)
                        .gesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .sequenced(
                                    before: DragGesture(
                                        minimumDistance: 10,
                                        coordinateSpace: .named(coordinateSpace)
                                    )
                                )
                                .updating($longPress) { value, state, _ in
                                    switch value {
                                    case .first(true):
                                        state = true
                                        selected = item
                                    case .second(true, let drag):
                                        guard let drag else { return }
                                        state = true
                                        selected = item
                                        draggingItemPosition = drag.location

                                        // Calculate the target index based on drag position
                                        let targetIndex = Int(
                                            (drag.location.y) / cellHeight)
                                        guard targetIndex >= 0,
                                            targetIndex < items.count
                                        else { return }

                                        // Get the current index of the selected item
                                        guard
                                            let currentIndex = items.firstIndex(
                                                of: item)
                                        else { return }

                                        // Only update if the indices are different
                                        if targetIndex != currentIndex {
                                            withAnimation {
                                                let item = items.remove(
                                                    at: currentIndex)
                                                items.insert(
                                                    item, at: targetIndex)
                                            }
                                        }
                                    default:
                                        break
                                    }
                                }
                                .onEnded { value in
                                    switch value {
                                    case .second(true, _):
                                        selected = nil
                                        draggingItemPosition = .zero
                                    default:
                                        break
                                    }
                                }
                        )
                }
            }
            .overlay {
                if let selected {
                    GeometryReader { proxy in
                        itemCell(selected)
                            .transition(.opacity)
                            .scaleEffect(1.05)
                            .offset(y: draggingItemPosition.y - cellHeight / 2)
                    }
                }
            }
            .coordinateSpace(name: coordinateSpace)
            .padding()
            .animation(.interactiveSpring(), value: selected)
        }
        .padding()
    }

    func itemCell(_ item: MenuItem) -> some View {
        Text(item.rawValue.uppercased())
            .font(.title)
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray)
            }
    }
}
