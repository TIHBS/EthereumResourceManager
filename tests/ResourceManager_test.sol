// SPDX-License-Identifier: Apache-2.0
    
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/ResourceManager.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract TestExternalOperations {
    
    ResourceManager rm;
    string txid = "id-1";
    string txid2 = "id-2";
    string txid3 = "id-3";
    string txid4 = "id-4";
    string txid5 = "idd-5";
    string txid6 = "idd-6";
    string txid7 = "idd-7";

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
       
        rm = new ResourceManager();
    }
    
    function checkBegin() public {
        try rm.begin(txid) {
            Assert.ok(true, 'successfully started tx');
        } catch {
            Assert.ok(false, 'failed unexpected');
        }
    
        
        try rm.begin(txid) {
            Assert.ok(false, 'should not be able to start same tx again!');
        } catch  {
            Assert.ok(true, 'failed expectedly');
        }
        
        try rm.begin(txid2) {
            Assert.ok(true, 'successfully started tx2');
        } catch  {

            Assert.ok(false, 'failed unexpected');
        }
        
    }

    function checkTxOwner() public {
        try rm.begin(txid3) {
            Assert.ok(true, 'successfully started tx');
        } catch  {
            Assert.ok(false, 'failed unexpected');
        }
        
        address owner = rm.getTxOwner(txid);
        Assert.equal(owner, TestsAccounts.getAccount(0), "wrong sender");
    }
    
    function checkSuccessfulCommit() public {
        try rm.commit(txid) {
            Assert.ok(true, 'successfully committed tx');
        } catch {
            Assert.ok(false, 'failed unexpected');
        }
        
        try rm.commit(txid2) {
            Assert.ok(true, 'successfully committed tx2');
        } catch {
            Assert.ok(false, 'failed unexpected');
        }
    }
    
    /// #sender: account-1
    function checkFailedCommit_wrongSender() public {
        try rm.commit(txid3) {
            Assert.ok(false, 'successfully comitted unexpectedly');
        } catch  {
            Assert.ok(true, 'failed expectedly');
        }
    }
    
    function checkFailedCommit_alreadyCommitted() public {
        try rm.commit(txid) {
            Assert.ok(false, 'successfully comitted unexpectedly');
        } catch  {
            Assert.ok(true, 'failed expectedly');
        }
    }
    
    function checkFailedCommit_noTx() public {
        try rm.commit(txid4) {
            Assert.ok(false, 'successfully comitted unexpectedly');
        } catch  {
            Assert.ok(true, 'failed expectedly');
        }
    }
    
    function checkSuccessfulAbort() public {
        try rm.begin(txid4) {
            Assert.ok(true, 'successfully started tx4');
        } catch {
            Assert.ok(false, 'failed unexpected');
        }
        
        try rm.begin(txid5) {
            Assert.ok(true, 'successfully started tx4');
        } catch {
            Assert.ok(false, 'failed unexpected');
        }
        
        try rm.abort(txid4) {
            Assert.ok(true, 'successfully aborted tx4');
        } catch {
            Assert.ok(false, 'failed unexpectedly');
        }
    }
    
    
    /// #sender: account-1
    function checkFailedAbort_wrongSender() public {
        try rm.abort(txid5) {
            Assert.ok(false, 'successfully aborted unexpectedly');
        } catch  {
            Assert.ok(true, 'failed expectedly');
        }
    }
    
    function checkFailedAbort_alreadyAborted() public {
        try rm.abort(txid4) {
            Assert.ok(false, 'successfully aborted unexpectedly');
        } catch  {
            Assert.ok(true, 'failed expectedly');
        }
    }
    
    function checkFailedAbort_alreadyCommitted() public {
        try rm.abort(txid) {
            Assert.ok(false, 'successfully aborted unexpectedly');
        } catch  {
            Assert.ok(true, 'failed expectedly');
        }
    }
    
    function checkFailedAbort_noTx() public {
        try rm.abort(txid6) {
            Assert.ok(false, 'successfully aborted unexpectedly');
        } catch  {
            Assert.ok(true, 'failed expectedly');
        }
    }
    
    /*
    function toString(address account) private pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(uint256 value) private pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }
    
    function toString(bytes32 value) private pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }
    
    function toString(bytes memory data) private pure returns(string memory) {
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
    */


}


