This guide covers the Metapolis map: how to open it, move around, select, colour and filter the buildings, use the map tools, and change what the map displays.

The map is built from two ResearchSpace components, described in the [Map Component Guide](Map-Component-Guide):

- **`semantic-map-advanced`**: the map itself (OpenLayers), which draws the building footprints over a basemap. It also holds the on-map buttons: basemap switcher, compass and measuring tool.
- **`semantic-map-controls`**: the toolbar on the left of the map, with the **Details**, **Layers** and **Style** panels, the visualization modes and the timeline.

**See also:** [Map Component Guide](Map-Component-Guide) · [PostGIS and SQL Sail](PostGIS-and-SQL-Sail) · [Data Model and Forms](Data-Model-and-Forms)

## Contents

- [Open the map](#open-the-map)
- [Screen layout](#screen-layout)
- [Move around the map](#move-around-the-map)
- [Switch the basemap](#switch-the-basemap)
- [Select a building](#select-a-building)
- [Colour, label and filter buildings by function](#colour-label-and-filter-buildings-by-function)
- [Show, hide and fade the buildings layer](#show-hide-and-fade-the-buildings-layer)
- [Filter by year with the timeline](#filter-by-year-with-the-timeline)
- [Tools: measure, spyglass, swipe and 3D](#tools-measure-spyglass-swipe-and-3d)
- [The simple map page](#the-simple-map-page)
- [Customize the map](#customize-the-map)
- [Troubleshooting](#troubleshooting)

---

## Open the map

The map is a ResearchSpace template page with the IRI `https://metapolis.com/resource/map`:

```
http://<your-researchspace-host>/resource/?uri=https%3A%2F%2Fmetapolis.com%2Fresource%2Fmap
```

Its source is `data/templates/https%3A%2F%2Fmetapolis.com%2Fresource%2Fmap.html` in the `metapolis` app. The page runs in `<semantic-context repository="metapolis">`, so its query goes straight to the backend (PostGIS through the [SQL Sail](PostGIS-and-SQL-Sail), or a SPARQL endpoint, see [QLever and SPARQL Backends](QLever-and-SPARQL-Backends)).

A loading overlay is shown while the query runs, then the map **zooms to fit every building** returned by the `all_buildings` query (with the sample data, the historic centre of Florence).

## Screen layout

| Where | What |
|---|---|
| Left toolbar, top | **Details** (house icon), **Layers** (layers icon), **Style** (paint brush icon). Each opens a panel; click the icon again or **✕** to close it |
| Left toolbar, below the divider | **Spyglass Mode**, **Swipe Mode**, **Toggle 3D View** |
| Bottom of the map | The **timeline** |
| Bottom-right corner | **Basemap switcher** |
| Top-right corner | **Compass** |
| Top-left | **Measure distance** (ruler icon) and the **+** / **−** zoom buttons |

Hover a toolbar button to see its name.

## Move around the map

| Action | Mouse / trackpad | Keyboard / touch |
|---|---|---|
| Pan | Click and drag | Arrow keys (when the map has focus), or drag with one finger |
| Zoom in / out | Scroll wheel, or **+** / **−** | `+` / `-` keys, or pinch |
| Zoom in on a point | Double-click | Double-tap |
| Zoom to an area | `Shift` + drag a box | — |
| Rotate | Drag the **compass**, or `Alt` + `Shift` + drag | Two-finger twist |
| Reset to north | Click the **compass** | — |

## Switch the basemap

Hover (or click) the basemap switcher in the bottom-right corner, then pick a basemap. Three are configured as `<tiles-layer level="basemap">` elements:

| Name | Identifier | Source |
|---|---|---|
| Google Roadmap | `GRoadmap` | Google |
| Light | `CartoLight` | Carto |
| OpenStreetMap | `OpenStreetMap` | OpenStreetMap |

Only one basemap is shown at a time; building footprints are always drawn on top.

## Select a building

Click a footprint. The map zooms to it with a short flash, highlights it in bright blue with a black 2 px outline (`selected-feature-style`), dims the other buildings and opens the **Details** panel with:

- **Name** and **Category** (the function)
- **Building ID**: the `id` of the row in `metapolis.buildings`
- **Time Period**: shown when the query returns `?bob`
- **Subject URI**: the IRI of the feature in the `metapolis` repository

Click an empty part of the map to clear the selection. Clicks do not select buildings while the measuring tool, spyglass or swipe is on.

The Building ID is what connects the footprint to a Metapolis Building: the Building form stores `http://metapolis.com/resource/feature/<building_id>` (see [Linking a Building to its geometry](Data-Model-and-Forms#linking-a-building-to-its-geometry)).

## Colour, label and filter buildings by function

Colouring is **off when the page opens**. To turn it on, click **Style**, switch on **Enable Feature Styling** and choose **function** under **Color by**. The template's palette is:

| Function | Colour |
|---|---|
| Religious | green `rgba(46,125,50,0.9)` |
| Government | blue `rgba(21,101,192,0.9)` |
| Cultural | pink `rgba(194,24,91,0.9)` |
| Commercial | orange `rgba(239,108,0,0.9)` |

In the same panel, **Label by** writes a property on each building (with an optional label background), and the palette buttons generate a random palette or reset all groups to one colour.

With a **Color by** option selected, a **legend** appears on the map: click a function's name to hide/show it, click its colour dot to change the colour, or use **See all** / **Hide all**. The legend lists the functions in the current view; hover it to see all of them. Switching styling off resets **Label by** and **Color by**.

## Show, hide and fade the buildings layer

Click **Layers**. The **Geometries** section lists the buildings layer with an **eye** icon (hide/show) and an **opacity** slider.

## Filter by year with the timeline

The timeline hides the buildings that did not exist in the selected year (`year-filtering="true"` on the map). It is set to range **1300–2025**, default year **1700**, mode `normal`, not locked.

A building is shown when `?bob` ≤ year ≤ `?eoe`:

- a building **without** `?bob` is never filtered;
- a building without `?eoe` is treated as still existing;
- only the part before the first `-` is read (`1450-03-01` counts as 1450); a value that cannot be read hides the building while the filter is on.

> **Note:** the current query does not read real dates. It binds `?bob`/`?eob` = 1300 and `?boe`/`?eoe` = 2025 for every building, so all buildings stay visible on the whole timeline. To filter by real dates, replace the `BIND` lines with values from the backend (e.g. optional `start_year` / `end_year` columns mapped in `config/services/metapolis-ephedra.ttl`, see [Adding a query or a column](PostGIS-and-SQL-Sail#adding-a-query-or-a-column)) or from the Building's physical phase.

Add `"tour": true` to the `timeline` setting to show a **play** button that advances the year by 10 at a time and loops.

## Tools: measure, spyglass, swipe and 3D

While a tool is on, a banner at the top of the map names it. Press `Esc` or click **✕** in the banner to leave it.

| Tool | How to use it |
|---|---|
| **Measure distance** (ruler, top-left) | Click on the map to add points along a line; the distance is shown on the map |
| **Spyglass Mode** | Shows the chosen layer (by default the buildings) only inside a circle that follows the pointer. Change the radius with the slider in the banner, or with right-click / `Ctrl` + click |
| **Swipe Mode** | Drag the vertical line to show the chosen layer on one side only |
| **Toggle 3D View** | Shows the map on a 3D globe. Metapolis has no 3D models yet, so this only tilts the 2D layers. A sun panel on the right sets the light direction |

Spyglass and swipe are most useful with historical maps: add them as `<tiles-layer level="overlay">` and choose them in the banner's layer list.

## The simple map page

`https://metapolis.com/resource/map_base` is a lighter page that uses the basic `semantic-map` component (no toolbar, styling or timeline):

```
http://<your-researchspace-host>/resource/?uri=https%3A%2F%2Fmetapolis.com%2Fresource%2Fmap_base
```

It runs on the `ephedra` federation and is meant to show only the footprints already **linked to a Metapolis Building**.

> **Known issue:** its query joins on `?building metapolis_ontology:related_feature ?name`, but the Building form stores the link as `crm:P138i_has_representation` → `rdfs:label` on the physical phase (see [Linking a Building to its geometry](Data-Model-and-Forms#linking-a-building-to-its-geometry)). As written, the page will normally show nothing until the query is aligned with the form.

## Customize the map

All settings live in the template. Edit it in ResearchSpace (**Edit page**) or in `data/templates/` and reload.

| To change | Edit |
|---|---|
| Which buildings are shown | The `query` on `semantic-map-advanced`. Swap `"all_buildings"` for another [predefined query](PostGIS-and-SQL-Sail#predefined-queries). The map needs at least `?subject` and `?wkt` |
| Colours | `features-colors-palette` on `semantic-map-controls`. Keys must match `function` values exactly |
| Colour by function on load | Add `styling-enabled="true"` to `semantic-map-controls` |
| Selection highlight | `selected-feature-style` on `semantic-map-advanced` |
| Timeline range, start year, play button | `timeline` on `semantic-map-controls` (`min`, `max`, `default`, `tour`) |
| Details panel | The `<template id="feature-details">` block. Read a property with `{{selectedFeature.values_.<variable>.value}}`, where `<variable>` is selected in the query |
| Basemaps | Add, remove or reorder `<tiles-layer level="basemap">`. `url` is an XYZ template with `{x}`, `{y}`, `{z}`; `thumbnail` is the image in the switcher |
| Historical maps | Add `<tiles-layer level="overlay">` with a `year`. They appear in **Layers**, with filters to sync them with the timeline |
| Initial view | `fix-center` (`[lng, lat]`) and `fix-zoom-level` |

> **Note:** the template sets `map-options='{"crs":"EPSG:4326", "extent": [11.248, 43.764, 11.264, 43.775]}'`, but `semantic-map-advanced` currently ignores `extent` (only `crs` is used), so the initial view always fits the loaded buildings.

> Check the terms of use of each tile provider before publishing a public instance. The Google tile URL in the template is not an official API endpoint.

The core of the template, for reference:

```html
<semantic-context repository="metapolis">
  <semantic-map-controls
    id="my-map-controls"
    target-map-id="my-map"
    features-options-enabled="true"
    features-taxonomies="function"
    features-color-taxonomies="function"
    features-colors-palette='{"Religious":"rgba(46,125,50,0.9)", "Government":"rgba(21,101,192,0.9)", "Cultural":"rgba(194,24,91,0.9)", "Commercial":"rgba(239,108,0,0.9)"}'
    timeline='{"mode": "normal", "min": 1300, "max": 2025, "default": 1700, "locked": false}'
    render-template="{{> feature-details}}"
    template-mapping='{"selectedFeature": "{{> feature-details}}"}'>
    <template id="feature-details">
      {{#if selectedFeature.values_}}
        <h3>{{selectedFeature.values_.name.value}}</h3>
        <p><strong>Category:</strong> {{selectedFeature.values_.function.value}}</p>
        <p><strong>Building ID:</strong> {{selectedFeature.values_.building_id.value}}</p>
        ...
      {{/if}}
    </template>
  </semantic-map-controls>

  <semantic-map-advanced
    id="my-map"
    target-controls='["my-map-controls"]'
    feature-selection-targets='["my-map-controls"]'
    map-options='{"crs":"EPSG:4326", "extent": [11.248, 43.764, 11.264, 43.775]}'
    year-filtering="true"
    selected-feature-style='{"color": "rgba(0, 128, 255, 1)", "borderColor": "black", "borderWidth": 2}'
    query='
      PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
      PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>
      SELECT ?subject ?wkt ?function ?name ?building_id ?bob ?eob ?boe ?eoe WHERE {
        ?subject rs_sql_sail:hasQueryId "all_buildings";
          metapolis_sql:building_id ?building_id;
          metapolis_sql:name ?name;
          metapolis_sql:function ?function;
          metapolis_sql:wkt ?wkt.
        BIND("1300" AS ?bob) BIND("1300" AS ?eob)
        BIND("2025" AS ?boe) BIND("2025" AS ?eoe)
      }'>
    <tiles-layer level="basemap" identifier="GRoadmap" name="Google Roadmap" ... ></tiles-layer>
    <tiles-layer level="basemap" identifier="CartoLight" name="Light" ... ></tiles-layer>
    <tiles-layer level="basemap" identifier="OpenStreetMap" name="OpenStreetMap" ... ></tiles-layer>
  </semantic-map-advanced>
</semantic-context>
```

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| The map loads but shows no buildings | The `metapolis` repository cannot reach the backend. Run the test query in [Step 6](Installation-and-Setup#step-6-check-that-everything-works) |
| No buildings on `map_base` | No Building has a linked feature, the Ephedra federation is not configured ([Step 4](Installation-and-Setup#step-4-add-metapolis-to-the-ephedra-federation)), or the known `related_feature` issue described in [The simple map page](#the-simple-map-page) |
| Buildings in the wrong place, or missing after an import | The geometry is not in EPSG:4326, or is invalid |
| All buildings have the same colour | Feature styling is off by default. Open **Style**, enable it and choose **Color by: function** (or add `styling-enabled="true"`) |
| A building has an unexpected colour | Its `function` value is not a key of `features-colors-palette` (check spelling and case) |
| Clicking a building does nothing | A tool is on (measure, spyglass or swipe). Press `Esc` |
| The basemap is blank | The tile provider is unreachable or blocks the request. Switch basemap |
| The timeline does not hide anything | Expected with the current query (see the note in [Filter by year](#filter-by-year-with-the-timeline)) |
| The map does not open on the `extent` in `map-options` | Known limitation: use `fix-center` and `fix-zoom-level` |
