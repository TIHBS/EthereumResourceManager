const ResourceManager = artifacts.require("ResourceManager");
const StringUtils = artifacts.require("StringUtils");

module.exports = function (deployer) {
      deployer.deploy(StringUtils);
      deployer.link(StringUtils, ResourceManager);
      deployer.deploy(ResourceManager);
}