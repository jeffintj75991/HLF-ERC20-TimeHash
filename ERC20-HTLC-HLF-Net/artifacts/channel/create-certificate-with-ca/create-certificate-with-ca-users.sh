  
  createcertificatesUsers() {

    #For the bank
  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/org1.example.com/

fabric-ca-client register --caname ca.org1.example.com --id.name bank --id.secret bankpw --id.type client \
 --tls.certfiles ${PWD}/fabric-ca/org1/tls-cert.pem
 
 fabric-ca-client enroll -u https://bank:bankpw@localhost:7054 --caname ca.org1.example.com \
 -M ${PWD}/../crypto-config/peerOrganizations/org1.example.com/users/bank@org1.example.com/msp \
 --tls.certfiles ${PWD}/fabric-ca/org1/tls-cert.pem
 
  cp ${PWD}/../crypto-config/peerOrganizations/org1.example.com/msp/config.yaml \
  ${PWD}/../crypto-config/peerOrganizations/org1.example.com/users/bank@org1.example.com/msp/config.yaml

    #For Alice

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/org2.example.com/

 fabric-ca-client register --caname ca.org2.example.com --id.name alice --id.secret alicepw --id.type client \
 --tls.certfiles ${PWD}/fabric-ca/org2/tls-cert.pem
 
 fabric-ca-client enroll -u https://alice:alicepw@localhost:8054 --caname ca.org2.example.com \
 -M ${PWD}/../crypto-config/peerOrganizations/org2.example.com/users/alice@org2.example.com/msp \
 --tls.certfiles ${PWD}/fabric-ca/org2/tls-cert.pem

 cp ${PWD}/../crypto-config/peerOrganizations/org2.example.com/msp/config.yaml \
  ${PWD}/../crypto-config/peerOrganizations/org2.example.com/users/alice@org2.example.com/msp/config.yaml

 #For BondX
 export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/org1.example.com/

    fabric-ca-client register --caname ca.org1.example.com --id.name bondx --id.secret bondxpw --id.type client \
     --tls.certfiles ${PWD}/fabric-ca/org1/tls-cert.pem

    fabric-ca-client enroll -u https://bondx:bondxpw@localhost:7054 --caname ca.org1.example.com \
 -M ${PWD}/../crypto-config/peerOrganizations/org1.example.com/users/bondx@org1.example.com/msp \
     --tls.certfiles ${PWD}/fabric-ca/org1/tls-cert.pem

cp ${PWD}/../crypto-config/peerOrganizations/org1.example.com/msp/config.yaml \
  ${PWD}/../crypto-config/peerOrganizations/org1.example.com/users/bondx@org1.example.com/msp/config.yaml



  }

 

createcertificatesUsers 