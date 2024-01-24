source ../../net-config.env

createArtifacts() {
# Store paths in variables
ARTIFACTS_DIR="../../channel-artifacts"
CONFIG_PATH="."

# System channel
SYS_CHANNEL="sys-channel"

# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"

# Use a loop for organizations passed as arguments
for ORG in "$@"; do
    echo "#######    Generating anchor peer update for $ORG  ##########"
    configtxgen -profile BasicChannel -configPath "$CONFIG_PATH" -outputAnchorPeersUpdate ./"$ORG"anchors.tx -channelID "$CHANNEL_NAME" -asOrg "$ORG"
done

# Combine rm commands
rm genesis.block mychannel.tx "$ARTIFACTS_DIR"/*

# Generate System Genesis block
configtxgen -profile OrdererGenesis -configPath "$CONFIG_PATH" -channelID "$SYS_CHANNEL" -outputBlock ./genesis.block

# Generate channel configuration block
configtxgen -profile BasicChannel -configPath "$CONFIG_PATH" -outputCreateChannelTx ./mychannel.tx -channelID "$CHANNEL_NAME"

echo "Script executed successfully."
}

# Call the function with the desired organizations
createArtifacts "${ORGS_MSPS[@]}"
