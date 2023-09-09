var MyContract = artifacts.require("VRFv2Consumer");
module.exports = function(deployer) {
    deployer.deploy(MyContract,"1218");
};