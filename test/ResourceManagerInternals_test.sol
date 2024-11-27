// SPDX-License-Identifier: Apahce-2.0
    
pragma solidity ^0.8.17;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/IResourceManager.sol";
import "../contracts/ResourceManager.sol";
import "hardhat/console.sol";
import {StringUtils} from "../contracts/StringUtils.sol";

contract TestInternals is ResourceManager {
    string txid = "id-1";
    string txid2 = "id-2";
    string txid3 = "id-3";
    string txid4 = "id-4";
    string txid5 = "idd-5";
    string txid6 = "idd-6";
    string txid7 = "idd-7";
    string vara = "var-a";
    string varb = "var-b";
    string varc = "var-c";
    
    string abc = "abc";
    string abc2 = "abc";
    string cba = "cba";
    
    mapping(string => VariableState) variables;

    function testAddressConversion() public {
        address a = tx.origin;
        string memory s = StringUtils.addressToHexString(a);
        Assert.equal(bytes(s).length, 42, "reasonable length");
    }
    
    
    function testCompareStrings() public {
        string memory a = "abc";
        string storage b = abc;
        string memory c = "abc";
        string storage d = abc2;
        
        Assert.ok(StringUtils.compareStrings(a, b), "strings are equal");
        Assert.ok(StringUtils.compareStrings(a, c), "strings are equal");
        Assert.ok(StringUtils.compareStrings(b, d), "strings are equal");
        Assert.ok(StringUtils.compareStrings(a, a), "strings are equal");
    }

    function testUintToString() public {
        string memory a = "1200";
        string memory b = StringUtils.uintToString(1200);
        string memory a0 = "0";
        string memory b0 = StringUtils.uintToString(0);

        Assert.ok(StringUtils.compareStrings(a, b), "strings are equal");
        Assert.ok(StringUtils.compareStrings(a0, b0), "strings are equal");
    }

    function testStringToUint() public {
        uint a = StringUtils.stringToUint("1200");
        uint b = 1200;
        uint a0 = StringUtils.stringToUint("0");
        uint b0 = 0;

        Assert.ok(a == b, "uints are equal");
        Assert.ok(a0 == b0, "uints are equal");
    }
    
    function testCopyStrings() public {
        variables[vara].value = "a";
        variables[vara].beforeImage = "b";
        string memory beforeImage = variables[vara].beforeImage;
        variables[vara].value = beforeImage;
        variables[vara].beforeImage = "";
        
        Assert.equal("b", variables[vara].value, "incorrect value");
        Assert.equal("", variables[vara].beforeImage, "incorrect beforeImage");
    }
    
    /// #sender: account-1
    function testHappyPathWriteThenRead() public {
        bool isSuccessful = this.setValue(vara, txid, "hello", TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, 'set value failed unexpectedly!');
        isSuccessful = this.setValue(varb, txid, "bye bye", TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, 'set value failed unexpectedly!');
        (string memory value, bool isSuccessful2) = this.getValue(vara, txid, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful2, 'get value failed unexpectedly!');
        Assert.equal("hello", value, "var-a contains an unexpected value!");
        (value, isSuccessful) = this.getValue(varb, txid, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, 'get value failed unexpectedly!');
        Assert.equal("bye bye", value, "var-a contains an unexpected value!");
        string[] memory lockedVariables = getLockedVariables(txid);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
        this.prepare(txid);
        this.commit(txid);
    }
    
    /// #sender: account-1
    function testTwoTransactions() public {
        (string memory value, bool isSuccessful) = this.getValue(vara, txid2, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "get value failed unexpectedly!");
        Assert.equal("hello", value, "var-a contains an unexpected value!");
        
        (value, isSuccessful) = this.getValue(vara, txid3, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "get value failed unexpectedly!");
        (string memory value2, bool isSuccessful2) = this.getValue(varb, txid3, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful2, "get value failed unexpectedly!");
        Assert.equal("bye bye", value2, "var-b contains an unexpected value!");
        isSuccessful = this.setValue(varb, txid3, value, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "set value failed unexpectedly!");
        (value2, isSuccessful2) = this.getValue(varb, txid3, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful2, "get value failed unexpectedly!");
        Assert.equal("hello", value2, "var-b contains an unexpected value!");
        string[] memory lockedVariables = getLockedVariables(txid3);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
        this.prepare(txid3);
        this.commit(txid3);
        lockedVariables = getLockedVariables(txid3);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
        

        (value, isSuccessful) = this.getValue(vara, txid2, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "get value failed unexpectedly!");
        Assert.equal("hello", value, "var-a contains an unexpected value!");
        
        // lets see if we can see the effects of txid3
        (value, isSuccessful) = this.getValue(varb, txid2, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "get value failed unexpectedly!");
        Assert.equal("hello", value, "var-b contains an unexpected value!");
        this.setValue(vara, txid2, "I am the king!", TestsAccounts.getAccount(1));
        this.setValue(varb, txid2, "I am the boss!", TestsAccounts.getAccount(1));
        (value, isSuccessful) = this.getValue(vara, txid2, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "get value failed unexpectedly!");
        Assert.equal("I am the king!", value, "var-a contains an unexpected value!");
        (value, isSuccessful) = this.getValue(varb, txid2, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "get value failed unexpectedly!");
        Assert.equal("I am the boss!", value, "var-b contains an unexpected value!");
        lockedVariables = getLockedVariables(txid2);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
        this.prepare(txid2);
        this.commit(txid2);
        lockedVariables = getLockedVariables(txid2);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
        
    }
    
    /// #sender: account-1
    function testEffectsOfAbort() public {

        (string memory beforeSet, bool isSuccessful) = this.getValue(vara, txid5, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "get value failed unexpectedly!");
        this.setValue(vara, txid5, "this is a new value!", TestsAccounts.getAccount(1));
        string memory value = getBeforeImage(vara);
        Assert.equal(beforeSet, value, "incorrect value for vara.getBeforeImage()");
        (value, isSuccessful) = this.getValue(vara, txid5, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "get value failed unexpectedly!");
        Assert.equal("this is a new value!", value, "incorrect value for vara");
        isSuccessful = this.setValue(vara, txid5, "yet another new value!", TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "set value failed unexpectedly!");
        string[] memory lockedVariables = getLockedVariables(txid5);
        Assert.equal(1, lockedVariables.length, "incorrect number of variables locked!");
        this.abort(txid5);
        lockedVariables = getLockedVariables(txid5);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
        
        value = getBeforeImage(vara);
        Assert.equal("", value, "incorrect value for vara.getBeforeImage()");
        value = getValueNoLocking(vara);
        Assert.equal(beforeSet, value, "the value after abort must return to its original state");
        
        // lets see if we can the effects of txid5 were removed because of the abort
        (value, isSuccessful) = this.getValue(vara, txid4, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "get value failed unexpectedly!");
        Assert.equal("I am the king!", value, "incorrect value for vara");
        this.prepare(txid4);
        this.commit(txid4);
    }
    
    /// #sender: account-1
    function testLocks_ReadThenWrite() public {
    
        (string memory value, bool isSuccessful) = this.getValue(vara, txid6, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "get value failed unexpectedly!");
        (value, isSuccessful) = this.getValue(varb, txid6, TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "get value failed unexpectedly!");
        string[] memory lockedVariables = getLockedVariables(txid6);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
    
        isSuccessful = this.setValue(vara, txid6, "newValA", TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "set value failed unexpectedly!");
        isSuccessful = this.setValue(varb, txid6, "newValB", TestsAccounts.getAccount(1));
        Assert.ok(isSuccessful, "set value failed unexpectedly!");
        lockedVariables = getLockedVariables(txid6);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
        this.prepare(txid6);
        this.commit(txid6);
        
        lockedVariables = getLockedVariables(txid6);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
    }
}