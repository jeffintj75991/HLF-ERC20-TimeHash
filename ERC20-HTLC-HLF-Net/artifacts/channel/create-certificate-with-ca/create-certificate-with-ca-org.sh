source ../../../net-config.env

createcertificatesForOrg() {

  local ORG_NAME=$1
  local CA_PORT=$2
  local USER=$3
  echo
  echo "Enroll the CA admin"
  echo
  mkdir -p ../crypto-config/peerOrganizations/${ORG_NAME}.example.com/
  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/

   
  fabric-ca-client enroll -u https://admin:adminpw@localhost:${CA_PORT} --caname ca.${ORG_NAME}.example.com --tls.certfiles ${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem
   

  echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-$CA_PORT-ca-$ORG_NAME-example-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-$CA_PORT-ca-$ORG_NAME-example-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-$CA_PORT-ca-$ORG_NAME-example-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-$CA_PORT-ca-$ORG_NAME-example-com.pem
    OrganizationalUnitIdentifier: orderer" >$PWD/../crypto-config/peerOrganizations/$ORG_NAME.example.com/msp/config.yaml


  echo
  echo "Register peer0"
  echo
  fabric-ca-client register --caname ca.${ORG_NAME}.example.com --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem

  echo
  echo "Register ${USER}"
  echo
  fabric-ca-client register --caname ca.${ORG_NAME}.example.com --id.name ${USER} --id.secret ${USER}pw --id.type client --tls.certfiles ${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem

  echo
  echo "Register the org admin"
  echo
  fabric-ca-client register --caname ca.${ORG_NAME}.example.com --id.name ${ORG_NAME}admin --id.secret ${ORG_NAME}adminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers

  # -----------------------------------------------------------------------------------
  #  Peer 0
  mkdir -p ../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com

  echo
  echo "## Generate the peer0 msp"
  echo
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:${CA_PORT} --caname ca.${ORG_NAME}.example.com -M ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/msp --csr.hosts peer0.${ORG_NAME}.example.com --tls.certfiles ${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:${CA_PORT} --caname ca.${ORG_NAME}.example.com -M ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/tls --enrollment.profile tls --csr.hosts peer0.${ORG_NAME}.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/tlsca/tlsca.${ORG_NAME}.example.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/peers/peer0.${ORG_NAME}.example.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/ca/ca.${ORG_NAME}.example.com-cert.pem

  # --------------------------------------------------------------------------------------------------
  mkdir -p ../crypto-config/peerOrganizations/${ORG_NAME}.example.com/users

  #-----------------------------------------------------------------------------------------------------------
  mkdir -p ../crypto-config/peerOrganizations/${ORG_NAME}.example.com/users/${USER}@${ORG_NAME}.example.com
  echo
  echo "## Generate the ${USER} msp"
  echo
  fabric-ca-client enroll -u https://${USER}:${USER}pw@localhost:${CA_PORT} --caname ca.${ORG_NAME}.example.com -M ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/users/${USER}@${ORG_NAME}.example.com/msp --tls.certfiles ${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/users/${USER}@${ORG_NAME}.example.com/msp/config.yaml


#------------------------------------------------------------------------------------------------------------------
  mkdir -p ../crypto-config/peerOrganizations/${ORG_NAME}.example.com/users/Admin@${ORG_NAME}.example.com
  echo
  echo "## Generate the org admin msp"
  echo
  fabric-ca-client enroll -u https://${ORG_NAME}admin:${ORG_NAME}adminpw@localhost:${CA_PORT} --caname ca.${ORG_NAME}.example.com -M ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/users/Admin@${ORG_NAME}.example.com/msp --tls.certfiles ${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/${ORG_NAME}.example.com/users/Admin@${ORG_NAME}.example.com/msp/config.yaml

}




sudo rm -rf ../crypto-config/*

for ((i = 0; i < ${#ORG_NAMES[@]}; i++)); do
  createcertificatesForOrg "${ORG_NAMES[i]}" "${CA_PORTS[i]}" "${USERS[i]}"
done







