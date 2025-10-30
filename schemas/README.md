# bloomy JSON Schemas

This directory contains JSON Schema definitions for all data models in the bloomy application. These schemas serve as the **source of truth** for data structure, validation, and documentation.

## Overview

JSON Schemas provide a consistent way to define, validate, and document data structures across the application. They can be used for:

- **Code Generation**: Generate Swift models, TypeScript interfaces, or other language bindings
- **API Validation**: Validate API requests and responses
- **Documentation**: Auto-generate documentation from schemas
- **Testing**: Validate test data against expected structures
- **CloudKit Sync**: Define CloudKit record types and fields

## Schema Files

### 📄 [event.schema.json](./event.schema.json)

Defines all event types tracked in bloomy:

- **Sleep Events**: Track sleep duration, quality, and location
- **Feeding Events**: Support breast, bottle, and solid feeding with detailed metadata
- **Diaper Events**: Log diaper changes with type and consistency
- **Pumping Events**: Record breast pumping sessions with volume data

**Key Features:**
- Unified base event structure with `kind` discriminator
- Type-specific metadata for each event kind
- Support for ongoing events (null `end` time)
- Soft delete support with `isDeleted` flag
- CloudKit sync tracking with `isSynced` flag

**Example Usage:**
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "kind": "sleep",
  "start": "2025-10-28T14:30:00Z",
  "end": "2025-10-28T16:45:00Z",
  "notes": "Afternoon nap",
  "metadata": {
    "quality": "good",
    "location": "crib"
  },
  "createdAt": "2025-10-28T14:30:00Z",
  "updatedAt": "2025-10-28T16:45:00Z",
  "isSynced": true,
  "isDeleted": false
}
```

### 👶 [baby.schema.json](./baby.schema.json)

Defines the baby profile data model:

- Personal information (name, birth date, gender)
- Birth measurements (weight, height, head circumference)
- Photo data (base64 or URL)
- Medical information (pediatrician, allergies, medications)
- Parent/caregiver information

**Example Usage:**
```json
{
  "id": "623e4567-e89b-12d3-a456-426614174005",
  "name": "Emma",
  "birthDate": "2025-08-15T10:30:00Z",
  "gender": "female",
  "weight": 3.5,
  "height": 50.0,
  "metadata": {
    "parentNames": ["Anna", "John"],
    "pediatrician": {
      "name": "Dr. Smith",
      "phone": "+1-555-0123"
    }
  }
}
```

### 📏 [measurement.schema.json](./measurement.schema.json)

Defines measurement data for tracking baby's growth:

- **Types**: Height, Weight, Head Circumference
- **Units**: Metric (cm, kg) and Imperial (in, lb, oz)
- **WHO Data**: Percentile and z-score calculations
- **Metadata**: Measurement method, device, location

**Unit Validation:**
- Height/Head: `cm` or `in`
- Weight: `kg`, `lb`, or `oz`

**Example Usage:**
```json
{
  "id": "723e4567-e89b-12d3-a456-426614174006",
  "type": "weight",
  "value": 4.2,
  "unit": "kg",
  "date": "2025-10-28T10:00:00Z",
  "percentile": 50.5,
  "zScore": 0.01
}
```

### ⚙️ [app-state.schema.json](./app-state.schema.json)

Defines application state, settings, and preferences:

- **User Account**: CloudKit user information
- **Subscription**: Premium status and StoreKit data
- **Preferences**: Locale, theme, measurement system, notifications
- **Sync State**: CloudKit sync status and pending changes
- **Onboarding**: Onboarding progress tracking
- **Active Timers**: Currently running event timers

**Example Usage:**
```json
{
  "version": "1.0.0",
  "subscription": {
    "isPremium": true,
    "productId": "com.example.bloomy.premium.monthly"
  },
  "preferences": {
    "locale": "en",
    "theme": "system",
    "measurementSystem": "metric"
  }
}
```

## Examples

The [`examples/`](./examples/) directory contains valid JSON examples for each schema:

### Event Examples
- [sleep-event.example.json](./examples/sleep-event.example.json) - Sleep tracking
- [feeding-breast-event.example.json](./examples/feeding-breast-event.example.json) - Breastfeeding
- [feeding-bottle-event.example.json](./examples/feeding-bottle-event.example.json) - Bottle feeding
- [diaper-event.example.json](./examples/diaper-event.example.json) - Diaper change
- [pumping-event.example.json](./examples/pumping-event.example.json) - Breast pumping

### Other Examples
- [baby.example.json](./examples/baby.example.json) - Baby profile
- [measurement-weight.example.json](./examples/measurement-weight.example.json) - Weight measurement
- [measurement-height.example.json](./examples/measurement-height.example.json) - Height measurement
- [app-state.example.json](./examples/app-state.example.json) - Application state

## Schema Validation

All schemas follow [JSON Schema Draft 7](https://json-schema.org/draft-07/json-schema-release-notes.html) specification.

### Validating Locally

You can validate JSON data against schemas using command-line tools:

```bash
# Install ajv-cli globally
npm install -g ajv-cli

