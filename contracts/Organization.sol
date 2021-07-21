// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address owner) external view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);
}


contract Organization {
  string public _name;
  address private _factory;
  address public _owner;
  bool public isRemoved;

  // Set Organization name
  function initiate(string memory name_, address owner_) external {
    _name = name_;
    _factory = msg.sender;
    _owner = owner_;
    isRemoved = false;
  }

  // modifiers
  modifier onlyFactory {
    require(msg.sender == _factory, "Caller is not factory contract");
    _;
  }

  // remove the organization
  function remove() external onlyFactory {
    isRemoved = true;
  }
}