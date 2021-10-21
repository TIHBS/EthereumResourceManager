// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

contract ResourceManager {
    enum LockType { UNLOCKED, READ_LOCK, WRITE_LOCK }
    enum TxState { UNDEFINED, STARTED, COMMITTED, ABORTED }

    event TxStarted(address indexed owner, string txId);
    event TxCommitted(address indexed owner, string txId);
    event TxAborted(address indexed owner, string txId);
    
    struct VariableState {
        string name;
        // a mapping(txid => HasReadLockOnVariable)
        mapping (string => bool) hasReadLock;
        // the total number of active read locks on this variable
        uint readLocksCount;
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
    
    function acquireLock(string memory variableName, string memory txId, LockType lockType) private returns (bool) { 
        if (canObtainLock(variableName, txId, lockType)) {
            lock(variableName, txId, lockType);
            return true;
        }

        return false;
    }

    function releaseLocks(string memory txId) private {
        // we need this to be a copy. Otherwise, the loop will be messed up!
        string[] memory lockedVariables = txs[txId].lockedVariables;

        for(uint i = 0; i < lockedVariables.length; i++) {
            releaseLock(lockedVariables[i], txId);
        }
    }
    
    function begin(string calldata txId) external {
        require (txs[txId].owner ==  address(0), "The global transaction is already started!");
        txs[txId].owner = tx.origin;
        txs[txId].state = TxState.STARTED;
        emit TxStarted(tx.origin, txId);
    }

    function commit(string calldata txId) external isTxOwner(txId) isTxStarted(txId) {
        // release all relevant locks
        releaseLocks(txId);
        txs[txId].state = TxState.COMMITTED;
        emit TxCommitted(tx.origin, txId);
    }
    
    function abort(string calldata txId) external isTxOwner(txId) isTxStarted(txId) {
        string[] storage lockedVariables = txs[txId].lockedVariables;
        
        // restore the before image of all write-locked variables.
        for(uint i = 0; i < lockedVariables.length; i++) {
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
    
    function setValue(string memory variableName, string memory txId, string memory value) internal isTxOwner(txId) isTxStarted(txId) {
        require(acquireLock(variableName, txId, LockType.WRITE_LOCK), "Cannot lock a variable for writing!");
        VariableState storage variable = variables[variableName];
        string memory oldValue = variable.value;
        variable.beforeImage = oldValue;
        variable.value = value;
    }

    function getValue(string memory variableName, string memory txId) internal isTxOwner(txId) isTxStarted(txId) returns(string memory) {
        require(acquireLock(variableName, txId, LockType.READ_LOCK), "Cannot lock a variable for reading!");
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
        if (isWL(variableName) && !compareStrings(variable.writeLock, txId)) {
            return false;
        }

        return true;
    }
    
    /**
     * @dev Grants a tx a lock over a variable.
     * Assumes the preconditions for allowing this operation are already checked.
     */
    function lock(string memory variableName, string memory txId, LockType lockType) private {
        VariableState storage variable = variables[variableName];

        if (lockType == LockType.READ_LOCK) {
            
            // we don't already have ANY lock, obtain it! Otherwise, do nothing!
            if (!variable.hasReadLock[txId] && !compareStrings(variable.writeLock, txId)) {
                setRL(variableName, txId);
            }
        } else { // WL is requested
        
            // ifWL then it is already us (do nothing)!
            if (!isWL(variableName)) {
                
                // if isRL then it is also us. Unlock it!
                if (isRL(variableName)) {
                    releaseRL(variableName, txId);
                }
                
                setWL(variableName, txId);
            }
        }
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
        return !isEmpty(variable.writeLock);
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
            if (compareStrings(array[i], element)) {
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
    
    /**
     * @dev  compares two variable-length byte arrays for equality
     */
    function compareBytes(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
    
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