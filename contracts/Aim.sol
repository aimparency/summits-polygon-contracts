//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1; 

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

uint8 constant EDITOR = 1; 
uint8 constant NETWORKER = 2; 
uint8 constant MANAGER = 4; 

uint128 constant MAX_TOKENS = uint128(0) - 1;

contract Aim is Ownable, ERC20 {
  // make Ownable attributes accessible
  address private _owner;

  // make ERC20 attributes accessible
  mapping(address => uint256) private _balances;
  uint256 private _totalSupply;
	string private _name; 
	string private _symbol; 

  // Aim attributes

	string title; 
	string description;
	bytes3 color; // sowas könnte in einen key-value-store
	uint64 effort; // in seconds

	uint16 loopWeight; 

	mapping (address => Flow) inflows;

	bool initialized; 
  bool deleted; 

  mapping (address => uint8) permissions; 

  constructor(address creator, uint256 amount) ERC20("","") {
    _mint(creator, amount);
  }

  function init(
    address __owner, 
    string calldata _title, 
    string calldata _description, 
    uint64 _effort, 
    bytes3 _color, 
    string calldata _tokenName,
    string calldata _tokenSymbol
  ) public {
    require(!initialized, "aim already initialized");
    initialized = true; 

		_owner = __owner; 

		title = _title; 
		color = _color; 
		effort = _effort; 
		description = _description; 

		_name = _tokenName; 
		_symbol = _tokenSymbol;
	}

	modifier onlyEditors() {
    require(
      msg.sender == _owner || (permissions[msg.sender] & EDITOR > 0),
      "sender has no permission to edit this aim"
    );
    _;
  }

  modifier onlyNetworkers() {
    require(
      msg.sender == _owner || (permissions[msg.sender] & NETWORKER > 0),
      "sender has no permission to change flows"
    );
    _;
  }

	function updateTitle(
		string calldata _title
	) public onlyEditors {
		title = _title;
	}

	function updateColor(
		bytes3 _color
	) public onlyEditors {
		color = _color;
	}

	function updateEffort(
		uint64 _effort
	) public onlyEditors {
		effort = _effort;
	}

	function updateDetailsCid(
		string calldata _description 
	) public onlyEditors {
		description = _description;
	}

	function buy (
	  uint128 amount
	) public payable {
	  uint256 targetSupply = _totalSupply + amount; 
	  require(targetSupply < MAX_TOKENS, "this should never happen");
	  /* a bit more than half of all possible eth must be invested in this bonding curve 
	    for the target amount exceeding MAX_TOKENS. 
	    By this limit the following power calculations are safe */

	  uint256 currentAccumulatedPrice = _totalSupply ** 2; 
		uint256 targetAccumulatedPrice = targetSupply ** 2;

		uint256 price = targetAccumulatedPrice - currentAccumulatedPrice; 

		require(price <= msg.value, "insufficient eth sent"); 

		if(msg.value == price || payable(msg.sender).send(msg.value - price)) {
      _mint(msg.sender, amount);
    } else {
      revert("eth sent exceeds price and sender not payable");
    }
	}

	function withdraw(
	  uint128 amount, 
		uint256 minPayout
	) public {
		require(amount <= _balances[msg.sender], "not enough tokens"); 

		uint256 targetSupply = _totalSupply - amount;

		uint256 currentAccumulatedPrice = _totalSupply ** 2; 
		uint256 targetAccumulatedPrice = targetSupply ** 2; 
		
		uint256 payout = currentAccumulatedPrice - targetAccumulatedPrice; 

		require(payout >= minPayout, "price dropped");

    if(payable(msg.sender).send(payout)) {
      _burn(msg.sender, amount); 
    } else {
      revert("sender not payable");
    }
	}

	function createInflow(
		address _from, 
		string calldata _explanation,
		uint16 _weight, 
		bytes4 dx, 
		bytes4 dy
	) public onlyNetworkers {
		Flow storage flow = inflows[_from];

		require(!flow.exists, "flow already exists");

		flow.exists = true;

		flow.weight = _weight;
		flow.explanation = _explanation;
		flow.dx = dx;
		flow.dy = dy;
	}

	function removeInflow(
		address _from
	) public onlyNetworkers {
	  inflows[_from].exists = false;  
	}
}	

