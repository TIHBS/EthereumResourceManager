// SPDX-License-Identifier: Apache-2.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 
import "../contracts/ResourceManager.sol";

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/HotelManager.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract TestHotelManager {
    ResourceManager rm;
    HotelManager hm;
    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        rm = new ResourceManager();
        address rmAddress = address(rm);
        hm = new HotelManager();
        hm.setResourceManagerAddress(rmAddress);
    }

    function testChangePrice() public {
        rm.begin("tx1");
        uint initialPrice = hm.queryRoomPrice("tx1");
        hm.changeRoomPrice("tx1", initialPrice * 2);
        uint newPrice = hm.queryRoomPrice("tx1");
        Assert.equal(initialPrice * 2, newPrice, "price should double");
    }
}
    