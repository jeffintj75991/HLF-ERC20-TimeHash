// Copyright 2021 Kaleido
//
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package utils

import (
	"os"
	"testing"

	"github.com/golang/protobuf/proto" //nolint
	"github.com/hyperledger/fabric-protos-go/common"
	"github.com/hyperledger/fabric-protos-go/peer/lifecycle"
	"github.com/stretchr/testify/assert"
)

func TestDecodeEndorserBlockWithEvents(t *testing.T) {
	assert := assert.New(t)
	content, _ := os.ReadFile("../../../test/resources/tx-event.block")
	testblock := &common.Block{}
	_ = proto.Unmarshal(content, testblock)
	decoded, _, err := DecodeBlock(testblock)
	assert.NoError(err)
	assert.Equal(1, len(decoded.Data.Data))
	assert.Equal(byte(0), decoded.Metadata.Metadata[common.BlockMetadataIndex_TRANSACTIONS_FILTER][0])

	tx := decoded.Data.Data[0]
	actions := tx.Payload.Data.Actions
	assert.Equal(1, len(actions))
	action := actions[0]
	assert.Equal("u0o4mkkzs6", action.Header.Creator.Mspid)

	apa := action.Payload.Action
	assert.Equal("asset_transfer", apa.ProposalResponsePayload.Extension.ChaincodeID.Name)
	assert.Equal("1.1.0.u0ypz4p14q", apa.ProposalResponsePayload.Extension.ChaincodeID.Version)

	event := apa.ProposalResponsePayload.Extension.Events
	assert.Equal("asset_transfer", event.ChaincodeID)
	assert.Regexp("[0-9a-f]{64}", event.TxID)
	assert.Regexp("[0-9]+", event.Timestamp)
	assert.Equal("AssetCreated", event.EventName)
	m, ok := event.Payload.([]byte)
	assert.Equal(true, ok)
	assert.Equal("{\"ID\":\"asset05\",\"color\":\"red\",\"size\":10,\"owner\":\"Tom\",\"appraisedValue\":123000}", string(m))

	cpp := action.Payload.ChaincodeProposalPayload
	assert.Equal("asset_transfer", cpp.Input.ChaincodeSpec.ChaincodeID.Name)
	assert.Equal("CreateAsset", cpp.Input.ChaincodeSpec.Input.Args[0])
}

func TestDecodeEndorserBlockLifecycleTxs(t *testing.T) {
	assert := assert.New(t)
	content, _ := os.ReadFile("../../../test/resources/chaincode-deploy.block")
	testblock := &common.Block{}
	_ = proto.Unmarshal(content, testblock)
	decoded, _, err := DecodeBlock(testblock)
	assert.NoError(err)
	assert.Equal(1, len(decoded.Data.Data))
	assert.Equal(byte(0), decoded.Metadata.Metadata[common.BlockMetadataIndex_TRANSACTIONS_FILTER][0])

	tx := decoded.Data.Data[0]
	actions := tx.Payload.Data.Actions
	assert.Equal(1, len(actions))
	action := actions[0]
	assert.Equal("u0o4mkkzs6", action.Header.Creator.Mspid)

	apa := action.Payload.Action
	assert.Equal("_lifecycle", apa.ProposalResponsePayload.Extension.ChaincodeID.Name)
	assert.Equal("syscc", apa.ProposalResponsePayload.Extension.ChaincodeID.Version)

	cpp := action.Payload.ChaincodeProposalPayload
	assert.Equal("_lifecycle", cpp.Input.ChaincodeSpec.ChaincodeID.Name)
	assert.Equal("UNDEFINED", cpp.Input.ChaincodeSpec.Type)
	assert.Equal("ApproveChaincodeDefinitionForMyOrg", cpp.Input.ChaincodeSpec.Input.Args[0])
	assert.Equal(int64(1), cpp.Input.ChaincodeSpec.Input.Args[1].(*lifecycle.ApproveChaincodeDefinitionForMyOrgArgs).Sequence)
	assert.Equal("asset_transfer", cpp.Input.ChaincodeSpec.Input.Args[1].(*lifecycle.ApproveChaincodeDefinitionForMyOrgArgs).Name)
	assert.Equal("1.1.0.u0ypz4p14q", cpp.Input.ChaincodeSpec.Input.Args[1].(*lifecycle.ApproveChaincodeDefinitionForMyOrgArgs).Version)
}

func TestDecodeConfigBlock(t *testing.T) {
	assert := assert.New(t)

	content, _ := os.ReadFile("../../../test/resources/config-0.block")
	testblock := &common.Block{}
	_ = proto.Unmarshal(content, testblock)
	decoded, _, err := DecodeBlock(testblock)
	assert.NoError(err)
	assert.Equal(1, len(decoded.Data.Data))

	content, _ = os.ReadFile("../../../test/resources/config-1.block")
	testblock = &common.Block{}
	_ = proto.Unmarshal(content, testblock)
	decoded, _, err = DecodeBlock(testblock)
	assert.NoError(err)
	assert.Equal(1, len(decoded.Data.Data))
}

func TestGetEvents(t *testing.T) {
	assert := assert.New(t)
	content, _ := os.ReadFile("../../../test/resources/tx-event.block")
	testblock := &common.Block{}
	_ = proto.Unmarshal(content, testblock)
	events := GetEvents(testblock)
	assert.Equal(1, len(events))
	entry := events[0]
	assert.Equal("asset_transfer", entry.ChaincodeID)
	assert.Equal(uint64(16), entry.BlockNumber)
	assert.Equal("AssetCreated", entry.EventName)
	assert.Regexp("[0-9a-f]{64}", entry.TransactionID)
	assert.Equal(0, entry.TransactionIndex)
	assert.Equal(int64(1641861241312746000), entry.Timestamp)
}
