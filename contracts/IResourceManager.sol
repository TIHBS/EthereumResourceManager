// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

interface IResourceManager {

    event TxStarted(address indexed owner, string indexed txId);
    event TxCommitted(address indexed owner, string indexed txId);
    event TxAborted(address indexed owner, string indexed txId);
    event Voted(address indexed owner, string indexed txId, bool isYes);

    function prepare(string calldata txId) external;
    function commit(string calldata txId) external;
    function abort(string calldata txId) external;
    function setValue(string memory variableName, string calldata txId, string memory value, address tmId) external returns(bool);
    function getValue(string memory variableName, string calldata txId, address tmId) external returns(string memory, bool);
}