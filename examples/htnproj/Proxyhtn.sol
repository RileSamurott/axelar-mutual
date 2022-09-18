pragma solidity 0.8.9;

// Implement dao.sol
// Path: dao.sol

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';

contract Proxy is AxelarExecutable {
    
    error IsLocked();
    error NotContract();

    uint256 internal constant IS_NOT_LOCKED = uint256(1);
    uint256 internal constant IS_LOCKED = uint256(2);

    uint256 internal _lockedStatus = IS_NOT_LOCKED;
    // idk if this works please remove if not needed
    IAxelarGateway internal _gateway;
    IAxelarGasService internal _gasService;
    address internal _dao;
    
    constructor(address gateway, address gasServiceo) AxelarExecutable(gateway) {
        _gateway = IAxelarGateway(gateway);
        _gasService = IAxelarGasService(_gasService);
    }

    
    function initialize(
        address dao
    ) public {
        _dao = dao;
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
    }
    
}