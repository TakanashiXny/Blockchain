// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

contract VotingContract {
    struct Candidate {
        address addr;
        uint256 votes;
    }

    struct Vote {
        address creator;
        string name;
        uint256 maxVoters;
        uint256 endTime;
        uint256 candidateNum;
        uint256 totalVoters;
        bool closed;
        address winner;
    }

    Vote[] public votes;
    mapping(uint256 => Candidate[]) public voteToCandidates;

    function createVote(string memory _name, uint256 _max_voters, uint256 _endTime) public returns (uint256) {
        require(_endTime > block.timestamp, "End time must be in the future");

        // 创建投票实例并添加到数组中
        Vote memory newVote = Vote({
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

        return votes.length - 1; // 返回新投票的索引作为投票地址
    }

    function addCandidate(uint256 _voteIndex, address _addr) public {
        require(_voteIndex < votes.length, "Invalid vote index");
        require(!votes[_voteIndex].closed, "Vote is closed");

        voteToCandidates[_voteIndex].push(Candidate(_addr, 0));
        votes[_voteIndex].candidateNum++;
    }

    function vote(uint256 _voteIndex, uint256 _candidateIndex) public returns (bool) {
        require(_voteIndex < votes.length, "Invalid vote index");
        require(!votes[_voteIndex].closed, "Vote is closed");
        require(votes[_voteIndex].endTime > block.timestamp, "Voting has ended");

        voteToCandidates[_voteIndex][_candidateIndex].votes++;
        votes[_voteIndex].totalVoters++;

        // 检查是否到达指定的投票人数
        if (votes[_voteIndex].totalVoters >= votes[_voteIndex].maxVoters) {
            endVote(_voteIndex);
            return true;
        } else {
            return false;
        }
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

    function endVote(uint256 _voteIndex) private {
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

        // 发送奖励给获胜的候选人（这里使用了简化的方式，实际中应该使用安全的支付方式）
        payable(voteToCandidates[_voteIndex][winningCandidateIndex].addr).transfer(address(this).balance);

        // 标记投票为关闭状态
        votes[_voteIndex].closed = true;
    }

    receive() external payable {}
}
