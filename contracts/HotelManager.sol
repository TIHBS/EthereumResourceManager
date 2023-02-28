// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

import "./IResourceManager.sol"; 
import {StringUtils} from "./StringUtils.sol";

contract HotelManager {
    address private resourceManagerAddress;

    function setResourceManagerAddress(address _newAddress) public {
        resourceManagerAddress = _newAddress;
    }

    function getRM() private view returns (IResourceManager) {
        return IResourceManager(resourceManagerAddress);
    }

    function isRoomAvailable(string memory txId) public returns (bool) {
        string memory seatOwner = getRM().getValue(txId, "roomOwner");

        return StringUtils.isEmpty(seatOwner);
    }

    function queryRoomPrice(string calldata txId) external returns (uint) {
        uint defaultPrice = 500;
        string memory priceS = getRM().getValue(txId, "roomPrice");
        
    }

}