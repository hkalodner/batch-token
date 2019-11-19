const BatchToken = artifacts.require("./BatchToken.sol");

module.exports = function(deployer) {
  deployer.deploy(BatchToken);
};
