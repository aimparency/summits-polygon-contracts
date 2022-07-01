
module.exports = function(prefix, vars, additionalParams, additionalLines, objName) {
  let combinations = [[]]
  let capitalizedVars = []
  for(let i = 0; i < vars.length; i++) {
    let varName = vars[i][0]
    capitalizedVars[i] = varName[0].toUpperCase() + varName.slice(1) 
    combinations.push(...combinations.map(a => a.concat(i)))
  }

  for(let i = 1; i < combinations.length; i++) {
    const combination = combinations[i]
    console.log(`
	function update${prefix}${combination.map(j => capitalizedVars[j]).join("")}(
	  ${additionalParams.concat(combination.map(j => vars[j][1] + " _" + vars[j][0])).join(",\n\t  ")}
	) public onlyEditors {
	  ${additionalLines.concat(combination.map(j => `${objName}.${vars[j][0]} = _${vars[j][0]}`)).join(";\n\t  ")};
	}`)
  }
}

