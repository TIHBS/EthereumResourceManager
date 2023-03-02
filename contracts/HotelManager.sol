// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

import "./IResourceManager.sol";
import {StringUtils} from "./StringUtils.sol";

contract HotelManager {
    address private resourceManagerAddress;

    event IsRoomAvailableEvent(string txId, bool isRoomAvailable);
    event QueryRoomPriceEvent(string txId, uint256 roomPrice);
    event QueryClientBalanceEvent(string txId, uint256 clientBalance);
    event HasReservationEvent(string txId, bool hasReservation);

    function setResourceManagerAddress(address _newAddress) public {
        resourceManagerAddress = _newAddress;
    }

    function getRM() private view returns (IResourceManager) {
        return IResourceManager(resourceManagerAddress);
    }

    function isRoomAvailable(string memory txId) public returns (bool) {
        string memory seatOwner = getRM().getValue("roomOwner", txId);
        bool result = StringUtils.isEmpty(seatOwner);

        emit IsRoomAvailableEvent(txId, result);
        return result;
    }

    function queryRoomPrice(string calldata txId) external returns (uint256) {
        uint256 defaultPrice = 500;
        string memory priceS = getRM().getValue("roomPrice", txId);
        uint256 result = defaultPrice;

        if (!StringUtils.isEmpty(priceS)) {
            result = StringUtils.stringToUint(priceS);
        }

        emit QueryRoomPriceEvent(txId, result);
        return result;
    }

    function queryClientBalance(string calldata txId) public returns (uint256) {
        string memory varName = formulateClientBalanceVarName(tx.origin);
        string memory balance = getRM().getValue(varName, txId);
        uint256 result = 0;

        if (!StringUtils.isEmpty(balance)) {
            result = StringUtils.stringToUint(balance);
        }

        emit QueryClientBalanceEvent(txId, result);
        return result;
    }

    function changeRoomPrice(string calldata txId, uint256 newPrice) external {
        string memory priceS = StringUtils.uintToString(newPrice);
        getRM().setValue("roomPrice", txId, priceS);
    }

    function addToClientBalance(string calldata txId, uint256 amountToAdd) external {
        require(amountToAdd > 0, "The amount must be a positive value!");
        string memory varName = formulateClientBalanceVarName(tx.origin);
        uint256 balance = queryClientBalance(txId);
        uint256 newBalance = balance + amountToAdd;
        string memory newBalanceS = StringUtils.uintToString(newBalance);
        getRM().setValue(varName, txId, newBalanceS);
    }

    function bookRoom(string calldata txId) external {
        require(isRoomAvailable(txId), "the room must be available!");
        uint256 roomPrice = this.queryRoomPrice(txId);
        deductFromClientBalance(txId, roomPrice);
        getRM().setValue("roomOwner", txId, StringUtils.addressToHexString(tx.origin));
    }

    function hasReservation(string calldata txId) external returns (bool) {
        string memory ownerS = getRM().getValue("roomOwner", txId);
        string memory currentClient = StringUtils.addressToHexString(tx.origin);
        bool result = StringUtils.compareStrings(ownerS, currentClient);

        emit HasReservationEvent(txId, result);
        return result;
    }

    function checkout(string calldata txId) external {
        require(this.hasReservation(txId), "you must have a reservation in order to checkout!");
        getRM().setValue("roomOwner", txId, "");
    }

    function deductFromClientBalance(string calldata txId, uint256 amountToDeduct) internal {
        string memory varName = formulateClientBalanceVarName(tx.origin);
        uint256 balance = queryClientBalance(txId);
        uint256 newBalance = balance - amountToDeduct;
        require(newBalance >= 0, "The amount to deduct cannot be larger than the current balance!");
        string memory newBalanceS = StringUtils.uintToString(newBalance);
        getRM().setValue(varName, txId, newBalanceS);
    }

    function formulateClientBalanceVarName(address client) private pure returns (string memory) {
        return StringUtils.addressToHexString(client);
    }
}
