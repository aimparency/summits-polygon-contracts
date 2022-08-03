const genPermutations = require('./gen-update-permutations')

genPermutations(
  "Flow", 
  [
    ["explanation", "string calldata"],
    ["weight", "uint16"], 
    ["d2d", "bytes8"]
  ], 
  ["address _from"],
  ["FlowData storage flowData = inflows[_from].data"], 
  "flowData", 
  "onlyNetworkers"
)

