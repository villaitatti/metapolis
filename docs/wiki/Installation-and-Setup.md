This page explains how to install Metapolis in a ResearchSpace instance, either with the `setup.sh` script or by hand, and how to check that every part works.

**See also:** [PostGIS and SQL Sail](PostGIS-and-SQL-Sail) · [QLever and SPARQL Backends](QLever-and-SPARQL-Backends) · [Map Navigation](Map-Navigation)

## Contents

- [Prerequisites](#prerequisites)
- [Quick start with `setup.sh`](#quick-start-with-setupsh)
  - [Recommended flow](#recommended-flow)
  - [Options](#options)
- [Manual installation](#manual-installation)
  - [Step 1: Install ResearchSpace and add the Metapolis app](#step-1-install-researchspace-and-add-the-metapolis-app)
  - [Step 2: Start the PostGIS database](#step-2-start-the-postgis-database)
  - [Step 3: Point the app at the database](#step-3-point-the-app-at-the-database)
  - [Step 4: Add Metapolis to the Ephedra federation](#step-4-add-metapolis-to-the-ephedra-federation)
  - [Step 5: Import the Metapolis configuration](#step-5-import-the-metapolis-configuration)
  - [Step 6: Check that everything works](#step-6-check-that-everything-works)
- [Using Metapolis](#using-metapolis)
  - [Create a Building and link it to a feature](#create-a-building-and-link-it-to-a-feature)
  - [Explore the map](#explore-the-map)
- [Adding geometries from QGIS](#adding-geometries-from-qgis)
- [Going to production](#going-to-production)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- **ResearchSpace 4.0 or later**, installed and running. It can run on a [server](https://github.com/researchspace/researchspace-docker-compose) or on your [local machine](https://github.com/researchspace/researchspace); by default it is available at `http://localhost:10214`. The map components are part of ResearchSpace core; this version of Metapolis is tested with the Docker image [`researchspace/platform-ci:metapolis-v1.0.0`](https://hub.docker.com/r/researchspace/platform-ci/tags?name=metapolis-v1.0.0), built from the [`build-docker/metapolis-v1.0.0`](https://github.com/researchspace/researchspace/tree/build-docker/metapolis-v1.0.0) branch.
- **Docker** and **Docker Compose** ([installation guide](https://docs.docker.com/engine/install/))
- **Git**, **Bash** and **curl** (for `setup.sh`)
- Optional: **QGIS** or another GIS tool, to prepare geometries
- Some familiarity with the command line; basic SPARQL knowledge helps for testing

---

## Quick start with `setup.sh`

`setup.sh`, at the root of the `metapolis` repository, does most of the installation for you. It:

1. clones (or updates) `metapolis_setup` next to the app repository (`../metapolis_setup`),
2. creates the backend `.env` file and starts the backend in Docker (PostGIS by default),
3. waits until the sample data is loaded,
4. writes `config/repositories/metapolis.ttl` so the app can reach the backend,
5. optionally, with `--rs-url`, adds `metapolis` to the Ephedra federation and imports the ontology and entity configurations into a running ResearchSpace, through its REST API.

It does **not** install or start ResearchSpace itself, and it cannot import the Knowledge Patterns.

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

| Option | Meaning |
|---|---|
| `--backend postgis` | PostgreSQL + PostGIS in Docker (default) |
| `--backend qlever` | QLever SPARQL endpoint in Docker, loaded with GeoSPARQL data (see [QLever and SPARQL Backends](QLever-and-SPARQL-Backends)) |
| `--backend sparql --endpoint URL` | An existing SPARQL endpoint (see [QLever and SPARQL Backends](QLever-and-SPARQL-Backends#custom-sparql-endpoints)) |
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

## Manual installation

Follow the steps in order. Each step ends with a quick check so you know it worked before moving on.

### Step 1: Install ResearchSpace and add the Metapolis app

1. Install ResearchSpace 4.0+ following the [official instructions](https://github.com/researchspace/researchspace) and start it. With [researchspace-docker-compose](https://github.com/researchspace/researchspace-docker-compose), use the tested image by setting in `.env`:

   ```bash
   RESEARCHSPACE_IMAGE=researchspace/platform-ci:metapolis-v1.0.0
   ```

   `setup.sh` warns if the running ResearchSpace container uses a different image.
2. Clone both Metapolis repositories:

   ```bash
   git clone https://github.com/villaitatti/metapolis.git
   git clone https://github.com/villaitatti/metapolis_setup.git
   ```

3. Add the `metapolis` folder to ResearchSpace as an app, following the [ResearchSpace documentation on apps](https://github.com/researchspace/researchspace). The app id is `metapolis` (from `plugin.properties`).

**Check:** open **System Settings** (gear icon, top right) → **Apps & Storages**. `metapolis` should be listed.

### Step 2: Start the PostGIS database

From the `metapolis_setup` repository:

```bash
cd metapolis_setup/metapolis-db
cp .env.template .env          # then edit .env if you want different credentials
docker compose up -d           # or: docker-compose up -d
```

This starts a `postgis/postgis:15-3.3` container named `metapolis-postgres` on port `5432`. On the **first** start it automatically enables PostGIS, creates the `metapolis` schema and the `metapolis.buildings` table, and loads 8 sample buildings in Florence.

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

The app connects to PostgreSQL through `config/repositories/metapolis.ttl` in the **app** repository. It defines a repository with id `metapolis` that uses the SQL Sail (see [PostGIS and SQL Sail](PostGIS-and-SQL-Sail)):

```turtle
repo:repositoryID "metapolis" ;
...
    sail:sailType "researchspace:SQLSail" ;
    ephedra:serviceURL "jdbc:postgresql://localhost:5432/metapolis" ;
    rsrepo:username "postgres" ;
    rsrepo:password "metapolis_password" ;
    ephedra:implementsService :metapolis ;
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

The Metapolis forms (and the `map_base` page) do **not** query the `metapolis` repository directly. They go through ResearchSpace's federated repository (`ephedra`) using `SERVICE <…/federation#metapolis>`. This step is therefore **required**.

1. Go to **System Settings** → **System Configurations** → **Repositories** and open the `ephedra` repository configuration.
2. Find the `fedsail:member` list and add this entry **after the last member** (note the leading comma):

   ```turtle
   , [
       ephedra:delegateRepositoryID "metapolis" ;
       ephedra:serviceReference <http://www.researchspace.org/resource/system/repository/federation#metapolis>
     ]
   ```

3. Save and restart ResearchSpace if asked.

`setup.sh --rs-url …` does this for you through the ResearchSpace REST API (`/rest/repositories/config/ephedra`).

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

You should get the same 8 rows as in Step 3. With the federation in place you can also combine the geodata with the semantic data of any other repository in the same query.

### Step 5: Import the Metapolis configuration

The data model (ontology), the entity configurations and the form fields live in `metapolis_setup/configurations/`. Import all three files:

| File | What it defines | Where to import it |
|---|---|---|
| `Metapolis_Ontology.trig` | The classes `Building`, `Event`, `Person`, `Source` (subclasses of `Metapolis_Entity`) | **Data Import & Download** |
| `Metapolis_Entity.trig` | Entity configurations: links each class to its form and adds it to the Finder | **Data Import & Download** |
| `Metapolis_KP.trig` | Knowledge Patterns: the fields used by the forms, including the PostGIS autocomplete | **Knowledge Patterns** |

1. **Ontology and entities** – go to **System Settings** → **Data Import & Download** (or `/resource/Admin:DataImportExport`). Upload `Metapolis_Ontology.trig` **first**, then `Metapolis_Entity.trig`, each with **"Keep source named graphs"** checked.
2. **Knowledge Patterns** – go to **System Settings** → **Knowledge Patterns** and import `Metapolis_KP.trig`.
3. Restart ResearchSpace (or at least reload the page).

`setup.sh --rs-url …` imports the ontology and the entity configurations for you (`/rdf-graph-store?keepSourceGraphs=true`). The Knowledge Patterns must always be imported by hand.

What each file contains is described in [Data Model and Forms](Data-Model-and-Forms).

**Check:** the Finder sidebar on the left now shows **Metapolis Building**, **Metapolis Event**, **Metapolis Person** and **Metapolis Source**, and clicking **New Metapolis Building** opens a form.

### Step 6: Check that everything works

You are done when all of these are true:

- [ ] `metapolis` appears under **Apps & Storages**
- [ ] the `metapolis-postgres` container is running and contains 8 buildings
- [ ] `all_buildings` returns results from both the **metapolis** and the **ephedra** repository
- [ ] the four Metapolis entities appear in the Finder
- [ ] in the Building form, typing in the **2D Representation** field suggests buildings from PostGIS
- [ ] the map page `/resource/?uri=https%3A%2F%2Fmetapolis.com%2Fresource%2Fmap` shows the buildings

---

## Using Metapolis

### Create a Building and link it to a feature

A **feature** is a row in the `metapolis.buildings` table (a name, a function and a polygon). A **Metapolis Building** is the semantic entity that scholars describe and link to events, people and sources. You connect the two by picking the feature from the Building form.

![Finder sidebar with Metapolis entities](https://github.com/user-attachments/assets/0d752286-d387-483d-8d6a-ed6f797fa0a3)

1. In the Finder sidebar, click **Metapolis Building**, then **New Metapolis Building**.
2. Fill in **Name** and **Function**.
3. In the physical phase section, set **Begin** / **End** dates if known, then start typing a feature name (e.g. `Uffizi`) in the **2D Representation** field. Suggestions come live from PostGIS through the federation. Pick one.
4. Optionally link related **Events**, **People** and **Sources**, and add notes (see [Relations](Relations)).
5. Click **Create Metapolis Building**.

![Linking a Building to a feature](https://github.com/user-attachments/assets/8177fc19-9eb1-48a2-a71a-5c5619188620)

The linked feature is stored as `http://metapolis.com/resource/feature/<building_id>`, where `<building_id>` is the `id` of the row in `metapolis.buildings`. The same works for Events, People and Sources from their own Finder entries.

### Explore the map

See [Map Navigation](Map-Navigation) for how to open and use the map.

---

## Adding geometries from QGIS

Any GIS tool that can write to PostGIS works. With QGIS:

1. Add a PostGIS connection (**Layer → Data Source Manager → PostgreSQL**, or **Database → DB Manager**): host `localhost`, port `5432`, database `metapolis`, user/password from your `.env`.
2. Digitize or import footprints into the `metapolis.buildings` table (in DB Manager: select the layer and use **Import Layer/File**, schema `metapolis`, table `buildings`, target SRID `4326`).
3. The new features are immediately available in the **2D Representation** autocomplete and on the map. Create a Building for each one as described above.

The `metapolis.buildings` table:

| Column | Type | Notes |
|---|---|---|
| `id` | `SERIAL` primary key | Becomes `building_id` and the feature IRI |
| `name` | text | **Required** |
| `function` | text | **Required**. The sample data uses `Government`, `Religious`, `Cultural`, `Commercial` |
| `geom` | `GEOMETRY(POLYGON, 4326)` | **Required**, WGS84. Indexed with GIST (`idx_buildings_geom`) |
| `start_year`, `end_year` | integer | Optional |
| `created_at`, `updated_at` | timestamp | Filled automatically |

Good practices:

- Use the **same name** for a feature in PostGIS and its Building in Metapolis, and make names unambiguous (e.g. add the city).
- Keep all geometries in **WGS84 (EPSG:4326)** and check they are valid (no self-intersections).
- Use a consistent list of **functions**: they drive the map colours and must match the keys of the map palette.
- Record provenance and uncertainty in the notes, and link Buildings to the Sources that support them.

With a QLever or SPARQL backend, geometries are edited in the RDF data instead; see [QLever and SPARQL Backends](QLever-and-SPARQL-Backends).

---

## Going to production

> 🔒 Change the database password and set `POSTGRES_HOST_AUTH_METHOD` to `md5` or `scram-sha-256`, in `metapolis_setup/metapolis-db/.env` **and** in `config/repositories/metapolis.ttl`.

- Do not expose port `5432` (or QLever's `7001`) publicly unless you need to.
- Never commit `.env`, nor a `metapolis.ttl` that contains real credentials.
- Check the terms of use of the map tile providers (the Google tile URL in the map template is not an official API endpoint).

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| Metapolis entities don't appear in the Finder | `Metapolis_Ontology.trig` / `Metapolis_Entity.trig` not imported, or imported without **Keep source named graphs**. Re-import and reload. |
| Building form opens but fields are missing or broken | `Metapolis_KP.trig` not imported (Step 5.2). |
| `all_buildings` works on **metapolis** but not on **ephedra** | Federation member missing or misspelled (Step 4). |
| `all_buildings` fails on **metapolis** | Wrong credentials/host in `config/repositories/metapolis.ttl`, the database is not running (`docker ps`), or the SPARQL variable names do not match the SQL column names (HTTP 500). |
| Works from the host but not from ResearchSpace in Docker | `localhost` points to the ResearchSpace container. Re-run `setup.sh` with `--data-host host.docker.internal`. |
| `setup.sh --rs-url` says the app is not loaded | Add the app to ResearchSpace, restart it, then run the script again. |
| **2D Representation** never suggests anything | Federation not configured (Step 4), or the `buildings` table is empty. |
| Database is empty after `docker compose up` | The volume already existed, so init scripts were skipped. See [Resetting the database](https://github.com/villaitatti/metapolis_setup#resetting-the-database). |
| Map loads slowly with many features | Make sure the GIST index on `geom` exists (`CREATE INDEX idx_buildings_geom ON metapolis.buildings USING GIST (geom);`) and restrict the query (e.g. `buildings_in_bbox`). |

Debugging tips:

- Validate every SPARQL query on `/sparql` (first on **metapolis**, then on **ephedra**) before using it in a template.
- Use the browser developer tools to inspect failing network requests and JavaScript errors.
- Check the ResearchSpace logs (`docker logs <container>`) for SQL or JDBC errors.

If you are still stuck, please [open an issue](https://github.com/villaitatti/metapolis/issues) describing what you did and what you see.
