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

uint8 constant EDIT = 0x01; 
uint8 constant NETWORK = 0x02; 
uint8 constant MANAGE = 0x04; 

uint128 constant MAX_TOKENS = uint128(0) - 1;

contract Aim is Ownable, ERC20 {
	string internal tokenName; 
	string internal tokenSymbol; 

  // Aim attributes
	bool public initialized; 
	string public title; 
	string public description;
	bytes3 public color; // sowas könnte in einen key-value-store
	uint64 public effort; // in seconds
	uint16 public loopWeight; 
	mapping (address => Flow) public inflows;
  mapping (address => uint8) public permissions; 
  mapping (address => bool) public outflowApprovals; 

  constructor(address creator, uint256 amount) ERC20("erc20 field name","erc20 field symbol") {
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

		_transferOwnership(__owner);

		title = _title; 
		color = _color; 
		effort = _effort; 
		description = _description; 

		tokenName = _tokenName; 
		tokenSymbol = _tokenSymbol;
	}

	function name() public view virtual override returns(string memory) {
    return tokenName;
  }

	function symbol() public view virtual override returns(string memory) {
    return tokenSymbol;
  }

	modifier onlyEditors() {
    require(
      msg.sender == owner() || (permissions[msg.sender] & EDIT > 0),
      "sender has no permission to edit this aim"
    );
    _;
  }

  modifier onlyNetworkers() {
    require(
      msg.sender == owner() || (permissions[msg.sender] & NETWORK > 0),
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

	function getPermissions() public view returns (uint8) {
    return permissions[msg.sender];
  }

	function getInvestment() public view returns (uint256) {
    return balanceOf(msg.sender); 
  }

	function buy (
	  uint128 amount
	) public payable {
	  uint256 targetSupply = totalSupply() + amount; 
	  require(targetSupply < MAX_TOKENS, "this should never happen");
	  /* a bit more than half of all possible eth must be invested in this bonding curve 
	    for the target amount exceeding MAX_TOKENS. 
	    By this limit the following power calculations are safe */

	  uint256 currentAccumulatedPrice = totalSupply() ** 2; 
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
		require(amount <= balanceOf(msg.sender), "not enough tokens"); 

		uint256 targetSupply = totalSupply() - amount;

		uint256 currentAccumulatedPrice = totalSupply() ** 2; 
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

//	function getData() public view returns (
//	  string memory title_, 
//    string memory description_, 
//    uint16 loopWeight_, 
//    uint8 permissions_,
//    uint64 effort_,
//    bytes3 color_
//	) {
//	  return (title, description, loopWeight, permissions, effort, color);
//  }
//
//  function getInflows() public view returns (Flow [] inflows_) {
//    return ;
//  }
}	

