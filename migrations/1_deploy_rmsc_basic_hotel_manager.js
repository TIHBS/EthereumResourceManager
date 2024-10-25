const ResourceManager = artifacts.require("ResourceManager");
const StringUtils = artifacts.require("StringUtils");
const BasicHotelManager = artifacts.require("BasicHotelManager");

module.exports = function (deployer) {
      deployer.deploy(StringUtils);
      deployer.link(StringUtils, ResourceManager);
      deployer.link(StringUtils, BasicHotelManager);
      deployer.deploy(ResourceManager);
      deployer.deploy(BasicHotelManager);
}