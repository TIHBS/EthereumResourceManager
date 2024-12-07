// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

interface IResourceManager {

    event TxStarted(address owner, string txId);
    event TxCommitted(address owner, string txId);
    event TxAborted(address owner, string txId);
    event Voted(address owner, string txId, bool isYes);

    function prepare(string calldata txId) external;
    function commit(string calldata txId) external;
    function abort(string calldata txId) external;
    function setValue(string memory variableName, string calldata txId, string memory value, address tmId) external returns(bool);
    function getValue(string memory variableName, string calldata txId, address tmId) external returns(string memory, bool);
}