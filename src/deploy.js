const { predictContractConstant } = require("@axelar-network/axelar-gmp-sdk-solidity");
const { getGasPrice } = require("@axelar-network/axelar-local-dev");
const { deploy } = require("../scripts/deploy");
const {
    getDefaultProvider,
    constants: { AddressZero },
    utils: { defaultAbiCoder },
} = require('ethers');

const { deployUpgradable } = require('@axelar-network/axelar-gmp-sdk-solidity');
const Proxy = require('../../artifacts/src/Proxy.sol/Proxy.json');
const DAO = require('../../artifacts/src/Dao.sol/Dao.json');
const ExampleProxy = require('../../artifacts/examples/Proxy.sol/ExampleProxy.json');

// Deploy function will not run!! - AS

async function deploy(wallet) {
    // If ethereum, deploy the DAO. For all, deploy the proxy.
    console.log(`Deploying ERC20CrossChain for ${chain.name}.`);
    var b = await predictContractConstant(chain.constAddressDeployer, wallet, Proxy, chain.name + "-proxy", []);
    var p = await predictContractConstant(chain.constAddressDeployer, wallet, Proxy, chain.name + "-proxy", []);
    const daocontract = await deployUpgradable(
        chain.constAddressDeployer,
        wallet,
        DAO,
        ExampleProxy,
        [chain.gateway, chain.gasReceiver, ],
        [],
        defaultAbiCoder.encode(['string', 'string'], [name, symbol]),
        'dao',
    );
    chain.crossChainToken = contract.address;
    console.log(`Deployed DAO for ${chain.name} at ${chain.crossChainToken}.`);

    const proxycontract = await deployUpgradable(
        chain.constAddressDeployer,
        wallet,
        DAO,
        ExampleProxy,
        [chain.gateway, chain.gasReceiver, decimals],
        [],
        defaultAbiCoder.encode(['string', 'string'], [name, symbol]),
        'dao',
    );
}


async function test(chains, wallet, options) {
    const args = options.args || [];
    const getGasPrice = options.getGasPrice;
    for (const chain of chains) {
        const provider = getDefaultProvider(chain.rpc);
        chain.wallet = wallet.connect(provider);
        chain.contract = await deployUpgradable(
            chain.constAddressDeployer,
            chain.wallet,
            ERC20CrossChain,
            ExampleProxy,
            [chain.gateway, chain.gasReceiver, decimals],
            [],
            defaultAbiCoder.encode(['string', 'string'], [name, symbol]),
            'cross-chain-token',
        );
    }
    const source = chains.find((chain) => chain.name === (args[0] || 'Avalanche'));
    const destination = chains.find((chain) => chain.name === (args[1] || 'Fantom'));
    const amount = parseInt(args[2]) || 1e5;
}

module.exports = {
    deploy,
    test,
};