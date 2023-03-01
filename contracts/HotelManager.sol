// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

import "./IResourceManager.sol"; 
import {StringUtils} from "./StringUtils.sol";

contract HotelManager {
    address private resourceManagerAddress;

    event IsRoomAvailable(string txId, bool isRoomAvailable);
    event QueryRoomPrice(string txId, uint roomPrice);
    event QueryClientBalance(string txId, uint clientBalance);
    event HasReservation(string txId, bool hasReservation);

    function setResourceManagerAddress(address _newAddress) public {
        resourceManagerAddress = _newAddress;
    }

    function getRM() private view returns (IResourceManager) {
        return IResourceManager(resourceManagerAddress);
    }

    function isRoomAvailable(string memory txId) public returns (bool) {
        string memory seatOwner = getRM().getValue(txId, "roomOwner");
        bool result = StringUtils.isEmpty(seatOwner);

        emit IsRoomAvailable(txId, result);
        return result;
    }

    function queryRoomPrice(string calldata txId) external returns (uint) {
        uint defaultPrice = 500;
        string memory priceS = getRM().getValue(txId, "roomPrice");
        uint result = defaultPrice;

        if(!StringUtils.isEmpty(priceS)) {
            result = StringUtils.stringToUint(priceS);
        }

        emit QueryRoomPrice(txId, result);
        return result;
    }

    function queryClientBalance(string calldata txId) public returns (uint) {
        string memory varName = formulateClientBalanceVarName(tx.origin);
        string memory balance = getRM().getValue(txId, varName);
        uint result = 0;

        if (!StringUtils.isEmpty(balance)) {
            result = StringUtils.stringToUint(balance);
        }

        emit QueryClientBalance(txId, result);
        return result;
    }

    function changeRoomPrice(string calldata txId, uint newPrice) external {
        string memory priceS = StringUtils.uintToString(newPrice);
        getRM().setValue(txId, "roomPrice", priceS);
    }

    function addToClientBalance(string calldata txId, uint amountToAdd) external {
        require(amountToAdd > 0, "The amount must be a positive value!");
        string memory varName = formulateClientBalanceVarName(tx.origin);
        uint balance = queryClientBalance(txId);
        uint newBalance = balance + amountToAdd;
        string memory newBalanceS = StringUtils.uintToString(newBalance);
        getRM().setValue(txId, varName, newBalanceS);
    }

    function bookRoom(string calldata txId) external {
        require(isRoomAvailable(txId), "the room must be available!");
        uint roomPrice = this.queryRoomPrice(txId);
        deductFromClientBalance(txId, roomPrice);
        getRM().setValue(txId, "roomOwner", StringUtils.addressToHexString(tx.origin));
    }

    function hasReservation(string calldata txId) external returns (bool) {
        string memory ownerS = getRM().getValue(txId, "roomOwner");
        string memory currentClient = StringUtils.addressToHexString(tx.origin);
        bool result = StringUtils.compareStrings(ownerS, currentClient);

        emit HasReservation(txId, result);
        return result;
    }
 
    function deductFromClientBalance(string calldata txId, uint amountToDeduct) internal {
        string memory varName = formulateClientBalanceVarName(tx.origin);
        uint balance = queryClientBalance(txId);
        uint newBalance = balance - amountToDeduct;
        require(newBalance >= 0, "The amount to deduct cannot be larger than the current balance!");
        string memory newBalanceS = StringUtils.uintToString(newBalance);
        getRM().setValue(txId, varName, newBalanceS);
    }

    function formulateClientBalanceVarName(address client) private pure returns (string memory) {    
        return StringUtils.addressToHexString(client);
    }
}