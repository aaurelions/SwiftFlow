import Foundation

/// Configuration for accessibility features in SwiftFlow.
///
/// Controls VoiceOver announcements and role descriptions for graph elements.
public struct AccessibilityConfig: Equatable, Sendable {
    /// Whether to announce selection changes via VoiceOver.
    public var announceSelectionChanges: Bool
    /// Whether to announce connection events via VoiceOver.
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

    public init(
        announceSelectionChanges: Bool = true,
        announceConnectionEvents: Bool = true,
        nodeRoleDescription: String = "Graph node",
        edgeRoleDescription: String = "Graph edge",
        nodeDescription: String = "Press Enter to select, drag to move",
        nodeDescriptionKeyboardDisabled: String = "Node",
        edgeDescription: String = "Press Enter to select",
        controlsAriaLabel: String = "Graph controls",
        minimapAriaLabel: String = "Graph minimap",
        handleAriaLabel: String = "Drag to create a connection",
        zoomInAriaLabel: String = "Zoom in",
        zoomOutAriaLabel: String = "Zoom out",
        fitViewAriaLabel: String = "Fit view",
        interactiveAriaLabel: String = "Toggle interactivity"
    ) {
        self.announceSelectionChanges = announceSelectionChanges
        self.announceConnectionEvents = announceConnectionEvents
        self.nodeRoleDescription = nodeRoleDescription
        self.edgeRoleDescription = edgeRoleDescription
        self.nodeDescription = nodeDescription
        self.nodeDescriptionKeyboardDisabled = nodeDescriptionKeyboardDisabled
        self.edgeDescription = edgeDescription
        self.controlsAriaLabel = controlsAriaLabel
        self.minimapAriaLabel = minimapAriaLabel
        self.handleAriaLabel = handleAriaLabel
        self.zoomInAriaLabel = zoomInAriaLabel
        self.zoomOutAriaLabel = zoomOutAriaLabel
        self.fitViewAriaLabel = fitViewAriaLabel
        self.interactiveAriaLabel = interactiveAriaLabel
    }

    public static let `default` = AccessibilityConfig()
}
