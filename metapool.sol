/**
 * Metapool v1.0
 * designed and engineered by Jscrui, Tiboo, Anoop, Pablitous, Ramax, and PaSan.
 * author: 0xJscrui & Anoop
 * website: metapool.in
 * telegram: @metapoolin
 *
 *
 *   /$$      /$$ /$$$$$$$$ /$$$$$$$$ /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$  /$$      
 *  | $$$    /$$$| $$_____/|__  $$__//$$__  $$| $$__  $$ /$$__  $$ /$$__  $$| $$      
 *  | $$$$  /$$$$| $$         | $$  | $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$| $$      
 *  | $$ $$/$$ $$| $$$$$      | $$  | $$$$$$$$| $$$$$$$/| $$  | $$| $$  | $$| $$      
 *  | $$  $$$| $$| $$__/      | $$  | $$__  $$| $$____/ | $$  | $$| $$  | $$| $$      
 *  | $$\  $ | $$| $$         | $$  | $$  | $$| $$      | $$  | $$| $$  | $$| $$      
 *  | $$ \/  | $$| $$$$$$$$   | $$  | $$  | $$| $$      |  $$$$$$/|  $$$$$$/| $$$$$$$$
 *  |__/     |__/|________/   |__/  |__/  |__/|__/       \______/  \______/ |________/
 *                                                                                
 *
 * SPDX-License-Identifier: MIT
 *
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Metapool is Ownable{
    
    //Tokens
    IERC20 private metapoolToken;            

    //Mappings
    mapping(address => bool) private alreadyClaimed;   
    mapping(address => uint256) private timesWinner; 
    mapping(address => uint256) private earnedTotal;
    mapping(address => uint256) private earnedLast;
    mapping(address => uint256) private userTotalClaims;
    
    //Vars
    bool private poolOpen;
    uint256 private poolBalance;
    uint256 private poolNewBalance;
    uint256 private minBalance;   
    uint256 private minToClaim;
    uint256 private claimAmount;
    uint256 private unlockFee;
    uint256 private openTime;  
    uint256 private closeTime;
    uint256 private time = 86400;
    uint256 private timeFrame = 3600;
    address private lastWinner; 
    address private firstClaim;

    
    //Statistics Vars
    uint256 private totalPools;
    uint256 private totalClaims;
    uint256 private allPoolBalances;
    
    constructor(uint _openTime, address _metapoolToken) {        
        openTime = _openTime;
        closeTime = openTime + timeFrame;
        poolOpen = false;
        minBalance = 100000000000000000; // 0.1 BNB
        claimAmount = 10; // % of total Pool Balance
        minToClaim = 200000 * 10**18; // 800 Metapool tokens        

        metapoolToken = IERC20(_metapoolToken); 

        unlockFee = 5; // % of total Pool Balance 

    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {    

        if (poolOpen) {                                    
                        
            poolNewBalance += msg.value;

        } else {

            poolBalance += msg.value;
            
        }
    }

    function claim() public {
        require(metapoolToken.balanceOf(msg.sender) > minToClaim, "You not have enough tokens to participate on Metapool.");
        require(lastWinner != msg.sender, "You have been the Winner of the previous Metapool.");
        require(alreadyClaimed[msg.sender] == false, "You already claimed your reward from this Metapool."); 
        require(tx.origin == msg.sender, "Sorry, not allowed to do a claim.");        

        if(poolBalance > minBalance && openTime < block.timestamp && block.timestamp < openTime + timeFrame) {
            
            uint256 prize = poolBalance * claimAmount / 100;            
            
            if (firstClaim == 0x0000000000000000000000000000000000000000) {
                
                allPoolBalances += poolBalance;                

                firstClaim = msg.sender;
                lastWinner = msg.sender;
                timesWinner[msg.sender] += 1;
                poolOpen = true;                

            }            
            
            poolBalance -= prize;
            earnedLast[msg.sender] = prize;
            earnedTotal[msg.sender] += prize;
            alreadyClaimed[msg.sender] = true; 
            userTotalClaims[msg.sender] += 1;           
            totalClaims++;

            (bool sent, ) = msg.sender.call{value: prize }("");
            require(sent, "Failed to send your prize.");

        }else if (firstClaim != 0x0000000000000000000000000000000000000000) {
            
            uint256 littleReward = poolBalance * (claimAmount / 10) / 100;                        
            
            poolBalance -= littleReward;
            
            resetPoolData();

            (bool sent, ) = msg.sender.call{value: littleReward }("");
            require(sent, "Failed to send your little reward.");

        }else{
            
            require(poolOpen == true, "Metapool is closed." );
        
        }
    }

    function setClaimAmount(uint256 _claimAmount) public onlyOwner {
        claimAmount = _claimAmount;
    }      
    
    function setMinToClaim(uint256 _minToClaim) public onlyOwner {
        minToClaim = _minToClaim * 10**18;
    }
    
    function setTimeFrame(uint256 _timeFrame) public onlyOwner {
        timeFrame = _timeFrame;
    }

    function setMinPoolBalance(uint256 _minBalance) public onlyOwner {
        minBalance = _minBalance;
    }        

    function setUnlockFee(uint256 _unlockFee) public onlyOwner {
        unlockFee = _unlockFee;
    }
            
    function resetPoolData() internal {
        firstClaim = 0x0000000000000000000000000000000000000000;
        poolBalance += poolNewBalance;
        poolNewBalance = 0;        
        openTime = openTime + time;
        closeTime = openTime + timeFrame;        
        totalPools++;
        poolOpen = false;        
    }  

    function unlockMe() external payable {
        require(!poolOpen, "Metapool is open.");
        require(alreadyClaimed[msg.sender] == true, "You don't need to unlock this address");        
        require(msg.value >= (earnedLast[msg.sender] * unlockFee / 100), "You didn't send enough bnb to unlock your address.");  
        poolBalance += msg.value;
        alreadyClaimed[msg.sender] = false;
    }

    function getMinBalance() public view returns (uint256){
        return minBalance;
    }

    function getMinToClaim() public view returns (uint256){
        return minToClaim;
    }

    function getPoolBalance() public view returns (uint256){
        return poolBalance;
    }

    function getPoolNewBalance() public view returns (uint256){
        return poolNewBalance;
    }

    function getPoolStatus() public view returns (bool){
        return poolOpen;
    }

    function getLastWinner() public view returns (address){
        return lastWinner;
    }

    function getTimesWinner() public view returns (uint256){
        return timesWinner[msg.sender];
    }

    function getEarnedTotal() public view returns (uint256){
        return earnedTotal[msg.sender];
    }  

    function getEarnedLast() public view returns (uint256){
        return earnedLast[msg.sender];
    }

    function getUnlockFee() public view returns (uint256){
        return unlockFee;
    }

    function getUserTotalClaims() public view returns (uint256){
        return userTotalClaims[msg.sender];
    }  
    
    function getFirstClaim() public view returns (address){
        return firstClaim;
    }
    
    function getOpenTime() public view returns (uint256){
        return openTime;
    }
    
    function getCloseTime() public view returns (uint256){
        return closeTime;
    }
    
    function getAlreadyClaimed() public view returns (bool){
        return alreadyClaimed[msg.sender];
    }
    
    function getTotalClaims() public view returns (uint256){
        return totalClaims;
    }
    
    function getTotalPools() public view returns (uint256){
        return totalPools;
    }
    
    function getAllPoolBalances() public view returns (uint256){
        return allPoolBalances;
    }
    
    function getBlockTimestamp() public view returns (uint256){
        return block.timestamp;
    }
    
    function recoverTokens(address _token, uint256 amount) external onlyOwner{
         IERC20(_token).transfer(msg.sender, amount);
    }

    function recoverBNB(uint256 weiAmount) external onlyOwner{
         payable(msg.sender).transfer(weiAmount);
    }

}
