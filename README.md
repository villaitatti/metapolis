# Metapolis

## Quickstart Guide

Get Metapolis up and running in just a few steps:

### Step 1: Import Resource Configurations

1. **Navigate to Data Import**: Go to `resource/Admin:DataImportExport` or click the settings button (⚙️) → "Data Import & Download"
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

---

## Introduction & Overview

Metapolis is a geospatial visualization platform that enables researchers to manage and visualize complex geospatial data. It integrates two primary components: the SQL Sail integration and the Advanced Semantic Map. These components allow Metapolis to connect a PostgreSQL database with PostGIS for geospatial queries and analysis with the ResearchSpace semantic framework.

### Metapolis Overview

Metapolis enables users to:
- Visualize historical geospatial data on interactive maps
- Query and analyze spatial relationships
- Link archival sources to geographical locations
- Create temporal visualizations of changing urban landscapes

### App Structure

Metapolis is implemented as a ResearchSpace app with the following structure:

```
metapolis/
├── config/                     # Configuration files
│   ├── page-layout/            # Page layout templates
│   │   └── html-head.hbs       # HTML head template
│   └── services/               # Service configurations
│       └── geosql.ttl          # SPARQL service for database queries
├── data/                       # Data and templates
│   └── templates/              # HTML templates
│       └── metapolis:test.html # Test page for Florence buildings
├── lib/                        # External libraries
│   └── postgresql-42.2.14.jar  # PostgreSQL JDBC driver
├── plugin.properties           # Plugin configuration
└── README.md                   # This documentation
```

The application primarily consists of HTML templates that utilize the SemanticMapAdvanced component from the ResearchSpace core. The actual implementation of the map components is in the ResearchSpace business core.

## Requirements

Metapolis requires the ResearchSpace platform with specific components:

