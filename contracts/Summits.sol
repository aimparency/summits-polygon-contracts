//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./Aim.sol"; 

contract Summits {
  Aim public baseAim; 
  // bytes private cloneCode; // TBD? instead of reconstructing the bytes, save it?
    // storage vs calc tradeof
  
  Aim [] aims; 

  event AimCreation(address aimAddress); 

  constructor() {
    baseAim = new Aim(
      msg.sender, 
      2 * 10 ** 9 // equals 4 ETH
    );
    baseAim.init(
      msg.sender,
      "aimparency", 
      "An efficient socioeconomic system", 
      100 * 31557600, // 100 years
      0x999999,
      "Aimparency", 
      "MPRNC"
    );
  }

  function createAim(
    string calldata _title, 
    string calldata _initialDescription, 
    uint64 _effort, 
    bytes3 _color, 
    string calldata _tokenName, 
    string calldata _tokenSymbol, 
    uint128 _initialAmount
  ) public payable returns (address aimAddress) {
    aimAddress = createAimMimicker(); 
    Aim aim = Aim(aimAddress); 
    aim.init(
      msg.sender,
      _title,
      _initialDescription, 
      _effort, 
      _color, 
      _tokenName, 
      _tokenSymbol
    );
    emit AimCreation(aimAddress);
    console.log("created aim", aimAddress, " - calling buy");
    aims.push(aim); 
    if(_initialAmount > 0) {
      aim.buy{value: msg.value}(_initialAmount);
    }
  }

  function createAimMimicker() internal returns(address mimickerAddress)  {
    bytes20 targetBytes = bytes20(address(baseAim));
    // TODO?: Optimization?: create this code on baseAim change?
    assembly {
      let code:= mload(0x40)
      mstore(code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(code, 0x14), targetBytes)
      mstore(add(code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      mimickerAddress := create(0, code, 0x37)
    }
  }

  function isLegitAimMimicker(address subject) public view returns(bool isLegit) {
    bytes20 targetBytes = bytes20(address(baseAim));
    assembly {
      let code:= mload(0x40)
      mstore(code, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(code, 0xa), targetBytes)
      mstore(add(code, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let subjectCode:= add(code, 0x40)
      extcodecopy(subject, subjectCode, 0, 0x2d)
      isLegit := and(
        eq(mload(code), mload(subjectCode)),
        eq(mload(add(code, 0xd)), mload(add(subjectCode, 0xd)))
      )
    }
  }
}

// maintain list of aims? it's implicitly there in the history of createAim calls
// flows are stored at receiving aims
// "home aims" are stored in the client. 
// mapping (address => uint128) public homes; 

