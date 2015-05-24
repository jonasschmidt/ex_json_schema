* Check schema version when resolving a schema
* Enable validating the schema against its meta schema as well
* Return validation errors and not just a boolean
* Only require Poison and HTTPoison dependencies in test/development (schema resolving needs a callback for fetching and parsing remote schemata)
* Add URLs resolved in remote schemata to root's refs
* Make sure properties, items etc. are only validated once
* Enable providing JSON for known schemata at resolve time
