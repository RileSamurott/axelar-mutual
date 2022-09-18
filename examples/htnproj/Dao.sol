pragma solidity 0.8.9;

// Implement dao.sol
// Path: dao.sol

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { ERC20 } from '@axelar-network/axelar-cgp-solidity/contracts/ERC20.sol';
import { IDao } from './IDao.sol';


contract DAO is ERC20, IDao, AxelarExecutable {
    enum ProposalStatus {
        Active,
        Rejected,
        Approved,
        Executed
    }

    enum ProposalType {
        BUY,
        SELL
    }

    struct Proposal {
        string author;
        string token;
        ProposalType proposalType; // true = sell, false = buy
        uint256 amount;
        string destinationChain;
        uint256 upv; // votes in favour
        uint256 downv; // votes in opposition
        uint256 abstainv; // number of people who have yet to vote (decremented wth every vote functon call)
        ProposalStatus status; // status of proposal
    }

    uint256 public incirctoken;
    Proposal[] public proposals;
    string[] public chainaddrs;
    mapping(string => address) chproxies;
    //mapping(address => mapping (address => uint256)) allowed;
    IAxelarGasService public immutable gasReceiver;

    constructor(address gateway_, address gasReceiver_) AxelarExecutable(gateway_) ERC20('','',18) {
        gasReceiver = IAxelarGasService(gasReceiver_);
    }

    function initProxyAddrs(
        string[] memory chains,
        address[] memory proxies
    ) public {
        for (uint i = 0; i < chains.length; i++) {
            chainaddrs.push(chains[i]);
            chproxies[chains[i]] = proxies[i];
        }
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

        function char(bytes1 b) internal pure returns (bytes1 c) {
            if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
            else return bytes1(uint8(b) + 0x57);
    }

    function pushProposal(
        string memory author,   
        ProposalType proposalType,
        string memory token,
        uint256 amount,
        string memory destinationChain
    ) public {
        proposals.push(
            Proposal({
                author: author,
                token: token,
                proposalType: proposalType,
                amount: amount,
                destinationChain: destinationChain,
                upv: 0,
                downv: 0,
                abstainv: incirctoken,
                status: ProposalStatus.Active
            })
        );
    }

    // Why is this payable? - AS
    function vote(uint256 proposalId, bool voteYes) public payable {
        // Fetch proposal from storage
        Proposal storage proposal = proposals[proposalId];

        // Check if proposal is active
        require(proposal.status == ProposalStatus.Active, 'Proposal is not active');

        // Check if user has already voted
        //require(proposal.votes[msg.sender] == 0, 'You have already voted');

        // Number of votes is how many gov tokens sender has
        uint256 numVotes = sqrt((this).balanceOf(msg.sender));

        // if voteYes is true, then upv is incremented by numVotes
        if (voteYes) {
            proposal.upv += numVotes;
        }
        // if voteYes is false, then downv is incremented by numVotes
        else {
            proposal.downv += numVotes;
        }

        // Remove the number of votes from the abstainv count
        proposal.abstainv -= numVotes;

        // Remember number of votes that the user has cast
        //proposal.votes[msg.sender] = numVotes;

        // If abstainv is 0, then the proposal is executed. Set arbitrary threshold for now
        if (proposal.abstainv == 0) {
            if (proposal.upv > proposal.downv) {
                proposal.status = ProposalStatus.Approved;
                bytes memory payload = abi.encode(proposal.token, uint(proposal.proposalType), proposal.amount);
                string memory dest = proposal.destinationChain;
                string memory proxy = toAsciiString(chproxies[proposal.destinationChain]);
                gasReceiver.payNativeGasForContractCall{ value: msg.value }(
                    address(this),
                    dest,
                    proxy,
                    payload,
                    address(this)
                );
                gateway.callContractWithToken(dest, proxy, payload, 'aUSDC', proposal.amount);
            } else {
                proposal.status = ProposalStatus.Rejected;
            }
        }
    }

    // Square root function
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    
    function buyTokens(uint256 amount) public {
        // Transfer tokens from user to DAO
        // User must call APPROVE function before
        // Axelar Wrapped aUSDC is used as the token
        // Addr: 0xb2F4857D2e4374db9Fc6CD2D3Abd69D86F2C511d (localnet)
        // Change this if it changes 
        this.transferFrom(msg.sender, address(0xb2F4857D2e4374db9Fc6CD2D3Abd69D86F2C511d), amount);
        
        // Calculate how many gov tokens to mint
        uint govTokenAmount = amount / getGovTokenValue();

        // Mint new tokens to user
        _mint(msg.sender, govTokenAmount);
        incirctoken += govTokenAmount;
    }

    function sellTokens(uint amount) public {
        // Require that there is enough USDC in the DAO
        require(this.balanceOf(address(0xb2F4857D2e4374db9Fc6CD2D3Abd69D86F2C511d)) >= 10 * 10e13, 'Not enough USDC in DAO');

        // Burn tokens from user
        _burn(msg.sender, amount);

        // Decrement incirctoken
        incirctoken -= amount;

        // Transfer USDC to user
        this.transfer(msg.sender, amount * getGovTokenValue());
    }

    // How does this work? - AS
    function burnTokens(uint256 amount) public {
        // Burn tokens from user
        _burn(address(this), amount);
        incirctoken -= amount;
        // Transfer tokens from DAO to user
        // this.transfer(msg.sender, amount);
    }

    function getGovTokenValue() public view returns (uint256) {
        return 1; // REMOVE THIS!!! THIS IS TEMPORARY
        // get the value of token using memoery of tokens boght and a
    }
}