- Researchspace installed with Docker, specifying the [build-docker/metapolis](https://github.com/researchspace/researchspace/tree/build-docker/metapolis) branch.
- QGIS for data preparation (optional)
- A running PostgreSQL database with PostGIS extension

## Installation Guide

### Step 1: Install ResearchSpace Docker Image

Researchspace can be installed on a [Server](https://github.com/researchspace/researchspace-docker-compose) or on your [local machine](https://documentation.researchspace.org/resource/rsp:Documentation_Download#rs-doc_installationDocker). The following steps are based on the server implementation.

Download or clone the repository the [Researchspace Docker Compose repository](https://github.com/researchspace/researchspace-docker-compose).

Move in the basic folder and update the docker image
```bash
> cd basic/
> vim .env
```

Replace line `23`, change the `RESEARCHSPACE_IMAGE` attribute to match the metapolis label. The new line is: 

```RESEARCHSPACE_IMAGE=researchspace/platform-ci:metapolis```

Follow the setup for the [basic configuration](https://github.com/researchspace/researchspace-docker-compose/tree/master/basic)

Verify the installation by accessing the ResearchSpace platform at `http://localhost:10214` or the server IP address.

### Step 2: Database Setup

For the database setup, follow the comprehensive guide in the [metapolis_setup repository](https://github.com/villaitatti/metapolis_setup):

1. **Clone the setup repository**:
   ```bash
   git clone https://github.com/villaitatti/metapolis_setup.git
   cd metapolis_setup
   ```

2. **Follow Step 1: Database Setup** in the repository's README.md:
   - **Environment Configuration**: Copy `.env.template` to `.env` and configure your database credentials
   - **Launch Database**: Use Docker Compose to start PostgreSQL with PostGIS
   - **Initialize Data**: Automatic setup of PostGIS, schema creation, and sample Florence buildings data
   - **Verify Setup**: Test database connection and data integrity

3. **Repository Configuration**: Update your ResearchSpace repository configuration to connect to the database using the credentials from your `.env` file

The setup repository provides:
- **Complete Docker environment** with PostgreSQL 15 + PostGIS 3.3
- **Environment variable configuration** for secure credential management
- **Sample Florence buildings dataset** with realistic geospatial data
- **Comprehensive verification commands** to ensure proper setup

### Step 3: Prerequisites and Setup

Before using Metapolis, ensure you have completed:

1. **Database Setup**: PostgreSQL with PostGIS extension (see Step 2 above)
2. **Knowledge Platform**: ResearchSpace platform configuration
3. **Sample Data**: Florence buildings dataset (included in database setup)

**For detailed setup instructions, see the comprehensive setup guide in the [metapolis_setup repository](https://github.com/villaitatti/metapolis_setup).**

### Step 4: Service Configuration

The geosql service configuration at `config/services/geosql.ttl` enables SPARQL queries against your PostgreSQL database.

**Key Features:**
- Adapted for the Buildings table structure (id, name, function, geom)
- 15+ predefined queries for common use cases
- Florence-specific spatial queries
- Bounding box and distance-based queries

**Example SPARQL Usage:**
```sparql
PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>

SELECT ?name ?function ?wkt WHERE {
  ?result rs_sql_sail:hasQueryId "all_buildings" .
  ?result metapolis_sql:name ?name .
  ?result metapolis_sql:function ?function .
  ?result metapolis_sql:wkt ?wkt .
}
```

### Step 5: Test Page - Florence Buildings Map

A test HTML page has been created at `data/templates/metapolis:test.html` to demonstrate the SemanticMap component.

**Features:**
- Interactive map centered on Florence
- Color-coded building function badges
- Multiple base map options
- Popup information with building details

**Access:** `http://localhost:10214/resource/metapolis:test`

### Step 6: Optional: Import Data from QGIS

If you have existing geospatial data in QGIS that you want to import:

1. **Export data from QGIS to PostgreSQL:**
   - Open your project in QGIS
   - Go to Database > DB Manager
   - Connect to your PostgreSQL database using the connection details from the setup guide
   - Select the layers you want to export
   - Right-click and select "Export to PostgreSQL"
   - Configure the export settings (schema: `metapolis`, table name, etc.)
   - Click "OK" to export the data

2. **Configure SQL Sail integration in ResearchSpace:**

   Use the configuration provided in the setup guide.

For more detailed information, see the [SQL Sail integration wiki](https://github.com/villaitatti/metapolis/wiki/SQL-Sail-integration).

## Implementation Guide

### SemanticMapAdvanced Component

The SemanticMapAdvanced component is the core of Metapolis, providing interactive map visualization capabilities. It integrates with the SQL Sail to query geospatial data from PostgreSQL.

Key features of the SemanticMapAdvanced component:
- Interactive map visualization
- Temporal filtering
- Feature selection and highlighting
- Custom styling based on feature properties
- Integration with other ResearchSpace components

For detailed implementation information, see the [SemanticMapAdvanced component wiki](https://github.com/villaitatti/metapolis/wiki/Implementing-SemanticMapAdvanced-component).

### HTML Template Creation

To create a map visualization page, follow these steps:

1. Create a new HTML template file in your ResearchSpace instance
2. Implement the SemanticMapAdvanced component with appropriate configuration
3. Configure the map controls and layers

Here's a basic template example:

```html
<div style="width: 100%; height: 95vh; display: flex; position: relative">
  <!-- Sidebar component -->
  <semantic-map-controls
    id="my-map-controls"
    target-map-id="my-map"
    features-options-enabled="true"
    features-taxonomies="function"
    features-color-taxonomies="function"
    features-colors-palette='{
        "Religious":"rgba(46,125,50,0.9)",
        "Government":"rgba(21,101,192,0.9)",
        "Cultural":"rgba(194,24,91,0.9)",
        "Commercial":"rgba(239,108,0,0.9)"
      }'
    render-template="{{> feature-details}}"
    template-mapping='{
      "selectedFeature": "{{> feature-details}}"
    }'
  >
    <template id="feature-details">
      <!-- Custom feature details template -->
      <div>
        <h3>{{name}}</h3>
        <p>Function: {{function}}</p>
        <p>ID: {{building_id}}</p>
      </div>
    </template>
  </semantic-map-controls>

  <!-- Map component -->
  <div style="flex: 1; position: relative">
    <semantic-context repository="metapolis">
      <semantic-map-advanced
        id="my-map"
        target-controls='["my-map-controls"]'
        feature-selection-targets='["my-map-controls"]'
        map-options='{"crs":"EPSG:4326", "center": [43.7731, 11.2560], "zoom": 14}'
        selected-feature-style='{
            "color": "rgba(0, 128, 255, 1)",
            "borderColor": "black",
            "borderWidth": 2
          }'
        query='
          PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
          PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>

          SELECT * WHERE {
            ?root rs_sql_sail:hasQueryId "all_buildings";	
                  metapolis_sql:building_id ?building_id;
                  metapolis_sql:name ?name;
                  metapolis_sql:function ?function;
                  metapolis_sql:wkt ?wkt
          }'
      >
        <!-- Base map layers -->
        <tiles-layer
          thumbnail="../assets/images/osm.png"
          url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
          identifier="OpenStreetMap"
          name="OpenStreetMap"
          level="basemap"
          author="OpenStreetMap"
          year="2024"
        >
        </tiles-layer>
        
        <!-- Add additional tile layers as needed -->
      </semantic-map-advanced>
    </semantic-context>
  </div>
</div>
```

## Examples & Use Cases

### Historical Urban Development Visualization

Metapolis can be used to visualize the historical development of urban areas over time. By configuring the timeline component, users can see how cities evolved through different periods.

![Historical Urban Development](https://github.com/villaitatti/metapolis/wiki/images/historical-development.png)

### Archival Source Integration

Researchers can link archival sources to geographical locations, creating a rich contextual understanding of historical documents.

```html
<template id="document-template">
  <div class="document-card">
    <h3>{{title}}</h3>
    <p>Date: {{date}}</p>
    <p>Source: {{archive}}</p>
    <div class="document-image">
      <img src="{{imageUrl}}" alt="{{title}}">
    </div>
    <p>{{description}}</p>
  </div>
</template>
```

### Thematic Mapping

Create thematic maps by configuring the color palette based on feature categories:

```html
features-colors-palette='{
  "Religious":"rgba(46,125,50,0.9)",
  "Government":"rgba(21,101,192,0.9)",
  "Cultural":"rgba(194,24,91,0.9)",
  "Commercial":"rgba(239,108,0,0.9)"
}'
```

## Troubleshooting

### Common Issues

1. **Map doesn't display**: Check that your PostgreSQL connection is properly configured and that your SPARQL query returns valid WKT geometries.

2. **Features not appearing**: Verify that your data has the correct structure and that the service configuration matches your database schema.

3. **Performance issues**: Large datasets may cause performance problems. Consider optimizing your PostgreSQL database with appropriate indexes:

```sql
CREATE INDEX idx_geom ON metapolis.buildings USING GIST (geom);
```

4. **CORS errors**: If loading external tile layers, ensure that the server allows cross-origin requests.

### Debugging Tips

- Enable debug logging in ResearchSpace by adding `-Dlog4j.configurationFile=file:///opt/researchspace/config/log4j2-debug.xml` to your PLATFORM_OPTS
- Use browser developer tools to inspect network requests and JavaScript errors
- Validate your SPARQL queries using the ResearchSpace SPARQL editor before using them in the map component

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
