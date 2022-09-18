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
        uint256 price;
        uint256 upv; // votes in favour
        uint256 downv; // votes in opposition
        uint256 abstainv; // number of people who have yet to vote (decremented wth every vote functon call)
        ProposalStatus status; // status of proposal
    }

    uint256 public incirctoken;
    Proposal[] public proposals;
    mapping(address => mapping (address => uint256)) allowed;
    IAxelarGasService public immutable gasReceiver;

    constructor(address gateway_, address gasReceiver_) AxelarExecutable(gateway_) ERC20('','',18) {
        gasReceiver = IAxelarGasService(gasReceiver_);
    }

    function pushProposal(
        address calldata author,   ProposalType proposalType,
        uint256 amount,
        uint256 price
    ) public {
        proposals.push(
            Proposal({
                author: author,
                token: token,
                proposalType: proposalType,
                amount: amount,
                price: price,
                upv: 0,
                downv: 0,
                abstainv: incirctoken,
                status: ProposalStatus.Active
            })
        );
    }

    function vote(uint256 proposalId, bool voteYes) public {
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
        this.transferFrom(msg.sender, address(this), amount);
        
        // Mint new tokens to user
        _mint(msg.sender, amount);
        incirctoken += amount;
        // Transfer to msg.sender

    }

    function burnTokens(uint256 amount) public {
        // Burn tokens from user
        _burn(address(this), amount);
        incirctoken -= amount;
        // Transfer tokens from DAO to user
        this.transfer(msg.sender, amount);
    }

    function getGovTokenValue() public view returns (uint256) {
        return 1; // REMOVE THIS!!! THIS IS TEMPORARY
        // get the value of token using memoery of tokens boght and a
    }
}
