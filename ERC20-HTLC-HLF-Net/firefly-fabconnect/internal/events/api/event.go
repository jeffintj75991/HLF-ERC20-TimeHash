// Copyright © 2023 Kaleido, Inc.
//
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package api

import "fmt"

const (
	BlockTypeTX                     = "tx"              // corresponds to blocks containing regular transactions
	BlockTypeConfig                 = "config"          // corresponds to blocks containing channel configurations and updates
	EventPayloadTypeBytes           = "bytes"           // default data type of the event payload, no special processing is done before returning to the subscribing client
	EventPayloadTypeString          = "string"          // event payload will be an UTF-8 encoded string
	EventPayloadTypeJSON            = "json"            // event payload will be a structured map with UTF-8 encoded string values
	EventPayloadTypeStringifiedJSON = "stringifiedJSON" // equivalent to "json" (deprecated)
)

// persistedFilter is the part of the filter we record to storage
// BlockType:   optional. only notify on blocks of a specific type
//
//	types are defined in github.com/hyperledger/fabric-protos-go/common:
//	"config": for HeaderType_CONFIG, HeaderType_CONFIG_UPDATE
//	"tx": for HeaderType_ENDORSER_TRANSACTION
//
// ChaincodeID: optional, only notify on blocks containing events for chaincode Id
// Filter:      optional. regexp applied to the event name. can be used independent of Chaincode ID
// FromBlock:   optional. "newest", "oldest", a number. default is "newest"
type persistedFilter struct {
	BlockType   string `json:"blockType,omitempty"`
	ChaincodeID string `json:"chaincodeId,omitempty"`
	EventFilter string `json:"eventFilter,omitempty"`
}

// SubscriptionInfo is the persisted data for the subscription
type SubscriptionInfo struct {
	TimeSorted
	ID          string          `json:"id,omitempty"`
	ChannelID   string          `json:"channel,omitempty"`
	Path        string          `json:"path"`
	Summary     string          `json:"-"`      // System generated name for the subscription
	Name        string          `json:"name"`   // User provided name for the subscription, set to Summary if missing
	Stream      string          `json:"stream"` // the event stream this subscription is associated under
	Signer      string          `json:"signer"`
	FromBlock   string          `json:"fromBlock,omitempty"`
	Filter      persistedFilter `json:"filter"`
	PayloadType string          `json:"payloadType,omitempty"` // optional. data type of the payload bytes; "bytes", "string" or "stringifiedJSON/json". Default to "bytes"
}

// GetID returns the ID (for sorting)
func (info *SubscriptionInfo) GetID() string {
	return info.ID
}

type EventEntry struct {
	ChaincodeID      string      `json:"chaincodeId"`
	BlockNumber      uint64      `json:"blockNumber"`
	TransactionID    string      `json:"transactionId"`
	TransactionIndex int         `json:"transactionIndex"`
	EventIndex       int         `json:"eventIndex"`
	EventName        string      `json:"eventName"`
	Payload          interface{} `json:"payload"`
	Timestamp        int64       `json:"timestamp,omitempty"`
	SubID            string      `json:"subId"`
}

func GetKeyForEventClient(channelID string, chaincodeID string) string {
	// key for a unique event client is <channelID>-<chaincodeID>
	// note that we don't allow "fromBlock" to be a key segment, because on restart
	// the "fromBlock" will be set to the checkpoint which will be the same, thus failing
	// to differentiate unique event clients
	return fmt.Sprintf("%s-%s", channelID, chaincodeID)
}
