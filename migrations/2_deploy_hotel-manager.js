const ResourceManager = artifacts.require("ResourceManager");
const HotelManager = artifacts.require("HotelManager");

module.exports = async function (deployer) {
      await deployer.deploy(HotelManager);
      const hm =  await HotelManager.deployed();
      const rm = await ResourceManager.deployed();
      await hm.setResourceManagerAddress(rm.address);
}