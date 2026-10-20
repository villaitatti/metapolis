# Metapolis

**Metapolis** is an interactive, map-based research and publication platform for the humanities, built as an app for [ResearchSpace](https://github.com/researchspace/researchspace).

It lets scholars geospatially reconstruct places through time: archival, bibliographic and multimedia sources are linked to interpretive research and visualized on a map. Because it runs on ResearchSpace (an open-source Semantic Web environment), all data is Linked Open Data and can be enriched with external knowledge bases such as VIAF, Wikidata, OCLC and the Getty vocabularies.

With Metapolis you can:

- create and manage **Buildings**, **Events**, **People** and **Sources**
- link each Building to a geometry stored in **PostgreSQL/PostGIS** (or a SPARQL endpoint such as QLever)
- connect entities to each other and to archival sources
- visualize the results on an interactive map
- publish everything as Linked Open Data

## Quick start

Requirements: **ResearchSpace 4.0+**, **Docker** with Docker Compose, **Git**, **Bash** and **curl**.

```bash
git clone https://github.com/villaitatti/metapolis.git
cd metapolis

# 1. Download metapolis_setup next to this folder, start PostGIS and configure the app
#    (add --data-host host.docker.internal if ResearchSpace runs in Docker)
./setup.sh

# 2. Add this folder to ResearchSpace as an app and restart ResearchSpace

# 3. Configure ResearchSpace: federation, ontology and entity configurations
./setup.sh --rs-url http://localhost:10214
```

Then import `../metapolis_setup/configurations/Metapolis_KP.trig` in **System Settings → Knowledge Patterns**.

The map is at `http://<your-researchspace-host>/resource/?uri=https%3A%2F%2Fmetapolis.com%2Fresource%2Fmap`.

Run `./setup.sh --help` for all options. The manual installation, checks and troubleshooting are in [Installation and Setup](https://github.com/villaitatti/metapolis/wiki/Installation-and-Setup).

## Documentation

Everything else is in the **[wiki](https://github.com/villaitatti/metapolis/wiki)**:

| Page | What it covers |
|---|---|
| [Installation and Setup](https://github.com/villaitatti/metapolis/wiki/Installation-and-Setup) | `setup.sh`, manual installation, adding geometries from QGIS, production, troubleshooting |
| [PostGIS and SQL Sail](https://github.com/villaitatti/metapolis/wiki/PostGIS-and-SQL-Sail) | The default backend and the predefined SQL queries |
| [QLever and SPARQL Backends](https://github.com/villaitatti/metapolis/wiki/QLever-and-SPARQL-Backends) | Using QLever or any SPARQL endpoint instead of PostGIS |
| [Data Model and Forms](https://github.com/villaitatti/metapolis/wiki/Data-Model-and-Forms) | Ontology, Knowledge Patterns and the entity forms |
| [Relations](https://github.com/villaitatti/metapolis/wiki/Relations) | How entities are linked to each other |
| [Map Navigation](https://github.com/villaitatti/metapolis/wiki/Map-Navigation) | Using and customizing the Metapolis map |
| [Map Component Guide](https://github.com/villaitatti/metapolis/wiki/Map-Component-Guide) | Building your own map pages |
| [Map Component Reference](https://github.com/villaitatti/metapolis/wiki/Map-Component-Reference) | Developer reference for the map components |

The wiki source lives in [`docs/wiki/`](docs/wiki) and is published automatically on every push to `main` (`.github/workflows/publish-wiki.yml`). Edit the files there, not on the wiki: direct wiki edits are overwritten.

## Contributing

Contributions are welcome: fork the repository, create a feature branch, commit your changes and open a pull request. If something does not work, please [open an issue](https://github.com/villaitatti/metapolis/issues).

## Acknowledgements

Funded by the National Endowment for the Humanities (NEH) as part of the Digital Humanities Advancement Grants.

- **Project:** Metapolis: Spatializing Histories through Archival Sources ([HAA-287761-22](https://apps.neh.gov/publicquery/AwardDetail.aspx?gn=HAA-287761-22))
- **Project Director:** Lukas Klic
