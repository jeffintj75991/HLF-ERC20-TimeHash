export FABRIC_CFG_PATH=${PWD}/artifacts/channel/config/
export CORE_PEER_TLS_ENABLED=true
export TARGET_TLS_OPTIONS=(-o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/artifacts/channel/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt")
export CHANNEL_NAME=mychannel
export CC_NAME="test-erc20-cc-1"

setGlobalsForOrg1() {

  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/users/bank@org1.example.com/msp
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForOrg2() {
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org2.example.com/users/alice@org2.example.com/msp
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  export CORE_PEER_ADDRESS=localhost:9051
}

contractMint() {
  echo "token minting"

  setGlobalsForOrg1
  peer chaincode invoke "${TARGET_TLS_OPTIONS[@]}" -C ${CHANNEL_NAME} -n ${CC_NAME} \
    -c '{"function":"Mint","Args":["10"]}'
}

clientAccountBalanceOrg1() {
  setGlobalsForOrg1
  export BALANCE=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"ClientAccountBalance","Args":[]}')
  echo "clientAccountBalance Org1: $BALANCE"
}

clientAccountBalanceOrg2() {
  setGlobalsForOrg2
  export BALANCE=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"ClientAccountBalance","Args":[]}')
  echo "clientAccountBalance Org2: $BALANCE"
}

approveBondx() {
  echo "approve for Bondx"
  setGlobalsForOrg1
  export BANK=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"ClientAccountID","Args":[]}')

  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/users/bondx@org1.example.com/msp
  export BONDX=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"ClientAccountID","Args":[]}')
  setGlobalsForOrg1
  peer chaincode invoke "${TARGET_TLS_OPTIONS[@]}" -C ${CHANNEL_NAME} -n ${CC_NAME} \
    -c '{"function":"Approve","Args":[ "'"$BONDX"'","5"]}'
  sleep 3
  setGlobalsForOrg1
  export ALLOWANCE=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"Allowance","Args":["'"$BANK"'", "'"$BONDX"'"]}')
  echo "ALLOWANCE-BONDX: $ALLOWANCE"

}

transferFromBondx() {
  echo "transfer using Bondx"
  setGlobalsForOrg2
  export ALICE=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"ClientAccountID","Args":[]}')

  setGlobalsForOrg1
  export BANK=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"ClientAccountID","Args":[]}')

  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/users/bondx@org1.example.com/msp

  peer chaincode invoke "${TARGET_TLS_OPTIONS[@]}" -C ${CHANNEL_NAME} -n ${CC_NAME} \
    -c '{"function":"TransferFrom","Args":[ "'"$BANK"'", "'"$ALICE"'", "4"]}'

  sleep 2
  setGlobalsForOrg1
  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/users/bondx@org1.example.com/msp

  export ALLOWANCE=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"Allowance","Args":["'"$BANK"'", "'"$BONDX"'"]}')
  echo "ALLOWANCE remaining-BONDX: $ALLOWANCE"
}

#Time stamp is in UTC
transferConditional() {
  echo "transfer Conditional"
  setGlobalsForOrg2
  export ALICE=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"ClientAccountID","Args":[]}')

  setGlobalsForOrg1
  peer chaincode invoke "${TARGET_TLS_OPTIONS[@]}" -C ${CHANNEL_NAME} -n ${CC_NAME} \
    -c '{"Args":["TransferConditional", "'"$ALICE"'", "2", "HASH_LOCK", "2024-01-22T12:01:00Z", "SECRET_PASSWORD"]}'

}

getHashTimeLock() {
  echo "get HashTimeLock"
  setGlobalsForOrg1
  peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"Args":["GetHashTimeLock", "HASH_LOCK"]}'

}
claim() {
  echo "get claim"

  setGlobalsForOrg1
  peer chaincode invoke "${TARGET_TLS_OPTIONS[@]}" -C ${CHANNEL_NAME} -n ${CC_NAME} \
    -c '{"Args":["Claim", "HASH_LOCK", "SECRET_PASSWORD"]}'

}

revert() {
  echo "revert"
  setGlobalsForOrg1
  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/users/bondx@org1.example.com/msp
  export BONDX=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"ClientAccountID","Args":[]}')
  setGlobalsForOrg1
  peer chaincode invoke "${TARGET_TLS_OPTIONS[@]}" -C ${CHANNEL_NAME} -n ${CC_NAME} \
    -c '{"Args":["Revert", "HASH_LOCK"]}'

}

#Minting tokens
contractMint
sleep 3

#View the Account Balance of bank entity
 clientAccountBalanceOrg1

#Approve the number of tokens which can be transferred by BondX 
 approveBondx
 sleep 3

#Transfer the tokens from BondX to Alice 
 transferFromBondx
sleep 3

#View the Account Balance of bank entity
clientAccountBalanceOrg1
sleep 1
#View the Account Balance of Alice
clientAccountBalanceOrg2

#Initiate Conditional transfer of tokens from Bank entity
transferConditional
sleep 3

#View the Hash Time Lock
 getHashTimeLock

#View the Account Balance of bank entity
clientAccountBalanceOrg1
sleep 1
#View the Account Balance of Alice
clientAccountBalanceOrg2
sleep 2

#Raise the claim to transfer the tokens from bank entity to Alice
claim
sleep 2

#Revert the transfer by sending tokens from Alice to bank entity 
revert
