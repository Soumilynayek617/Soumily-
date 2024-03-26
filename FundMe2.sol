// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//Imports the required Price Converter solidity file

import "./PriceConverter.sol";

error NotOwner();
error AlreadyFunded();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;

    //This mapping checks whether if the input address is pre-existing in the mapping or not
    mapping(address => bool) private isFunder;
    address[] public funders;

    address public i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    
    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "You need to spend more ETH!");

        //If the address is already funded, then return an error message    
        require(!isFunder[msg.sender], "Address has already funded");

        //else add the address to the given mapping
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        isFunder[msg.sender] = true;
    }
    
    function getVersion() public pure returns (uint256){
        return 0; //Chainlink integration is removed
    }
    
    modifier onlyOwner {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }
    
    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        delete funders;
        // transfer balance
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        i_owner = newOwner;
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}