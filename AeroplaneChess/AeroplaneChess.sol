// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;
pragma abicoder v2;

// 合约
contract AeroplaneChess {

    // 玩家结构体
    struct Player {
        address addr;
        string name;
        uint position;
        int direction;
        uint step;
        uint round;
    }

    uint destination;           // 目的地
    uint dice;                  // 骰子
    bool gamestart;             // 游戏是否开始
    bool gameover;              // 游戏是否结束
    uint winnerId;              // 赢家id
    uint currentPlayerCount;    // 当前玩家数目
    uint playerNum;             // 玩家数目
    uint times;                 // 游戏运行次数
    uint nextPlayerId;          // 下一个玩家id
    Player[] players;
    mapping(address => uint) playerId;
    mapping(address => bool) isPlay;

    // 构造器
    constructor(uint _destination, uint _dice, uint _player_num) {
        require(_destination > 0 && _dice > 0 && _player_num > 0);
        destination = _destination;
        dice = _dice;
        currentPlayerCount = 0;
        playerNum = _player_num;
        gamestart = false;
        gameover = false;
        times = 0;
    }

    function isStart() public view returns (bool start) {
        return gamestart;
    }

    function isOver() public view returns (bool over) {
        return gameover;
    }

    function isMyRound() public view returns (bool) {
        return msg.sender == players[times % players.length].addr;
    }

    function getWinner() public view returns (Player memory) {
        require(gameover);
        return players[winnerId];
    }

    function getGameInfo() public view returns (uint, uint, bool, uint, uint) {
        return (destination, dice, gameover, winnerId, currentPlayerCount);
    }

    function getPlayers() public view returns (Player[] memory) {
        return players;
    }

    // 获取当前以太坊账户的参与账号
    function getPlayer() public view returns (Player memory) {
        require(isPlay[msg.sender]);
        uint id = playerId[msg.sender];
        return players[id];
    }

    // 是否参加了游戏，遍历玩家数组
    function isJoin() public view returns (bool) {
        bool ret = false;
        for (uint i = 0; i < currentPlayerCount; ++i) {
            if (players[i].addr == msg.sender) {
                ret = true;
                break;
            }
        }
        return ret;
    }

    // 随机骰子 [1, dice]
    function randomDice(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % uint(dice) + 1;
    }

    // 参与游戏
    function join(string memory _name) public {
        require(!isPlay[msg.sender]);
        require(currentPlayerCount < playerNum);
        isPlay[msg.sender] = true;

        // 数组添加一个用户，后面四个数字依次为：初始位置，方向，当前骰子步数，轮次
        players.push(Player(msg.sender, _name, 0, 1, 0, 0));
        playerId[msg.sender] = currentPlayerCount;
        currentPlayerCount += 1;
        if (currentPlayerCount == playerNum) {
            gamestart = true;
        }
    }

    // 进行游戏，字符串作为随机值参数
    function play(string memory _str) public {
        require(isPlay[msg.sender]);
        require(gamestart);
        require(!gameover);

        // 判断是否是当前用户轮次
        
        // 获取当前应走的步数

        // 起飞需要掷出6

        // 起飞后无要求

            // 达到终点游戏结束

            // 超过终点需要往回走

            // 若是撞到别人的飞机，则将其撞回原点

        // 游戏运行次数+1
    }
}
