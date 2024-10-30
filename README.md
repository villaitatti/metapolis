# Metapolis

The official repository of Metapolis. This repository contains two primary components: the **SQL Sail integration** and the **Advanced Semantic Map**. These components enable Metapolis to manage and visualize complex geospatial data by integrating a PostgreSQL database with PostGIS for geospatial queries and analysis.

## SQL Sail integration

Metapolis displays geospatial data by integrating with a PostgreSQL database configured with PostGIS. The SQL Sail integration provides an interface to perform SQL queries on this database and convert the results to RDF format, enabling SPARQL queries over traditional SQL data.

The setup for SQL Sail integration requires the database to be created and a JDBC driver to be installed. For PostgreSQL, this driver can be downloaded from the [PostgreSQL JDBC driver page](https://jdbc.postgresql.org/download/). Once downloaded, the driver should be placed in the application’s `lib` folder. Metapolis includes this driver at `lib/postgresql-42.2.14.jar`, so no further installation is required.

A sample application demonstrating this integration can be found on GitHub: [test repository](https://github.com/villaitatti/RS_SQLSAIL_test).

### Example

The following example uses a sample table called Artworks, representing artwork data in the SQL database:

```
id  title                                                                         technique   catalogue width
1   Nude Baptist lightly seated, leaning on left elbow, with right hand held up   black chalk 228       157
2   Mapping out of the lunette at Poggio a Cajano.                                black chalk 2151      79
3   Various "putti" for same work, or for the Lucca God the Father                Red chalk   361       126
```

The table `Artworks` has the following columns:
* **id**: the identifier in string format, 
* **title**: the artwork's title in string format, 
* **technique**: the technique used to draw the painting in string format, 
* **catalogue**: is the number used within the catalogue, 
* **width**: is the artwork width and it is an integer.

### Configuration
To implement SQL Sail, create a dedicated repository similar to the RESTSail configuration. SQL Sail allows direct querying and retrieval of SQL database data within the RDF model, making SQL data accessible via SPARQL.

### Service Descriptor
This service descriptor maps SQL table columns to RDF properties, defines constraints for query inputs, and specifies predefined SQL queries that can be executed by the SPARQL endpoint.

Within the prefixes there are a few to note.

*	rssqlsail: – Namespace for properties associated with SQL Sail configurations.
* ephedra: – Namespace specific to this service configuration.

```
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
  spin:column [ a spin:Column; spl:predicate :_technique; spl:valueType xsd:string; rdfs:comment "Output technique"];
  spin:column [ a spin:Column; spl:predicate :_catalogue; spl:valueType xsd:integer; rdfs:comment "Output catalogue"] ;
  spin:column [ a spin:Column; rdfs:comment "Output width"; spl:predicate :_width; spl:valueType xsd:integer];

  rssqlsail:includesSQLQuery [ rssqlsail:hasQueryId "default"; rssqlsail:text "SELECT * FROM Artworks;" ];
  rssqlsail:includesSQLQuery [ rssqlsail:hasQueryId "getBySize"; rssqlsail:text "SELECT * FROM Artworks where technique = ?inputTechnique;" ] .
```

The service is defined with the URI :artworks, marked as a type of ephedra:Service, which designates it as an SQL Sail service.
The property `<http://www.openrdf.org/config/sail#sailType>` specifies the service type, and it is mandatory. It must be **researchspace:SQLSail** indicating that it’s an SQL-based data source.

```
:artworks a ephedra:Service ;
  <http://www.openrdf.org/config/sail#sailType> "researchspace:SQLSail" ;
  rdfs:label "A wrapper for the SQL Artworks service." ;
```

`ephedra:hasSPARQLPattern` defines mappings between the inputs, outputs, and SPARQL properties, making these parameters accessible thorugh SPARQL queries. Each pattern here represents a single column in the Artworks table, or an input parameter, and its RDF representation.

* **sp:subject:** The general subject for result entries.
* **sp:predicate:** Defines the predicate (property) representing the SQL column.
* **sp:object:** The object mapped to a variable or constant within SPARQL.

`spin:constraint` defines the constraints for query parameters, specifying the input values that users must provide when querying the database.


* **spl:predicate:** The predicate name for the input.
* **spl:valueType:** The expected data type (to be chosen between `xsd:string`, `xsd:integer` or `xsd:int`, `xsd:float`).
* **rdfs:comment:** A brief description.

The two constraint in the example are `:_queryID` (which allows users to select the SQL queries by ID), and `:_inputTechnique` (that is a parameter on which the query filters artworks). 

`spin:column` maps each SQL column to RDF output variables for SPARQL queries. These definitions set the output types for each column, allowing the SPARQL system to understand how each SQL result column should be interpreted.

* **spl:predicate:** The RDF property corresponding to each SQL column.
* **spl:valueType:** The expected data type (to be chosen between `xsd:string`, `xsd:integer` or `xsd:int`, `xsd:float`).
* **rdfs:comment:** A description of the column.

`rssqlsail:includesSQLQuery` specifies the predefined SQL queries available within this service. Each query is defined by a unique ID and the SQL text itself.

**NOTE**: the query body may contain parameters (e.g., inputTechnique) that must prepend a question mark.

The previous code shows how the RDF triple must be formed. The predicate must be `rssqlsail:hasTitle`, where the prefix is defined in the same file, and hasTitle is an arbitrary predicate name. It means the SPARQL subject is related to an element with `_title` as `spl:predicate`.

### Repository Configuration File
The repository configuration file defines the repository ID, database connection details, and service endpoints. Below is an example:
```
Repository configuration file
@prefix repo: <http://www.openrdf.org/config/repository#> .
@prefix reposail: <http://www.openrdf.org/config/repository/sail#> .
@prefix sail: <http://www.openrdf.org/config/sail#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix ephedra: <http://www.researchspace.org/resource/system/ephedra#> .
@prefix rsrepo: <http://www.researchspace.org/resource/system/repository#> .
@prefix rssqlsail: <http://www.researchspace.org/resource/system/sql#> .
@prefix : <http://www.researchspace.org/resource/system/repository#> .

[] a repo:Repository ;
  repo:repositoryID "artworks" ;
  rdfs:label "A wrapper for the SQL test repository." ;
  repo:repositoryImpl [
	repo:repositoryType "openrdf:SailRepository" ;
	reposail:sailImpl [
  	sail:sailType "researchspace:SQLSail" ;
  	ephedra:serviceURL "jdbc:postgresql://{database url}/{database name}" ;
  	rsrepo:username "{username here}" ;
  	rsrepo:password "{password here}" ;
  	ephedra:implementsService :artworks ;
	] ;
  ] .
```

The `ephedra:serviceURL` is generally composed as follows:
`jdbc:{dbms service}://{url}:{port}/{database_name}`. The DBMS service can be postgresql, mysql, or other services name. For this use case, the URL service is the following: **jdbc:postgresql://localhost:3306/artworks_data**.

The `rsrepo:username` and `rsrepo:password` must be passed in plain text in the configuration file; otherwise, they can be passed through the secret resolver (see Repository Manager).

### Querying the system

With the repository and descriptor loaded, you can query SQL data using SPARQL. For instance, to retrieve all rows in the `Artworks` table, use the default query ID:

```
PREFIX rssqlsail: <http://www.researchspace.org/resource/system/sql#>

SELECT ?title ?technique ?catalogue ?width WHERE {
  ?subject rssqlsail:hasQueryId "default".
  ?subject rssqlsail:hasTitle ?title.
  ?subject rssqlsail:hasTechnique ?technique.
  ?subject rssqlsail:hasCatalogue ?catalogue.
  ?subject rssqlsail:hasWidth ?width.
}
```

For more complex queries requiring parameters, like filtering by technique, use the `getBySize` query:

```
PREFIX rssqlsail: <http://www.researchspace.org/resource/system/sql#>

SELECT ?title ?technique ?catalogue ?width WHERE {
  ?subject rssqlsail:hasQueryId "getBySize".
  ?subject rssqlsail:hasTitle ?title.
  ?subject rssqlsail:hasTechnique ?technique.
  ?subject rssqlsail:hasCatalogue ?catalogue.
  ?subject rssqlsail:hasWidth ?width.
  ?subject rssqlsail:hasInputTechnique "black chalk"
}
```

These examples demonstrate how SPARQL queries can access SQL data seamlessly using predefined descriptors, enabling integration between relational databases and semantic queries.