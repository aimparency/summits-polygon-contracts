const genPermutations = require('./gen-update-permutations')

genPermutations(
  "Flow", 
  [
    ["explanation", "string calldata"],
    ["d2d", "bytes4"]
  ], 
  ["address _from"],
  ["FlowData storage flowData = inflows[_from].data"], 
  "flowData"
)

