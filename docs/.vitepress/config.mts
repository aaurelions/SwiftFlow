import { defineConfig } from "vitepress";

export default defineConfig({
  base: "/SwiftFlow/",
  lang: "en-US",
  title: "SwiftFlow",
  description: "A SwiftUI-native node-based graph editor for iOS and macOS.",
  head: [
    ["meta", { name: "theme-color", content: "#2a7486" }],
    ["meta", { name: "og:type", content: "website" }],
    ["meta", { name: "og:title", content: "SwiftFlow" }],
    [
      "meta",
      {
        name: "og:description",
        content: "A SwiftUI-native node-based graph editor for iOS and macOS.",
      },
    ],
    ["link", { rel: "icon", href: "/SwiftFlow/favicon.ico" }],
  ],

  themeConfig: {
    nav: [
      { text: "Guide", link: "/guide/getting-started" },
      { text: "API", link: "/api/swiftflow-canvas" },
      { text: "Examples", link: "/examples/ai-flow" },
    ],

    socialLinks: [{ icon: "github", link: "https://github.com/aaurelions/SwiftFlow" }],

    sidebar: {
      "/guide/": [
        {
          text: "Guide",
          items: [
            { text: "Getting Started", link: "/guide/getting-started" },
            { text: "Installation", link: "/guide/installation" },
            { text: "State Management", link: "/guide/state-management" },
            { text: "Theming", link: "/guide/theming" },
            { text: "Interactions", link: "/guide/interactions" },
            { text: "Viewport Controls", link: "/guide/viewport-controls" },
          ],
        },
      ],
      "/api/": [
        {
          text: "Core API",
          items: [
            { text: "SwiftFlow Canvas", link: "/api/swiftflow-canvas" },
            { text: "Models", link: "/api/models" },
            { text: "Callbacks", link: "/api/callbacks" },
          ],
        },
        {
          text: "Components",
          items: [
            { text: "Handle", link: "/api/handle" },
            { text: "Background", link: "/api/background" },
            { text: "Controls", link: "/api/controls" },
            { text: "MiniMap", link: "/api/minimap" },
            { text: "Panel & Overlays", link: "/api/panel-overlays" },
            { text: "BaseEdge", link: "/api/base-edge" },
          ],
        },
        {
          text: "State Management",
          items: [
            { text: "SwiftFlowStore", link: "/api/swiftflow-store" },
            { text: "SwiftFlowInstance", link: "/api/swiftflow-instance" },
          ],
        },
        {
          text: "Utilities",
          items: [
            { text: "Change Utilities", link: "/api/change-utilities" },
            { text: "Graph & Geometry", link: "/api/graph-utilities" },
            { text: "Auto Layout", link: "/api/auto-layout" },
            { text: "Serialization", link: "/api/serialization" },
          ],
        },
        {
          text: "Reference",
          items: [{ text: "Types Reference", link: "/api/types-reference" }],
        },
      ],
      "/examples/": [
        {
          text: "Examples",
          items: [
            { text: "AI Flow Demo", link: "/examples/ai-flow" },
            { text: "Basic Graph", link: "/examples/basic" },
            { text: "Custom Nodes", link: "/examples/custom-nodes" },
            { text: "Custom Edges", link: "/examples/custom-edges" },
            { text: "State Management", link: "/examples/state-management" },
            { text: "Connection Validation", link: "/examples/connection-validation" },
            { text: "Auto Layout", link: "/examples/auto-layout" },
            { text: "Viewport Controls", link: "/examples/viewport-controls" },
            { text: "Resizable Nodes", link: "/examples/resizable-nodes" },
            { text: "Serialization", link: "/examples/serialization" },
          ],
        },
      ],
    },

    search: {
      provider: "local",
    },

    footer: {
      message: "SwiftUI-native node graph editor.",
    },
  },
});
