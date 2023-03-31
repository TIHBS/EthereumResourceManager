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
        (uint initialPrice, bool isSuccessful1) = hm.queryRoomPrice("tx1");
        bool isSuccessful2 = hm.changeRoomPrice("tx1", initialPrice * 2);
        (uint newPrice, bool isSuccessful3) = hm.queryRoomPrice("tx1");
        Assert.equal(initialPrice * 2, newPrice, "price should double!");
        rm.prepare("tx1");
        rm.commit("tx1");

        Assert.ok(isSuccessful1 && isSuccessful2 && isSuccessful3, "Failed unexpectedly!");
    }

    function testChangeBalance() public {
        (uint initialBalance, bool isSuccessful1) = hm.queryClientBalance("tx2");
        bool isSuccessful2 = hm.addToClientBalance("tx2", 2000);
        (uint newBalance, bool isSuccessful3) = hm.queryClientBalance("tx2");
        Assert.equal(initialBalance + 2000, newBalance, "balance should increase!");
        rm.prepare("tx2");
        rm.commit("tx2");

        Assert.ok(isSuccessful1 && isSuccessful2 && isSuccessful3, "Failed unexpectedly!");
    }

    function testBookRoom() public {
        bool isAvailable = hm.isRoomAvailable("tx3");
        Assert.ok(isAvailable, "the room must be available at this stage!");
        (uint initialBalance, bool isSuccessful1) = hm.queryClientBalance("tx3");
        (uint roomPrice, bool isSuccessful2) = hm.queryRoomPrice("tx3");
        hm.bookRoom("tx3");
        (uint newBalance, bool isSuccessful3) = hm.queryClientBalance("tx3");
        isAvailable = hm.isRoomAvailable("tx3");
        Assert.equal(initialBalance - roomPrice, newBalance, "the new balance should be the old one minus the room price");
        Assert.ok(!isAvailable, "the room must be booked at this stage!");
        rm.prepare("tx3");
        rm.commit("tx3");

        Assert.ok(isSuccessful1 && isSuccessful2 && isSuccessful3, "Failed unexpectedly!");
    }

    function testCheckout() public {
        (bool hasReservation, bool isSuccessful1) = hm.hasReservation("tx4");
        Assert.ok(hasReservation, "we must have a reservation now!");
        hm.checkout("tx4");
        (bool hasReservation1, bool isSuccessful2) = hm.hasReservation("tx4");
        Assert.ok(!hasReservation1, "we must have no reservation now!");
        rm.prepare("tx4");
        rm.commit("tx4");

        Assert.ok(isSuccessful1 && isSuccessful2, "Failed unexpectedly!");
    }

    function realWorldScenario() public {
        // increase price
        (uint price, bool isSuccessful1) = hm.queryRoomPrice("txf1");
        hm.changeRoomPrice("txf1", 320);
        rm.prepare("txf1");
        rm.commit("txf1");

        // try to book -- uh oh not enough money, abort
        bool isAvailable = hm.isRoomAvailable("txf2");
        (uint price2, bool isSuccessful2) = hm.queryRoomPrice("txf2");
        (uint balance, bool isSuccessful3) = hm.queryClientBalance("txf2");
        rm.prepare("txf2");
        rm.abort("txf2");
        
        // add to the balance
        hm.addToClientBalance("txf3", 5000);
        rm.prepare("txf3");
        rm.commit("txf3");

        // now do the actual booking
        isAvailable = hm.isRoomAvailable("txf4");
        (uint price3, bool isSuccessful4) = hm.queryRoomPrice("txf4");
        (uint balance2, bool isSuccessful5) = hm.queryClientBalance("txf4");
        Assert.ok(balance2 > price3, "we should have enough balance now!");
        hm.bookRoom("txf4");
        rm.prepare("txf4");
        rm.commit("txf4");

        Assert.ok(isSuccessful1 && isSuccessful2 && isSuccessful3 && isSuccessful4 && isSuccessful5, "Failed unexpectedly!");
    }
}
    
    