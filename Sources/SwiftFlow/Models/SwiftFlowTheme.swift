import SwiftUI

/// Configurable visual theme for the entire SwiftFlow canvas.
///
/// Customize colors, sizes, and fonts for edges, nodes, handles,
/// the selection box, canvas background, minimap, snap lines, and edge labels.
///
/// Where each group applies:
/// - **Edges / edge labels**: default edge rendering. Per-edge `EdgeStyle` values win.
/// - **Nodes**: the selection outline drawn around selected nodes, and the
///   background behind nodes that opt into library styling with `Node.style`.
///   Set `nodeSelectedBorderWidth` to `0` when node views draw their own selection.
/// - **Handles**: `Handle` views that do not pass an explicit color.
/// - **Selection box, snap lines, canvas, grid**: canvas chrome. The grid is
///   drawn when `SwiftFlow(backgroundVariant:)` is set.
/// - **Minimap**: `MiniMap` defaults when no explicit colors are passed.
///
/// Use `SwiftFlowTheme.default` for the standard appearance, or create
/// a custom theme:
///
/// ```swift
/// let darkTheme = SwiftFlowTheme(
///     edgeColor: .white.opacity(0.4),
///     canvasBackgroundColor: Color(white: 0.12),
///     gridColor: .white.opacity(0.1)
/// )
/// ```
public struct SwiftFlowTheme: Equatable, Sendable {
  // MARK: Edges
  public var edgeColor: Color
  public var edgeSelectedColor: Color
  public var edgeWidth: CGFloat
  public var edgeSelectedWidth: CGFloat

  // MARK: Nodes
  public var nodeBackgroundColor: Color
  public var nodeSelectedBorderColor: Color
  public var nodeSelectedBorderWidth: CGFloat

  // MARK: Handles
  public var handleColor: Color
  public var handleBorderColor: Color
  public var handleSize: CGFloat

  // MARK: Selection Box
  public var selectionBoxColor: Color
  public var selectionBoxBorderColor: Color

  // MARK: Canvas
  public var canvasBackgroundColor: Color
  public var gridColor: Color
  public var gridSpacing: CGFloat

  // MARK: Minimap
  /// Opacity of the minimap background material.
  public var minimapBackgroundOpacity: CGFloat
  public var minimapNodeColor: Color
  public var minimapSelectedNodeColor: Color

  // MARK: Snap Lines
  public var snapLineColor: Color
  public var snapLineWidth: CGFloat

  // MARK: Edge Labels
  public var edgeLabelFont: Font
  public var edgeLabelColor: Color
  public var edgeLabelBackgroundColor: Color

  public init(
    edgeColor: Color = .gray.opacity(0.6),
    edgeSelectedColor: Color = .blue,
    edgeWidth: CGFloat = 2,
    edgeSelectedWidth: CGFloat = 3,
    nodeBackgroundColor: Color = .white,
    nodeSelectedBorderColor: Color = .blue,
    nodeSelectedBorderWidth: CGFloat = 2,
    handleColor: Color = .gray,
    handleBorderColor: Color = .white,
    handleSize: CGFloat = 12,
    selectionBoxColor: Color = .blue.opacity(0.1),
    selectionBoxBorderColor: Color = .blue.opacity(0.5),
    canvasBackgroundColor: Color = .clear,
    gridColor: Color = .gray.opacity(0.3),
    gridSpacing: CGFloat = 20,
    minimapBackgroundOpacity: CGFloat = 0.9,
    minimapNodeColor: Color = .gray.opacity(0.5),
    minimapSelectedNodeColor: Color = .blue,
    snapLineColor: Color = .blue.opacity(0.5),
    snapLineWidth: CGFloat = 1,
    edgeLabelFont: Font = .system(size: 11),
    edgeLabelColor: Color = .black,
    edgeLabelBackgroundColor: Color = .white
  ) {
    self.edgeColor = edgeColor
    self.edgeSelectedColor = edgeSelectedColor
    self.edgeWidth = edgeWidth
    self.edgeSelectedWidth = edgeSelectedWidth
    self.nodeBackgroundColor = nodeBackgroundColor
    self.nodeSelectedBorderColor = nodeSelectedBorderColor
    self.nodeSelectedBorderWidth = nodeSelectedBorderWidth
    self.handleColor = handleColor
    self.handleBorderColor = handleBorderColor
    self.handleSize = handleSize
    self.selectionBoxColor = selectionBoxColor
    self.selectionBoxBorderColor = selectionBoxBorderColor
    self.canvasBackgroundColor = canvasBackgroundColor
    self.gridColor = gridColor
    self.gridSpacing = gridSpacing
    self.minimapBackgroundOpacity = minimapBackgroundOpacity
    self.minimapNodeColor = minimapNodeColor
    self.minimapSelectedNodeColor = minimapSelectedNodeColor
    self.snapLineColor = snapLineColor
    self.snapLineWidth = snapLineWidth
    self.edgeLabelFont = edgeLabelFont
    self.edgeLabelColor = edgeLabelColor
    self.edgeLabelBackgroundColor = edgeLabelBackgroundColor
  }

  /// The default SwiftFlow theme.
  public static let `default` = SwiftFlowTheme()

  /// A dark theme suitable for dark mode interfaces.
  public static let dark = SwiftFlowTheme(
    edgeColor: .white.opacity(0.4),
    edgeSelectedColor: .cyan,
    nodeBackgroundColor: Color(white: 0.2),
    nodeSelectedBorderColor: .cyan,
    handleColor: .white.opacity(0.6),
    selectionBoxColor: .cyan.opacity(0.1),
    selectionBoxBorderColor: .cyan.opacity(0.5),
    canvasBackgroundColor: Color(white: 0.12),
    gridColor: .white.opacity(0.08),
    minimapNodeColor: .white.opacity(0.3),
    minimapSelectedNodeColor: .cyan,
    snapLineColor: .cyan.opacity(0.5),
    edgeLabelColor: .white,
    edgeLabelBackgroundColor: Color(white: 0.2)
  )

  /// A light theme suitable for light mode interfaces (identical to `default`).
  public static let light = SwiftFlowTheme()
}
