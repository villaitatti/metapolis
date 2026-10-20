This page describes the Metapolis data model: the ontology, the ResearchSpace entity configurations, the Knowledge Patterns that define the form fields, the four entity forms, and how a Building is linked to its geometry.

**See also:** [Relations](Relations) · [PostGIS and SQL Sail](PostGIS-and-SQL-Sail) · [Installation and Setup](Installation-and-Setup)

## Contents

- [Overview](#overview)
- [Namespaces](#namespaces)
- [The configuration files](#the-configuration-files)
  - [Metapolis_Ontology.trig](#metapolis_ontologytrig)
  - [Metapolis_Entity.trig](#metapolis_entitytrig)
  - [Metapolis_KP.trig](#metapolis_kptrig)
- [How a form is built](#how-a-form-is-built)
- [Building](#building)
  - [Linking a Building to its geometry](#linking-a-building-to-its-geometry)
- [Event](#event)
- [Person](#person)
- [Source](#source)
- [Relations](#relations)
- [Extending the model](#extending-the-model)
- [Known issues](#known-issues)
- [Troubleshooting](#troubleshooting)

---

## Overview

Metapolis has four entity types, all subclasses of `metapolis_ontology:Metapolis_Entity`:

| Entity | Class | Form | Subject IRI pattern |
|---|---|---|---|
| Building | `metapolis_ontology:Building` | `metapolis_forms:Building` | `http://metapolis.com/resource/building/{UUID}` |
| Event | `metapolis_ontology:Event` | `metapolis_forms:Event` | `http://metapolis.com/resource/event/{UUID}` |
| Person | `metapolis_ontology:Person` | `metapolis_forms:Person` | `http://metapolis.com/resource/person/{UUID}` |
| Source | `metapolis_ontology:Source` | `metapolis_forms:Source` | `https://metapolis.com/resource/source/{UUID}` |

Entities are linked to each other through **Relation** entities (`metapolis_ontology:Relation`, IRIs `https://metapolis.com/resource/relation/{UUID}`), described in [Relations](Relations).

Fields use [CIDOC-CRM](https://cidoc-crm.org/) where possible (appellations, time-spans, births, productions, presences). All data created with the forms is written to the named graph `http://www.researchspace.org/resource/g/data` of the `default` repository. Geometries are **not** stored in the triple store: they stay in the backend (PostGIS by default) and are referenced by IRI.

## Namespaces

Defined in `config/namespaces.prop` of the app:

| Prefix | Namespace |
|---|---|
| `metapolis_ontology` | `http://metapolis.com#` |
| `metapolis_forms` | `http://metapolis.com/forms/` |

Other IRIs used by the data:

| IRI | Used for |
|---|---|
| `http://metapolis.com/resource/type/{Building,Event,Person,Source}` | `crm:P2_has_type` of each entity |
| `http://metapolis.com/resource/function/{government,religious,cultural,commercial,military}` | Building functions |
| `http://metapolis.com/resource/feature/<building_id>` | A geometry (row of `metapolis.buildings`, or feature in a SPARQL backend) |
| `http://metapolis.com/vocabulary/{given_name,family_name,patronymic,source_title}` | Types of the `E41_Appellation` names |

## The configuration files

The model is defined in three files in `metapolis_setup/configurations/`. How to import them is described in [Installation and Setup, Step 5](Installation-and-Setup#step-5-import-the-metapolis-configuration).

### Metapolis_Ontology.trig

An OWL ontology with namespace `http://metapolis.com#`:

- the root class `metapolis_ontology:Metapolis_Entity`;
- its subclasses `Building` (physical structures), `Event` (historical events), `Person` (historical persons) and `Source` (documentary sources), with English labels.

Import it first, in **Data Import & Download**, with **Keep source named graphs** checked.

### Metapolis_Entity.trig

The ResearchSpace **resource configurations** "Metapolis Building / Event / Person / Source configuration". For each entity it sets:

- the resource name shown in the UI (e.g. "Metapolis Building");
- the ontology class (`resource_ontology_class`);
- the form (`resource_form`, e.g. `metapolis_forms:Building`);
- the search view type (list);
- a Finder navigation item, so the entity appears in the Finder sidebar;
- creation/modification records (CIDOC-CRM / CRMdig).

Import it after the ontology, in **Data Import & Download**, with **Keep source named graphs** checked.

### Metapolis_KP.trig

The **Knowledge Patterns** (field definitions) used by the forms, all in the category **Metapolis**, with IRIs `http://www.researchspace.org/pattern/<id>`. Each KP has a select, insert and delete pattern (and, where needed, a value-set or autosuggestion pattern).

| Group | Knowledge Patterns |
|---|---|
| Building | `building_has_function`, `physical_change_presence`, `physical_change_has_time-span`, `physical_change_bob`, `physical_change_eoe`, `physical_change_2d_representation` |
| Person | `person_name`, `person_surname`, `person_patronymic`, `person_birth_date`, `person_death_date` |
| Source | `source_title`, `source_production_date` |
| Dates | `time_primitive_day`, `time_primitive_month`, `time_primitive_year` |
| Relations | `entity_is_domain_of_relation_{building,event,person,source}`, `entity_is_range_of_relation_{…}`, `relation_has_domain_{…}`, `relation_has_range_{…}` |

Import it in **System Settings → Knowledge Patterns**. `setup.sh` cannot import it.

## How a form is built

The forms are templates in the app (`data/templates/http%3A%2F%2Fmetapolis.com%2Fforms%2F<Entity>.html`). Each is a `semantic-form` that:

- stores data with `persistence='{"type": "sparql", "targetInsertGraphIri": "http://www.researchspace.org/resource/g/data", "repository":"default"}'`;
- mints new subjects with `new-subject-template` (e.g. `http://metapolis.com/resource/building/{{UUID}}`);
- loads its fields from the Knowledge Patterns with the `fieldDefinitions` helper:

  ```html
  fields='[[fieldDefinitions
    type                  = "http://www.w3.org/2000/01/rdf-schema#type"
    has_type              = "http://www.cidoc-crm.org/cidoc-crm/P2_has_type"
    has_label             = "http://www.w3.org/2000/01/rdf-schema#label"
    building_has_function = "http://www.researchspace.org/pattern/building_has_function"
    ...
  ]]'
  ```

- sets the class and type with hidden inputs:

  ```html
  <semantic-form-hidden-input for="type" default-values='["http://metapolis.com#Building"]'></semantic-form-hidden-input>
  <semantic-form-hidden-input for="has_type" default-value="http://metapolis.com/resource/type/Building"></semantic-form-hidden-input>
  ```

- renders each field with a `semantic-form-*-input` whose `for` attribute is the field name.

Nested structures (time-spans, names, relations) use `semantic-form-composite-input`, which creates a new resource with its own fields and links it to the parent through the composite's field.

## Building

| Field | Label | Input | Stored as |
|---|---|---|---|
| `has_label` | Name | text | `rdfs:label` |
| `building_has_function` | Function | select | `metapolis_ontology:has_function` → one of the function IRIs (Government, Religious, Cultural, Commercial, Military) |
| `physical_change_presence` | Presences / Physical Phase | two nested composites | `crm:P166i_had_presence` → an `E92_Spacetime_Volume`, which in turn `crm:P166i_had_presence` → an `E93_Presence` (the physical phase) |
| `physical_change_has_time-span` | – | composite, inside the phase | `crm:P4_has_time-span` → `E52_Time-Span` |
| `physical_change_bob` | Begin | datetime | `crm:P82a_begin_of_the_begin` on the time-span |
| `physical_change_eoe` | End | datetime | `crm:P82b_end_of_the_end` on the time-span |
| `physical_change_2d_representation` | 2D Representation | autocomplete, inside the presence | see below |
| relations | Events / People / Sources tabs | composite + drag and drop | see [Relations](#relations) |

### Linking a Building to its geometry

The **2D Representation** field connects the semantic Building to a footprint in the backend.

Its **autosuggestion pattern** queries the backend live through the Ephedra federation, and turns each row into a feature IRI:

```sparql
PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>

SELECT ?value ?label WHERE {
  SERVICE <http://www.researchspace.org/resource/system/repository/federation#metapolis> {
    ?s rs_sql_sail:hasQueryId "all_buildings";
       metapolis_sql:building_id ?building_id;
       metapolis_sql:name ?name;
       metapolis_sql:function ?function;
       metapolis_sql:wkt ?wkt
  }
  BIND(?name as ?label)
  BIND(URI(CONCAT("http://metapolis.com/resource/feature/", STR(?building_id))) as ?value)
  FILTER REGEX(STR(?label), "?token", "i")
} LIMIT 100
```

Its **insert pattern** creates a representation node on the physical phase (`E93_Presence`):

```sparql
INSERT {
  $subject crm:P138i_has_representation ?representation.
  ?representation crm:P2_has_type <https://veniss.net/ontology#2d_representation>.
  ?representation rdfs:label $value.
} WHERE {
  BIND (IRI(CONCAT(STR($subject), "2drepresentation/", STRUUID())) AS ?representation)
}
```

So the chosen feature IRI (`http://metapolis.com/resource/feature/<building_id>`) is stored as the label of a `2d_representation` node. To find the geometry of a Building, follow `P166i_had_presence` / `P166i_had_presence` → `P138i_has_representation` → `rdfs:label`, extract the `building_id` from the IRI and query `building_by_id` (PostGIS) or the feature IRI (SPARQL backends).

This requires the federation ([Installation, Step 4](Installation-and-Setup#step-4-add-metapolis-to-the-ephedra-federation)). If the field never suggests anything, the federation is missing or the backend is empty.

## Event

| Field | Label | Input | Stored as |
|---|---|---|---|
| `has_label` | Title | text | `rdfs:label` |
| `event_description` | Description | textarea | see [Known issues](#known-issues) |
| relations | Buildings / People / Sources tabs | composite + drag and drop | see [Relations](#relations) |

## Person

| Field | Label | Stored as |
|---|---|---|
| `person_name` | Name | `crm:P1_is_identified_by` → `E41_Appellation` typed `…/vocabulary/given_name`, with `rdfs:label` (IRI `<subject>/given_name`) |
| `person_surname` | Surname | same, typed `…/vocabulary/family_name` (IRI `<subject>/family_name`) |
| `person_patronymic` | Patronymic | same, typed `…/vocabulary/patronymic` (IRI `<subject>/patronymic`) |
| `person_birth_date` | Birth date | `crm:P98i_was_born` → `E67_Birth` → `crm:P4_has_time-span`, with day / month / year time primitives |
| `person_death_date` | Death date | the same pattern for the death |
| relations | Buildings / Events / Sources tabs | see [Relations](#relations) |

The date composites use `time_primitive_day`, `time_primitive_month` and `time_primitive_year`: each stores an `E61_Time-Primitive` (`crm:P170i_time_is_defined_by`) with the value as `rdfs:label` and a type for day, month or year.

## Source

| Field | Label | Input | Stored as |
|---|---|---|---|
| `source_title` | Title | text | `crm:P1_is_identified_by` → `E41_Appellation` typed `…/vocabulary/source_title`. The hidden `has_label` copies the title into `rdfs:label` |
| `P108i_was_produced_by` | Author | tree picker over `metapolis_ontology:Person` | `crm:P108i_was_produced_by` |
| `source_production_date` | Production date | composite (day / month / year) | `crm:P108i_was_produced_by` → `E12_Production` → `crm:P4_has_time-span` |
| relations | Buildings / Events / People tabs | composite + drag and drop | see [Relations](#relations) |

## Relations

Every form has tabs for the three other entity types. Each tab has **Outgoing relations** (the current entity is the domain) and **Incoming relations** (the current entity is the range). A relation is its own resource, of type `metapolis_ontology:Relation`, with:

- a domain and a range, picked by drag and drop or created inline with a nested form;
- **Notes** (`rdfs:label`).

The full mechanism and the SPARQL patterns are in [Relations](Relations).

## Extending the model

To add an entity type (e.g. `Place`):

1. Add the class to `Metapolis_Ontology.trig`, as a subclass of `metapolis_ontology:Metapolis_Entity`.
2. Create its form in the app, in `data/templates/http%3A%2F%2Fmetapolis.com%2Fforms%2FPlace.html`, using an existing form as a template (new subject template, hidden `type`/`has_type`, fields).
3. Add an entity configuration to `Metapolis_Entity.trig` that points to the class and to `metapolis_forms:Place`, and adds it to the Finder. The easiest way is to create it in the ResearchSpace UI and export it.
4. Add any new fields as Knowledge Patterns, in the **Metapolis** category, and export them into `Metapolis_KP.trig`.
5. If the new type takes part in relations, add the four relation KPs for it and the corresponding tabs in the other forms ([Relations](Relations#adding-a-new-entity-type-to-relations)).
6. Re-import the changed `.trig` files (`./setup.sh --rs-url … --reimport` for ontology and entities; Knowledge Patterns by hand).

To add a field to an existing form, create the Knowledge Pattern, add it to the form's `fieldDefinitions`, and add an input with `for="<field id>"`.

## Known issues

- **Event description**: the Event form renders a `event_description` textarea, but there is no `event_description` entry in its `fieldDefinitions` nor a Knowledge Pattern with that ID, so the description is not saved. Add a KP (e.g. with `crm:P3_has_note`) and register it in the form.
- **Building–Building relations**: the KPs `entity_is_domain_of_relation_building` / `entity_is_range_of_relation_building` are declared in the Building form, but the form has no tab that uses them.
- **Function values**: the Building form stores function **IRIs** (`…/function/religious`), while the backend stores function **strings** (`Religious`) used by the map colours. They are not linked automatically.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| The Finder sidebar has no Metapolis entries | `Metapolis_Entity.trig` was not imported ([Step 5](Installation-and-Setup#step-5-import-the-metapolis-configuration)) |
| A form shows errors or empty fields | `Metapolis_KP.trig` was not imported, or a field ID in `fieldDefinitions` does not match a Knowledge Pattern IRI |
| **2D Representation** never suggests anything | The Ephedra federation is missing ([Step 4](Installation-and-Setup#step-4-add-metapolis-to-the-ephedra-federation)) or the backend is empty |
| A field is shown but its value is not saved | The input's `for` is not declared in `fieldDefinitions`, or its Knowledge Pattern has no insert pattern (see [Known issues](#known-issues)) |
| Classes or properties show as raw IRIs | `Metapolis_Ontology.trig` was not imported |
