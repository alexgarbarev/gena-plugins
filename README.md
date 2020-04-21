# gena-plugins
iOS Development automation tasks

# Fonts

Scans a folder for custom fonts, creates a new category to access these fonts and puts into project.

# TyphoonRestClient 

In order to fill dependencies of TRC-related templates (mapping, request), install: 
```
pod 'TRCAPIClient', :git => 'git@github.com:alexgarbarev/TRCAPIClient.git'
```

# Open API

Gena can generate whole RestClient based on OpenAPI specification. 
Features:
- Automatically generates requests, mappers, value transformers for TyphoonRestClient
- Great support for enums
- Supports generic response, with allOf. Useful if your API has has common. Example:
```
responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/CommonResponse'
                  - type: object
                    properties:
                      result:
                        type: array
                        items:
                          $ref: '#/components/schemas/User'
```
Where CommonResponse is:
```
    CommonResponse:
      type: object
      required:
        - statusCode
        - message
      properties:
        statusCode:
          type: number
        message:
          type: string
        result:
          description: Can be either an object containing the response or NULL
          type: object
          format: x-generic
```
Note that `x-generic` indicates which property should be used to store generic result.

Limitations:
- Objects must be defined inside `components` section of spec. (not a response schema). As otherwiste `gena` can't find a name for an object. If your endpoint returns response object, it should be referenced to components, not inlined, like:
```
application/json:
  schema:
    "$ref": "#/components/schemas/User"
```
- Supports OpenAPI v3
