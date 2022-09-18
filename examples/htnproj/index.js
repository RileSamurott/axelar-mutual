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
    var proxycontracts = [];
    const daochain = chains.find(chain => chain.name == "Ethereum");
    for (const chain of chains) {
        console.log(`Deploying Proxy for ${chain.name}`);
        const provider = getDefaultProvider(chain.rpc);
        chain.wallet = wallet.connect(provider);
        chain.proxy = deployContract(chain.wallet, Proxy, [chain.gateway, chain.gasReceiver]);
        proxycontracts.push(chain.proxy);
        console.log(`Deployed Proxy to ${chain.name}`);
    }
    var end = await Promise.all(proxycontracts);
    daochain.dao = await deployContract(daochain.wallet, DAO, [daochain.gateway, daochain.gasReceiver]);
    for (const contract of end) {
        contract.initialize(daochain.dao.address);
        console.log(`Added DAO to ${contract.address} Proxy.`);
    }
    console.log(chains.map(chain => chain.name));
    console.log(end.map(obj => obj.address));

    await daochain.dao.pushProposal(
        "Aayush", 1, "ETH", 1500, "Ethereum"
    );

    // console.log(daochain.dao) 
    
    


}

module.exports = {
    deploy,
    test,
};