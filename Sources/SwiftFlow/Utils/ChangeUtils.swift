import Foundation

/// Applies node changes to a node array and returns the new array.
///
/// This is the primary state-update function for nodes. Use it in your
/// `onNodesChange` callback:
///
/// ```swift
/// onNodesChange: { changes in
///     nodes = applyNodeChanges(changes, nodes: nodes)
/// }
/// ```
///
/// Changes are applied in order. Changes that reference unknown IDs are
/// ignored, and `.add` is ignored when a node with the same ID already exists.
public func applyNodeChanges<T: Sendable>(_ changes: [NodeChange<T>], nodes: [Node<T>]) -> [Node<T>]
{
  var elements = IndexedElements(nodes)
  for change in changes {
    switch change {
    case .position(let id, let position):
      elements.update(id) { $0.position = position }
    case .selection(let id, let selected):
      elements.update(id) { $0.selected = selected }
    case .dimensions(let id, let width, let height):
      elements.update(id) {
        $0.width = width
        $0.height = height
      }
    case .replace(let id, let item):
      elements.update(id) { $0 = item }
    case .remove(let id):
      elements.remove(id)
    case .add(let item):
      elements.add(item)
    }
  }
  return elements.items
}

/// Applies edge changes to an edge array and returns the new array.
///
/// This is the primary state-update function for edges. Use it in your
/// `onEdgesChange` callback:
///
/// ```swift
/// onEdgesChange: { changes in
///     edges = applyEdgeChanges(changes, edges: edges)
/// }
/// ```
///
/// Changes are applied in order. Changes that reference unknown IDs are
/// ignored, and `.add` is ignored when an edge with the same ID already exists.
public func applyEdgeChanges<EdgeData: Equatable & Sendable & Hashable>(
  _ changes: [EdgeChange<EdgeData>],
  edges: [Edge<EdgeData>]
) -> [Edge<EdgeData>] {
  var elements = IndexedElements(edges)
  for change in changes {
    switch change {
    case .selection(let id, let selected):
      elements.update(id) { $0.selected = selected }
    case .replace(let id, let item):
      elements.update(id) { $0 = item }
    case .remove(let id):
      elements.remove(id)
    case .add(let item):
      elements.add(item)
    }
  }
  return elements.items
}

/// An array with a lazily rebuilt ID → index lookup, so applying many
/// changes does not scan the whole array for every change.
private struct IndexedElements<Element: Identifiable> where Element.ID == String {
  private(set) var items: [Element]
  private var indexById: [String: Int]?

  init(_ items: [Element]) { self.items = items }

  private mutating func index(of id: String) -> Int? {
    if indexById == nil {
      var lookup: [String: Int] = [:]
      for (index, item) in items.enumerated() where lookup[item.id] == nil {
        lookup[item.id] = index
      }
      indexById = lookup
    }
    return indexById?[id]
  }

  mutating func update(_ id: String, _ transform: (inout Element) -> Void) {
    guard let index = index(of: id) else { return }
    transform(&items[index])
    // A replacement may change the ID stored at this index.
    if items[index].id != id { indexById = nil }
  }

  mutating func remove(_ id: String) {
    guard index(of: id) != nil else { return }
    items.removeAll { $0.id == id }
    indexById = nil
  }

  mutating func add(_ item: Element) {
    guard index(of: item.id) == nil else { return }
    items.append(item)
    indexById?[item.id] = items.count - 1
  }
}
