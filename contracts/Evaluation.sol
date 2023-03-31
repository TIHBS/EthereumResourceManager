// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;
import "./IResourceManager.sol";

contract Evaluation {
    string private theValue;
    address private rmAddress;

    function setAddress(address newAddress) public {
        rmAddress = newAddress;
    }

    function empty() public {
    }

    function emptyForExternalCall() public {
        IResourceManager rm = IResourceManager(rmAddress);
    }


    function set() public {
        theValue = "100";
    }

    function get() public returns(string memory) {
        return theValue;
    }


    function callSet(string calldata varName) public {
        IResourceManager rm = IResourceManager(rmAddress);
        rm.setValue(varName, "t", "100");
    }

    function callGet() public {
        IResourceManager rm = IResourceManager(rmAddress);
        (string memory value, ) = rm.getValue("v", "t");
    }
}