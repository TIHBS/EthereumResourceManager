// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "./IResourceManager.sol";
import {StringUtils} from "./StringUtils.sol";

contract HotelManager {
    address private resourceManagerAddress;

    event IsRoomAvailableEvent(string txId, bool isRoomAvailable);
    event QueryRoomPriceEvent(string txId, uint256 roomPrice);
    event QueryClientBalanceEvent(string txId, uint256 clientBalance);
    event HasReservationEvent(string txId, bool hasReservation);

    function setResourceManagerAddress(address _newAddress) external {
        resourceManagerAddress = _newAddress;
    }

    function getRM() private view returns (IResourceManager) {
        return IResourceManager(resourceManagerAddress);
    }

    function isRoomAvailable(string memory txId, address tm) public returns (bool, bool) {
        (string memory roomOwner, bool isSuccessful) = getRM().getValue("roomOwner", txId, tm);

        if (isSuccessful) {
            bool result = StringUtils.isEmpty(roomOwner);

            emit IsRoomAvailableEvent(txId, result);
            return (result, true);
        } else {
            return (false, false);
        }
    }

    function queryRoomPrice(string calldata txId, address tm) external returns (uint256, bool) {
        uint256 defaultPrice = 500;
        (string memory priceS, bool isSuccessful) = getRM().getValue("roomPrice", txId, tm);

        if (isSuccessful) {
            uint256 result = defaultPrice;

            if (!StringUtils.isEmpty(priceS)) {
                result = StringUtils.stringToUint(priceS);
            }

            emit QueryRoomPriceEvent(txId, result);
            return (result, true);
        }
        else {
            return (0, false);
        }
    }

    function queryClientBalance(string calldata txId, address tm) public returns (uint256, bool) {
        string memory varName = formulateClientBalanceVarName(tx.origin);
        (string memory balance, bool isSuccessful) = getRM().getValue(varName, txId, tm);

        if (isSuccessful) {
            uint256 result = 0;

            if (!StringUtils.isEmpty(balance)) {
                result = StringUtils.stringToUint(balance);
            }

            emit QueryClientBalanceEvent(txId, result);
            return (result, true);
        } else {
            return (0, false);
        }
    }

    function changeRoomPrice(string calldata txId, uint256 newPrice, address tm) external returns (bool) {
        string memory priceS = StringUtils.uintToString(newPrice);
        return getRM().setValue("roomPrice", txId, priceS, tm);
    }

    function addToClientBalance(string calldata txId, uint256 amountToAdd, address tm) external returns (bool) {
        require(amountToAdd > 0, "The amount must be a positive value!");
        string memory varName = formulateClientBalanceVarName(tx.origin);
        (uint256 balance, bool isSuccessful) = queryClientBalance(txId, tm);

        if (isSuccessful) {
            uint256 newBalance = balance + amountToAdd;
            string memory newBalanceS = StringUtils.uintToString(newBalance);
            getRM().setValue(varName, txId, newBalanceS, tm);

            return true;
        } else {
            return false;
        }
    }

    function bookRoom(string calldata txId, address tm) external returns (bool) {
        (bool available, bool successful) = isRoomAvailable(txId, tm);
        require(available && successful, "the room must be available!");
        (uint256 roomPrice, bool isSuccessful) = this.queryRoomPrice(txId, tm);
        if (isSuccessful) {
            if (deductFromClientBalance(txId, roomPrice, tm)) {
                return getRM().setValue("roomOwner", txId, StringUtils.addressToHexString(tx.origin), tm);
            } else {
                return false;
            }

        } else {
            return false;
        }
    }

    function hasReservation(string calldata txId, address tm) external returns (bool, bool) {
        (string memory ownerS, bool isSuccessful) = getRM().getValue("roomOwner", txId, tm);
        if (isSuccessful) {
            string memory currentClient = StringUtils.addressToHexString(tx.origin);
            bool result = StringUtils.compareStrings(ownerS, currentClient);

            emit HasReservationEvent(txId, result);
            return (result, true);
        } else {
            return (false, false);
        }
    }

    function checkout(string calldata txId, address tm) external returns (bool) {
        (bool gotReservation, bool isSuccessful) = this.hasReservation(txId, tm);
        require(gotReservation && isSuccessful, "you must have a reservation in order to checkout!");
        return getRM().setValue("roomOwner", txId, "", tm);
    }

    function deductFromClientBalance(string calldata txId, uint256 amountToDeduct, address tm) internal returns (bool) {
        string memory varName = formulateClientBalanceVarName(tx.origin);
        (uint256 balance, bool isSuccessful) = queryClientBalance(txId, tm);

        if (isSuccessful) {
            uint256 newBalance = balance - amountToDeduct;
            require(newBalance >= 0, "The amount to deduct cannot be larger than the current balance!");
            string memory newBalanceS = StringUtils.uintToString(newBalance);
            return getRM().setValue(varName, txId, newBalanceS, tm);

        } else {
            return false;
        }
    }

    function formulateClientBalanceVarName(address client) private pure returns (string memory) {
        return StringUtils.addressToHexString(client);
    }
}
