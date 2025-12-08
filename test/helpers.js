const { ethers } = require("hardhat");

async function deployContract(name) {
    const Contract = await ethers.getContractFactory(name);
    const contract = await Contract.deploy();
    await contract.deployed();
    return contract;
}

module.exports = {
    deployContract,
};
