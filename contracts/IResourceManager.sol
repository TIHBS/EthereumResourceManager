// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

interface IResourceManager {

    event TxStarted(address indexed owner, string txId);
    event TxCommitted(address indexed owner, string txId);
    event TxAborted(address indexed owner, string txId);

    function begin(string calldata txId) external;
    function commit(string calldata txId) external;
    function abort(string calldata txId) external;
    function setValue(string memory variableName, string memory txId, string memory value) external;
    function getValue(string memory variableName, string memory txId) external returns(string memory);
}