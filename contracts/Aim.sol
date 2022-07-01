//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9; 

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct AimData {
	string title; 
	string description;
	string status;
	uint64 effort; 
	bytes3 color; 
}

struct FlowData {
	string explanation;
	bytes4 d2d; // 2x float16
}

struct Flow {
	bool exists;

	uint16 weight;

  FlowData data; 
}

uint8 constant EDIT = 0x01; 
uint8 constant NETWORK = 0x02; 
uint8 constant MANAGE = 0x04; 

uint128 constant MAX_TOKENS = 0xffffffffffffffffffffffffffffffff;

contract Aim is Ownable, ERC20 {
	string internal tokenName; 
	string internal tokenSymbol; 

	bool public initialized; 

	uint16 public loopWeight; 

	AimData public data;

  mapping (address => uint8) public permissions; 

	address [] inflowAddresses; 
	mapping (address => Flow) public inflows;

  constructor(address creator, uint128 initialAmount) payable ERC20("", "") {
    require(msg.value == uint256(initialAmount) ** 2); 

    _mint(creator, initialAmount);

    data.title = "aimparency"; 
    data.status = "wip"; 
    data.description = "an efficient socioeconomic system"; 
    data.effort = 60 * 60 * 24 * 356 * 30;
    data.color = 0x999999;

    tokenName = "aimparencent";
    tokenSymbol = "MPRNC";
  }

  event FlowCreation(address from, address to); 
  event FlowRemoval(address from, address to); 

  function init(
    address creator, 
    AimData calldata _data, 
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

		data = _data;

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
		uint16 _weight, 
		FlowData calldata _data
	) public onlyNetworkers {
		Flow storage flow = inflows[_from];

		require(!flow.exists, "flow already exists");

		flow.exists = true;

		flow.weight = _weight;

		flow.data = _data;

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

  // use ../codegen to autogen the following combinations of setters for aims and flows
  // aim updates
	function updateAimTitle(
	  string calldata _title
	) public onlyEditors {
	  data.title = _title;
	}

	function updateAimDescription(
	  string calldata _description
	) public onlyEditors {
	  data.description = _description;
	}

	function updateAimTitleDescription(
	  string calldata _title,
	  string calldata _description
	) public onlyEditors {
	  data.title = _title;
	  data.description = _description;
	}

	function updateAimStatus(
	  string calldata _status
	) public onlyEditors {
	  data.status = _status;
	}

	function updateAimTitleStatus(
	  string calldata _title,
	  string calldata _status
	) public onlyEditors {
	  data.title = _title;
	  data.status = _status;
	}

	function updateAimDescriptionStatus(
	  string calldata _description,
	  string calldata _status
	) public onlyEditors {
	  data.description = _description;
	  data.status = _status;
	}

	function updateAimTitleDescriptionStatus(
	  string calldata _title,
	  string calldata _description,
	  string calldata _status
	) public onlyEditors {
	  data.title = _title;
	  data.description = _description;
	  data.status = _status;
	}

	function updateAimEffort(
	  uint64 _effort
	) public onlyEditors {
	  data.effort = _effort;
	}

	function updateAimTitleEffort(
	  string calldata _title,
	  uint64 _effort
	) public onlyEditors {
	  data.title = _title;
	  data.effort = _effort;
	}

	function updateAimDescriptionEffort(
	  string calldata _description,
	  uint64 _effort
	) public onlyEditors {
	  data.description = _description;
	  data.effort = _effort;
	}

	function updateAimTitleDescriptionEffort(
	  string calldata _title,
	  string calldata _description,
	  uint64 _effort
	) public onlyEditors {
	  data.title = _title;
	  data.description = _description;
	  data.effort = _effort;
	}

	function updateAimStatusEffort(
	  string calldata _status,
	  uint64 _effort
	) public onlyEditors {
	  data.status = _status;
	  data.effort = _effort;
	}

	function updateAimTitleStatusEffort(
	  string calldata _title,
	  string calldata _status,
	  uint64 _effort
	) public onlyEditors {
	  data.title = _title;
	  data.status = _status;
	  data.effort = _effort;
	}

	function updateAimDescriptionStatusEffort(
	  string calldata _description,
	  string calldata _status,
	  uint64 _effort
	) public onlyEditors {
	  data.description = _description;
	  data.status = _status;
	  data.effort = _effort;
	}

	function updateAimTitleDescriptionStatusEffort(
	  string calldata _title,
	  string calldata _description,
	  string calldata _status,
	  uint64 _effort
	) public onlyEditors {
	  data.title = _title;
	  data.description = _description;
	  data.status = _status;
	  data.effort = _effort;
	}

	function updateAimColor(
	  bytes3 _color
	) public onlyEditors {
	  data.color = _color;
	}

	function updateAimTitleColor(
	  string calldata _title,
	  bytes3 _color
	) public onlyEditors {
	  data.title = _title;
	  data.color = _color;
	}

	function updateAimDescriptionColor(
	  string calldata _description,
	  bytes3 _color
	) public onlyEditors {
	  data.description = _description;
	  data.color = _color;
	}

	function updateAimTitleDescriptionColor(
	  string calldata _title,
	  string calldata _description,
	  bytes3 _color
	) public onlyEditors {
	  data.title = _title;
	  data.description = _description;
	  data.color = _color;
	}

	function updateAimStatusColor(
	  string calldata _status,
	  bytes3 _color
	) public onlyEditors {
	  data.status = _status;
	  data.color = _color;
	}

	function updateAimTitleStatusColor(
	  string calldata _title,
	  string calldata _status,
	  bytes3 _color
	) public onlyEditors {
	  data.title = _title;
	  data.status = _status;
	  data.color = _color;
	}

	function updateAimDescriptionStatusColor(
	  string calldata _description,
	  string calldata _status,
	  bytes3 _color
	) public onlyEditors {
	  data.description = _description;
	  data.status = _status;
	  data.color = _color;
	}

	function updateAimTitleDescriptionStatusColor(
	  string calldata _title,
	  string calldata _description,
	  string calldata _status,
	  bytes3 _color
	) public onlyEditors {
	  data.title = _title;
	  data.description = _description;
	  data.status = _status;
	  data.color = _color;
	}

	function updateAimEffortColor(
	  uint64 _effort,
	  bytes3 _color
	) public onlyEditors {
	  data.effort = _effort;
	  data.color = _color;
	}

	function updateAimTitleEffortColor(
	  string calldata _title,
	  uint64 _effort,
	  bytes3 _color
	) public onlyEditors {
	  data.title = _title;
	  data.effort = _effort;
	  data.color = _color;
	}

	function updateAimDescriptionEffortColor(
	  string calldata _description,
	  uint64 _effort,
	  bytes3 _color
	) public onlyEditors {
	  data.description = _description;
	  data.effort = _effort;
	  data.color = _color;
	}

	function updateAimTitleDescriptionEffortColor(
	  string calldata _title,
	  string calldata _description,
	  uint64 _effort,
	  bytes3 _color
	) public onlyEditors {
	  data.title = _title;
	  data.description = _description;
	  data.effort = _effort;
	  data.color = _color;
	}

	function updateAimStatusEffortColor(
	  string calldata _status,
	  uint64 _effort,
	  bytes3 _color
	) public onlyEditors {
	  data.status = _status;
	  data.effort = _effort;
	  data.color = _color;
	}

	function updateAimTitleStatusEffortColor(
	  string calldata _title,
	  string calldata _status,
	  uint64 _effort,
	  bytes3 _color
	) public onlyEditors {
	  data.title = _title;
	  data.status = _status;
	  data.effort = _effort;
	  data.color = _color;
	}

	function updateAimDescriptionStatusEffortColor(
	  string calldata _description,
	  string calldata _status,
	  uint64 _effort,
	  bytes3 _color
	) public onlyEditors {
	  data.description = _description;
	  data.status = _status;
	  data.effort = _effort;
	  data.color = _color;
	}

	function updateAimTitleDescriptionStatusEffortColor(
	  string calldata _title,
	  string calldata _description,
	  string calldata _status,
	  uint64 _effort,
	  bytes3 _color
	) public onlyEditors {
	  data.title = _title;
	  data.description = _description;
	  data.status = _status;
	  data.effort = _effort;
	  data.color = _color;
	}

  // flow updates

	function updateFlowExplanation(
	  address _from,
	  string calldata _explanation
	) public onlyEditors {
	  FlowData storage flowData = inflows[_from].data;
	  flowData.explanation = _explanation;
	}

	function updateFlowD2d(
	  address _from,
	  bytes4 _d2d
	) public onlyEditors {
	  FlowData storage flowData = inflows[_from].data;
	  flowData.d2d = _d2d;
	}

	function updateFlowExplanationD2d(
	  address _from,
	  string calldata _explanation,
	  bytes4 _d2d
	) public onlyEditors {
	  FlowData storage flowData = inflows[_from].data;
	  flowData.explanation = _explanation;
	  flowData.d2d = _d2d;
	}
}	

