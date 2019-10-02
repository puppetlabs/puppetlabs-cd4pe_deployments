# cd4pe_deployments

//TODO:
- get information about the environment deployments will be running in (available vars, restrictions, secrets manaagement, etc)
- figure out the development section, how will others develop new policies and test them?

#### Table of Contents

1. [Description](#description)
2. [Usage - Configuration options and additional functionality](#usage)
3. [Reference](#reference)
4. [Development - Guide for contributing to the module](#development)

## Description

This module provides a set of tools, via CD4PE, for creating your own custom CD4PE deployment policies. It is also a place to find a set of generic policies.

## Usage

1. Get started with a custom deployment policy by creating a [Puppet Plan] in the `plans/` directory.
2. You'll have access to all of the functions listed in our [REFERENCE.md]() to perform deployment operations (e.g. pinning nodes to an environment group or getting information about an environment group)
3. Deployment policies will run inside a CD4PE context with certain environment variables available.

```
myplan.yaml

plan cd4pe_deployments::myplan(

) {


}
```

## Reference

### CD4PEFunctionResult

Most functions available in this module will always return a [CD4PEFunctionResult] that contains:
- result
- error: { message, code }

#### Example success result
```ruby
{
  result: {
    approvalDecision: "APPROVED"
  },
  error: nil
}
```

#### Example error result
```ruby
{
  result: nil,
  error: {
    message: "Something went wrong",
    code: "SomeErrorCode",
  }
}
```

#### Error Codes
- `ParameterMissing`
  - The CD4PE API was expecting a parameter that was not provided.
- `ParameterParsing`
  - The CD4PE API was unable to parse the provided parameter value.
- `FunctionFailure`
  - CD4PE was unable to complete the function's primary purpose (e.g. run_puppet() failed to run Puppet)
  
#### Usage
```puppet
$result = get_node_group('abcd-1234-efgh-56789')

if($result[error]){
  fail_plan("Could not get node group! ${result[error][message]}")
}
```

See our [REFERENCE.md]() for reference documentation.

## Development

TBD


[Puppet Plan]:https://puppet.com/docs/bolt/latest/writing_plans.html
[CD4PEFunctionResult]:lib/puppet_x/puppetlabs/cd4pe_function_result.rb