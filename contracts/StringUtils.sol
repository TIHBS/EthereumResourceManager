// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

library StringUtils {

    
    /**
     * @dev  compares two variable-length strings for equality
     */ 
    function compareStrings(string memory a, string memory b) internal pure returns(bool){
        return compareBytes(bytes(a), bytes(b));
    }
    
    /**
     * @dev  checks if the passed string is empty.
     */
    function isEmpty(string memory value) internal pure returns(bool) {
        return compareStrings(value, "");
    }
    
    function copyString(string memory value) internal  pure returns (string memory) {
        string memory copy = string(copyBytes(bytes(value)));
        return copy;
    }

    function stringToUint(string memory s) internal pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }

    function uintToString(uint v) internal pure returns (string memory) {
        if (v == 0) {
            return "0";
        }

        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;

        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }

        bytes memory s = new bytes(i);

        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; 
        }
        
        string memory str = string(s);  
        return str;
    }


    function addressToHexString(address x) internal pure returns(string memory) {
        bytes memory data = abi.encodePacked(x);
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    /**
     * @dev  compares two variable-length byte arrays for equality
     */
    function compareBytes(bytes memory a, bytes memory b) private pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
    
    function copyBytes(bytes memory _bytes) private pure returns (bytes memory)
    {
        bytes memory copy = new bytes(_bytes.length);
        uint256 max = _bytes.length + 31;
        
        for (uint256 i = 32; i <= max; i += 32) {
            assembly { mstore(add(copy, i), mload(add(_bytes, i))) }
        }
        
        return copy;
    }
}