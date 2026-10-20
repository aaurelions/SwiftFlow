import Foundation

/// Accessibility labels, descriptions, and VoiceOver announcements for the
/// canvas, mirroring React Flow's `ariaLabelConfig`.
///
/// Every default is localized from SwiftFlow's string catalog. To use your
/// own wording or translations, pass strings (for example from
/// `String(localized:)`) or message closures:
///
/// ```swift
/// let config = AccessibilityConfig(
///     nodeRoleDescription: String(localized: "Step"),
///     selectionAnnouncement: { nodes, edges in
///         String(localized: "\(nodes) steps selected")
///     }
/// )
/// ```
public struct AccessibilityConfig: Sendable {
  /// Whether selection changes are announced through VoiceOver.
  public var announceSelectionChanges: Bool
  /// Whether new connections and reconnections are announced through VoiceOver.
  public var announceConnectionEvents: Bool
  /// VoiceOver role description for nodes.
  public var nodeRoleDescription: String
  /// VoiceOver role description for edges.
  public var edgeRoleDescription: String
  /// Default accessibility description for nodes.
  public var nodeDescription: String
  /// Accessibility description for nodes when keyboard interaction is disabled.
  public var nodeDescriptionKeyboardDisabled: String
  /// Default accessibility description for edges.
  public var edgeDescription: String
  /// Accessibility label for the controls component.
  public var controlsAriaLabel: String
  /// Accessibility label for the minimap component.
  public var minimapAriaLabel: String
  /// Accessibility label for handles.
  public var handleAriaLabel: String
  /// Accessibility label for the zoom-in control button.
  public var zoomInAriaLabel: String
  /// Accessibility label for the zoom-out control button.
  public var zoomOutAriaLabel: String
  /// Accessibility label for the fit-view control button.
  public var fitViewAriaLabel: String
  /// Accessibility label for the interactive/lock control button.
  public var interactiveAriaLabel: String
  /// Announcement after the selection changes, given the number of selected
  /// nodes and edges (`0, 0` when the selection was cleared).
  public var selectionAnnouncement: @Sendable (_ nodeCount: Int, _ edgeCount: Int) -> String
  /// Announcement after a connection is created or an edge is reconnected.
  public var connectionAnnouncement: @Sendable (_ connection: Connection) -> String

  /// Creates a configuration. Every `nil` argument uses the localized default.
  public init(
    announceSelectionChanges: Bool = true,
    announceConnectionEvents: Bool = true,
    nodeRoleDescription: String? = nil,
    edgeRoleDescription: String? = nil,
    nodeDescription: String? = nil,
    nodeDescriptionKeyboardDisabled: String? = nil,
    edgeDescription: String? = nil,
    controlsAriaLabel: String? = nil,
    minimapAriaLabel: String? = nil,
    handleAriaLabel: String? = nil,
    zoomInAriaLabel: String? = nil,
    zoomOutAriaLabel: String? = nil,
    fitViewAriaLabel: String? = nil,
    interactiveAriaLabel: String? = nil,
    selectionAnnouncement: (@Sendable (_ nodeCount: Int, _ edgeCount: Int) -> String)? = nil,
    connectionAnnouncement: (@Sendable (_ connection: Connection) -> String)? = nil
  ) {
    self.announceSelectionChanges = announceSelectionChanges
    self.announceConnectionEvents = announceConnectionEvents
    self.nodeRoleDescription =
      nodeRoleDescription
      ?? String(localized: "Graph node", bundle: .module, comment: "VoiceOver role of a node")
    self.edgeRoleDescription =
      edgeRoleDescription
      ?? String(localized: "Graph edge", bundle: .module, comment: "VoiceOver role of an edge")
    self.nodeDescription =
      nodeDescription
      ?? String(
        localized: "Press Enter to select, drag to move", bundle: .module,
        comment: "VoiceOver hint of a node")
    self.nodeDescriptionKeyboardDisabled =
      nodeDescriptionKeyboardDisabled
      ?? String(
        localized: "Node", bundle: .module,
        comment: "VoiceOver hint of a node when keyboard interaction is disabled")
    self.edgeDescription =
      edgeDescription
      ?? String(
        localized: "Press Enter to select", bundle: .module, comment: "VoiceOver hint of an edge")
    self.controlsAriaLabel =
      controlsAriaLabel
      ?? String(
        localized: "Graph controls", bundle: .module, comment: "Label of the controls panel")
    self.minimapAriaLabel =
      minimapAriaLabel
      ?? String(localized: "Graph minimap", bundle: .module, comment: "Label of the minimap")
    self.handleAriaLabel =
      handleAriaLabel
      ?? String(
        localized: "Drag to create a connection", bundle: .module,
        comment: "VoiceOver hint of a connection handle")
    self.zoomInAriaLabel =
      zoomInAriaLabel
      ?? String(localized: "Zoom in", bundle: .module, comment: "Zoom-in button label")
    self.zoomOutAriaLabel =
      zoomOutAriaLabel
      ?? String(localized: "Zoom out", bundle: .module, comment: "Zoom-out button label")
    self.fitViewAriaLabel =
      fitViewAriaLabel
      ?? String(localized: "Fit view", bundle: .module, comment: "Fit-view button label")
    self.interactiveAriaLabel =
      interactiveAriaLabel
      ?? String(
        localized: "Toggle interactivity", bundle: .module,
        comment: "Interactivity lock button label")
    self.selectionAnnouncement = selectionAnnouncement ?? Self.defaultSelectionAnnouncement
    self.connectionAnnouncement = connectionAnnouncement ?? Self.defaultConnectionAnnouncement
  }

