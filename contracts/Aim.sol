//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9; 

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
	uint16 weight;
	bytes4 dx; // float32
	bytes4 dy; 
}

uint8 constant EDIT = 0x01; 
uint8 constant NETWORK = 0x02; 
uint8 constant MANAGE = 0x04; 

uint128 constant MAX_TOKENS = 0xffffffffffffffffffffffffffffffff;

contract Aim is Ownable, ERC20 {
	string internal tokenName; 
	string internal tokenSymbol; 

	bool public initialized; 

	string public title; 
	string public description;
	string public state;
	uint64 public effort; 
	bytes3 public color; // sowas könnte in einen key-value-store

	uint16 public loopWeight; 

  mapping (address => uint8) public permissions; 

	address [] inflowAddresses; 
	mapping (address => Flow) public inflows;

  constructor(address creator, uint128 initialAmount) payable ERC20("", "") {
    require(msg.value == uint256(initialAmount) ** 2); 
    _mint(creator, initialAmount);
    title = "aimparency"; 
    description = "an efficient socioeconomic system"; 
    tokenName = "aimparencent";
    tokenSymbol = "MPRNC";
  }

  event FlowCreation(address from, address to); 
  event FlowRemoval(address from, address to); 

  function init(
    address creator, 
    string calldata _title, 
    string calldata _tokenName,
    string calldata _tokenSymbol,
    uint128 initialAmount
  ) public payable {
    require(!initialized, "aims can only be initialized once");
    require(
      uint256(initialAmount) * initialAmount == msg.value, 
      "initial investment requires funds to equal the square of initial token amount"
    ); 

    initialized = true; 

		_transferOwnership(creator);

		title = _title; 

		tokenName = _tokenName; 
		tokenSymbol = _tokenSymbol;

    _mint(creator, initialAmount);
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

  // updateTitleDescriptionStateEffortColor - update permutations begin

	function updateTitle(
		string calldata _title
	) public onlyEditors {
		title = _title;
	}

	function updateTitleDescription(
		string calldata _title,
		string calldata _description 
	) public onlyEditors {
		title = _title;
		description = _description;
	}

	function updateTitleDescriptionState(
		string calldata _title,
		string calldata _description,
		string calldata _state
	) public onlyEditors {
		title = _title;
		description = _description;
		state = _state;
	}

	function updateTitleDescriptionStateEffort(
		string calldata _title,
		string calldata _description,
		string calldata _state,
		uint64 _effort
	) public onlyEditors {
		title = _title;
		description = _description;
		state = _state;
		effort = _effort;
	}

	function updateTitleDescriptionStateEffortColor(
		string calldata _title,
		string calldata _description,
		string calldata _state,
		uint64 _effort,
		bytes3 _color
	) public onlyEditors {
		title = _title;
		description = _description;
		state = _state;
		effort = _effort;
		color = _color;
	}

	
	function updateDescription(
		string calldata _description 
	) public onlyEditors {
		description = _description;
	}

	function updateDescriptionState(
		string calldata _description,
		string calldata _state
	) public onlyEditors {
		description = _description;
		state = _state;
	}

	function updateDescriptionStateEffort(
		string calldata _description,
		string calldata _state,
		uint64 _effort
	) public onlyEditors {
		description = _description;
		state = _state;
		effort = _effort;
	}

	function updateDescriptionStateEffortColor(
		string calldata _description,
		string calldata _state,
		uint64 _effort,
		bytes3 _color
	) public onlyEditors {
		description = _description;
		state = _state;
		effort = _effort;
		color = _color;
	}


	function updateState(
		string calldata _state
	) public onlyEditors {
		state = _state;
	}

	function updateStateEffort(
		string calldata _state,
		uint64 _effort
	) public onlyEditors {
		state = _state;
		effort = _effort;
	}

	function updateStateEffortColor(
		string calldata _state,
		uint64 _effort,
		bytes3 _color
	) public onlyEditors {
		state = _state;
		effort = _effort;
		color = _color;
	}


	function updateEffort(
		uint64 _effort
	) public onlyEditors {
		effort = _effort;
	}

	function updateEffortColor(
		uint64 _effort,
		bytes3 _color
	) public onlyEditors {
		effort = _effort;
		color = _color;
	}


	function updateColor(
		bytes3 _color
	) public onlyEditors {
		color = _color;
	}

	// update permutations end



	function getPermissions() public view returns (uint8) {
    return permissions[msg.sender];
  }

	function getInvestment() public view returns (uint256) {
    return balanceOf(msg.sender); 
  }

	function buy (
	  uint128 amount
	) public payable {
	  console.log("buying", amount, tokenSymbol); 
	  uint256 targetSupply = totalSupply() + amount; 
	  require(targetSupply < MAX_TOKENS, "");
	  /* a bit more than half of all possible eth must be invested in this bonding curve 
	    for the target amount exceeding MAX_TOKENS. 
	    By this limit the following power calculations are safe */

	  console.log("targetSupply", targetSupply); 

	  uint256 currentAccumulatedPrice = totalSupply() ** 2; 
		uint256 targetAccumulatedPrice = targetSupply ** 2;

		uint256 price = targetAccumulatedPrice - currentAccumulatedPrice; 

	  console.log("targetSupply", price); 

		require(price <= msg.value, "insufficient funds sent"); 

		if(msg.value == price || payable(msg.sender).send(msg.value - price)) { // diese Zeile könnte Probleme machen
      console.log("minting", amount); 
      _mint(msg.sender, amount);
    } else {
      revert("funds sent exceeds price and sender not payable");
    }
	}

	function sell(
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
      // or not enough funds in contract, which should never happen
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

		inflowAddresses.push(_from);

		emit FlowCreation(_from, address(this));
	}

	function removeInflow(
		address _from
	) public onlyNetworkers {
	  Flow storage flow = inflows[_from]; 
	  flow.exists = false;  

	  emit FlowRemoval(_from, address(this));
	}

  function getInflows() public view returns( address [] memory ) {
    return inflowAddresses; 
  }
}	

