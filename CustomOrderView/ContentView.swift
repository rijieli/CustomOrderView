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
                        .gesture(mixedGesture(of: item))
                }
            }
            .overlay {
                if let selected {
                    GeometryReader { proxy in
                        itemCell(selected)
                            .transition(.opacity)
                            .scaleEffect(1.05)
                            .offset(y: draggingItemPosition.y - cellHeight / 2)
                            .id(selected)
                    }
                }
            }
            .coordinateSpace(name: coordinateSpace)
            .padding()
            .animation(.interactiveSpring(), value: selected)
        }
        .padding()
    }

    func mixedGesture(of item: MenuItem) -> some Gesture {
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
                    break
                case .second(true, nil):
                    // This is the real time when dragging Start
                    guard let index = items.firstIndex(of: item) else {
                        break
                    }
                    // Compute height of the cell
                    // Compute the position of the dragging item
                    state = true
                    selected = item
                    draggingItemPosition = CGPoint(
                        x: 0, y: cellHeight * CGFloat(index + 1))
                case .second(true, let drag):
                    guard let drag else { break }
                    state = true
                    selected = item
                    draggingItemPosition = drag.location

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
                default:
                    state = false
                }
            }
            .onChanged({ g in
                switch g {
                case .second(let v, let drag):
                    print("onChanged second: \(v)")
                case .first(let v):
                    print("onChanged first: \(v)")
                }
            })
            .onEnded { value in
                switch value {
                case .first(true):
                    selected = nil
                    draggingItemPosition = .zero
                case .second(true, _):
                    selected = nil
                    draggingItemPosition = .zero
                default:
                    print("onChanged onEnded default")
                }
            }
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
