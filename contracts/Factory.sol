// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Organization.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Factory is Ownable {
  address[] public organizations; // cloned organization contracts address array
  address public clonableOrganization; // clonable organization contract address
  mapping(address => address[]) public userOrganizations; // user delegate amount for delegators
  mapping(address => address[]) public orgAdmins;

  constructor () {
  }

  /*
  Set cloable contract address which uses as a library
  */
  function setClonableOrganization(address _clonableAddress) external onlyOwner {
      clonableOrganization = _clonableAddress;
  }
  /*Add organization*/
  function addOrganization(string memory name) public {
      address clone = Clones.clone(clonableOrganization);
      Organization newOrg = Organization(clone);
      newOrg.initiate(name, msg.sender);
      organizations.push(clone);
      userOrganizations[msg.sender].push(clone);
      emit OrganizationAdded(msg.sender, name);
  }

  function _remove(address organization) internal {
    uint i;
    for(i = 0; i < organizations.length; i++) {
      if (organizations[i] == organization) {
        organizations[i] = organizations[organizations.length - 1];
        organizations.pop();
        Organization org = Organization(organization);
        org.remove();
        break;
      }
    }
  }

  function removeOrganization(address organization) public {
    uint i;
    for(i = 0; i < userOrganizations[msg.sender].length; i++) {
      if (userOrganizations[msg.sender][i] == organization) {
        userOrganizations[msg.sender][i] = userOrganizations[msg.sender][userOrganizations[msg.sender].length - 1];
        userOrganizations[msg.sender].pop();
        _remove(organization);
        emit OrganizationRemoved(organization);
        break;
      }
    }
  }

  // deposit function
  function deposit(address orgAddr, address tokenAddr, uint amount) external{
    Organization org = Organization(orgAddr);
    bool isRemoved = org.isRemoved();
    require(!isRemoved, "The organization is removed!");
    IERC20 token = IERC20(tokenAddr);
    require(token.transferFrom(msg.sender, orgAddr, amount), "transfer failed");

    emit Deposit(orgAddr, tokenAddr, amount);
  }

  // remove admin from organization
  function _removeAdmin(address orgAddr, address admin) internal {
    address[] memory admins = orgAdmins[orgAddr];
    uint i;
    for(i = 0; i < admins.length; i++) {
      if(admins[i] == admin) {
        orgAdmins[orgAddr][i] = admins[admins.length - 1];
        orgAdmins[orgAddr].pop();
        break;
      }
    }
  }

  // check if the msg.sender is organization owner
  modifier onlyOrgOwner(address orgAddr) {
    Organization org = Organization(orgAddr);
    address owner = org._owner();
    require(msg.sender == owner, "Caller is not organization owner!");
    _;
  }

  // add admin to organization
  function addAdmin(address orgAddr, address newAdmin) external onlyOrgOwner(orgAddr) {
    orgAdmins[orgAddr].push(newAdmin);
  }

  // remove admin from organization
  function removeAdmin(address orgAddr, address admin) external onlyOrgOwner(orgAddr) {
    _removeAdmin(orgAddr, admin);
  }

  // send function-send ERC-20 token to address
  function send(address orgAddr, address to, address tokenAddr,uint amount) public returns (bool) {
    Organization org = Organization(orgAddr);
    bool isRemoved = org.isRemoved();
    address _owner = org._owner();
    require(!isRemoved, "The organization is removed!");
    bool isValid = false;
    if(msg.sender == _owner) {
      isValid = true;
    } else {
      uint i;
      address[] memory admins = orgAdmins[orgAddr];
      for(i = 0; i < admins.length; i++) {
        if(admins[i] == msg.sender) {
          isValid = true;
          break;
        }
      }
    }
    require(isValid, "Caller is not admin, nor owner");
    IERC20 token = IERC20(tokenAddr);
    require(token.transfer(to, amount), "Transfer failed");
    emit TokenSend(orgAddr, tokenAddr, to, amount);
    return true;
  }

  // Events
  event OrganizationAdded(address owner, string name);
  event OrganizationRemoved(address organization);
  event Deposit(address organization, address tokenAddr, uint amount);
  event TokenSend(address organization, address tokenAddr, address to, uint amount);
}