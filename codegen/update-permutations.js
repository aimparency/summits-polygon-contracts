const vars = [
  ["title", "string calldata"],
  ["description", "string calldata"],
  ["status", "string calldata"],
  ["effort", "uint64"],
  ["color", "bytes3"]
]

/* 0
 * 0, 1
 * 0, 1, 2
 * 0, 1, 2, 3
 * ...
 * 0, 1, 2, 3, n
 *
 * 0, 2
 * 0, 2, 3
 * ...
 * 0, 2, 3, n
 *
 * 0, 3
 * ...
 * 0, 3, n
 *
 * 1
 * 1, 2, 
 * 1, 2, 3, 
 * ...
 * 1, 2, 3, n
 */

let combinations = [[]]
let capitalizedVars = []
for(let i = 0; i < vars.length; i++) {
  let varName = vars[i][0]
  capitalizedVars[i] = varName[0].toUpperCase() + varName.slice(1) 
  combinations.push(...combinations.map(a => a.concat(i)))
}

//console.log(combinations)
//console.log(capitalizedVars)

for(let i = 1; i < combinations.length; i++) {
  const combination = combinations[i]
  let params = []
  let setters = []
  for(let j of combination) {
    let varName = j
    params.push()
    setters.push()
    
  }
  console.log(`
	function update${combination.map(j => capitalizedVars[j]).join("")}(
	  ${combination.map(j => vars[j][1] + " _" + vars[j][0]).join(",\n\t  ")}
	) public onlyEditors {
	  ${combination.map(j => "data." + vars[j][0] + " = _" + vars[j][0]).join(";\n\t  ")}
	}`)
}

