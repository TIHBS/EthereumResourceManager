// SPDX-License-Identifier: Apache-2.0
    
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/ResourceManager.sol";
import "hardhat/console.sol";


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
    
    /**
     * @dev tests the compareStrings function
     */ 
    function testCompareStrings() public {
        string memory a = "abc";
        string storage b = abc;
        string memory c = "abc";
        string storage d = abc2;
        
        Assert.ok(compareStrings(a, b), "strings are equal");
        Assert.ok(compareStrings(a, c), "strings are equal");
        Assert.ok(compareStrings(b, d), "strings are equal");
        Assert.ok(compareStrings(a, a), "strings are equal");
    }
    
    /**
     * @dev tests how we copy strings
     */ 
    function testCopyStrings() public {
        variables[vara].value = "a";
        variables[vara].beforeImage = "b";
        string memory beforeImage = variables[vara].beforeImage;
        variables[vara].value = beforeImage;
        variables[vara].beforeImage = "";
        
        Assert.equal("b", variables[vara].value, "incorrect value");
        Assert.equal("", variables[vara].beforeImage, "incorrect beforeImage");
    }
    
    /**
     * b_tx1 w_tx1[vara] w_tx2[varb] r_tx1[varb] c_tx1
     */ 
    function testHappyPathWriteThenRead() public {
        this.begin(txid);
        setValue(vara, txid, "hello");
        setValue(varb, txid, "bye bye");
        string memory value = getValue(vara, txid);
        Assert.equal("hello", value, "var-a contains an unexpected value!");
        value = getValue(varb, txid);
        Assert.equal("bye bye", value, "var-a contains an unexpected value!");
        string[] memory lockedVariables = getLockedVariables(txid);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
        
        this.commit(txid);
    }
    
    /**
     * b_tx2 r_tx2[vara]                                                 r_tx2[vara] r_tx2[varb] w_tx2[vara] w_tx2[varb] r_tx2[vara] r_tx2[varb] c_tx2
     *                   b_tx3 r_tx3[vara] w_tx3[varb] r_tx3[varb] c_tx3 
     */ 
    function testTwoTransactions() public {
        this.begin(txid2);
        string memory value = getValue(vara, txid2);
        Assert.equal("hello", value, "var-a contains an unexpected value!");
        
        
        this.begin(txid3);
        value = getValue(vara, txid3);
        string memory value2 = getValue(varb, txid3);
        Assert.equal("bye bye", value2, "var-b contains an unexpected value!");
        setValue(varb, txid3, value);
        value2 = getValue(varb, txid3);
        Assert.equal("hello", value2, "var-b contains an unexpected value!");
        string[] memory lockedVariables = getLockedVariables(txid3);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
        this.commit(txid3);
        lockedVariables = getLockedVariables(txid3);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
        

        value = getValue(vara, txid2);
        Assert.equal("hello", value, "var-a contains an unexpected value!");
        
        // lets see if we can see the effects of txid3
        value = getValue(varb, txid2);
        Assert.equal("hello", value, "var-b contains an unexpected value!");
        setValue(vara, txid2, "I am the king!");
        setValue(varb, txid2, "I am the boss!");
        value = getValue(vara, txid2);
        Assert.equal("I am the king!", value, "var-a contains an unexpected value!");
        value = getValue(varb, txid2);
        Assert.equal("I am the boss!", value, "var-b contains an unexpected value!");
        lockedVariables = getLockedVariables(txid2);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
        this.commit(txid2);
        lockedVariables = getLockedVariables(txid2);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
        
    }
    
    /**
     * b_tx4                                                 r_tx4[vara] c_tx4
     *       b_tx5 r_tx5[vara] w_tx5[vara] r_tx5[vara] a_tx5
     */ 
    function testEffectsOfAbort() public {
        this.begin(txid4);
        
        this.begin(txid5);
        string memory value = getValue(vara, txid5);
        
        setValue(vara, txid5, "this is a new value!");
        value = getBeforeImage(vara);
        Assert.equal("I am the king!", value, "incorrect value for vara.getBeforeImage()");
        value = getValue(vara, txid5);
        Assert.equal("this is a new value!", value, "incorrect value for vara");
        string[] memory lockedVariables = getLockedVariables(txid5);
        Assert.equal(1, lockedVariables.length, "incorrect number of variables locked!");
        this.abort(txid5);
        lockedVariables = getLockedVariables(txid5);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
        
        value = getBeforeImage(vara);
        Assert.equal("", value, "incorrect value for vara.getBeforeImage()");
        
        // lets see if we can the effects of txid5 were removed because of the abort
        value = getValue(vara, txid4);
        Assert.equal("I am the king!", value, "incorrect value for vara");
        
        this.commit(txid4);
    }
    
    /**
     * b_tx6 r_tx6[vara] r_tx6[varb] w_tx6[vara] w_tx6[varb] c_tx6
     */ 
    function testLocks_ReadThenWrite() public {
        this.begin(txid6);
        
        string memory value1 = getValue(vara, txid6);
        string memory value2 = getValue(varb, txid6);
        string[] memory lockedVariables = getLockedVariables(txid6);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
    
        setValue(vara, txid6, "newValA");
        setValue(varb, txid6, "newValB");
        lockedVariables = getLockedVariables(txid6);
        Assert.equal(2, lockedVariables.length, "incorrect number of variables locked!");
    
        this.commit(txid6);
        
        lockedVariables = getLockedVariables(txid6);
        Assert.equal(0, lockedVariables.length, "incorrect number of variables locked!");
    }
}