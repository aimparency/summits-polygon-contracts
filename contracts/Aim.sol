//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1; 

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/Ownable.sol"

// enum Rights {
// 	ALL, 
// 	MANAGE, 
// 	MODIFY
// }

/* Do not allow your master contract to be self-destructed as it will cause all clones to stop working, thus freezing their state and balances. */

struct Flow {
	bool exists;
	string explanation;
	// uint8[][] explanationChanges; // save delta
	uint16 weight;
	bytes4 dx; // float32
	bytes4 dy; 
}

contract IAim {
  function aimType() returns string {
    return 'base'
  }
  
}

contract Aim is IAim, Ownable, ERC20 {
	string title; 
	string readme;
	bytes3 color;
	uint64 effort; // in seconds

	uint16 loopWeight; 

	bool initialized; 

	mapping (address => Flow) flowsFrom;

  uint constant _initial_supply = (7 ** 12) * (10**18);
  uint256 constant _max_shares = 2 ** 128 - 1;

	mapping (uint128 => Aim) public aims; 
	mapping (uint128 => mapping(uint128 => Flow)) public flows; // from into
	mapping (address => uint128) public homes; 

  constructor(address felix, uint256 amount) ERC20("Summits", "MM") {
      _mint(felix, amount);
      console.log("minted initial supply");
      // hier im Konstruktor kann ich mir selbst tokens zuschreiben ohne sie zu bezahlen. Perks of creating systems. Denn der Konstruktor wird nur 
  }

  function init(
    address owner, 
    string _title, 
    string _initialDescription, 
    uint64 _effort, 
    bytes3 _color, 
    uint256 _initialShares, 
  ) {
    require(!initialized, "aim already initialized") 
  }

	function createAim(
		uint128 aimId, 
		string calldata title, 
		bytes3 color, 
		uint64 calldata effort, 
		string calldata detailsCid, 
		uint128 initialShares
	) public {
		Aim storage a = aims[aimId]; 

		require(!a.exists, "Aim with this id exists. Use other aimId."); 

		uint256 initialDeposit = uint256(initialShares) * initialShares; 

		_transfer(msg.sender, address(this), initialDeposit); 

		a.exists = true; 

		a.owner = msg.sender; 

		a.title = title; 
		a.color = color; 
		a.effort = effort; 
		a.detailsCid = detailsCid; 

		a.sharesTook = initialShares;
		a.shares[msg.sender] = initialShares; 
	}

	function removeAim(
		uint128 aimId
	) public {
		Aim storage a = aims[aimId];
		require(a.exists, "No aim with this id exists"); 
		a.exists = false;
	}

	function requireExistingOwnedAim(
		uint128 aimId
	) internal view returns (Aim storage) {
		Aim storage a = aims[aimId];
		require(a.exists, "No aim with this id exists");
		require(a.owner == msg.sender, "Sender does not own this aim");
		return a;
	}

	function updateAimTitle(
		uint128 aimId, 
		string calldata title
	) public {
		requireExistingOwnedAim(aimId).title = title;
	}

	function updateAimColor(
		uint128 aimId, 
		bytes3 color
	) public {
		requireExistingOwnedAim(aimId).color = color;
	}

	function updateAimEffort(
		uint128 aimId, 
		Effort calldata effort
	) public {
		requireExistingOwnedAim(aimId).effort = effort;
	}

	function updateAimDetailsCid(
		uint128 aimId, 
		string calldata detailsCid
	) public {
		requireExistingOwnedAim(aimId).detailsCid = detailsCid;
	}

	function updateAim(
		uint128 aimId, 
		string calldata title, 
		bytes3 color, 
		Effort calldata effort, 
		string calldata detailsCid
	) public {
		Aim storage a = requireExistingOwnedAim(aimId); 
		a.title = title;
		a.color = color; 
		a.effort = effort;
		a.detailsCid = detailsCid;
	}
		
	function deposit(
		uint128 aimId, 
		uint128 amount, 
		uint128 current
	) public {
		Aim storage a = aims[aimId]; 

		require(a.exists, "No aim with this id exists."); 
		require(a.sharesTook <= current, "Shares price rose. You might want to try again"); 
		require(uint256(amount) + a.sharesTook <= _max_shares, "Max amount of shares exceeded. Buy less."); 
	
		uint256 targetDeposit = uint256(amount) * amount; 
		uint256 currentDeposit = uint256(a.sharesTook) * a.sharesTook; 

		_transfer(msg.sender, address(this), targetDeposit - currentDeposit);

		a.sharesTook += amount; 
		a.shares[msg.sender] += amount; 
	}

	function withdraw(
		uint128 aimId, 
		uint128 amount, 
		uint128 current
	) public {
		Aim storage a = aims[aimId]; 

		require(a.exists, "No aim with this id exists."); 
		require(a.sharesTook >= current, "Shares price dropped. You might want to try again."); 
		require(amount <= a.shares[msg.sender], "Not enough shares. Withdraw less."); 
	
		uint256 targetDeposit = uint256(amount) * amount; 
		uint256 currentDeposit = uint256(a.sharesTook) * a.sharesTook; 

		_transfer(msg.sender, address(this), targetDeposit - currentDeposit);

		a.sharesTook += amount; 
		a.shares[msg.sender] += amount; 
	}

	function createFlow(
		uint128 fromAimId, 
		uint128 intoAimId, 
		uint16 share, 
		string calldata detailsCid, 
		bytes4 dx, 
		bytes4 dy
	) public {
		Aim storage intoAim = requireExistingOwnedAim(intoAimId);
		Aim storage fromAim = aims[fromAimId]; 
		require(fromAim.exists, "Flow source aim does not exist."); 
		Flow storage flow = flows[fromAimId][intoAimId];
		require(!flow.exists, "Flow exists.");

		flow.exists = true;
		flow.share = share;
		flow.detailsCid = detailsCid;
		flow.dx = dx;
		flow.dy = dy;

		intoAim.flowsFrom.push(fromAimId);
		fromAim.flowsInto.push(intoAimId);
	}

	function transferOwnership(
    uint128 aimId, 
    address newOwner
  ) public {
    Aim storage aim = requireExistingOwnedAim(aimId); 
    aim.owner = newOwner;
  }

	function removeFlow(
		uint128 fromAimId, 
		uint128 intoAimId
	) public {
		requireExistingOwnedAim(intoAimId);
		require(aims[fromAimId].exists, "Flow source aim does not exist."); 
		Flow storage flow = flows[fromAimId][intoAimId];
		require(flow.exists, "Flow does not exist.");
		flow.exists = false;
	}

	function setHome(uint128 aimId) public {
		homes[msg.sender] = aimId;
	}
}	