# Validate an example against a schema
ajv validate -s event.schema.json -d examples/sleep-event.example.json --spec=draft7
```

### Online Validation

You can also use online validators:
- [JSONSchemaValidator.net](https://www.jsonschemavalidator.net/)
- [JSON Schema Validator](https://www.jsonschemavalidator.net/)

## Usage in Code

### Swift Code Generation

You can use tools like [quicktype](https://quicktype.io/) to generate Swift models:

```bash
quicktype -l swift --src event.schema.json -o EventModels.swift
```

### TypeScript Interfaces

Generate TypeScript interfaces for web/React Native:

```bash
quicktype -l typescript --src event.schema.json -o event.types.ts
```

### Runtime Validation

For runtime validation in JavaScript/Node.js:

```javascript
const Ajv = require('ajv');
const ajv = new Ajv();

const eventSchema = require('./event.schema.json');
const validate = ajv.compile(eventSchema);

const data = { /* your event data */ };
const valid = validate(data);

if (!valid) {
  console.error('Validation errors:', validate.errors);
}
```

## Schema Design Principles

1. **Explicit Types**: All fields have explicit types (no implicit `any`)
2. **Required Fields**: Core fields marked as `required` in schema
3. **Validation Rules**: Use `minLength`, `maxLength`, `minimum`, `maximum` where appropriate
4. **Enums**: Use enums for fixed sets of values (e.g., event kinds, measurement types)
5. **Descriptions**: All fields include human-readable descriptions
6. **UUID Format**: All IDs use UUID v4 format with regex validation
7. **ISO 8601 Dates**: All timestamps use ISO 8601 format (`date-time`)
8. **Extensibility**: Use `metadata` objects for extensible key-value data

## Maintaining Schemas

### Adding New Fields

When adding new fields to existing schemas:

1. Add the field to the schema with proper type and description
2. Mark as optional unless it's critical (`required` array)
3. Provide a default value if applicable
4. Add examples demonstrating the new field
5. Update this README if it's a significant change

### Creating New Schemas

When creating a new schema:

1. Follow naming convention: `{entity}.schema.json`
2. Include `$schema`, `$id`, `title`, and `description`
3. Define all properties with types and descriptions
4. Create at least one example in `examples/`
5. Document the schema in this README
6. Validate the schema and examples

### Versioning

Schemas should be versioned when breaking changes are made:

- **Patch**: Adding optional fields, fixing descriptions
- **Minor**: Adding new event types, new enums
- **Major**: Removing fields, changing required fields, changing types

Track schema versions in the `$id` field or via git tags.

## CloudKit Mapping

These schemas can be used to define CloudKit record types:

### Event Record Type
```
Record Type: Event
Fields:
  - id (String, indexed)
  - kind (String, indexed)
  - start (Date/Time, indexed)
  - end (Date/Time)
  - notes (String)
  - metadata (String, JSON-encoded)
  - createdAt (Date/Time)
  - updatedAt (Date/Time)
  - isDeleted (Int64, 0 or 1)
```

### Baby Record Type
```
Record Type: Baby
Fields:
  - id (String, indexed)
  - name (String)
  - birthDate (Date/Time, indexed)
  - photoData (Asset)
  - metadata (String, JSON-encoded)
  - createdAt (Date/Time)
  - updatedAt (Date/Time)
```

## Resources

- [JSON Schema Official Site](https://json-schema.org/)
- [Understanding JSON Schema](https://json-schema.org/understanding-json-schema/)
- [JSON Schema Validator](https://www.jsonschemavalidator.net/)
- [quicktype - Generate types from JSON](https://quicktype.io/)

## Contributing

When modifying schemas:

1. Ensure backward compatibility when possible
2. Update examples to reflect schema changes
3. Validate all examples against updated schemas
4. Update this README with any significant changes
5. Run validation: `npm run validate-schemas` (if configured)

## License

These schemas are part of the bloomy project and follow the same MIT license.
