// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner(); // where the error came from

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant minimumUsd = 5e18; //add constant decrease gas

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable owner; //add constant decrease gas

    AggregatorV3Interface private s_priceFeed; //make it modular

    constructor(address priceFeed) {
        owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }
    
    function fund() public payable {
        //require(getConversionRate(msg.value) >= minimumUsd, "didn't sent enough ETH");
        require(msg.value.getConversionRate(s_priceFeed) >= minimumUsd, "didn't sent enough ETH");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value;
    }

    function getVersion() public view returns (uint256){
        //return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
        return s_priceFeed.version();
    }

    function withdraw() public onlyOwner{
        //require(msg.sender == owner, "Must be owner!");
        for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); //reset array
        //withdraw
        // transfer
        //payable(msg.sender).transfer(address(this).balance); //auto revert
        //send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send failed"); //revert by require
        //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner () {
        require(msg.sender == owner, "Sender is not owner!");
        _;
    }

    receive() external payable { //if she forgot to click fund
        fund();
    }

    fallback() external payable {
        fund();
    }    

}
