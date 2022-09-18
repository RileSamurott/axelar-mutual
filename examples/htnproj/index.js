const { predictContractConstant } = require("@axelar-network/axelar-gmp-sdk-solidity");
const { getGasPrice } = require("@axelar-network/axelar-local-dev");
const {
    Contract,
    getDefaultProvider,
    constants: { AddressZero },
    utils: { defaultAbiCoder },
} = require('ethers');
const {
    utils: { deployContract },
} = require('@axelar-network/axelar-local-dev');

const { deployUpgradable } = require('@axelar-network/axelar-gmp-sdk-solidity');
const Proxy = require('../../artifacts/examples/htnproj/Proxyhtn.sol/Proxy.json');
const DAO = require('../../artifacts/examples/htnproj/Dao.sol/Dao.json');
const ExampleProxy = require('../../artifacts/examples/Proxy.sol/ExampleProxy.json');

// Deploy function will not run!! - AS

async function deploy(chain, wallet) {
    // If ethereum, deploy the DAO. For all, deploy the proxy.
    //console.log(`Deploying Proxy for ${chain.name}: \nChain Gateway: ${chain.gateway}, \nChain GR: ${chain.gasReceiver}.`);
    //console.log(`shit that is changing (maybe): ${chain.constAddressDeployer}`)
    //var p = await predictContractConstant(chain.constAddressDeployer, wallet, Proxy, "prxy",  [chain.gateway]);
    const proxycontract = await deployContract(wallet, Proxy, [chain.gateway]);
    chain.proxy = proxycontract.address;
    var p = chain.proxy   // cheesing because we are not able to predict shit properly
    console.log(`Deployed Proxy for ${chain.name} at ${chain.proxy}.`);
    
    if (chain.name == "Ethereum") {
        const DAOcontract = await deployContract(wallet, DAO, [chain.gateway, chain.gasReceiver]);
        chain.DAO = DAOcontract.address;
        console.log(`\nDeployed DAO for ${chain.name} at ${chain.DAO}.`);
    }
    



}


async function test(chains, wallet, options) {
    
}

module.exports = {
    deploy,
    test,
};