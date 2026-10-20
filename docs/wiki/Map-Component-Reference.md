This is the developer reference for the `semantic-map-advanced` and `semantic-map-controls` components: their architecture, props, state, events and internals. The components are built on OpenLayers and are part of the ResearchSpace core from version 4.0, in `src/main/web/components/semantic/map-advanced/` (attribute reference: `USER_README.md` in the same folder).

**See also:** [Map Component Guide](Map-Component-Guide) · [Map Navigation](Map-Navigation)

## Contents

- [Architecture](#architecture)
- [File structure](#file-structure)
- [Core classes and interfaces](#core-classes-and-interfaces)
  - [SemanticMapAdvanced](#semanticmapadvanced)
  - [SemanticMapControls](#semanticmapcontrols)
- [Event system](#event-system)
  - [Map-to-controls events](#map-to-controls-events)
  - [Controls-to-map events](#controls-to-map-events)
- [Integration with OpenLayers](#integration-with-openlayers)
- [Advanced features](#advanced-features)
  - [Visualization modes](#visualization-modes)
  - [Feature styling](#feature-styling)
  - [Timeline](#timeline)
  - [Feature selection](#feature-selection)
- [Performance optimizations](#performance-optimizations)
- [Known limitations](#known-limitations)
- [Integration example](#integration-example)

---

## Architecture

The component consists of two main parts:

1. **SemanticMapAdvanced**: The core map component that renders the OpenLayers map and handles feature display, interactions, and visualization modes.
2. **SemanticMapControls**: A companion component that provides a user interface for controlling map layers, styling features, and activating visualization modes.

These components communicate through a custom event system, allowing them to be used together or independently.

## File structure

- **SemanticMapAdvanced.ts**: Main map component implementation
- **SemanticMapControls.tsx**: UI controls component implementation
- **SemanticMapEvents.ts**: Event definitions for map-to-controls communication
- **SemanticMapControlsEvents.ts**: Event definitions for controls-to-map communication
- **TilesLayer.ts**: Component for defining tile layers
- **SemanticMapLoading.scss**: Styling for loading indicators
- **SemanticMapControls.scss**: Styling for the controls component

## Core classes and interfaces

### SemanticMapAdvanced

#### Props (`SemanticMapAdvancedConfig`)

| Property | Type | Description |
|----------|------|-------------|
| `query` | string | SPARQL Select query that projects geographic data |
| `tupleTemplate` | string | Template for marker popups |
| `noResultTemplate` | string | Template displayed when query returns no results |
| `fixZoomLevel` | number | Optional fixed zoom level (0-18) |
| `fixCenter` | Array<number> | Optional fixed center coordinates |
| `mapOptions` | MapOptions | Map configuration options |
| `id` | string | Component ID for event communication |
| `provider` | Source | Map tile provider (e.g., "osm") |
| `providerOptions` | ProviderOptions | Provider-specific options |
| `targetControls` | Array<string> | IDs of control components to sync with |
| `featureSelectionTargets` | Array<string> | Targets for feature selection events |
| `yearFiltering` | boolean | Enable filtering by year |
| `vectorLevels` | Array | Possible levels of features in the map |
| `selectedFeatureStyle` | object | Style configuration for selected features |

> **Limitation:** of `mapOptions`, only `crs` is used. `extent` is ignored (`getInputExtent()` never returns the value), so the initial view always fits the loaded features. Use `fixCenter` and `fixZoomLevel` to force a view.

#### State (`MapState`)

| Property | Type | Description |
|----------|------|-------------|
| `tupleTemplate` | Data.Maybe<HandlebarsTemplateDelegate> | Compiled template for popups |
| `errorMessage` | Data.Maybe<string> | Error message if any |
| `noResults` | boolean | Whether query returned no results |
| `isLoading` | boolean | Loading state |
| `baseMapLoaded` | boolean | Whether base map has loaded |
| `overlayVisualization` | string | Current visualization mode |
| `featureColor` | string | Default feature color |
| `mapLayers` | Array<any> | Map layers |
| `maskIndex` | number | Index for visualization mask |
| `featuresLabel` | string | Property to use for feature labels |
| `featuresColorTaxonomy` | string | Property to use for feature coloring |
| `groupColorAssociations` | object | Color associations for feature groups |
| `year` | string | Current year for filtering |
| `yearFiltering` | boolean | Whether year filtering is enabled |
| `registeredControls` | Array<any> | Registered control components |
| `selectedFeature` | Feature | Currently selected feature |
| `vectorLevels` | object | Configuration for vector levels |

#### Key methods

| Method | Description |
|--------|-------------|
| `createMap()` | Initializes the OpenLayers map |
| `addMarkersFromQuery()` | Executes SPARQL query and adds markers to the map |
| `initializeMarkerPopup()` | Sets up popup functionality for markers |
| `updateLayers()` | Updates map layers with new geometries |
| `setOverlayVisualization()` | Sets the current visualization mode |
| `applyFeaturesFilteringFromControls()` | Applies filters from controls to features |
| `updateFeatureColorsByGroups()` | Updates feature colors based on group associations |
| `highlightFeaturesByIris()` | Highlights features by their subject IRIs |
| `zoomToFeature()` | Zooms the map to a specific feature |
| `activateMeasurementTool()` | Activates the measurement tool |
| `deactivateMeasurementTool()` | Deactivates the measurement tool |

### SemanticMapControls

#### Props

| Property | Type | Description |
|----------|------|-------------|
| `targetMapId` | string | ID of the target map component |
| `id` | string | Component ID for event communication |
| `featuresTaxonomies` | string | Comma-separated list of taxonomies for features |
| `featuresColorTaxonomies` | string | Comma-separated list of taxonomies for coloring |
| `featuresOptionsEnabled` | boolean | Whether feature options are enabled |
| `filtersInitialization` | Filters | Initial filter state |
| `showFilters` | boolean | Whether to show filters |
| `timeline` | Timeline | Timeline configuration |
| `featuresColorsPalette` | string | Color palette for features |
| `locked` | boolean | Whether timeline is locked |
| `tour` | boolean | Whether tour mode is enabled |
| `renderTemplate` | string | Template reference for rendering |
| `fallbackTemplate` | string | Fallback template |
| `detailsMapTemplate` | string | Template for details panel |
| `baseMapTemplate` | string | Template for base maps panel |
| `buildingsTemplate` | string | Template for buildings panel |
| `templateMapping` | object | Mapping of data kinds to templates |
| `stylingEnabled` | boolean | Turn feature styling (Color by / Label by) on when the page loads (default: false; attribute `styling-enabled`) |

#### State

| Property | Type | Description |
|----------|------|-------------|
| `overlayOpacity` | number | Opacity of overlay layers |
| `swipeValue` | number | Value for swipe visualization |
| `overlayVisualization` | string | Current visualization mode |
| `loading` | boolean | Loading state |
| `color` | any | Current color |
| `mapLayers` | Array<any> | Map layers |
| `maskIndex` | number | Index for visualization mask |
| `filters` | Filters | Current filter state |
| `selectedFeaturesLabel` | string | Property to use for feature labels |
| `featuresColorTaxonomy` | string | Property to use for feature coloring |
| `featuresColorGroups` | string[] | Groups for feature coloring |
| `groupColorAssociations` | object | Color associations for feature groups |
| `displayColorPicker` | object | State of color pickers |
| `year` | number | Current year for filtering |
| `yearMarks` | number[] | Year marks for timeline |
| `registeredMap` | string | ID of registered map |
| `groupDisabled` | object | Disabled state of groups |
| `selectedFeature` | any | Currently selected feature |
| `activePanel` | string | Currently active panel |
| `isPlaying` | boolean | Whether timeline is playing |
| `generalizedData` | GeneralizedEventData | Generalized data for rendering |

#### Key methods

| Method | Description |
|--------|-------------|
| `triggerRegisterToMap()` | Registers the controls with the map |
| `triggerUnregisterToMap()` | Unregisters the controls from the map |
| `triggerSendLayers()` | Sends layer information to the map |
| `triggerSendYear()` | Sends year information to the map |
| `triggerSendFeaturesColorsAssociationsToMap()` | Sends color associations to the map |
| `triggerVisualization()` | Triggers visualization mode change |
| `togglePanel()` | Toggles a panel open/closed |
| `toggleVisualizationMode()` | Toggles a visualization mode on/off |
| `handleTimelinePlay()` | Handles timeline play/pause |
| `handleColorPickerChange()` | Handles color picker changes |
| `generateColorPalette()` | Generates a color palette for features |

## Event system

The components communicate through a custom event system defined in `SemanticMapEvents.ts` and `SemanticMapControlsEvents.ts`. Key events include:

### Map-to-controls events

| Event | Description |
|-------|-------------|
| `SemanticMapBoundingBoxChanged` | Fired when the map's bounding box changes |
| `SemanticMapUpdateFeatureColor` | Updates feature colors |
| `SemanticMapSendSelectedFeature` | Sends selected feature to controls |
| `SemanticMapRequestControlsRegistration` | Requests controls to register with the map |
| `SemanticMapClearSelectedFeature` | Clears the selected feature |

### Controls-to-map events

| Event | Description |
|-------|-------------|
| `SemanticMapControlsOverlayVisualization` | Sets visualization mode |
| `SemanticMapControlsOverlaySwipe` | Sets swipe value |
| `SemanticMapControlsFeatureColor` | Sets feature color |
| `SemanticMapControlsSendMapLayersToMap` | Sends layer information to the map |
| `SemanticMapControlsSendMaskIndexToMap` | Sends mask index to the map |
| `SemanticMapControlsSendFeaturesLabelToMap` | Sends feature label property to the map |
| `SemanticMapControlsSendFeaturesColorTaxonomyToMap` | Sends color taxonomy to the map |
| `SemanticMapControlsSendGroupColorsAssociationsToMap` | Sends color associations to the map |
| `SemanticMapControlsSendYear` | Sends year to the map |
| `SemanticMapControlsRegister` | Registers controls with the map |
| `SemanticMapControlsUnregister` | Unregisters controls from the map |
| `SemanticMapControlsToggleMeasurement` | Toggles measurement tool |
| `SemanticMapControlsHighlightFeatures` | Highlights features based on a SPARQL pattern |

## Integration with OpenLayers

The component uses OpenLayers for map rendering and interaction. Key OpenLayers classes used include:

- `Map`: Main map class
- `View`: Map view configuration
- `TileLayer`: For base maps and overlays
- `VectorLayer`: For feature layers
- `Feature`: For map features
- `Style`: For feature styling
- `Overlay`: For popups and tooltips
- `Draw`, `Modify`, `Snap`: For editing interactions
- `Cluster`: For clustering features

## Advanced features

### Visualization modes

The component supports several visualization modes:

- **Normal**: Standard map view
- **Spyglass**: Allows viewing one layer through another using a circular lens
- **Swipe**: Allows comparing two layers using a swipe interface
- **Measurement**: Allows measuring distances on the map
- **3D view**: Shows the map on a 3D globe (toolbar button **Toggle 3D View**), with a sun panel to set the light direction. Without 3D models it tilts the 2D layers

While a mode is on, a banner at the top of the map names it; `Esc` or **✕** leaves it, and clicks no longer select features.

### Feature styling

Features can be styled based on properties:

- Color by taxonomy
- Label by taxonomy
- Custom color associations for groups
- Off by default: enabled from the **Style** panel or with `styling-enabled="true"`
- Highlight selected features

### Timeline

The component supports timeline functionality for temporal data:

- Year-based filtering
- Timeline slider
- Animation mode
- Year marks for navigation

### Feature selection

Features can be selected by clicking, which:

- Highlights the feature
- Displays feature information in a popup
- Sends feature information to controls
- Can trigger SPARQL queries for related data

## Performance optimizations

The component includes several optimizations for handling large datasets:

- Feature clustering for point data
- Dynamic cluster distance based on zoom level
- Style caching to reduce style creation overhead
- Visible feature tracking to optimize rendering
- Debounced updates for viewport changes
- Optimized feature filtering

## Known limitations

- **`extent` is ignored**: of `mapOptions`, only `crs` is used (`getInputExtent()` never returns the value), so the initial view always fits the loaded features. Use `fixCenter` and `fixZoomLevel` to force a view.
- **Styling is off by default**: Color by / Label by start disabled unless `stylingEnabled` is set.
- **3D view without 3D data**: without 3D models, the 3D view only tilts the 2D layers.

## Integration example

See the [Map Component Guide](Map-Component-Guide) for examples, and [Map Navigation](Map-Navigation) for the Metapolis map page.
