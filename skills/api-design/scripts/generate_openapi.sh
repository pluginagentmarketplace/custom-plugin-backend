#!/bin/bash
# Generate OpenAPI specification from FastAPI app
# Usage: ./generate_openapi.sh

set -e

OUTPUT_FILE=${1:-"openapi.json"}

echo "Generating OpenAPI specification..."

python -c "
import json
from app.main import app

openapi_schema = app.openapi()
with open('$OUTPUT_FILE', 'w') as f:
    json.dump(openapi_schema, f, indent=2)
print('OpenAPI spec written to $OUTPUT_FILE')
"

echo "Done!"
