// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

import "./IResourceManager.sol"; 
import {StringUtils} from "./StringUtils.sol";


contract ResourceManager is IResourceManager {
    using StringUtils for string;
    enum LockType { UNLOCKED, READ_LOCK, WRITE_LOCK }
    enum TxState { UNDEFINED, STARTED, COMMITTED, ABORTED }

    struct VariableState {
        string name;
        // a mapping(txid => HasReadLockOnVariable)
        mapping (string => bool) hasReadLock;
        // the total number of active read locks on this variable
        uint256 readLocksCount;
        // the txid holding a write lock on a 
        string writeLock;
        // the current value of the variable
        string value;
        // the before-image of the variable
        string beforeImage;
    }
    
    struct TxDetails {
        //The address that first initiated this transaction
       address owner;
       // The state of the current transaction
       TxState state;
       // The list of variables locked (read or write) by the transaction
       string[] lockedVariables;
    }
    
    modifier isTxOwner(string memory txId) {
        require (txs[txId].owner == tx.origin, "Message sender is not owner of global transaction!");
        _;
    }

    modifier isTxStarted(string memory txId) {
        require(txs[txId].state == TxState.STARTED, "The transaction is in invalid state!");
        _;
    }
    
    // mapping(VariableName => VariableState)
    mapping (string => VariableState) private variables;
    // mapping(TxId => TransactionState)
    mapping (string => TxDetails) private txs;
    
    // for testing
    function getTxOwner(string memory txId) public view returns (address) {
        return txs[txId].owner;
    }
    
    // for testing
    function getBeforeImage(string memory variableName) internal view returns (string memory) {
        return variables[variableName].beforeImage;
    }
    
    // for testing
    function getValueNoLocking(string memory variableName) internal view returns (string memory) {
        return variables[variableName].value;
    }
    
    function getLockedVariables(string memory txId) internal view returns (string[] memory) {
        return txs[txId].lockedVariables;
    }
    
    function acquireLock(string memory variableName, string memory txId, LockType lockType) private returns (bool, bool) { 
        if (canObtainLock(variableName, txId, lockType)) {
            bool hasSetLock = lock(variableName, txId, lockType);
            return (true, hasSetLock);
        }

        return (false, false);
    }

    function releaseLocks(string memory txId) private {
        // we need this to be a copy. Otherwise, the loop will be messed up!
        string[] memory lockedVariables = txs[txId].lockedVariables;

        for(uint256 i = 0; i < lockedVariables.length; i++) {
            releaseLock(lockedVariables[i], txId);
        }
    }
    
    function begin(string calldata txId) external override {
        require (txs[txId].owner ==  address(0), "The global transaction is already started!");
        txs[txId].owner = tx.origin;
        txs[txId].state = TxState.STARTED;
        emit TxStarted(tx.origin, txId);
    }

    function commit(string calldata txId) external override isTxOwner(txId) isTxStarted(txId) {
        // release all relevant locks
        releaseLocks(txId);
        txs[txId].state = TxState.COMMITTED;
        emit TxCommitted(tx.origin, txId);
    }
    
    function abort(string calldata txId) external override isTxOwner(txId) isTxStarted(txId) {
        string[] storage lockedVariables = txs[txId].lockedVariables;
        
        // restore the before image of all write-locked variables.
        for(uint256 i = 0; i < lockedVariables.length; i++) {
            if (isWL(lockedVariables[i])) {
                string memory beforeImage = variables[lockedVariables[i]].beforeImage;
                variables[lockedVariables[i]].value = beforeImage;
                variables[lockedVariables[i]].beforeImage = "";
            }
        }
        
        releaseLocks(txId);
        txs[txId].state = TxState.ABORTED;
        emit TxAborted(tx.origin, txId);
    }
    
    function setValue(string memory variableName, string memory txId, string memory value) external override isTxOwner(txId) isTxStarted(txId) {
        bool acquiredLock;
        bool hasSetLock;
        (acquiredLock, hasSetLock) = acquireLock(variableName, txId, LockType.WRITE_LOCK);
        require(acquiredLock, "Cannot lock a variable for writing!");
        VariableState storage variable = variables[variableName];

        if (hasSetLock == true) {
            string memory oldValue = variable.value;
            variable.beforeImage = oldValue;
        }
        
        variable.value = value;
    
    }

    function getValue(string memory variableName, string memory txId) external override isTxOwner(txId) isTxStarted(txId) returns(string memory) {
        bool acquiredLock;
        (acquiredLock, ) = acquireLock(variableName, txId, LockType.WRITE_LOCK);
        require(acquiredLock, "Cannot lock a variable for reading!");
        VariableState storage variable = variables[variableName];

        return variable.value;
    }
    
    function canObtainLock(string memory variableName, string memory txId, LockType lockType) private view returns(bool){
        VariableState storage variable = variables[variableName];
        // Read-locked and we want to set a write lock on it and we don't have an exclusive read lock on it.
        if (isRL(variableName) && lockType == LockType.WRITE_LOCK && !(variable.readLocksCount == 1 && variable.hasReadLock[txId])) {
            return false;
        }

        // Write-locked and we don't own the lock
        if (isWL(variableName) && !StringUtils.compareStrings(variable.writeLock, txId)) {
            return false;
        }

        return true;
    }
    
    /**
     * @dev Grants a tx a lock over a variable.
     * Assumes the preconditions for allowing this operation are already checked.
     */
    function lock(string memory variableName, string memory txId, LockType lockType) private returns(bool) {
        VariableState storage variable = variables[variableName];
        bool hasSetLock = false;

        if (lockType == LockType.READ_LOCK) {
            // we don't already have ANY lock, obtain it! Otherwise, do nothing!
            if (!variable.hasReadLock[txId] && !StringUtils.compareStrings(variable.writeLock, txId)) {
                setRL(variableName, txId);
                hasSetLock = true;
            }
        } else {
            // WL is requested

            // ifWL then it is already us (do nothing)!
            if (!isWL(variableName)) {
                // if isRL then it is also us. Unlock it!
                if (isRL(variableName)) {
                    releaseRL(variableName, txId);
                }

                setWL(variableName, txId);
                hasSetLock = true;
            }
        }

        return hasSetLock;
    }
    
    function releaseLock(string memory variableName, string memory txId) private {
        // if it WL, then it can only be us!
        if (isWL(variableName) ) {
            releaseWL(variableName, txId);
        } else { // Otherwise, we certainly have a readlock on the variable (we know we have some lock :)).
            releaseRL(variableName, txId);
        }
    }

    /**
     * @dev checks if a variable is write-locked
     */ 
    function isWL(string memory variableName) private view returns(bool) {
        VariableState storage variable = variables[variableName];
        return !StringUtils.isEmpty(variable.writeLock);
    }
    
    /**
     * @dev checks if a variable is read-locked
     */ 
    function isRL(string memory variableName) private view returns(bool) {
        VariableState storage variable = variables[variableName];
        return variable.readLocksCount > 0;
    }
    
    function setRL(string memory variableName, string memory txId) private {
        VariableState storage variable = variables[variableName];
        variable.hasReadLock[txId] = true;
        variable.readLocksCount += 1;
        txs[txId].lockedVariables.push(variableName);
    }
    
    function releaseRL(string memory  variableName, string memory txId) private {
        VariableState storage variable = variables[variableName];
        variable.hasReadLock[txId] = false;
        variable.readLocksCount -= 1;
        assert(removeElement(txs[txId].lockedVariables, variableName));
    }

    function setWL(string memory variableName, string memory txId) private {
        VariableState storage variable = variables[variableName];
        variable.writeLock = txId;
        txs[txId].lockedVariables.push(variableName);
    }

    function releaseWL(string memory variableName, string memory txId) private {
        VariableState storage variable = variables[variableName];
        delete variable.writeLock;
        assert(removeElement(txs[txId].lockedVariables, variableName));
    }



    /**
     * @dev Remove the element from the array (returns true if successful).
     * This operation will not leave holes but will reorder the array.
     */
    function removeElement(string[] storage array, string memory element) private returns(bool) {
        uint length = array.length;

        for(uint i = 0; i < length; i++) {
            if (StringUtils.compareStrings(array[i], element)) {
                // overwrite the value with the last value in the array (order does not matter)
                if (length > 1) {
                    array[i] = array[length - 1];
                }
                // delete the last element in the array (either a duplicate now or our value)
                array.pop();
                return true;
            }
        }

        return false;
    }
    

}