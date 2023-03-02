// SPDX-License-Identifier: Apache-2.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 
import "hardhat/console.sol";
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
        Assert.equal(initialPrice * 2, newPrice, "price should double!");
        rm.commit("tx1");
    }

    function testChangeBalance() public {
        rm.begin("tx2");
        uint initialBalance = hm.queryClientBalance("tx2");
        hm.addToClientBalance("tx2", 2000);
        uint newBalance = hm.queryClientBalance("tx2");
        Assert.equal(initialBalance + 2000, newBalance, "balance should increase!");
        rm.commit("tx2");
    }

    function testBookRoom() public {
        rm.begin("tx3");
        bool isAvailable = hm.isRoomAvailable("tx3");
        Assert.ok(isAvailable, "the room must be available at this stage!");
        uint initialBalance = hm.queryClientBalance("tx3");
        uint roomPrice = hm.queryRoomPrice("tx3");
        hm.bookRoom("tx3");
        uint newBalance = hm.queryClientBalance("tx3");
        isAvailable = hm.isRoomAvailable("tx3");
        Assert.equal(initialBalance - roomPrice, newBalance, "the new balance should be the old one minus the room price");
        Assert.ok(!isAvailable, "the room must be booked at this stage!");
        rm.commit("tx3");
    }

    function testCheckout() public {
        rm.begin("tx4");
        bool hasReservation = hm.hasReservation("tx4");
        Assert.ok(hasReservation, "we must have a reservation now!");
        hm.checkout("tx4");
        hasReservation = hm.hasReservation("tx4");
        Assert.ok(!hasReservation, "we must have no reservation now!");
        rm.commit("tx4");
    }

    function realWorldScenario() public {
        // increase price
        rm.begin("txf1");
        uint price = hm.queryRoomPrice("txf1");
        hm.changeRoomPrice("txf1", 320);
        rm.commit("txf1");

        // try to book -- uh oh not enough money, abort
        rm.begin("txf2");
        bool isAvailable = hm.isRoomAvailable("txf2");
        price = hm.queryRoomPrice("txf2");
        uint balance = hm.queryClientBalance("txf2");
        rm.abort("txf2");
        
        // add to the balance
        rm.begin("txf3");
        hm.addToClientBalance("txf3", 5000);
        rm.commit("txf3");

        // now do the actual booking
        rm.begin("txf4");
        isAvailable = hm.isRoomAvailable("txf4");
        price = hm.queryRoomPrice("txf4");
        balance = hm.queryClientBalance("txf4");
        Assert.ok(balance > price, "we should have enough balance now!");
        hm.bookRoom("txf4");
        rm.commit("txf4");
    }
}
    
    