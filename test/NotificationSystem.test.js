const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NotificationSystem", function () {
    it("Should return the new notification once it's changed", async function () {
        const NotificationSystem = await ethers.getContractFactory("NotificationSystem");
        const notificationSystem = await NotificationSystem.deploy();
        await notificationSystem.deployed();

        // Test logic here
        expect(await notificationSystem.address).to.be.properAddress;
    });
});
