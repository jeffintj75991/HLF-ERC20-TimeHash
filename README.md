# HLF-ERC20-Time.Hash
An ERC20 token contract in Hyperledger Fabric network which uses Hashed Time-Lock transactions <br/>

This implementation consists of 2 Organisations: <br/>
Org1 - Has the authority to do the critical activities regarding the tokens <br/>
Org2 -Organisation associated with normal users or consumers <br/>
In our implementation, for Org1,there are 2 users: <br/>
1.Bank <br/>
2.BondX<br/>

for Org1,we have 1:<br/>
Alice<br/>
Bank is transferring the tokens using BondX to Alice to track the tokens

The ERC20 token contract which is used in this implementation is Hashed Time-Lock transactions.
A HTLC is a contract that allows you to lock your assets for a certain amount of time with a hashed value from a secret/password. It's a well-known mechanism for implementing Atomic Swaps between Blockchains where there's no communication between the chains because the HTLC contract acts as an intermediary for the transfer. See here for a deep explanation: https://bcoin.io/guides/swaps.html 

The ERC20 contract contains the following methods: 

● Mint | creates new tokens and adds them to minter's account balance 
● Burn | redeems tokens the minter's account balance 
● Transfer | transfers tokens from client account to recipient account 
● BalanceOf | returns the balance of the given account 
● ClientAccountBalance | returns the balance of the requesting client's account 
● ClientAccountID | returns the id of the requesting client's account 
● TotalSupply | returns the total token supply 
● Approve | allows the spender to withdraw from the calling client's token account. The spender can withdraw multiple times if necessary, up to the value amount 
● Allowance | returns the amount still available for the spender to withdraw from the owner 
● TransferFrom | transfers the value amount from the "from" address to the "to" address 

Additionally we have :
● GetHashTimeLock | returns the created Hash Time-Lock 
All the following methods can be run by minter only
● TransferConditional | creates the conditional transfer from one account to another one, conditioned to hashlock + timelock 
● Claim | releases the lock and transfers the tokens to the "to" account 
● Revert | releases the lock and transfers the tokens to the "from" account 

# Running the scenario
For starting the network and deploying the chaincode:
cd ERC20-HTLC-HLF-Net
./start-network

For testing the functions in contract in the CLI itself run:
./ccOperations.sh

We are using Firefly-Fabconnect for interacting with the network.
For running :  
cd ERC20-HTLC-HLF-Net/firefly-fabconnect
make    #only for the initial time
./fabconnect -f "config.json"    #in the connection profile file (ccp-1) ,bank is the user

This will open a webapp (Swagger) in http://localhost:3000/api
To run an invoke ,in /transactions
{
  "headers": {
    "type": "SendTransaction",
    "signer": "bank",
    "channel": "mychannel",
    "chaincode": "test-erc20-cc-3"
  },
  "func": "Mint",
  "args": ["10"],
  "transientMap": {},
  "init": false
}

To run a query ,in /query
{
  "headers": {
    "signer": "bank",
    "channel": "mychannel",
    "chaincode": "test-erc20-cc-3"
  },
  "func": "ClientAccountBalance",
  "args": [],    
  "strongread": false
}

Like this we can do all the operations in the Firefly webconnect


