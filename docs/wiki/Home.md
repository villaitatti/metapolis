**Metapolis: Spatializing Histories through Archival Sources** is a [ResearchSpace](https://github.com/researchspace/researchspace) app for describing historical buildings, events, people and sources, and placing them on an interactive map.

It lets scholars geospatially reconstruct places through time: archival, bibliographic and multimedia sources are linked to interpretive research and visualized on a map. Because it runs on ResearchSpace, all data is Linked Open Data and can be enriched with external knowledge bases such as VIAF, Wikidata, OCLC and the Getty vocabularies.

Metapolis lets researchers:

- describe **Buildings**, **Events**, **People** and **Sources** with semantic forms, and link them to each other;
- link each Building to a **geometry** (a building footprint) kept in a GIS backend;
- show the footprints on an **interactive map** with styling by function, a timeline, spyglass/swipe comparison and a 3D view;
- query the geodata with **SPARQL**, even when it lives in a relational PostGIS database.

## How the pieces fit together

Metapolis is split across **two repositories**:

| Repository | What it contains | Where it goes |
|---|---|---|
| [`metapolis`](https://github.com/villaitatti/metapolis) | The ResearchSpace **app**: page templates, forms, map views, the repository and service definitions, the PostgreSQL JDBC driver and `setup.sh` | Installed as an app inside your ResearchSpace instance |
| [`metapolis_setup`](https://github.com/villaitatti/metapolis_setup) | The **backends** in Docker (PostGIS by default, QLever as an alternative) with sample data, and the **`.trig` files** (ontology, entities, Knowledge Patterns) imported into ResearchSpace | Run/imported once, alongside ResearchSpace |

At runtime the flow is:

```
Metapolis forms & map (ResearchSpace)
        │  SPARQL
        ▼
Ephedra federation ──SERVICE <…federation#metapolis>──▶ "metapolis" repository (SQL Sail)
                                                              │  SQL
                                                              ▼
                                                PostgreSQL + PostGIS (metapolis.buildings)
```

The app never stores geometries in the triple store. It queries them live from the backend through predefined queries, and links them to semantic entities by ID (`http://metapolis.com/resource/feature/<building_id>`).

PostGIS is the default backend. The `metapolis` repository can also point to a SPARQL endpoint, such as the bundled QLever setup or your own endpoint (see [QLever and SPARQL Backends](QLever-and-SPARQL-Backends)). The forms and the map work the same way with any backend.

## What is in the app repository

```
metapolis/
├── setup.sh                           # First-run setup script
├── plugin.properties                  # App id (metapolis) / version for ResearchSpace
├── docs/wiki/                         # This wiki (published by .github/workflows/publish-wiki.yml)
├── config/
│   ├── namespaces.prop                # metapolis_forms, metapolis_ontology prefixes
│   ├── repositories/metapolis.ttl     # Backend connection (PostGIS by default; rewritten by setup.sh)
│   ├── services/metapolis-ephedra.ttl # SPARQL ↔ SQL mapping and predefined queries
│   └── page-layout/html-head.hbs      # Extra <head> content
├── data/templates/                    # Start page, map pages, Building/Event/Person/Source forms
├── assets/images/                     # Static images (basemap thumbnail)
└── lib/postgresql-42.2.14.jar         # PostgreSQL JDBC driver
```

The map components themselves (`semantic-map-advanced`, `semantic-map-controls`) are part of ResearchSpace core (4.0+), in `src/main/web/components/semantic/map-advanced/`. Metapolis only configures them in its templates.

| Template | Page IRI | Purpose |
|---|---|---|
| `http%3A%2F%2Fmetapolis.com%2Fforms%2F{Building,Event,Person,Source}.html` | `http://metapolis.com/forms/…` | Entity forms (see [Data Model and Forms](Data-Model-and-Forms)) |
| `https%3A%2F%2Fmetapolis.com%2Fresource%2Fmap.html` | `https://metapolis.com/resource/map` | Full map with toolbar, styling and timeline |
| `https%3A%2F%2Fmetapolis.com%2Fresource%2Fmap_base.html` | `https://metapolis.com/resource/map_base` | Simple map of the features linked to Buildings |
| `https%3A%2F%2Fmetapolis.com%2Ftemplates%2Ftest.html` | `https://metapolis.com/templates/test` | Test page |
| `http%3A%2F%2Fwww.researchspace.org%2Fresource%2FStart.html` | `http://www.researchspace.org/resource/Start` | ResearchSpace start page |

## Quick start

Prerequisites: **ResearchSpace 4.0+** running, **Docker** with Docker Compose, **Git**, **Bash** and **curl**.

```bash
git clone https://github.com/villaitatti/metapolis.git
cd metapolis
./setup.sh                                  # starts PostGIS and writes config/repositories/metapolis.ttl
                                            # (add --data-host host.docker.internal if ResearchSpace runs in Docker)
# add the metapolis folder to ResearchSpace as an app, restart ResearchSpace, then:
./setup.sh --rs-url http://localhost:10214  # federation + ontology + entity configurations
```

Finally, import `../metapolis_setup/configurations/Metapolis_KP.trig` in **System Settings → Knowledge Patterns**. Full details, manual steps and checks are in [Installation and Setup](Installation-and-Setup).

Once installed:

- the Finder sidebar shows **Metapolis Building**, **Event**, **Person** and **Source**;
- the map is at `http://<host>/resource/?uri=https%3A%2F%2Fmetapolis.com%2Fresource%2Fmap`.

## Getting help

- Each page ends with a **Troubleshooting** table; start with [Installation and Setup](Installation-and-Setup#troubleshooting) and [Map Navigation](Map-Navigation#troubleshooting).
- Validate SPARQL queries on the `/sparql` page before using them in a template.
- Search or open an issue on [GitHub](https://github.com/villaitatti/metapolis/issues).

## Acknowledgements

Funded by the National Endowment for the Humanities (NEH) as part of the Digital Humanities Advancement Grants.

- **Project:** Metapolis: Spatializing Histories through Archival Sources ([HAA-287761-22](https://apps.neh.gov/publicquery/AwardDetail.aspx?gn=HAA-287761-22))
- **Project Director:** Lukas Klic
