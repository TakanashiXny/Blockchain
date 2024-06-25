// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;
pragma experimental ABIEncoderV2;

/// @title 投票合约
contract Voting {
    /// @title 候选者结构体
    struct Candidate {
        address addr;
        uint256 votes;
    }

    /// @title 投票结构体
    struct Vote {
        uint256 voteIndex; // 在投票数组中的下标
        address creator;
        string name;
        uint256 maxVoters; // 最大投票人数
        uint256 endTime; 
        uint256 candidateNum;
        uint256 totalVoters; // 该投票目前的投票人数
        bool closed;
        address winner;
    }

    uint256 voteNum; // 当前被记录的投票个数
    bytes32 public merkleRoot; // 当前的默克尔根

    uint256[] closeIndexes; // 已经关闭了的投票的下标，用于前端取相应的投票信息
    bytes32[] public transactionHashes; // 所有交易的哈希
    
    Vote[] public votes; // 投票结构体数组
    Vote[] public closedVotes; // 已经关闭的投票

    mapping(uint256 => Candidate[]) public voteToCandidates; // 投票编号到该投票所有候选人的数组的映射
    mapping(uint256 => address[]) public voteToVoters; // 投票编号到该投票所有投票者地址的映射

    /// @notice 创建投票
    /// @param 投票名称 投票最大人数 投票结束时间
    function createVote(string memory _name, uint256 _max_voters, uint256 _endTime) public payable returns (uint256) {
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

        // 开始更新默克尔树
        payable(address(this)).transfer(msg.value);
        bytes32 txHash = blockhash(block.number - 1);
        updateMerkleRoot();
        transactionHashes.push(txHash);

        return votes.length - 1; // 返回新投票的索引作为投票地址
    }

    /// @notice 返回所有被记录投票的数量
    function getVoteNum() public view returns (uint256) {
        return voteNum;
    }

    /// @notice 返回所有进行中的投票的下标
    function getOpenVotes() public view returns (int[100] memory) {
        // 初始化返回的数组
        int[100] memory openIndexes;
        
        // 遍历所有的投票，将进行中的投票加入数组
        uint256 index = 0;
        for (uint256 i = 0; i < votes.length; i++) {
            if (!votes[i].closed) {
                openIndexes[index] = int(i);
                index++;
            }
        }

        return openIndexes;
    }

    /// @notice 得到指定下标的投票的部分展示的信息
    function getVote(uint256 voteIndex) public view returns (bool closed_, address creator_, string memory name_, uint256 endTime_, address winner_) {
        return (votes[voteIndex].closed, votes[voteIndex].creator, votes[voteIndex].name, votes[voteIndex].endTime, votes[voteIndex].winner);
    } 

    /// @notice 得到已经关闭的投票的下标
    function getClosedVotes() public view returns (uint256[] memory) {
        return closeIndexes;
    }

    /// @notice 添加候选者
    function addCandidate(uint256 _voteIndex) public payable {
        // 自己不能加入
        if (votes[_voteIndex].creator == msg.sender) {
            return;
        }

        voteToCandidates[_voteIndex].push(Candidate(msg.sender, 0));
        votes[_voteIndex].candidateNum++;

        // 向投票创建者支付金额并改变默克尔树
        payable(votes[_voteIndex].creator).transfer(msg.value); 
        bytes32 txHash = blockhash(block.number - 1);
        transactionHashes.push(txHash);
        updateMerkleRoot();
    }

    /// @notice 投票
    function vote(uint256 _voteIndex, uint256 _candidateIndex) public payable returns (bool) {
        // 判断是否已经投过票了
        for (uint i = 0; i < voteToVoters[_voteIndex].length; i++) {
            if (voteToVoters[_voteIndex][i] == msg.sender) {
                return false;
            }
        }

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
    
    /// @notice 得到某个投票的所有候选者的地址，返回给前端展示
    function getCandidates(uint256 _voteIndex) public view returns (address[] memory) {
        address[] memory candidates = new address[](votes[_voteIndex].candidateNum);
        for (uint256 i = 0; i < votes[_voteIndex].candidateNum; i++) {
            candidates[i] = voteToCandidates[_voteIndex][i].addr;
        }
        return candidates;
    }

    /// @notice 得到某个投票的赢家
    function getWinner(uint256 _voteIndex) public view returns (address) {
        return votes[_voteIndex].winner;
    }

    /// @notice 结束某个投票，进行结算
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

        // 支付奖励并更新默克尔树
        payable(votes[_voteIndex].winner).transfer(5 ether);
        bytes32 txHash = blockhash(block.number - 1);
        transactionHashes.push(txHash);
        updateMerkleRoot();

        // 标记投票为关闭状态
        votes[_voteIndex].closed = true;
    }
    
    /// @notice 返回所有默克尔哈希值并在前端展示
    function getTransactionHashes() public view returns (bytes32[] memory) {
        return transactionHashes;
    }

    /// @notice 更新当前的默克尔根
    function updateMerkleRoot() internal {
        merkleRoot = computeMerkleRoot(transactionHashes);
    }

    /// @notice 计算默克尔根
    function computeMerkleRoot(bytes32[] memory hashes) public pure returns (bytes32) {
        if (hashes.length == 0) {
            return bytes32(0);
        } else if (hashes.length == 1) {
            return hashes[0];
        } else {
            while (hashes.length > 1) {
                if (hashes.length % 2 != 0) {
                    bytes32[] memory newHashes = new bytes32[](hashes.length + 1); // 使用辅助数组来存储当前数组
                    for (uint256 i = 0; i < hashes.length; i++) {
                        newHashes[i] = hashes[i];
                    }
                    newHashes[hashes.length] = hashes[hashes.length - 1]; // 复制最后一个元素
                    hashes = newHashes;
                }
                bytes32[] memory newLevel = new bytes32[](hashes.length / 2); // 新的数组
                for (uint256 i = 0; i < hashes.length; i += 2) {
                    newLevel[i / 2] = keccak256(abi.encodePacked(hashes[i], hashes[i + 1]));
                }
                hashes = newLevel;
            }
            return hashes[0];
        }
    }

    /// @notice 返回当前的默克尔根
    function getMerkleRoot() public view returns (bytes32) {
        return merkleRoot;
    }

    receive() external payable {}
}
