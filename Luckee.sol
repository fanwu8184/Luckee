pragma solidity ^0.4.21;
import "./Ownable.sol";
import "./SafeMath.sol";

//Decimal???
contract Luckee is Ownable {
    
    using SafeMath for uint256;
    
    struct Participant {
        address addr;
        uint reward;
    }

    struct Game {
        mapping(uint => Participant) parts;
        address createrAddr;
        uint createTime;
        uint fund;   //minimun and maximum limit?
        bool status;
        uint indexOfParts;
        uint numbOfPart;
    }
    
    mapping(uint => Game) games;
    uint index;
    uint randNonce = 0;
    uint revenue;
    uint gameFee = 0.001 ether;

    function createGame(uint _numbOfPart) public payable {
        require(msg.value > gameFee);
        Game memory newGame;
        newGame.createrAddr = msg.sender;
        newGame.createTime = now;
        newGame.status = true;
        newGame.numbOfPart = _numbOfPart;
        newGame.fund = msg.value;
        games[index] = newGame;
        index++;
    }
    
    function loserCreateGame(address loserAddr, uint _numbOfPart, uint _fund) private {
        Game memory newGame;
        newGame.createrAddr = loserAddr;
        newGame.createTime = now;
        newGame.status = true;
        newGame.numbOfPart = _numbOfPart;
        newGame.fund = _fund;
        games[index] = newGame;
        index++;
    }
    
    function joinGame(uint _id) external payable {
        require(games[_id].indexOfParts < games[_id].numbOfPart);
        require(games[_id].status == true);
        require(msg.value == games[_id].fund);
        Participant memory newPart;
        newPart.addr = msg.sender;
        games[_id].parts[games[_id].indexOfParts] = newPart;
        if(games[_id].indexOfParts == games[_id].numbOfPart - 1) {
            runGame(games[_id]);
        }
        games[_id].indexOfParts++;
    }
    
    function random() private returns(uint) {
        randNonce++;
        return uint(keccak256(now, msg.sender, randNonce)) % 100;
    }
    
    function runGame(Game storage _game) private {
        Participant memory loser;
        uint maxResult = 0;
        uint remain = _game.fund - gameFee;
        revenue = revenue.add(gameFee);
        for(uint i = 0; i < _game.numbOfPart; i++) {
            if (i < _game.numbOfPart - 1) {
                uint result = remain.mul(random()) / 100; //Decimal?
                _game.parts[i].reward = result + _game.fund;
                if(result >= maxResult) {
                    if(loser.addr != address(0)) {
                        loser.addr.transfer(loser.reward);
                    }
                    loser = _game.parts[i];
                }
                _game.parts[i].addr.transfer(_game.parts[i].reward);
                remain = remain - result;
            } else {
                _game.parts[i].reward = remain + _game.fund;
                if(remain >= maxResult) {
                    loser.addr.transfer(loser.reward);
                    loser = _game.parts[i];
                }
                _game.parts[i].addr.transfer(_game.parts[i].reward);
            }
        }
        _game.status = false;
        loserCreateGame(loser.addr ,_game.numbOfPart, _game.fund);
        loser.addr.transfer(loser.reward - _game.fund);
    }
    
    function endGame(uint _id) external {
        require(games[_id].createrAddr == msg.sender);
        require(now >= (games[_id].createTime + 1 days));
        games[_id].status = false;
        games[_id].createrAddr.transfer(games[_id].fund);
    }
    
    function setGameFee(uint _fee) external onlyOwner {
        gameFee = _fee;
    }
    
    function checkRevenue() external view onlyOwner returns(uint) {
        return revenue;
    }
    
    function withdraw() external onlyOwner {
        owner.transfer(revenue);
    }
}
