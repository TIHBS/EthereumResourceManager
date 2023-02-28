// SPDX-License-Identifier: Apahce-2.0
    
pragma solidity >=0.4.22 <0.9.0;

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
    
    function testHappyPathWriteThenRead() public {
        this.begin(txid);
        this.setValue(vara, txid, "hello");
        this.setValue(varb, txid, "bye bye");
        string memory value = this.getValue(vara, txid);
        Assert.equal("hello", value, "var-a contains an unexpected value!");
        value = this.getValue(varb, txid);
        Assert.equal("bye bye", value, "var-a contains an unexpected value!");
        string[] memory lockedVariables = getLockedVariables(txid);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
        
        this.commit(txid);
    }
    
    function testTwoTransactions() public {
        this.begin(txid2);
        string memory value = this.getValue(vara, txid2);
        Assert.equal("hello", value, "var-a contains an unexpected value!");
        
        
        this.begin(txid3);
        value = this.getValue(vara, txid3);
        string memory value2 = this.getValue(varb, txid3);
        Assert.equal("bye bye", value2, "var-b contains an unexpected value!");
        this.setValue(varb, txid3, value);
        value2 = this.getValue(varb, txid3);
        Assert.equal("hello", value2, "var-b contains an unexpected value!");
        string[] memory lockedVariables = getLockedVariables(txid3);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
        this.commit(txid3);
        lockedVariables = getLockedVariables(txid3);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
        

        value = this.getValue(vara, txid2);
        Assert.equal("hello", value, "var-a contains an unexpected value!");
        
        // lets see if we can see the effects of txid3
        value = this.getValue(varb, txid2);
        Assert.equal("hello", value, "var-b contains an unexpected value!");
        this.setValue(vara, txid2, "I am the king!");
        this.setValue(varb, txid2, "I am the boss!");
        value = this.getValue(vara, txid2);
        Assert.equal("I am the king!", value, "var-a contains an unexpected value!");
        value = this.getValue(varb, txid2);
        Assert.equal("I am the boss!", value, "var-b contains an unexpected value!");
        lockedVariables = getLockedVariables(txid2);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
        this.commit(txid2);
        lockedVariables = getLockedVariables(txid2);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
        
    }
    
    function testEffectsOfAbort() public {
        this.begin(txid4);
        
        this.begin(txid5);
        string memory value = this.getValue(vara, txid5);
        
        this.setValue(vara, txid5, "this is a new value!");
        value = getBeforeImage(vara);
        Assert.equal("I am the king!", value, "incorrect value for vara.getBeforeImage()");
        value = this.getValue(vara, txid5);
        Assert.equal("this is a new value!", value, "incorrect value for vara");
        string[] memory lockedVariables = getLockedVariables(txid5);
        Assert.equal(1, lockedVariables.length, "incorrect number of variables locked!");
        this.abort(txid5);
        lockedVariables = getLockedVariables(txid5);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
        
        value = getBeforeImage(vara);
        Assert.equal("", value, "incorrect value for vara.getBeforeImage()");
        
        // lets see if we can the effects of txid5 were removed because of the abort
        value = this.getValue(vara, txid4);
        Assert.equal("I am the king!", value, "incorrect value for vara");
        
        this.commit(txid4);
    }
    
    function testLocks_ReadThenWrite() public {
        this.begin(txid6);
        
        string memory value1 = this.getValue(vara, txid6);
        string memory value2 = this.getValue(varb, txid6);
        string[] memory lockedVariables = getLockedVariables(txid6);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
    
        this.setValue(vara, txid6, "newValA");
        this.setValue(varb, txid6, "newValB");
        lockedVariables = getLockedVariables(txid6);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
    
        this.commit(txid6);
        
        lockedVariables = getLockedVariables(txid6);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
    }
}