  public static let `default` = AccessibilityConfig()

  // MARK: - Default Announcements

  @Sendable
  static func defaultSelectionAnnouncement(nodeCount: Int, edgeCount: Int) -> String {
    switch (nodeCount, edgeCount) {
    case (0, 0):
      return String(
        localized: "Selection cleared", bundle: .module,
        comment: "Announcement when nothing is selected anymore")
    case (_, 0):
      return String(
        localized: "\(nodeCount) nodes selected", bundle: .module,
        comment: "Announcement of the number of selected nodes")
    case (0, _):
      return String(
        localized: "\(edgeCount) edges selected", bundle: .module,
        comment: "Announcement of the number of selected edges")
    default:
      return String(
        localized: "\(nodeCount) nodes and \(edgeCount) edges selected", bundle: .module,
        comment: "Announcement of the number of selected nodes and edges")
    }
  }

  @Sendable
  static func defaultConnectionAnnouncement(_ connection: Connection) -> String {
    String(
      localized: "Connected \(connection.source) to \(connection.target)", bundle: .module,
      comment: "Announcement after connecting two nodes; arguments are node IDs")
  }
}

// MARK: - Equatable

extension AccessibilityConfig: Equatable {
  /// Compares the flags and strings. The announcement closures cannot be
  /// compared and are ignored.
  public static func == (lhs: AccessibilityConfig, rhs: AccessibilityConfig) -> Bool {
    lhs.announceSelectionChanges == rhs.announceSelectionChanges
      && lhs.announceConnectionEvents == rhs.announceConnectionEvents
      && lhs.nodeRoleDescription == rhs.nodeRoleDescription
      && lhs.edgeRoleDescription == rhs.edgeRoleDescription
      && lhs.nodeDescription == rhs.nodeDescription
      && lhs.nodeDescriptionKeyboardDisabled == rhs.nodeDescriptionKeyboardDisabled
      && lhs.edgeDescription == rhs.edgeDescription
      && lhs.controlsAriaLabel == rhs.controlsAriaLabel
      && lhs.minimapAriaLabel == rhs.minimapAriaLabel
      && lhs.handleAriaLabel == rhs.handleAriaLabel
      && lhs.zoomInAriaLabel == rhs.zoomInAriaLabel
      && lhs.zoomOutAriaLabel == rhs.zoomOutAriaLabel
      && lhs.fitViewAriaLabel == rhs.fitViewAriaLabel
      && lhs.interactiveAriaLabel == rhs.interactiveAriaLabel
  }
}
