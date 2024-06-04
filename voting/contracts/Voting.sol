// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;
pragma experimental ABIEncoderV2;

contract Voting {
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
    mapping(uint256 => address[]) public voteToVoters;


    event NewVote(uint256 indexed voteIndex, address creator, string name, uint256 maxVoters, uint256 endTime);
    event NewCandidate(uint256 indexed voteIndex, address candidateAddr);
    event VoteClosed(uint256 indexed voteIndex, address winner);

    function createVote(string memory _name, uint256 _max_voters, uint256 _endTime) public returns (uint256) {
        // require(_endTime > block.timestamp, "End time must be in the future");

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

        emit NewVote(votes.length - 1, msg.sender, _name, _max_voters, _endTime);
        return votes.length - 1; // 返回新投票的索引作为投票地址
    }

    function getVotes() public view returns (Vote[] memory) {
        uint256 notClosedCount = 0;

        // 先计算 closed 为 true 的投票数量
        for (uint256 i = 0; i < votes.length; i++) {
            if (!votes[i].closed) {
                notClosedCount++;
            }
        }

        // 初始化内存数组
        Vote[] memory notClosedVotes = new Vote[](notClosedCount);
        uint256 index = 0;

        // 填充内存数组
        for (uint256 i = 0; i < votes.length; i++) {
            if (!votes[i].closed) {
                notClosedVotes[index] = votes[i];
                index++;
            }
        }

        return notClosedVotes;
    }


    function addCandidate(uint256 _voteIndex) public {
        require(_voteIndex < votes.length, "Invalid vote index");
        require(!votes[_voteIndex].closed, "Vote is closed");

        voteToCandidates[_voteIndex].push(Candidate(msg.sender, 0));
        votes[_voteIndex].candidateNum++;

        emit NewCandidate(_voteIndex, msg.sender);
    }

    function vote(uint256 _voteIndex, uint256 _candidateIndex) public returns (bool) {
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
        // address payable winner = voteToCandidates[_voteIndex][winningCandidateIndex].addr;
        // uint256 prize = address(this).balance;
        // winner.transfer(prize);
        address payable winner = address(uint160(votes[_voteIndex].winner));
        uint256 prize = address(this).balance;
        winner.transfer(prize);

        // 标记投票为关闭状态
        votes[_voteIndex].closed = true;

        emit VoteClosed(_voteIndex, winner);
    }
    
    function() external payable {
        // This is the fallback function, used to receive Ether
    }
    // receive() external payable {}
}
