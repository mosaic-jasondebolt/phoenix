### Best Practices
#### Consistency
* Please be consistent with naming conventions. Seriously. If you are unsure
how to name something like a CloudFormation Resource, Output Export Name, a
Parameter, or anything else, then please refer to existing code or ask someone
who knows. Consistency in naming conventions helps significantly with refactoring,
renaming, readability, seeing patterns arise, building abstractions, and detecting bugs.
Even if we do it differently than everyone else, consistency within the codebase
trumps all external conventions or style guides.

#### Stack Exports
* Use the pattern of {ProjectName}-{AWS service or function}-{Environment}-{Resource}. Here's an example:
```
"Outputs": {
    "EndpointAddress": {
      "Export": {
        "Name": {
          "Fn::Join": ["-", [
            {"Ref": "ProjectName"},
            "database",
            {"Ref": "Environment"},
            "EndpointAddress"
          ]]
        }
      },
      "Value": {
        "Fn::GetAtt": ["RDSCluster", "Endpoint.Address"]
      }
    }
  }
```
