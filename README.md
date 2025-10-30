# Metapolis

## Quickstart Guide

Get Metapolis up and running in just a few steps:

### Step 1: Import Resource Configurations

1. **Navigate to Data Import**: Go to `resource/Admin:DataImportExport` or click the settings button → "Data Import & Download"
2. **Download Configuration Files**: Get the files from the [`metapolis_setup/configurations`](https://github.com/villaitatti/metapolis_setup/tree/main/configurations) folder
3. **Import Files**: Upload both configuration files with "Keep source named graphs" checked:
   - `Metapolis_Ontology.trig` (ontology definitions)
   - `Metapolis_Entity.trig` (entity configurations)
4. **Verify Import**: Check the Finder sidebar for Metapolis entities (Event, Person, Building, Source)

### Step 2: Setup Database

Follow the comprehensive database setup guide at [metapolis_setup repository](https://github.com/villaitatti/metapolis_setup):

1. **Clone the setup repository**:
   ```bash
   git clone https://github.com/villaitatti/metapolis_setup.git
   cd metapolis_setup
   ```

2. **Follow the database setup instructions** in the repository's README.md:
   - Configure environment variables using the `.env.template`
   - Launch PostgreSQL with PostGIS using Docker Compose
   - Initialize the database with sample Florence buildings data

3. **Test the database connection** with the provided verification commands

### Step 3: Test Database Queries

1. **Access SPARQL Endpoint**: Navigate to `/sparql` and select the "metapolis" repository
2. **Run Test Query**:
   ```sparql
   PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
   PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>

   SELECT * WHERE {
     ?s rs_sql_sail:hasQueryId "all_buildings";
        metapolis_sql:building_id ?building_id;
        metapolis_sql:name ?name;
        metapolis_sql:function ?function;
        metapolis_sql:wkt ?wkt
   }
   ```

### Step 4: Explore Metapolis

- **Create Entities**: Use the Finder sidebar to create new Events, People, Buildings, and Sources
- **Visualize Data**: Access map visualization components
- **Link Sources**: Connect archival sources to geographical locations

## Contributing

Contributions to Metapolis are welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

Please ensure your code follows the project's coding standards and includes appropriate tests.

## Acknowledgements

Funded by the National Endowment for the Humanities (NEH) as part of the Digital Humanities Advancement Grants. 

**Project Title:** Metapolis: Spatializing Histories through Archival Sources [HAA-287761-22](https://apps.neh.gov/publicquery/AwardDetail.aspx?gn=HAA-287761-22)

**Project Director:** Lukas Klic

**Project Description:** The creation of geospatial enhancements to an existing digital infrastructure that will allow users to link to other scholarship, generate new research, and publish findings.

## Technical Specifications

For detailed technical specifications and additional documentation, see [the wiki](https://github.com/villaitatti/metapolis/wiki).
