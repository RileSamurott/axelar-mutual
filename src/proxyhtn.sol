pragma solidity 0.8.9;

// Implement dao.sol
// Path: dao.sol

import { ERC20CrossChain } from '../examples/cross-chain-token/ERC20CrossChain.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol';
import { ERC20 } from '@axelar-network/axelar-cgp-solidity/contracts/ERC20.sol';

contract Proxy is AxelarExecutable, ERC20 {
    error IsLocked();
    error NotContract();

    uint256 internal constant IS_NOT_LOCKED = uint256(1);
    uint256 internal constant IS_LOCKED = uint256(2);

    uint256 internal _lockedStatus = IS_NOT_LOCKED;

    // idk if this works please remove if not needed
    IAxelarGateway internal _gateway = IAxelarGateway(0x0000000000000000000000000000000000000000);
    IAxelarGasService internal _gasService = IAxelarGasService(0x0000000000000000000000000000000000000000);

    function initialize(
        address gateway,
        address gasService,
        address token
    ) public initializer {
        _gateway = IAxelarGateway(gateway);
        _gasService = IAxelarGasService(gasService);
        _token = IERC20(token);
    }
    // end of dk if this works

    modifier noReenter() {
        if (_lockedStatus == IS_LOCKED) revert IsLocked();

        _lockedStatus = IS_LOCKED;
        _;
        _lockedStatus = IS_NOT_LOCKED;
    }

    function execute(address callee, bytes calldata data) external noReenter returns (bool success, bytes memory returnData) {
        if (callee.code.length == 0) revert NotContract();
        (success, returnData) = callee.call(data);
    }

    // Proxy recieves info about three things:
    // 1. Ticker
    // 2. Action
    // 3. Amount
    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        (address callee, string ticker, bool sell, uint256 amount) = abi.decode(payload_ (address, string, bool, uint256));
    }
}