# HLF-ERC20-Time.Hash
An ERC20 token contract in Hyperledger Fabric network which uses Hashed Time-Lock transactions <br/>

This implementation consists of 2 Organisations: <br/>
Org1 - Has the authority to do the critical activities regarding the tokens <br/>
Org2 -Organisation associated with normal users or consumers <br/>
In our implementation, for Org1,there are 2 users: <br/>
1.Bank <br/>
2.BondX<br/>

for Org2,we have 1:<br/>
Alice<br/>
Bank is transferring the tokens using BondX to Alice to track the tokens <br/>

The ERC20 token contract which is used in this implementation is Hashed Time-Lock transactions. <br/>
A HTLC is a contract that allows you to lock your assets for a certain amount of time with a hashed value from a secret/password. It's a well-known mechanism for implementing Atomic Swaps between Blockchains where there's no communication between the chains because the HTLC contract acts as an intermediary for the transfer. See here for a deep explanation: https://bcoin.io/guides/swaps.html <br/>
<br/>
The ERC20 contract contains the following methods: <br/>

● Mint | creates new tokens and adds them to minter's account balance <br/>
● Burn | redeems tokens the minter's account balance <br/>
● Transfer | transfers tokens from client account to recipient account <br/>
● BalanceOf | returns the balance of the given account <br/>
● ClientAccountBalance | returns the balance of the requesting client's account <br/>
● ClientAccountID | returns the id of the requesting client's account <br/>
● TotalSupply | returns the total token supply <br/>
● Approve | allows the spender to withdraw from the calling client's token account. The spender can withdraw multiple times if necessary, up to the value amount <br/> 
● Allowance | returns the amount still available for the spender to withdraw from the owner <br/>
● TransferFrom | transfers the value amount from the "from" address to the "to" address <br/>
<br/>
Additionally we have : <br/>
● GetHashTimeLock | returns the created Hash Time-Lock <br/>
All the following methods can be run only by minter  <br/>
● TransferConditional | creates the conditional transfer from one account to another one, conditioned to hashlock + timelock  <br/>
● Claim | releases the lock and transfers the tokens to the "to" account <br/>
● Revert | releases the lock and transfers the tokens to the "from" account  <br/>
<br/>
# Running the scenario
For starting the network and deploying the chaincode: <br/>
cd ERC20-HTLC-HLF-Net <br/>
./start-network <br/>
<br/>
For testing the functions in contract in the CLI itself run: <br/>
./ccOperations.sh <br/>
<br/>
We are using Firefly-Fabconnect for interacting with the network. <br/>
For running :  <br/>
cd ERC20-HTLC-HLF-Net/firefly-fabconnect <br/>
make    #only for the initial time <br/>
./fabconnect -f "config.json"    #in the connection profile file (ccp-1) ,bank is the user <br/>
<br/>
This will open a webapp (Swagger) in http://localhost:3000/api <br/>
To run an invoke ,in /transactions <br/>
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
<br/>
To run a query ,in /query <br/>
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
<br/>
Like this we can do all the operations in the Firefly Fabconnect <br/>


