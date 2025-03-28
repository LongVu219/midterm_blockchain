// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.

const path = require("path");

async function main() {
  // Predefined fee collector address
  const FEE_COLLECTOR_ADDRESS = "0x54A0e29fDe67Ed72Dd9b272E7c47696DB8B8cec7";

  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  // ethers is available in the global scope
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());
  console.log("Fee Collector Address:", FEE_COLLECTOR_ADDRESS);

  const Token = await ethers.getContractFactory("Token");
  
  // Deploy the token with the predefined fee collector address
  const token = await Token.deploy(FEE_COLLECTOR_ADDRESS);
  await token.deployed();

  console.log("Token address:", token.address);

  // Verify the fee collector is set correctly
  const currentFeeCollector = await token.feeCollector();
  console.log("Deployed Token's Fee Collector:", currentFeeCollector);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(token);
}

function saveFrontendFiles(token) {
  const fs = require("fs");
  const contractsDir = path.join(__dirname, "..", "frontend", "src", "contracts");

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    path.join(contractsDir, "contract-address.json"),
    JSON.stringify({ 
      Token: token.address,
      FeeCollector: "0x54A0e29fDe67Ed72Dd9b272E7c47696DB8B8cec7"
    }, undefined, 2)
  );

  const TokenArtifact = artifacts.readArtifactSync("Token");

  fs.writeFileSync(
    path.join(contractsDir, "Token.json"),
    JSON.stringify(TokenArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });