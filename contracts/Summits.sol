//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "hardhat/console.sol";
import "./Aim.sol"; 

contract Summits {
  address public baseAim; 

  event AimCreated(address newAimAddress); 

  function Summits(address _baseAddress) public {
    baseAim = _baseAddress;
      "aimparency", 
      "An efficient socioeconomic system", 
      100 * 31557600, // 100 years
      0x555555,
      3 * 1337, 
    )
  }

  function createAim(
    string _title, 
    string _initialDescription, 
    uint64 _effort, 
    bytes3 _color, 
    uint256 _initialShares, 
  ) public {
    address aim = createAimMimicker(); 
    Aim(aim).init(
      msg.sender,
      _title,
      _initialDescription, 
      _effort, 
      _color, 
      _initialShares
    );
    aimIsWhitelisted[aim] = true; 
    emit AimCreated(aim);
    return aim;
  }

  function createAimMimicker() returns address {
    bytes20 targetBytes = bytes20(baseAim);
    // TODO: Optimization: create this code on baseAim change
    assembly {
      let code:= mload(0x40)
      mstore(code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(code, 0x14), targetBytes)
      mstore(add(code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      mimicker := create(0, code, 0x37)
    }
    return address(mimicker);
  }

  function isLegitAimMimicker(address subject) returns bool {
    bytes20 targetBytes = bytes20(baseAim);
    assembly {
      let code:= mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let subjectCode:= add(clone, 0x40)
      extcodecopy(subject, subjectCode, 0, 0x2d)
      result := and(
        eq(mload(code), mload(subjectCode)),
        eq(mload(add(code, 0xd)), mload(add(subjectCode, 0xd)))
      )
    }
  }
}

// maintain list of aims? it's implicitly there in the history of createAim calls
// flows are stored at receiving aims
// "home aims" are stored in the client. 
	mapping (address => uint128) public homes; 

  constructor() ERC20("Summits", "MM") {
      _mint(msg.sender, _initial_supply);
      console.log("minted initial supply");
  }

	function createAim(
		uint128 aimId, 
		string calldata title, 
		bytes3 color, 
		Effort calldata effort, 
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

