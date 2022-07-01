const genPermutations = require('./gen-update-permutations')

genPermutations(
  "Aim", 
  [
    ["title", "string calldata"],
    ["description", "string calldata"],
    ["status", "string calldata"],
    ["effort", "uint64"],
    ["color", "bytes3"]
  ], 
  [],
  [], 
  "data"
)
