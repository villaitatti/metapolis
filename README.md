# Metapolis

For detailed technical specifications and additional documentation, see [the wiki](https://github.com/villaitatti/metapolis/wiki).

## Quickstart Guide



Get Metapolis up and running in just a few steps:

### Step 0: Add the app

1. Execute a Researchspace instance
2. Add the app to the instance

See the [Official RS documentation](https://github.com/researchspace/researchspace).

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

3. **Configure Metapolis with Ephedra**: To enable querying Metapolis data from outside the "metapolis" repository:
   - Navigate to **System Configurations** → **Repositories**
   - Find the `fedsail:member` configuration
   - Append this configuration after the last element (note the comma is important):
   ```
   , [
         ephedra:delegateRepositoryID "metapolis";
         ephedra:serviceReference <http://www.researchspace.org/resource/system/repository/federation#metapolis>
       ]
   ```
   - Update the configuration to save changes

4. **Test Federated Query**: Now you can query using the **ephedra** repository:
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

   This federated query allows you to access Metapolis data from outside the "metapolis" repository, enabling broader integration with other data sources in your ResearchSpace instance.

### Step 4: Create new Buildings with Metapolis and connect them to the features in PostGIS

This guide will walk you through creating new Building entities in Metapolis and linking them to geographical features stored in your PostGIS database.

#### Prerequisites
- Complete Steps 1-3 to ensure proper configuration
- Ensure PostGIS database contains geographical features (buildings, monuments, etc.)
- Have feature names ready for linking

#### Step-by-Step Instructions

1. **Access the Finder**
   - Navigate to the Finder sidebar in your ResearchSpace interface
   
   ![Finder Interface](path/to/finder-screenshot.png)

2. **Create a New Building**
   - In the Finder, locate and click on **"Metapolis Building"**
   - Click the **"New Metapolis Building"** blue button to start creating a new entity

3. **Link to PostGIS Features**
   
   Your PostGIS database contains geographical features that may not yet be linked to Metapolis Building entities. For example, features like **"Galleria degli Uffizi"** might be available in the database but not yet connected.

   - In the Building creation form, find the **"Has Related Feature"** textbox
   - Start typing the name of the geographical feature (e.g., "Galleria degli Uffizi")
   - As you type, the system will search for matching features in the PostGIS database
   - Select the appropriate feature from the dropdown suggestions
   
   ![Feature Selection Interface](path/to/feature-selection-screenshot.png)

4. **Complete the Building Details**
   - Fill in additional fields (name and related entities)
   - Add any relevant metadata or relationships
   - Click **"Create Metapolis Building"** Building entity

5. **Verify the Connection**
   - The Building entity is now linked to its corresponding geographical feature in PostGIS
   - You can view the building on the map visualization components
   - The spatial data from PostGIS will be displayed for this building

#### Adding More Features

This process can be repeated for any geographical features in your PostGIS database:

- **Manual Creation**: Follow steps 1-4 for each unlinked feature
- **Batch Processing**: For multiple buildings, repeat the process systematically
- **GIS Software Integration**: You can add new geographical features using GIS software (e.g., QGIS, ArcGIS) that connects to the same PostGIS database:
  1. Use your GIS software to create or import new building footprints/features
  2. Ensure the features are stored in the appropriate PostGIS table
  3. The features will automatically become available in Metapolis
  4. Follow steps 1-4 above to create corresponding Building entities and link them

#### Tips
- Keep feature names consistent between GIS software and Metapolis for easier linking
- Use descriptive names that make features easy to identify
- Verify spatial data accuracy before linking to ensure proper map visualization
- Document any custom attributes or metadata in both the GIS database and Metapolis entities



### Next steps

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
