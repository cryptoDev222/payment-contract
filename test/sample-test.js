const { expect } = require("chai");

describe("Organization & Factory", function() {
  it("Should deploy", async function() {
    const [account, account1, account2] = await hre.ethers.getSigners();

    const Organization = await ethers.getContractFactory("Organization");
    const organization = await Organization.deploy();
    
    await organization.deployed();

    const Factory = await ethers.getContractFactory("Factory");
    const factory = await Factory.deploy();
    
    await factory.deployed();

    await factory.setClonableOrganization(organization.address);

    await factory.addOrganization("Apple");

    const addr = await factory.userOrganizations(account.address, 0);

    await factory.addAdmin(addr, account1.address);

    const admin = await factory.orgAdmins(addr, 0);
    console.log("admin", admin);

    expect(admin).to.equals(account1.address);

    console.log("Address", addr);

    factory.on("TokenSend", (data) => console.log(data))
  });
});
