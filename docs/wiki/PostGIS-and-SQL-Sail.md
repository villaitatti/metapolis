Metapolis displays geospatial data kept in a PostgreSQL database with PostGIS. The **SQL Sail** is the ResearchSpace component that connects the two worlds: it runs predefined SQL queries on the database and returns the results as RDF, so SQL data can be queried with SPARQL and combined with the semantic data of ResearchSpace.

**See also:** [Installation and Setup](Installation-and-Setup) · [QLever and SPARQL Backends](QLever-and-SPARQL-Backends) · [Map Navigation](Map-Navigation)

## Contents

- [Requirements](#requirements)
- [How it works](#how-it-works)
- [A generic example: Artworks](#a-generic-example-artworks)
  - [Service descriptor](#service-descriptor)
  - [Repository configuration file](#repository-configuration-file)
  - [Querying the system](#querying-the-system)
- [The Metapolis configuration](#the-metapolis-configuration)
  - [Repository: `config/repositories/metapolis.ttl`](#repository-configrepositoriesmetapolisttl)
  - [Service: `config/services/metapolis-ephedra.ttl`](#service-configservicesmetapolis-ephedrattl)
  - [Predefined queries](#predefined-queries)
  - [Querying through the Ephedra federation](#querying-through-the-ephedra-federation)
  - [Adding a query or a column](#adding-a-query-or-a-column)
- [Rules and pitfalls](#rules-and-pitfalls)
- [Troubleshooting](#troubleshooting)

---

## Requirements

- A running database (for Metapolis: PostgreSQL 15 + PostGIS 3.3, started from `metapolis_setup/metapolis-db`, see [Installation and Setup](Installation-and-Setup#step-2-start-the-postgis-database)).
- A **JDBC driver** for the database in the app's `lib` folder. For PostgreSQL it can be downloaded from the [PostgreSQL JDBC driver page](https://jdbc.postgresql.org/download/). Metapolis already ships it at `lib/postgresql-42.2.14.jar`, so no further installation is required.

A minimal application demonstrating the integration is available on GitHub: [RS_SQLSAIL_test](https://github.com/villaitatti/RS_SQLSAIL_test).

## How it works

An SQL Sail integration is made of two files:

1. a **service descriptor** (`config/services/*.ttl`): maps SQL columns and query parameters to RDF properties, and lists the predefined SQL queries, each with an ID;
2. a **repository configuration** (`config/repositories/*.ttl`): creates a ResearchSpace repository of sail type `researchspace:SQLSail`, with the JDBC connection details, and points to the service.

A SPARQL query sent to that repository selects an SQL query by its ID (`hasQueryId`), optionally binds input parameters, and reads the output columns through the mapped properties. Each SQL result row becomes a blank node (`?s` below) with one triple per mapped column. The SQL Sail is configured like the REST Sail: only the predefined queries can be executed, there is no automatic SPARQL-to-SQL translation.

---

## A generic example: Artworks

This example uses a table called `Artworks`:

```
id  title                                                                         technique   catalogue width
1   Nude Baptist lightly seated, leaning on left elbow, with right hand held up   black chalk 228       157
2   Mapping out of the lunette at Poggio a Cajano.                                black chalk 2151      79
3   Various "putti" for same work, or for the Lucca God the Father                Red chalk   361       126
```

Columns:

- **id**: the identifier, as a string;
- **title**: the artwork's title, as a string;
- **technique**: the technique used to draw it, as a string;
- **catalogue**: the number used within the catalogue;
- **width**: the artwork width, as an integer.

### Service descriptor

The service descriptor maps SQL table columns to RDF properties, defines the input parameters accepted by the queries, and specifies the predefined SQL queries that can be executed from SPARQL.

Two prefixes are worth noting:

- `rssqlsail:` – namespace for the properties of the SQL Sail configuration (`hasQueryId`, `includesSQLQuery`, `text`). You may use it, or your own namespace, for the column properties too.
- `ephedra:` – namespace of the Ephedra service vocabulary.

```turtle
PREFIX sp: <http://spinrdf.org/sp#>
PREFIX spin: <http://spinrdf.org/spin#>
PREFIX spl: <http://spinrdf.org/spl#>
PREFIX : <http://www.researchspace.org/resource/system/repository#>
PREFIX rssqlsail: <http://www.researchspace.org/resource/system/sql#>
PREFIX ephedra: <http://www.researchspace.org/resource/system/ephedra#>

:artworks a ephedra:Service ;
  <http://www.openrdf.org/config/sail#sailType> "researchspace:SQLSail" ;
  rdfs:label "A wrapper for the SQL Artworks service." ;
  ephedra:hasSPARQLPattern (
    [ sp:subject :_results; sp:predicate rssqlsail:hasQueryId; sp:object :_queryId ]
    [ sp:subject :_results; sp:predicate rssqlsail:hasTitle; sp:object :_title ]
    [ sp:subject :_results; sp:predicate rssqlsail:hasTechnique; sp:object :_technique ]
    [ sp:subject :_results; sp:predicate rssqlsail:hasInputTechnique; sp:object :_inputTechnique ]
    [ sp:subject :_results; sp:predicate rssqlsail:hasCatalogue; sp:object :_catalogue ]
    [ sp:subject :_results; sp:predicate rssqlsail:hasWidth; sp:object :_width ]
  ) ;

  spin:constraint [ a spl:Argument; spl:predicate :_queryId; spl:valueType xsd:string; rdfs:comment "query ID" ];
  spin:constraint [ a spl:Argument; spl:predicate :_inputTechnique; spl:valueType xsd:string; rdfs:comment "The technique parameter used as input" ];

  spin:column [ a spin:Column; spl:predicate :_results; spl:valueType rdfs:Resource; rdfs:comment "Row index: will be assigned a random blank node" ];
  spin:column [ a spin:Column; spl:predicate :_title; spl:valueType xsd:string; rdfs:comment "Output title" ];
  spin:column [ a spin:Column; spl:predicate :_technique; spl:valueType xsd:string; rdfs:comment "Output technique" ];
  spin:column [ a spin:Column; spl:predicate :_catalogue; spl:valueType xsd:integer; rdfs:comment "Output catalogue" ];
  spin:column [ a spin:Column; spl:predicate :_width; spl:valueType xsd:integer; rdfs:comment "Output width" ];

  rssqlsail:includesSQLQuery [ rssqlsail:hasQueryId "default"; rssqlsail:text "SELECT * FROM Artworks;" ];
  rssqlsail:includesSQLQuery [ rssqlsail:hasQueryId "getBySize"; rssqlsail:text "SELECT * FROM Artworks where technique = ?inputTechnique;" ] .
```

**The service.** `:artworks` is an `ephedra:Service`. The property `<http://www.openrdf.org/config/sail#sailType>` is mandatory and identifies the kind of service; for an SQL data source it is `researchspace:SQLSail`.

**`ephedra:hasSPARQLPattern`** defines the mapping between inputs, outputs and SPARQL properties. Each pattern represents one column of the table, or one input parameter, and its RDF representation:

- **`sp:subject`**: the subject shared by all values of a result row (`:_results`);
- **`sp:predicate`**: the property that represents the SQL column in SPARQL (e.g. `rssqlsail:hasTitle`; `hasTitle` is an arbitrary name);
- **`sp:object`**: the variable bound to the column or the parameter (e.g. `:_title`).

So the triple `?subject rssqlsail:hasTitle ?title` in a SPARQL query reads the `title` column, because `rssqlsail:hasTitle` points to `:_title`.

**`spin:constraint`** declares the input parameters that users can provide when querying:

- **`spl:predicate`**: the variable of the input;
- **`spl:valueType`**: the expected data type, one of `xsd:string`, `xsd:integer` (or `xsd:int`), `xsd:float`;
- **`rdfs:comment`**: a short description.

The example has two: `:_queryId`, which selects the SQL query by ID, and `:_inputTechnique`, the value the `getBySize` query filters on.

**`spin:column`** declares the output columns and their types, so the results are typed correctly in RDF. It takes the same `spl:predicate`, `spl:valueType` and `rdfs:comment` properties.

**`rssqlsail:includesSQLQuery`** lists the predefined SQL queries, each with a unique ID (`rssqlsail:hasQueryId`) and the SQL text (`rssqlsail:text`).

> **Note:** inside the SQL text, input parameters are written with a leading question mark and the name of their variable without `:_` (e.g. `:_inputTechnique` → `?inputTechnique`).

### Repository configuration file

The repository configuration defines the repository ID, the database connection and the service it implements:

```turtle
@prefix repo: <http://www.openrdf.org/config/repository#> .
@prefix reposail: <http://www.openrdf.org/config/repository/sail#> .
@prefix sail: <http://www.openrdf.org/config/sail#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix ephedra: <http://www.researchspace.org/resource/system/ephedra#> .
@prefix rsrepo: <http://www.researchspace.org/resource/system/repository#> .
@prefix : <http://www.researchspace.org/resource/system/repository#> .

[] a repo:Repository ;
  repo:repositoryID "artworks" ;
  rdfs:label "A wrapper for the SQL test repository." ;
  repo:repositoryImpl [
    repo:repositoryType "openrdf:SailRepository" ;
    reposail:sailImpl [
      sail:sailType "researchspace:SQLSail" ;
      ephedra:serviceURL "jdbc:postgresql://{database host}:{port}/{database name}" ;
      rsrepo:username "{username here}" ;
      rsrepo:password "{password here}" ;
      ephedra:implementsService :artworks ;
    ] ;
  ] .
```

`ephedra:serviceURL` is a JDBC URL: `jdbc:{dbms}://{host}:{port}/{database_name}`. The DBMS can be `postgresql`, `mysql` or any other one with a JDBC driver in `lib/`. For a local PostgreSQL holding the artworks, for example: `jdbc:postgresql://localhost:5432/artworks_data`.

`rsrepo:username` and `rsrepo:password` are written in plain text in the file, or provided through the ResearchSpace secret resolver (see the Repository Manager documentation).

`ephedra:implementsService` must point to the service IRI defined in the descriptor (`:artworks`).

### Querying the system

With the repository and the descriptor loaded (restart ResearchSpace after adding them), select the `artworks` repository on `/sparql`. To retrieve all rows, use the `default` query ID:

```sparql
PREFIX rssqlsail: <http://www.researchspace.org/resource/system/sql#>

SELECT ?title ?technique ?catalogue ?width WHERE {
  ?subject rssqlsail:hasQueryId "default" .
  ?subject rssqlsail:hasTitle ?title .
  ?subject rssqlsail:hasTechnique ?technique .
  ?subject rssqlsail:hasCatalogue ?catalogue .
  ?subject rssqlsail:hasWidth ?width .
}
```

For a query with parameters, bind the input property to a value. For example, `getBySize` filters by technique:

```sparql
PREFIX rssqlsail: <http://www.researchspace.org/resource/system/sql#>

SELECT ?title ?technique ?catalogue ?width WHERE {
  ?subject rssqlsail:hasQueryId "getBySize" .
  ?subject rssqlsail:hasTitle ?title .
  ?subject rssqlsail:hasTechnique ?technique .
  ?subject rssqlsail:hasCatalogue ?catalogue .
  ?subject rssqlsail:hasWidth ?width .
  ?subject rssqlsail:hasInputTechnique "black chalk"
}
```

---

## The Metapolis configuration

Metapolis applies exactly this pattern to the `metapolis.buildings` table of PostGIS.

### Repository: `config/repositories/metapolis.ttl`

```turtle
[] a repo:Repository ;
  repo:repositoryID "metapolis" ;
  rdfs:label "A wrapper for the SQL test repository." ;
  repo:repositoryImpl [
    repo:repositoryType "openrdf:SailRepository" ;
    reposail:sailImpl [
      sail:sailType "researchspace:SQLSail" ;
      ephedra:serviceURL "jdbc:postgresql://localhost:5432/metapolis" ;
      rsrepo:username "postgres" ;
      rsrepo:password "metapolis_password" ;
      ephedra:implementsService :metapolis ;
    ] ;
  ] .
```

The values match the defaults of `metapolis_setup/metapolis-db/.env.template`. `setup.sh` rewrites this file with your actual host, port, database and credentials (and with a SPARQL repository if you choose the QLever or SPARQL backend, see [QLever and SPARQL Backends](QLever-and-SPARQL-Backends)).

### Service: `config/services/metapolis-ephedra.ttl`

The service `:metapolis` uses these prefixes:

```turtle
PREFIX rs_sql_sail:   <http://www.researchspace.org/resource/system/sql#>
PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>
```

| Property | Variable | Role | Type |
|---|---|---|---|
| `rs_sql_sail:hasQueryId` | `:_queryId` | Input: query ID | `xsd:string` |
| `metapolis_sql:building_id` | `:_building_id` | Output (and input of `building_by_id`) | `xsd:integer` |
| `metapolis_sql:name` | `:_name` | Output, and input of `buildings_by_name_pattern` | `xsd:string` |
| `metapolis_sql:function` | `:_function` | Output, and input of `buildings_by_function` | `xsd:string` |
| `metapolis_sql:wkt` | `:_wkt` | Output: geometry as WKT (`ST_AsText(geom)`) | `xsd:string` |
| `metapolis_sql:minX` / `minY` / `maxX` / `maxY` | `:_MinX` / `:_MinY` / `:_MaxX` / `:_MaxY` | Inputs of `buildings_in_bbox` (longitude/latitude) | `xsd:float` |

The basic query is:

```turtle
rs_sql_sail:includesSQLQuery [
  rs_sql_sail:hasQueryId "all_buildings" ;
  rs_sql_sail:text "SELECT id as building_id, name, function, ST_AsText(geom) as wkt FROM metapolis.buildings ORDER BY name"
] ;
```

and a query with parameters:

```turtle
rs_sql_sail:includesSQLQuery [
  rs_sql_sail:hasQueryId "buildings_in_bbox" ;
  rs_sql_sail:text "SELECT id as building_id, name, function, ST_AsText(geom) as wkt FROM metapolis.buildings WHERE ST_Intersects(geom, ST_MakeEnvelope(?MinX, ?MinY, ?MaxX, ?MaxY, 4326)) ORDER BY name"
] ;
```

Note how the SQL aliases (`id as building_id`, `ST_AsText(geom) as wkt`) produce column names that match the mapped variables.

### Predefined queries

Every query returns `building_id`, `name`, `function` and `wkt` unless noted.

| Query ID | Description | Input |
|---|---|---|
| `all_buildings` | All buildings (used by the forms and the map) | – |
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

Example on the **metapolis** repository, all religious buildings:

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

Buildings in a bounding box:

```sparql
PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

SELECT * WHERE {
  ?s rs_sql_sail:hasQueryId "buildings_in_bbox" ;
     metapolis_sql:minX "11.250"^^xsd:float ; metapolis_sql:minY "43.765"^^xsd:float ;
     metapolis_sql:maxX "11.260"^^xsd:float ; metapolis_sql:maxY "43.775"^^xsd:float ;
     metapolis_sql:building_id ?building_id ;
     metapolis_sql:name ?name ;
     metapolis_sql:function ?function ;
     metapolis_sql:wkt ?wkt .
}
```

### Querying through the Ephedra federation

The forms query the same data from the **ephedra** repository, wrapping the pattern in a `SERVICE` clause. This requires `metapolis` to be a member of the federation ([Installation, Step 4](Installation-and-Setup#step-4-add-metapolis-to-the-ephedra-federation)):

```sparql
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

The **2D Representation** autocomplete of the Building form is such a query: it turns each row into the feature IRI `http://metapolis.com/resource/feature/<building_id>` (see [Data Model and Forms](Data-Model-and-Forms#linking-a-building-to-its-geometry)).

### Adding a query or a column

- **New query:** add a `rs_sql_sail:includesSQLQuery` block with a new ID to `metapolis-ephedra.ttl`, alias the SQL columns to the mapped names, and restart ResearchSpace.
- **New input parameter:** add a pattern to `ephedra:hasSPARQLPattern` and a `spin:constraint`, then use `?<name>` in the SQL.
- **New output column** (e.g. `start_year`, area, distance): add a pattern to `ephedra:hasSPARQLPattern` **and** a `spin:column` with its type. Without both, the column cannot be read from SPARQL.

---

## Rules and pitfalls

- **SPARQL variable names must match the SQL column names** (`?building_id`, `?name`, `?function`, `?wkt`). Other names make the query fail with an HTTP 500 error.
- Only the **mapped columns** can be read. `buildings_with_centroids`, `buildings_with_area` and the distance queries compute extra SQL columns that are **not** exposed until you map them.
- Only the predefined queries can be executed; there is no free SQL from SPARQL.
- The credentials in `metapolis.ttl` and in the database `.env` must match.
- If ResearchSpace runs in Docker, `localhost` in the JDBC URL is the ResearchSpace container; use `host.docker.internal` or the database's service name.
- The sail type in the service descriptor is currently `"researchspace:SQL"`, while the repository uses `"researchspace:SQLSail"`. The shipped configuration works with this combination; keep `researchspace:SQLSail` in the repository file, and use `researchspace:SQLSail` in new service descriptors as in the example above.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Queries on the `metapolis` repository fail or time out | The database is not running, or the JDBC URL, user or password in `config/repositories/metapolis.ttl` is wrong |
| `Connection refused` with ResearchSpace in Docker | `localhost` in the JDBC URL points to the ResearchSpace container: use `host.docker.internal` or the database service name |
| A query returns no rows | The `rs_sql_sail:hasQueryId` value does not match a predefined query, or the query reads a column that is not mapped |
| A variable is always empty | The column is not mapped in the service descriptor (see [Adding a query or a column](#adding-a-query-or-a-column)) |
| `SERVICE <…federation#metapolis>` fails on `ephedra` | Metapolis is not in the Ephedra federation ([Step 4](Installation-and-Setup#step-4-add-metapolis-to-the-ephedra-federation)) |
| `ClassNotFoundException: org.postgresql.Driver` | `lib/postgresql-42.2.14.jar` is missing from the app, or ResearchSpace was not restarted after adding the app |
