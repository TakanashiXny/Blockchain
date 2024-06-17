// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;
pragma experimental ABIEncoderV2;

contract Voting {
    struct Candidate {
        address addr;
        uint256 votes;
    }

    struct Vote {
        uint256 voteIndex;
        address creator;
        string name;
        uint256 maxVoters;
        uint256 endTime;
        uint256 candidateNum;
        uint256 totalVoters;
        bool closed;
        address winner;
    }

    uint256 voteNum; 
    Vote[] public votes;
    Vote[] public closedVotes;
    // uint256[] openIndexes;
    uint256[] closeIndexes;
    mapping(uint256 => Candidate[]) public voteToCandidates;
    mapping(uint256 => address[]) public voteToVoters;
    bytes32[] public transactionHashes;

    // constructor () public {
    //     voteNum = 0;
    // }

    function getVoteNum() public view returns (uint256) {
        return voteNum;
    }

    function createVote(string memory _name, uint256 _max_voters, uint256 _endTime) public payable returns (uint256) {
        // require(_endTime > block.timestamp, "End time must be in the future");

        // 创建投票实例并添加到数组中
        Vote memory newVote = Vote({
            voteIndex: votes.length,
            creator: msg.sender,
            name: _name,
            maxVoters: _max_voters,
            endTime: _endTime,
            candidateNum: 0,
            totalVoters: 0,
            closed: false,
            winner: address(0)
        });
        votes.push(newVote);
        voteNum++;
        payable(address(this)).transfer(msg.value);
        bytes32 txHash = blockhash(block.number - 1);
        transactionHashes.push(txHash);
        return votes.length - 1; // 返回新投票的索引作为投票地址
    }

    function getOpenVotes() public view returns (int[100] memory) {
        uint256 openNum = 0;
        for (uint256 i = 0; i < votes.length; i++) {
            if (!votes[i].closed) {
                openNum++;
            }
        }
        int[100] memory openIndexes;
        // uint256[] storage openIndexes;
        uint256 index = 0;
        for (uint256 i = 0; i < votes.length; i++) {
            if (!votes[i].closed) {
                openIndexes[index] = int(i);
                // openIndexes.push(i);
                index++;
            }
        }

        return openIndexes;
    }

    function getVotes() public view returns (Vote[] memory) {
        return votes;
    }

    function whetherOpen(uint256 _index) public view returns (bool) {
        return !votes[_index].closed;
    }

    function getVote(uint256 voteIndex) public view returns (bool closed_, address creator_, string memory name_, uint256 endTime_, address winner_) {
        return (votes[voteIndex].closed, votes[voteIndex].creator, votes[voteIndex].name, votes[voteIndex].endTime, votes[voteIndex].winner);
    } 

    function getClosedVotes() public view returns (uint256[] memory) {
        return closeIndexes;
    }

    function addCandidate(uint256 _voteIndex) public payable {
        voteToCandidates[_voteIndex].push(Candidate(msg.sender, 0));
        votes[_voteIndex].candidateNum++;
        payable(votes[_voteIndex].creator).transfer(msg.value); 
        bytes32 txHash = blockhash(block.number - 1);
        transactionHashes.push(txHash);
    }

    function vote(uint256 _voteIndex, uint256 _candidateIndex) public payable returns (bool) {
        // require(_voteIndex < votes.length, "Invalid vote index");
        // require(!votes[_voteIndex].closed, "Vote is closed");
        // require(votes[_voteIndex].endTime > block.timestamp, "Voting has ended");

        // for (uint i = 0; i < voteToVoters[_voteIndex].length; i++) {
        //     if (voteToVoters[_voteIndex][i] == msg.sender) {
        //         return false;
        //     }
        // }
        voteToCandidates[_voteIndex][_candidateIndex].votes++;
        voteToVoters[_voteIndex].push(msg.sender);
        votes[_voteIndex].totalVoters++;

        // 检查是否到达指定的投票人数
        if (votes[_voteIndex].totalVoters >= votes[_voteIndex].maxVoters) {
            endVote(_voteIndex);
            return true;
        } 
        return false;
    }

    function getCandidates(uint256 _voteIndex) public view returns (address[] memory) {
        address[] memory candidates = new address[](votes[_voteIndex].candidateNum);
        for (uint256 i = 0; i < votes[_voteIndex].candidateNum; i++) {
            candidates[i] = voteToCandidates[_voteIndex][i].addr;
        }
        return candidates;
    }

    function getWinner(uint256 _voteIndex) public view returns (address) {
        return votes[_voteIndex].winner;
    }

    function endVote(uint256 _voteIndex) public payable {
        uint256 winningVotes = 0;
        uint256 winningCandidateIndex;

        // 找到获胜的候选人
        for (uint256 i = 0; i < votes[_voteIndex].candidateNum; i++) {
            if (voteToCandidates[_voteIndex][i].votes > winningVotes) {
                winningVotes = voteToCandidates[_voteIndex][i].votes;
                winningCandidateIndex = i;
            }
        }

        votes[_voteIndex].winner = voteToCandidates[_voteIndex][winningCandidateIndex].addr;
        closeIndexes.push(_voteIndex);

        payable(votes[_voteIndex].winner).transfer(5 ether);
        bytes32 txHash = blockhash(block.number - 1);
        transactionHashes.push(txHash);

        // 标记投票为关闭状态
        votes[_voteIndex].closed = true;
    }
    
    function getTransactionHashes() public view returns (bytes32[] memory) {
        return transactionHashes;
    }

    // function() external payable {
    //     // This is the fallback function, used to receive Ether
    // }
    receive() external payable {}
}
