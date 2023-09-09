const { ethers } = require('hardhat')

async function main() {

    const RandomGen = await ethers.getContractFactory('ContestCampaign');
    const randomGen = await RandomGen.deploy(2379);

    await randomGen.deployed();
    console.log("Randomgen deployed on:", randomGen.address)
}

main().catch(_err => {
    throw _err
})