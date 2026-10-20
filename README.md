# Metapolis

**Metapolis** is an interactive, map-based research and publication platform for the humanities, built as an app for [ResearchSpace](https://github.com/researchspace/researchspace).

It lets scholars geospatially reconstruct places through time: archival, bibliographic and multimedia sources are linked to interpretive research and visualized on a map. Because it runs on ResearchSpace (an open-source Semantic Web environment), all data is Linked Open Data and can be enriched with external knowledge bases such as VIAF, Wikidata, OCLC and the Getty vocabularies.

With Metapolis you can:

- create and manage **Buildings**, **Events**, **People** and **Sources**
- link each Building to a geometry stored in **PostgreSQL/PostGIS**
- connect entities to each other and to archival sources
- visualize the results on an interactive map
- publish everything as Linked Open Data

Further technical documentation is in [the wiki](https://github.com/villaitatti/metapolis/wiki).

---

## Contents

- [How the pieces fit together](#how-the-pieces-fit-together)
- [What is in this repository](#what-is-in-this-repository)
- [Prerequisites](#prerequisites)
- [Quick start with `setup.sh`](#quick-start-with-setupsh)
- [Installation (manual)](#installation-manual)
  - [Step 1: Install ResearchSpace and add the Metapolis app](#step-1-install-researchspace-and-add-the-metapolis-app)
  - [Step 2: Start the PostGIS database](#step-2-start-the-postgis-database)
  - [Step 3: Point the app at the database](#step-3-point-the-app-at-the-database)
  - [Step 4: Add Metapolis to the Ephedra federation](#step-4-add-metapolis-to-the-ephedra-federation)
  - [Step 5: Import the Metapolis configuration](#step-5-import-the-metapolis-configuration)
  - [Step 6: Check that everything works](#step-6-check-that-everything-works)
- [Alternative backends](#alternative-backends)
  - [QLever](#qlever)
  - [Custom SPARQL endpoints](#custom-sparql-endpoints)
- [Using Metapolis](#using-metapolis)
  - [Create a Building and link it to a PostGIS feature](#create-a-building-and-link-it-to-a-postgis-feature)
  - [Add new geometries from QGIS](#add-new-geometries-from-qgis)
  - [Good practices](#good-practices)
- [Reference: predefined SQL queries](#reference-predefined-sql-queries)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Acknowledgements](#acknowledgements)

---

## How the pieces fit together

Metapolis is split across **two repositories**:

| Repository | What it contains | Where it goes |
|---|---|---|
| [`metapolis`](https://github.com/villaitatti/metapolis) (this repo) | The ResearchSpace **app**: page templates, forms, map views, the SQL repository and service definitions, the PostgreSQL JDBC driver | Installed as an app inside your ResearchSpace instance |
| [`metapolis_setup`](https://github.com/villaitatti/metapolis_setup) | The **PostGIS database** (Docker) with sample data, and the **`.trig` files** (ontology, entities, Knowledge Patterns) that you import through the ResearchSpace UI | Run/imported once, alongside ResearchSpace |

At runtime the flow is:

```
Metapolis forms & map (ResearchSpace)
        │  SPARQL
        ▼
Ephedra federation ──SERVICE <…federation#metapolis>──▶ "metapolis" repository (SQL Sail)
                                                              │  SQL
                                                              ▼
                                                    PostgreSQL + PostGIS
                                                    (metapolis.buildings)
```

The app never stores geometries in the triple store: it queries them live from PostGIS through predefined SQL queries, and links them to semantic entities by ID.

PostGIS is the default backend. The `metapolis` repository can also point to a SPARQL endpoint instead, such as the bundled [QLever](#qlever) setup or [your own endpoint](#custom-sparql-endpoints). The forms and the map work the same way with any backend.

## What is in this repository

```
metapolis/
├── setup.sh                           # First-run setup script (see Quick start)
├── plugin.properties                  # App id / version for ResearchSpace
├── config/
│   ├── namespaces.prop                # metapolis_forms, metapolis_ontology prefixes
│   ├── repositories/metapolis.ttl     # Backend connection (PostGIS by default; rewritten by setup.sh)
│   ├── services/metapolis-ephedra.ttl # SPARQL ↔ SQL mapping and predefined queries
│   └── page-layout/html-head.hbs      # Extra <head> content
├── data/templates/                    # Start page, map pages, Building/Event/Person/Source forms
├── assets/images/                     # Static images
└── lib/postgresql-42.2.14.jar         # PostgreSQL JDBC driver
```

## Prerequisites

- **ResearchSpace 4.0 or later**, installed and running
- **Docker** and **Docker Compose** ([installation guide](https://docs.docker.com/engine/install/))
- **Git**, **Bash** and **curl** (for `setup.sh`)
- Some familiarity with the command line; basic SPARQL knowledge helps for testing

---

## Quick start with `setup.sh`

`setup.sh` does most of the installation for you. It:

1. clones (or updates) `metapolis_setup` next to this repository,
2. creates the `.env` file and starts the backend in Docker (PostGIS by default),
3. waits until the sample data is loaded,
4. writes `config/repositories/metapolis.ttl` so the app can reach the backend,
5. optionally, with `--rs-url`, adds `metapolis` to the Ephedra federation and imports the ontology and entity configurations into a running ResearchSpace.

It does not install or start ResearchSpace itself.

### Recommended flow

```bash
# 1. Get the app
git clone https://github.com/villaitatti/metapolis.git
cd metapolis

# 2. Start PostGIS and configure the app
./setup.sh
#    If ResearchSpace runs in Docker, use:
#    ./setup.sh --data-host host.docker.internal

# 3. Add this folder to ResearchSpace as an app and restart ResearchSpace
#    (see Step 1 below)

# 4. Configure ResearchSpace: federation + ontology + entity configurations
./setup.sh --rs-url http://localhost:10214
#    add --rs-user / --rs-password if you changed the admin login
```

5. Import `../metapolis_setup/configurations/Metapolis_KP.trig` in **System Settings → Knowledge Patterns**. This is the only step the script cannot do for you.
6. Go through the checklist in [Step 6](#step-6-check-that-everything-works).

The script is safe to run again. It keeps an existing `.env`, skips the federation if `metapolis` is already a member, and skips the imports if the ontology is already loaded (use `--reimport` to force them). At the end it prints the steps that are still left.

### Options

| Option | Description |
|---|---|
| `--backend postgis` | PostgreSQL + PostGIS in Docker (default) |
| `--backend qlever` | [QLever](#qlever) SPARQL endpoint in Docker, loaded with GeoSPARQL data |
| `--backend sparql --endpoint URL` | An [existing SPARQL endpoint](#custom-sparql-endpoints) |
| `--setup-dir DIR` | Where to clone `metapolis_setup` (default: `../metapolis_setup`) |
| `--data-host HOST` | Host name ResearchSpace uses to reach the backend (default `localhost`; use `host.docker.internal` if ResearchSpace runs in Docker) |
| `--password PW` | PostgreSQL password for a new `.env` (PostGIS only) |
| `--no-start` | Only prepare the files, do not start any container |
| `--rs-url URL` | Running ResearchSpace with the app loaded, e.g. `http://localhost:10214` |
| `--rs-user`, `--rs-password` | ResearchSpace admin login (default `admin` / `admin`) |
| `--reimport` | Import the `.trig` files even if they are already loaded |

Run `./setup.sh --help` for the full list.

> ⚠️ `setup.sh` overwrites `config/repositories/metapolis.ttl`. That file is tracked by git, so do not commit it if it contains your local credentials or endpoint.

If you prefer to do everything by hand, or something goes wrong, follow the manual steps below. They describe exactly what the script does.

---

## Installation (manual)

Follow the steps in order. Each step ends with a quick check so you know it worked before moving on.

### Step 1: Install ResearchSpace and add the Metapolis app

1. Install ResearchSpace 4.0+ following the [official instructions](https://github.com/researchspace/researchspace) and start it. By default it is available at `http://localhost:10214`.

2. Clone both Metapolis repositories:

   ```bash
   git clone https://github.com/villaitatti/metapolis.git
   git clone https://github.com/villaitatti/metapolis_setup.git
   ```

3. Add the `metapolis` folder to ResearchSpace as an app, following the [ResearchSpace documentation on apps](https://github.com/researchspace/researchspace).

**Check:** open **System Settings** (gear icon, top right) → **Apps & Storages**. `metapolis` should be listed.

### Step 2: Start the PostGIS database

From the `metapolis_setup` repository:

```bash
cd metapolis_setup/metapolis-db
cp .env.template .env          # then edit .env if you want different credentials
docker compose up -d           # or: docker-compose up -d
```

This starts a `postgis/postgis:15-3.3` container named `metapolis-postgres` on port `5432`. On the **first** start it automatically creates the `metapolis` schema, the `metapolis.buildings` table and loads 8 sample buildings in Florence.

The defaults in `.env.template` are:

| Variable | Default |
|---|---|
| `POSTGRES_DB` | `metapolis` |
| `POSTGRES_USER` | `postgres` |
| `POSTGRES_PASSWORD` | `metapolis_password` |
| `POSTGRES_HOST_AUTH_METHOD` | `trust` (development only) |
| `POSTGRES_PORT` | `5432` |

**Check:**

```bash
docker exec -it metapolis-postgres psql -U postgres -d metapolis \
  -c "SELECT name, function FROM metapolis.buildings;"
```

You should see 8 rows (Palazzo Vecchio, Duomo di Firenze, …).

For all the details (environment variables, init scripts, backups, resetting the database) see the [`metapolis_setup` README](https://github.com/villaitatti/metapolis_setup#readme).

### Step 3: Point the app at the database

The app connects to PostgreSQL through `config/repositories/metapolis.ttl` in **this** repository:

```turtle
ephedra:serviceURL "jdbc:postgresql://localhost:5432/metapolis" ;
rsrepo:username "postgres" ;
rsrepo:password "metapolis_password" ;
```

- If you kept the defaults from `.env.template`, **nothing to do**.
- If you changed `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` or `POSTGRES_PORT` in `.env`, update these three lines so they match.
- If ResearchSpace itself runs in Docker, `localhost` refers to the ResearchSpace container. Use a hostname that reaches the database instead (for example `host.docker.internal`, or the service name if both run on the same Docker network).

> ⚠️ The credentials in `metapolis.ttl` and in `metapolis_setup/metapolis-db/.env` must always match. If you change one, change the other. `setup.sh` keeps them in sync for you.

Restart ResearchSpace so it loads the repository.

**Check:** open the SPARQL page (`/sparql`), select the **metapolis** repository and run:

```sparql
PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>

SELECT * WHERE {
  ?s rs_sql_sail:hasQueryId "all_buildings" ;
     metapolis_sql:building_id ?building_id ;
     metapolis_sql:name ?name ;
     metapolis_sql:function ?function ;
     metapolis_sql:wkt ?wkt .
}
```

You should get the 8 sample buildings with their geometries in WKT.

### Step 4: Add Metapolis to the Ephedra federation

The Metapolis forms and map do **not** query the `metapolis` repository directly. They go through ResearchSpace's federated repository (`ephedra`) using `SERVICE <…/federation#metapolis>`. This step is therefore **required**.

1. Go to **System Settings** → **System Configurations** → **Repositories** and open the `ephedra` repository configuration.
2. Find the `fedsail:member` list and add this entry **after the last member** (note the leading comma):

   ```turtle
   , [
       ephedra:delegateRepositoryID "metapolis" ;
       ephedra:serviceReference <http://www.researchspace.org/resource/system/repository/federation#metapolis>
     ]
   ```

3. Save and restart ResearchSpace if asked.

`setup.sh --rs-url …` does this for you through the ResearchSpace REST API.

**Check:** in `/sparql`, select the **ephedra** repository and run:

```sparql
PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>

SELECT * WHERE {
  SERVICE <http://www.researchspace.org/resource/system/repository/federation#metapolis> {
    ?s rs_sql_sail:hasQueryId "all_buildings" ;
       metapolis_sql:building_id ?building_id ;
       metapolis_sql:name ?name ;
       metapolis_sql:function ?function ;
       metapolis_sql:wkt ?wkt .
  }
}
```

You should get the same 8 rows as in Step 3.

### Step 5: Import the Metapolis configuration

The data model (ontology), the entity configurations and the form fields live in `metapolis_setup/configurations/`. Import all three files:

| File | What it defines | Where to import it |
|---|---|---|
| `Metapolis_Ontology.trig` | The classes `Building`, `Event`, `Person`, `Source` (subclasses of `Metapolis_Entity`) | **Data Import & Download** |
| `Metapolis_Entity.trig` | Entity configurations: links each class to its form and adds it to the Finder | **Data Import & Download** |
| `Metapolis_KP.trig` | Knowledge Patterns: the fields used by the forms, including the PostGIS autocomplete | **Knowledge Patterns** |

1. **Ontology and entities** – go to **System Settings** → **Data Import & Download** (or `/resource/Admin:DataImportExport`). Upload `Metapolis_Ontology.trig`, then `Metapolis_Entity.trig`, each with **"Keep source named graphs"** checked.
2. **Knowledge Patterns** – go to **System Settings** → **Knowledge Patterns** and import `Metapolis_KP.trig`.
3. Restart ResearchSpace (or at least reload the page).

`setup.sh --rs-url …` imports the ontology and the entity configurations for you. The Knowledge Patterns must always be imported by hand.

**Check:** the Finder sidebar on the left now shows **Metapolis Building**, **Metapolis Event**, **Metapolis Person** and **Metapolis Source**, and clicking **New Metapolis Building** opens a form.

### Step 6: Check that everything works

You are done when all of these are true:

- [ ] `metapolis` appears under **Apps & Storages**
- [ ] the `metapolis-postgres` container is running and contains 8 buildings
- [ ] `all_buildings` returns results from both the **metapolis** and the **ephedra** repository
- [ ] the four Metapolis entities appear in the Finder
- [ ] in the Building form, typing in the **2D Representation** field suggests buildings from PostGIS

> 🔒 **Before going to production:** change the database password and set `POSTGRES_HOST_AUTH_METHOD` to `md5` or `scram-sha-256`, in `metapolis_setup/metapolis-db/.env` **and** in `config/repositories/metapolis.ttl`.

---

## Alternative backends

The app only needs one thing from its backend: the `all_buildings` result (`building_id`, `name`, `function`, `wkt`) returned by the `metapolis` repository. With PostGIS, the SQL Sail produces it from the `metapolis.buildings` table. With a SPARQL backend, the same shape is stored as plain triples, so the forms, the map and the Knowledge Patterns work unchanged.

### QLever

[QLever](https://github.com/ad-freiburg/qlever) is a fast SPARQL engine. `metapolis_setup/metapolis-qlever/` runs it in Docker with the 8 sample buildings as GeoSPARQL data.

```bash
./setup.sh --backend qlever                       # ResearchSpace on the host
./setup.sh --backend qlever --data-host host.docker.internal   # ResearchSpace in Docker
```

This starts the `metapolis-qlever` container on port `7001` and writes a SPARQL repository configuration:

```turtle
[] a repo:Repository ;
  repo:repositoryID "metapolis" ;
  repo:repositoryImpl [
    repo:repositoryType "researchspace:SPARQLRepository" ;
    sparqlr:query-endpoint <http://localhost:7001>
  ] .
```

Then continue with steps 3–6 of the [recommended flow](#recommended-flow). To change the data, edit or add `.ttl` files in `metapolis_setup/metapolis-qlever/data/` and restart the container; the index is rebuilt on every start. See the [`metapolis_setup` README](https://github.com/villaitatti/metapolis_setup#qlever-metapolis-qlever) for details.

Notes:

- The SQL-specific queries in the [reference below](#reference-predefined-sql-queries) (`buildings_by_function`, `buildings_in_bbox`, …) only exist with PostGIS. With a SPARQL backend you can query the GeoSPARQL data directly instead.
- QLever is read-only from ResearchSpace. Geometries are edited in the `.ttl` files, not in QGIS.

### Custom SPARQL endpoints

You can point Metapolis at any SPARQL endpoint that holds your geodata:

```bash
./setup.sh --backend sparql --endpoint https://example.org/sparql
```

The script checks that the endpoint answers and warns if it does not contain data in the shape Metapolis expects. For each feature, the endpoint must contain:

```turtle
@prefix geo:           <http://www.opengis.net/ont/geosparql#> .
@prefix rs_sql_sail:   <http://www.researchspace.org/resource/system/sql#> .
@prefix metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#> .

<http://metapolis.com/resource/feature/1>
    # Required: what the Metapolis forms and map query
    rs_sql_sail:hasQueryId    "all_buildings" ;
    metapolis_sql:building_id 1 ;
    metapolis_sql:name        "Palazzo Vecchio" ;
    metapolis_sql:function    "Government" ;
    metapolis_sql:wkt         "POLYGON((11.2558 43.7696, ...))" ;
    # Recommended: standard GeoSPARQL, for other tools
    a geo:Feature ;
    rdfs:label "Palazzo Vecchio" ;
    geo:hasGeometry <http://metapolis.com/resource/geometry/1> .

<http://metapolis.com/resource/geometry/1>
    a geo:Geometry ;
    geo:asWKT "POLYGON((11.2558 43.7696, ...))"^^geo:wktLiteral .
```

- Use the feature IRI `http://metapolis.com/resource/feature/<building_id>`. Buildings are linked to features through this IRI.
- `metapolis-qlever/data/buildings.ttl` in `metapolis_setup` is a complete example.
- If your data uses another model, you can add the `metapolis_sql:*` triples with a SPARQL `INSERT` or a `CONSTRUCT` query.

If the endpoint needs a login, edit `config/repositories/metapolis.ttl` after running the script and use the basic-auth repository type:

```turtle
@prefix mph: <http://www.researchspace.org/resource/system/repository#> .

[] a repo:Repository ;
  repo:repositoryID "metapolis" ;
  repo:repositoryImpl [
    repo:repositoryType "researchspace:SPARQLBasicAuthRepository" ;
    sparqlr:query-endpoint <https://example.org/sparql> ;
    mph:username "user" ;
    mph:password "secret"
  ] .
```

Restart ResearchSpace after any change to `metapolis.ttl`.

---

## Using Metapolis

### Create a Building and link it to a PostGIS feature

A **feature** is a row in the `metapolis.buildings` table (a name, a function and a polygon). A **Metapolis Building** is the semantic entity that scholars describe and link to events, people and sources. You connect the two by picking the feature from the Building form.

![Finder sidebar with Metapolis entities](https://github.com/user-attachments/assets/0d752286-d387-483d-8d6a-ed6f797fa0a3)

1. In the Finder sidebar, click **Metapolis Building**, then **New Metapolis Building**.
2. Fill in **Name** and **Function**.
3. In the physical phase section, set **Begin** / **End** dates if known, then start typing a feature name (e.g. `Uffizi`) in the **2D Representation** field. Suggestions come live from PostGIS through the federation. Pick one.
4. Optionally link related **Events**, **People** and **Sources**, and add notes.
5. Click **Create Metapolis Building**.

![Linking a Building to a PostGIS feature](https://github.com/user-attachments/assets/8177fc19-9eb1-48a2-a71a-5c5619188620)

The Building page opens. The linked feature is stored as `http://metapolis.com/resource/feature/<building_id>`, where `<building_id>` is the `id` of the row in `metapolis.buildings`

### Add new geometries from QGIS

Any GIS tool that can write to PostGIS works. With QGIS:

1. Add a PostGIS connection: host `localhost`, port `5432`, database `metapolis`, user/password from your `.env`.
2. Digitize or import footprints into the `metapolis.buildings` table. Required columns: `name`, `function`, `geom` (`POLYGON`, **EPSG:4326**). Optional: `start_year`, `end_year`.
3. The new features are immediately available in the **2D Representation** autocomplete. Create a Building for each one as described above.

### Good practices

- Use the **same name** for a feature in PostGIS and its Building in Metapolis, and make names unambiguous (e.g. add the city).
- Keep all geometries in **WGS84 (EPSG:4326)** and check they are valid (no self-intersections).
- Use a consistent list of **functions** (the sample data uses `Government`, `Religious`, `Cultural`, `Commercial`).
- Record provenance and uncertainty in the notes, and link Buildings to the Sources that support them.

---

## Reference: predefined SQL queries

`config/services/metapolis-ephedra.ttl` exposes these queries via `rs_sql_sail:hasQueryId`. Every query returns `building_id`, `name`, `function` and `wkt` unless noted.

| Query ID | Description | Input |
|---|---|---|
| `all_buildings` | All buildings | – |
| `building_by_id` | One building | `metapolis_sql:building_id` |
| `buildings_by_function` | Buildings with a given function | `metapolis_sql:function` |
| `buildings_by_name_pattern` | Case-insensitive name search | `metapolis_sql:name` |
| `buildings_in_bbox` | Buildings intersecting a bounding box | `metapolis_sql:minX`, `minY`, `maxX`, `maxY` |
| `florence_religious_buildings` / `_government_` / `_cultural_` / `_commercial_` | Buildings of that function | – |
| `florence_historic_center` | Buildings in the historic-centre bounding box | – |
| `north_arno_buildings` / `oltrarno_buildings` | Buildings north / south of the Arno | – |
| `buildings_near_duomo` | Within 500 m of the Duomo | – |
| `buildings_near_palazzo_vecchio` | Within 300 m of Palazzo Vecchio | – |
| `buildings_with_centroids` | Adds centroid coordinates in SQL | – |
| `buildings_with_area` | Ordered by area | – |
| `building_summary_by_function` | Count per function | – |

Inputs are passed by binding the corresponding property to a value. For example, all religious buildings:

```sparql
PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>

SELECT * WHERE {
  ?s rs_sql_sail:hasQueryId "buildings_by_function" ;
     metapolis_sql:function "Religious" ;
     metapolis_sql:building_id ?building_id ;
     metapolis_sql:name ?name ;
     metapolis_sql:wkt ?wkt .
}
```

> SPARQL variable names must match the SQL column names (`?building_id`, `?name`, `?function`, `?wkt`). Other names make the query fail with an HTTP 500 error.
>
> Only the columns mapped in the service (`building_id`, `name`, `function`, `wkt`) can be read from SPARQL. Extra SQL columns such as distance, area or centroid are not exposed unless you add them to `ephedra:hasSPARQLPattern` and `spin:column` in `metapolis-ephedra.ttl`.

To add your own query, add a new `rs_sql_sail:includesSQLQuery` block to `metapolis-ephedra.ttl` and restart ResearchSpace.

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| Metapolis entities don't appear in the Finder | `Metapolis_Ontology.trig` / `Metapolis_Entity.trig` not imported, or imported without **Keep source named graphs**. Re-import and reload. |
| Building form opens but fields are missing or broken | `Metapolis_KP.trig` not imported (Step 5.2). |
| `all_buildings` works on **metapolis** but not on **ephedra** | Federation member missing or misspelled (Step 4). |
| `all_buildings` fails on **metapolis** | Wrong credentials/host in `config/repositories/metapolis.ttl`, the database is not running (`docker ps`), or the SPARQL variable names do not match the column names. |
| Works from the host but not from ResearchSpace in Docker | `localhost` points to the ResearchSpace container. Re-run `setup.sh` with `--data-host host.docker.internal`. |
| `setup.sh --rs-url` says the app is not loaded | Add the app to ResearchSpace, restart it, then run the script again. |
| **2D Representation** never suggests anything | Federation not configured (Step 4), or the `buildings` table is empty. |
| Database is empty after `docker compose up` | The volume already existed, so init scripts were skipped. See [Resetting the database](https://github.com/villaitatti/metapolis_setup#resetting-the-database). |

If you are still stuck, please [open an issue](https://github.com/villaitatti/metapolis/issues) describing what you did and what you see.

## Contributing

Contributions are welcome:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a pull request

## Wiki
[Wiki](https://github.com/villaitatti/metapolis/wiki)
[How to navigate the map](https://github.com/villaitatti/metapolis/wiki/Navigating-the-Metapolis-map)

## Acknowledgements

Funded by the National Endowment for the Humanities (NEH) as part of the Digital Humanities Advancement Grants.

- **Project:** Metapolis: Spatializing Histories through Archival Sources ([HAA-287761-22](https://apps.neh.gov/publicquery/AwardDetail.aspx?gn=HAA-287761-22))
- **Project Director:** Lukas Klic
