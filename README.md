# Metapolis

The creation of geospatial enhancements to an existing digital infrastructure that will allow users to link to other scholarship, generate new research, and publish findings.

Metapolis aims to develop a digital research infrastructure to support scholarship in the humanities that seeks to geospatially reconstruct places throughout time. As an interactive map-based publication platform, it enables users to cross-pollinate archival, bibliographic and multimedia sources with interpretive research, allowing for their interlinking and visualization on a map. Built on top of ResearchSpace, an open-source Semantic Web research environment, it facilitates the reuse and publishing of Linked Open Data. A rich set of features support data enrichment with external knowledge bases such as VIAF, WikiData, OCLC, and the Getty vocabularies. Designed both as a research and publication tool, the software allows groups of scholars from a wide range of humanistic disciplines to connect their research and augment each other's findings through the layering of historical maps, interlinking them to sources to allow users to build knowledge about the world and its history.

For detailed technical specifications and additional documentation, see [the wiki](https://github.com/villaitatti/metapolis/wiki).

## 📋 Table of Contents

* [Overview](#overview)
* [Prerequisites](#prerequisites)
* [Quickstart Guide](#quickstart-guide)
   - [Step 0: Add the App](#step-0-add-the-app)
      - [0.1: Install ResearchSpace](#01-install-researchspace)
      - [0.2: Add Metapolis App to ResearchSpace](#02-add-metapolis-app-to-researchspace)
      - [0.3: Download Metapolis Setup Repository](#03-download-metapolis-setup-repository)
   - [Step 1: Import Resource Configurations](#step-1-import-resource-configurations)
      - [1.1: Access Data Import Interface](#11-access-data-import-interface)
      - [1.2: Import Ontology Definitions](#12-import-ontology-definitions)
      - [1.3: Import Entity Configurations](#13-import-entity-configurations)
      - [1.4: Verify Import Success](#14-verify-import-success)
   - [Step 2: Setup Database](#step-2-setup-database)
      - [2.1: Navigate to Database Directory](#21-navigate-to-database-directory)
      - [2.2: Configure Environment Variables](#22-configure-environment-variables)
      - [2.3: Understand Database Initialization](#23-understand-database-initialization)
      - [2.4: Launch the Database](#24-launch-the-database)
      - [2.5: Verify Database Installation](#25-verify-database-installation)
      - [2.6: Troubleshooting Database Issues](#26-troubleshooting-database-issues)
* [Next Steps](#next-steps)
   - [Step 3: Test Database Queries](#step-3-test-database-queries)
      - [3.1: Access the SPARQL Endpoint](#31-access-the-sparql-endpoint)
      - [3.2: Run Basic Test Query](#32-run-basic-test-query)
      - [3.3: Configure Federated Queries with Ephedra](#33-configure-federated-queries-with-ephedra)
      - [3.4: Test Federated Query](#34-test-federated-query)
      - [3.5: Explore Additional Queries](#35-explore-additional-queries)
   - [Step 4: Create New Buildings with Metapolis](#step-4-create-new-buildings-with-metapolis-and-connect-them-to-the-features-in-postgis)
      - [4.1: Prerequisites](#41-prerequisites)
      - [4.2: Access the Finder Interface](#42-access-the-finder-interface)
      - [4.3: Create a New Building Entity](#43-create-a-new-building-entity)
      - [4.4: Link to PostGIS Features](#44-link-to-postgis-features)
      - [4.5: Complete Building Details](#45-complete-building-details)
      - [4.6: Verify the Connection](#46-verify-the-connection)
      - [4.7: Adding More Features](#47-adding-more-features)
      - [4.8: Best Practices](#48-best-practices)
   - [Other Next Steps](#other-next-steps)
* [Contributing](#contributing)
* [Acknowledgements](#acknowledgements)
* [Technical Specifications](#technical-specifications)

---

## Overview

Metapolis is a ResearchSpace application that provides geospatial visualization and data management capabilities for humanities research. The platform enables scholars to:

- Create and manage geospatial entities (Buildings, Events, People, Sources)
- Link archival sources to buildings and geographical locations
- Visualize historical data on interactive maps
- Connect research findings through semantic relationships
- Publish and share Linked Open Data

The application integrates with PostgreSQL/PostGIS for spatial data storage and leverages ResearchSpace's semantic web infrastructure for knowledge management.

## Prerequisites

Before installing Metapolis, ensure you have:

- **ResearchSpace Platform**: Version 4.0 or later installed and running
- **Docker & Docker Compose**: For database setup (see [Docker documentation](https://docs.docker.com/engine/install/))
- **Basic Knowledge**: Familiarity with SPARQL queries and semantic web concepts is helpful
- **System Requirements**: Sufficient resources to run ResearchSpace and PostgreSQL containers

## Quickstart Guide

This comprehensive guide will walk you through the complete setup process for Metapolis, from initial installation to creating your first geospatial entities.

### Step 0: Add the App

This initial step ensures that the Metapolis application is properly integrated with your ResearchSpace instance.

#### 0.1: Install ResearchSpace

1. **Download ResearchSpace**: Obtain ResearchSpace version 4.0 or later from the [official repository](https://github.com/researchspace/researchspace)
2. **Follow Installation Instructions**: Complete the ResearchSpace installation process according to the official documentation
3. **Start the Instance**: Launch your ResearchSpace instance and verify it's running correctly
4. **Access the Platform**: Navigate to your ResearchSpace instance in a web browser (typically `http://localhost:10214`)

#### 0.2: Add Metapolis App to ResearchSpace

1. **Clone the Metapolis Repository**:
   ```bash
   git clone https://github.com/villaitatti/metapolis.git
   ```

2. **Add App to ResearchSpace**: Follow the [Official ResearchSpace documentation](https://github.com/researchspace/researchspace) for adding apps to your instance.

3. **Verify App Installation**:
   - Navigate to the **Admin** page by clicking the **System Settings button** (gear icon) in the top right corner
   - Select **"Apps & Storages"** in the **System Management** group
   - Verify that **Metapolis** appears in the list of installed apps
   - Confirm the app status shows as "Active" or "Connected"

#### 0.3: Download Metapolis Setup Repository

The setup repository contains essential configuration files and database initialization scripts:

1. **Clone the Setup Repository**:
   ```bash
   git clone https://github.com/villaitatti/metapolis_setup.git
   cd metapolis_setup
   ```

2. **Review Directory Structure**: Familiarize yourself with the provided files:
   - `configurations/` - ResearchSpace configuration files
   - `metapolis-db/` - Database setup scripts and Docker configuration
   - `README.md` - Detailed setup instructions

This repository will be used extensively in the following steps for configuring your Metapolis instance.

### Step 1: Import Resource Configurations

This step establishes the semantic foundation for Metapolis by importing ontology definitions and entity configurations into your ResearchSpace instance.

#### 1.1: Access Data Import Interface

1. **Navigate to Data Import**: Access the import interface using one of these methods:
   - Direct URL: Navigate to `resource/Admin:DataImportExport`
   - Via Settings: Click the **System Settings button** (gear icon) → Select **"Data Import & Download"** from the menu

2. **Prepare for Import**: Ensure you have the configuration files from the `metapolis_setup/configurations` folder ready

#### 1.2: Import Ontology Definitions

The ontology file defines the conceptual framework for all Metapolis entities:

1. **Locate the File**: Find `Metapolis_Ontology.trig` in the `metapolis_setup/configurations/` directory
2. **Upload the File**: 
   - Click the **"Choose File"** or **"Browse"** button in the import interface
   - Select `Metapolis_Ontology.trig`
3. **Configure Import Options**:
   - ✅ Check **"Keep source named graphs"** to preserve the ontology structure
   - This ensures proper namespace and graph organization
4. **Execute Import**: Click **"Import"** and wait for confirmation
5. **Verify Success**: Check for success message indicating the ontology was imported

**What This File Contains:**
- Base entity class: `metapolis_ontology:Metapolis_Entity`
- Four main entity types: Building, Event, Person, Source
- OWL-compliant class hierarchies
- Multilingual labels and descriptions

#### 1.3: Import Entity Configurations

The entity configuration file connects the ontology to ResearchSpace forms and navigation:

1. **Locate the File**: Find `Metapolis_Entity.trig` in the `metapolis_setup/configurations/` directory
2. **Upload the File**:
   - Click **"Choose File"** or **"Browse"** again
   - Select `Metapolis_Entity.trig`
3. **Configure Import Options**:
   - ✅ Check **"Keep source named graphs"** to maintain entity relationships
4. **Execute Import**: Click **"Import"** and wait for confirmation
5. **Verify Success**: Confirm the import completed without errors

**What This File Contains:**
- Entity definitions for all four Metapolis types
- Form connections linking entities to semantic forms
- Navigation integration for the Finder interface
- Search and list view configurations
- Metadata tracking using CIDOC-CRM standards

#### 1.4: Verify Import Success

After importing both files, verify the configuration is active:

1. **Check the Finder Sidebar**: Look for the following entities in the left sidebar:
   - **Metapolis Building**
   - **Metapolis Event**
   - **Metapolis Person**
   - **Metapolis Source**

2. **Test Entity Access**: Click on any entity type to verify it opens without errors

3. **Verify Forms**: Try clicking **"New [Entity Type]"** to ensure forms are properly connected

If entities don't appear, try refreshing the page or restarting the ResearchSpace instance. If it still not showing up, please write a issue describing the problem.

### Step 2: Setup Database

Metapolis requires a PostgreSQL database with PostGIS extension for storing and querying geospatial data. This step guides you through setting up the database using Docker.

#### 2.1: Navigate to Database Directory

From the `metapolis_setup` repository you cloned in Step 0:

```bash
cd metapolis_setup/metapolis-db
```

This directory contains all necessary files for database setup:
- `docker-compose.yml` - Container configuration
- `.env.template` - Environment variables template
- `init-scripts/` - Automatic database initialization scripts

#### 2.2: Configure Environment Variables

Before launching the database, configure your credentials and settings:

1. **Create Environment File**:
   ```bash
   cp .env.template .env
   ```

2. **Edit the `.env` File**: Open the file in your preferred text editor and configure:
   ```bash
   # Database Configuration
   POSTGRES_DB=metapolis
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=your_secure_password_here
   
   # Authentication Method
   POSTGRES_HOST_AUTH_METHOD=md5  # Use md5 or scram-sha-256 for production
   ```

3. **Update Repository Configuration**: The database credentials must be synchronized in two locations:
   - **Metapolis Setup**: Update the `.env` file in `metapolis_setup/metapolis-db/.env` (completed in step 2 above)
   - **Metapolis Repository**: Update the repository configuration in the **Metapolis app** at `config/repositories/metapolis.ttl`
   
   In the `metapolis.ttl` file, update the connection parameters to match your `.env` values:
   ```turtle
   sql:jdbcUrl "jdbc:postgresql://localhost:5432/metapolis" ;
   sql:username "postgres" ;
   sql:password "your_secure_password_here" ;
   ```
   
   **Important**: Both files must have matching credentials for the connection to work properly.

4. **Security Considerations**:
   - **Development**: You can use `trust` authentication for local testing
   - **Production**: Always use `md5` or `scram-sha-256` with strong passwords
   - **Password Strength**: Choose a unique, complex password for `POSTGRES_PASSWORD`
   - **File Security**: The `.env` file is git-ignored to prevent credential exposure
   - **Credential Sync**: Always update both locations when changing database credentials

#### 2.3: Understand Database Initialization

The `init-scripts/` directory contains three SQL scripts that run **automatically** on first startup:

1. **`01-init-database.sql`**: 
   - Enables PostGIS and PostGIS Topology extensions
   - Creates the `metapolis` schema for organized data storage
   - Configures search paths for efficient queries

2. **`02-create-buildings-table.sql`**:
   - Defines the Buildings table structure with geometry support
   - Creates spatial indexes for efficient geospatial queries
   - Sets up automatic timestamp tracking

3. **`03-insert-sample-buildings.sql`**:
   - Inserts 5 famous Florence buildings as sample data
   - Provides realistic coordinates and building functions
   - Includes verification queries for data validation

#### 2.4: Launch the Database

Start the PostgreSQL container with PostGIS:

```bash
# Ensure you're in the metapolis-db directory
cd metapolis_setup/metapolis-db

# Start the database services
docker-compose up -d
```

**What Happens During Startup:**
- Docker pulls the `postgis/postgis:15-3.3` image (if not already present)
- Creates a container named `metapolis-postgres`
- Executes initialization scripts in alphabetical order
- Sets up PostGIS extensions and sample data
- Exposes the database on port 5432

#### 2.5: Verify Database Installation

After the container starts, verify everything is working correctly:

1. **Check Container Status**:
   ```bash
   docker ps | grep metapolis-postgres
   ```
   You should see the container running with status "Up"

2. **Test Database Connection**:
   ```bash
   docker exec -it metapolis-postgres psql -U postgres -d metapolis -c "SELECT version();"
   ```
   This should return the PostgreSQL version information

3. **Verify PostGIS Installation**:
   ```bash
   docker exec -it metapolis-postgres psql -U postgres -d metapolis -c "SELECT PostGIS_Version();"
   ```
   This should return the PostGIS version (e.g., "3.3")

4. **Check Buildings Table**:
   ```bash
   docker exec -it metapolis-postgres psql -U postgres -d metapolis -c "\dt metapolis.*"
   ```
   You should see the `buildings` table listed

5. **Verify Sample Data**:
   ```bash
   docker exec -it metapolis-postgres psql -U postgres -d metapolis -c "SELECT name, function FROM metapolis.buildings;"
   ```
   This should return the 5 Florence buildings (Palazzo Vecchio, Duomo, etc.)

#### 2.6: Troubleshooting Database Issues

**Problem: Container Already Exists**

If you see "Container already exists" or initialization scripts don't run:

```bash
# Stop and remove the container
docker-compose down

# Remove the persistent volume (⚠️ This deletes existing data)
docker volume rm metapolis-db_postgres_data

# Verify volume is removed
docker volume ls | grep metapolis

# Start fresh
docker-compose up -d
```

**Problem: Connection Refused**

If you can't connect to the database:
- Verify the container is running: `docker ps`
- Check logs for errors: `docker-compose logs -f postgres`
- Ensure port 5432 is not already in use
- Verify your `.env` file has correct credentials

**Problem: Scripts Not Executing**

If sample data is missing:
- Check container logs: `docker-compose logs postgres`
- Manually execute scripts (see metapolis_setup README for details)
- Verify scripts have proper line endings (Unix format, not Windows)

For detailed troubleshooting, refer to the [metapolis_setup repository README](https://github.com/villaitatti/metapolis_setup).

**Congratulations!** Your Metapolis system is now up and running with a properly configured database. You can proceed to the next steps to test queries and start creating geospatial entities.

** Important Security Note:** For production systems, make sure to update the default database password to a strong, unique password in both `config/repositories/metapolis.ttl` and `metapolis_setup/metapolis-db/.env` files.

## Next Steps

After completing the basic setup (Steps 0-2), you can proceed with testing and using your Metapolis instance.

### Step 3: Test Database Queries

This step verifies that ResearchSpace can successfully query the PostgreSQL/PostGIS database and retrieve geospatial data. You'll test both direct repository queries and federated queries.

#### 3.1: Access the SPARQL Endpoint

1. **Navigate to SPARQL Interface**: 
   - Go to `/sparql` in your ResearchSpace instance
   - Or click **"SPARQL"** from the main navigation menu

2. **Select Repository**: 
   - In the repository dropdown, select **"metapolis"**
   - This connects to the PostgreSQL database you configured

#### 3.2: Run Basic Test Query

Test the connection with a simple query that retrieves all buildings:

1. **Enter the Query**: Copy and paste this SPARQL query into the editor:
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

2. Select the repository **"Metapolis"**

3. **Execute the Query**: Click the **"Execute"** button

4. **Verify Results**: You should see results containing:
   - `building_id`: Unique identifier for each building
   - `name`: Building names (e.g., "Palazzo Vecchio", "Duomo di Firenze")
   - `function`: Building types (e.g., "Government", "Religious")
   - `wkt`: Well-Known Text geometry representation (polygon coordinates)

5. **Expected Results**: The query should return 5 rows representing the Florence sample buildings

**What This Query Does:**
- Uses the SQL Sail bridge to query PostgreSQL directly from SPARQL
- Executes the predefined `all_buildings` query from the service configuration
- Retrieves building data including spatial geometry in WKT format
- Demonstrates the integration between semantic web and relational database

At this point the system is running and you can navigate the map.

**TODO:** add here information on how to navigate the map

#### 3.3: Configure Federated Queries with Ephedra

To enable querying Metapolis data from other repositories in your ResearchSpace instance, configure Ephedra federation:

1. **Navigate to Repository Configuration**:
   - Go to **System Settings** (gear icon) → **"System Configurations"**
   - Select **"Repositories"** from the configuration menu

2. **Locate Federation Configuration**:
   - Find the `fedsail:member` configuration section
   - This defines which repositories participate in federated queries

3. **Add Metapolis to Federation**:
   - Scroll to the last element in the `fedsail:member` list
   - Append this configuration **after the last element** (note the comma before the opening bracket):
   ```turtle
   , [
         ephedra:delegateRepositoryID "metapolis";
         ephedra:serviceReference <http://www.researchspace.org/resource/system/repository/federation#metapolis>
       ]
   ```

4. **Save Configuration**:
   - Click **"Update"** or **"Save"** to apply changes
   - The system may require a restart to activate the new configuration

5. **Verify Federation**: Check that the configuration was saved without syntax errors

**Why This Matters:**
- Enables cross-repository queries combining Metapolis spatial data with other semantic data
- Allows integration with external knowledge bases (VIAF, Wikidata, Getty vocabularies)
- Supports complex queries that join geospatial and non-geospatial information

#### 3.4: Test Federated Query

Now test that you can access Metapolis data from the federated repository:

1. **Switch Repository**: In the SPARQL interface, select the **"ephedra"** repository (or your default federated repository)

2. **Enter Federated Query**: Copy and paste this query:
   ```sparql
   PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
   PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>

   SELECT * WHERE {
     SERVICE <http://www.researchspace.org/resource/system/repository/federation#metapolis> {
       ?s rs_sql_sail:hasQueryId "all_buildings";
          metapolis_sql:building_id ?building_id;
          metapolis_sql:name ?name;
          metapolis_sql:function ?function;
          metapolis_sql:wkt ?wkt
     }
   }
   ```

3. **Execute the Query**: Click  **"Execute"**

4. **Verify Results**: You should see the same building data as before, but now queried through the federation layer

**Understanding the Federated Query:**
- The `SERVICE` clause directs the query to the metapolis repository
- The federation layer handles routing and result aggregation
- This pattern allows combining Metapolis data with other data sources in a single query
- You can now join building data with entities from other repositories

#### 3.5: Explore Additional Queries

The Metapolis service configuration includes 15+ predefined queries. Try these examples:

**Query Buildings by Function:**
```sparql
PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>

SELECT * WHERE {
  ?s rs_sql_sail:hasQueryId "buildings_by_function";
     rs_sql_sail:hasParameter [
       rs_sql_sail:parameterName "function_type";
       rs_sql_sail:parameterValue "Religious"
     ];
     metapolis_sql:building_id ?building_id;
     metapolis_sql:name ?name;
     metapolis_sql:function ?function;
     metapolis_sql:wkt ?wkt
}
```

**Query Buildings Near a Point:**
```sparql
PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>

SELECT * WHERE {
  ?s rs_sql_sail:hasQueryId "buildings_near_point";
     rs_sql_sail:hasParameter [
       rs_sql_sail:parameterName "longitude";
       rs_sql_sail:parameterValue "11.2558"
     ];
     rs_sql_sail:hasParameter [
       rs_sql_sail:parameterName "latitude";
       rs_sql_sail:parameterValue "43.7696"
     ];
     rs_sql_sail:hasParameter [
       rs_sql_sail:parameterName "distance_meters";
       rs_sql_sail:parameterValue "500"
     ];
     metapolis_sql:building_id ?building_id;
     metapolis_sql:name ?name;
     metapolis_sql:distance ?distance
}
```

These queries demonstrate the power of combining SPARQL with spatial SQL queries for geospatial analysis.

### Step 4: Create New Buildings with Metapolis and Connect Them to the Features in PostGIS

Once you've verified that database queries work correctly, you can start creating Building entities in Metapolis and linking them to geographical features in your PostGIS database. This step demonstrates the core workflow for managing geospatial data.

#### 4.1: Prerequisites

Before creating buildings, ensure:
- ✅ Steps 1-3 are completed successfully
- ✅ PostGIS database contains geographical features (buildings, monuments, etc.)
- ✅ You have feature names ready for linking
- ✅ The Finder sidebar shows Metapolis entities

#### 4.2: Access the Finder Interface

The Finder is your primary navigation tool for managing Metapolis entities:

1. **Locate the Finder Sidebar**: Look for the left sidebar in your ResearchSpace interface
2. **Find Metapolis Entities**: Scroll to locate the Metapolis entity types
3. **Verify Access**: Ensure you can see all four entity types (Building, Event, Person, Source)

![sidebar](https://github.com/user-attachments/assets/0d752286-d387-483d-8d6a-ed6f797fa0a3)

#### 4.3: Create a New Building Entity

1. **Select Building Entity Type**:
   - In the Finder sidebar, locate and click on **"Metapolis Building"**
   - This opens the Buildings list view showing existing building entities

2. **Initiate Creation**:
   - Click the **"New Metapolis Building"** button (typically blue and prominent)
   - This opens the Building creation form with all available fields

3. **Understand the Form Structure**:
   The form includes several sections:
   - **Basic Information**: Name, description, and classification
   - **Relationships**: Connections to other entities (Events, People, Sources)
   - **Spatial Data**: Link to PostGIS geographical features
   - **Metadata**: Creation date, contributors, and provenance information

#### 4.4: Link to PostGIS Features

This is the critical step that connects semantic entities to geospatial data:

1. **Understand the Connection**:
   - Your PostGIS database contains geographical features (polygons, points) representing physical buildings
   - These features may not yet be linked to Metapolis Building entities
   - For example, **"Galleria degli Uffizi"** might exist in PostGIS but not as a Metapolis entity

2. **Find the Feature Field**:
   - Locate the **"Has Related Feature"** field in the Building creation form
   - This field provides autocomplete functionality connected to the PostGIS database

3. **Search for Features**:
   - Start typing the name of the geographical feature (e.g., "Galleria degli Uffizi")
   - As you type, the system queries the PostGIS database in real-time
   - A dropdown appears showing matching features from the database

4. **Select the Feature**:
   - Review the suggestions and select the appropriate feature
   - The system will link the Building entity to the selected PostGIS geometry
   - The spatial coordinates and geometry are now associated with your entity

![sidebar2](https://github.com/user-attachments/assets/8177fc19-9eb1-48a2-a71a-5c5619188620)

#### 4.5: Complete Building Details

Fill in additional information to enrich your Building entity:

1. **Required Fields**:
   - **Name**: The building's common name (e.g., "Galleria degli Uffizi")
   - **Has Related Feature**: The PostGIS feature link (completed in step 4.4)

2. **Optional Fields**:
   - **Function**: Building type or purpose (e.g., "Museum", "Government", "Religious")
   - **Related Events**: Link to historical events that occurred at this location
   - **Related People**: Connect to people associated with the building
   - **Related Sources**: Link to archival sources, documents, or references
   - **Description**: Additional context and historical information
   - **Time Period**: When the building was constructed or in use

3. **Save the Entity**:
   - Review all entered information for accuracy
   - Click **"Create Metapolis Building"** to save the entity
   - Wait for confirmation that the entity was created successfully

#### 4.6: Verify the Connection

After creating the building, verify everything is working correctly:

1. **Check Entity Page**:
   - The system should redirect you to the new Building entity's page
   - Verify all information displays correctly

2. **View on Map**:
   - Navigate to map visualization components
   - The building should appear on the map at its correct location
   - The spatial data from PostGIS is now visualized
   **TODO** complete

3. **Test Queries**:
   - Use the SPARQL endpoint to query for your new building
   - Verify it appears in results alongside the sample buildings

4. **Verify Relationships**:
   - If you linked Events, People, or Sources, check that these connections work
   - Navigate between related entities to test bidirectional links

#### 4.7: Adding More Features

Expand your Metapolis instance by adding more geographical features:

**Method 1: Manual Creation in Metapolis**
- Repeat steps 4.2-4.6 for each unlinked feature in your PostGIS database
- Suitable for small numbers of buildings or when detailed curation is needed
- Allows careful review and enrichment of each entity

**Method 2: Batch Processing**
- For multiple buildings, create a systematic workflow
- Use spreadsheets to organize building information before entry
- Consider creating templates for common building types

**Method 3: GIS Software Integration**

You can add new geographical features using GIS software (e.g., QGIS, ArcGIS) that connects to the same PostGIS database:

1. **Connect GIS Software to PostGIS**:
   - Open QGIS or your preferred GIS application
   - Create a new PostGIS connection using your database credentials
   - Connect to the `metapolis` database and `metapolis` schema

2. **Create or Import Building Footprints**:
   - Use GIS tools to digitize building footprints from maps or satellite imagery
   - Import existing shapefiles or GeoJSON data
   - Ensure geometries are in WGS84 (EPSG:4326) coordinate system

3. **Add to Buildings Table**:
   - Export or insert features into the `metapolis.buildings` table
   - Ensure required fields are populated (name, function, geom)
   - Verify spatial data integrity

4. **Link in Metapolis**:
   - The new features automatically become available in Metapolis
   - Follow steps 4.2-4.6 to create corresponding Building entities
   - Link each entity to its PostGIS feature using the autocomplete field

#### 4.8: Best Practices

Follow these guidelines for effective data management:

**Naming Conventions:**
- Keep feature names consistent between GIS software and Metapolis
- Use descriptive names that make features easy to identify
- Include location information when multiple buildings share similar names
- Consider using standardized naming schemes (e.g., "Building Name, City")

**Data Quality:**
- Verify spatial data accuracy before linking to ensure proper map visualization
- Check that polygon geometries are valid and don't have self-intersections
- Ensure coordinates are in the correct coordinate reference system (WGS84)
- Review building functions and classifications for consistency

**Documentation:**
- Document any custom attributes or metadata in both the GIS database and Metapolis entities
- Maintain records of data sources and provenance
- Create internal guidelines for data entry and quality control
- Use the Description field to provide context and historical information

**Relationships:**
- Link buildings to relevant Events, People, and Sources as you discover connections
- Build a network of relationships that enriches the research value
- Consider temporal relationships (when buildings were constructed, modified, or demolished)
- Document uncertainty or ambiguity in relationships

### Other Next Steps

After completing the setup and creating your first buildings, explore these additional capabilities:

**Expand Your Dataset:**
- **Create Events**: Document historical events and link them to buildings and locations
- **Add People**: Create Person entities for architects, owners, residents, and other associated individuals
- **Link Sources**: Connect archival sources, documents, photographs, and references to your entities
- **Import More Data**: Use GIS software to add more geographical features to your PostGIS database

**Visualize Your Data:**
- **Access Map Components**: Navigate to map visualization pages to see your buildings displayed geographically
- **Layer Historical Maps**: Upload and overlay historical maps to provide temporal context
- **Create Custom Views**: Design specialized map views for different research questions or time periods
- **Export Visualizations**: Generate maps and diagrams for publications and presentations

**Advanced Queries:**
- **Spatial Analysis**: Use SPARQL queries to find buildings within specific areas or distances
- **Temporal Queries**: Filter entities by time periods or date ranges
- **Relationship Exploration**: Query complex networks of relationships between entities
- **Data Export**: Extract data in various formats for external analysis

**Collaboration:**
- **User Management**: Add collaborators to your ResearchSpace instance
- **Access Control**: Configure permissions for different user roles
- **Shared Research**: Enable multiple scholars to contribute to the same dataset
- **Publication**: Prepare your data for public access and Linked Open Data publication

**Integration:**
- **External Knowledge Bases**: Link your entities to VIAF, Wikidata, OCLC, and Getty vocabularies
- **Authority Control**: Use standardized identifiers for people, places, and concepts
- **Data Enrichment**: Leverage external data sources to enhance your entities
- **Interoperability**: Ensure your data can be discovered and reused by other projects

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
