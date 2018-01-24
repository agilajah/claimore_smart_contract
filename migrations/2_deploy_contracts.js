var StringUtils = artifacts.require("./StringUtils.sol");
var LifeInsurancePolicy = artifacts.require("./LifeInsurancePolicy.sol");

module.exports = function(deployer) {
    deployer.deploy(StringUtils);
    deployer.link(StringUtils, LifeInsurancePolicy);
    deployer.deploy(LifeInsurancePolicy);
}