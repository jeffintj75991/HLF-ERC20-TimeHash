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

package rest

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/hyperledger/firefly-fabconnect/internal/conf"
	"github.com/hyperledger/firefly-fabconnect/internal/errors"
	"github.com/hyperledger/firefly-fabconnect/internal/events"
	"github.com/hyperledger/firefly-fabconnect/internal/fabric/client"
	restasync "github.com/hyperledger/firefly-fabconnect/internal/rest/async"
	"github.com/hyperledger/firefly-fabconnect/internal/rest/receipt"
	restsync "github.com/hyperledger/firefly-fabconnect/internal/rest/sync"
	"github.com/hyperledger/firefly-fabconnect/internal/tx"
	"github.com/hyperledger/firefly-fabconnect/internal/utils"
	"github.com/hyperledger/firefly-fabconnect/internal/ws"

	log "github.com/sirupsen/logrus"
)

const (
	// MaxHeaderSize max size of content
	MaxHeaderSize = 16 * 1024
)

// Gateway as the HTTP gateway interface for fabconnect
type Gateway struct {
	config          *conf.RESTGatewayConf
	processor       tx.Processor
	receiptStore    receipt.Store
	syncDispatcher  restsync.Dispatcher
	asyncDispatcher restasync.Dispatcher
	sm              events.SubscriptionManager
	ws              ws.WebSocketServer
	rpc             client.RPCClient
	router          *router
	srv             *http.Server
	sendCond        *sync.Cond
	pendingMsgs     map[string]bool
	successMsgs     map[string]interface{}
	failedMsgs      map[string]error
}

type statusMsg struct {
	OK bool `json:"ok"`
}

// NewRESTGateway constructor
func NewRESTGateway(config *conf.RESTGatewayConf) *Gateway {
	g := &Gateway{
		config:      config,
		sendCond:    sync.NewCond(&sync.Mutex{}),
		pendingMsgs: make(map[string]bool),
		successMsgs: make(map[string]interface{}),
		failedMsgs:  make(map[string]error),
	}
	g.processor = tx.NewTxProcessor(g.config)
	g.receiptStore = receipt.NewReceiptStore(g.config)
	return g
}

func (g *Gateway) Init() error {
	g.syncDispatcher = restsync.NewDispatcher(g.processor)
	g.asyncDispatcher = restasync.NewAsyncDispatcher(g.config, g.processor, g.receiptStore)
	err := g.asyncDispatcher.ValidateConf()
	if err != nil {
		return err
	}

	rpcClient, identityClient, err := client.RPCConnect(g.config.RPC, g.config.MaxTXWaitTime)
	if err != nil {
		return err
	}
	g.rpc = rpcClient
	g.processor.Init(rpcClient)

	ws := ws.NewWebSocketServer()
	g.ws = ws

	err = g.receiptStore.Init(ws)
	if err != nil {
		return err
	}

	if g.config.Events.LevelDB.Path != "" {
		g.sm = events.NewSubscriptionManager(&g.config.Events, rpcClient, ws)
		err = g.sm.Init()
		if err != nil {
			return errors.Errorf(errors.RESTGatewayEventManagerInitFailed, err)
		}
	}

	g.router = newRouter(g.syncDispatcher, g.asyncDispatcher, identityClient, g.sm, ws)
	g.router.addRoutes()

	return nil
}

func (g *Gateway) ValidateConf() error {
	// HTTP and RPC configurations are mandatory
	if g.config.HTTP.Port == 0 {
		return errors.Errorf(errors.ConfigRESTGatewayRequiredHTTPPort)
	}
	if g.config.RPC.ConfigPath == "" {
		return errors.Errorf(errors.ConfigRESTGatewayRequiredRPCPath)
	}
	if g.config.HTTP.LocalAddr == "" {
		g.config.HTTP.LocalAddr = "0.0.0.0"
	}
	return nil
}

// Start kicks off the HTTP listener and router
func (g *Gateway) Start() error {
	tlsConfig, err := utils.CreateTLSConfiguration(&g.config.HTTP.TLS)
	if err != nil {
		return err
	}
	// TODO: Fix linting: G112: Potential Slowloris Attack because ReadHeaderTimeout is not configured in the http.Server
	// #nosec
	g.srv = &http.Server{
		Addr:           fmt.Sprintf("%s:%d", g.config.HTTP.LocalAddr, g.config.HTTP.Port),
		TLSConfig:      tlsConfig,
		Handler:        g.router.newAccessTokenContextHandler(),
		MaxHeaderBytes: MaxHeaderSize,
	}

	readyToListen := make(chan bool)
	gwDone := make(chan error)
	svrDone := make(chan error)

	go func() {
		<-readyToListen
		log.Printf("HTTP server listening on %s", g.srv.Addr)
		err := g.srv.ListenAndServe()
		if err != nil {
			log.Errorf("Listening ended with: %s", err)
		}
		svrDone <- err
	}()
	go func() {
		err := g.asyncDispatcher.Run()
		if err != nil {
			log.Errorf("Async dispatcher ended with: %s", err)
		}
		gwDone <- err
	}()
	for !g.asyncDispatcher.IsInitialized() {
		time.Sleep(250 * time.Millisecond)
	}
	readyToListen <- true

	// Clean up on SIGINT
	signals := make(chan os.Signal, 1)
	signal.Notify(signals, os.Interrupt, syscall.SIGTERM, syscall.SIGINT, syscall.SIGHUP)
	// Complete the main routine if any child ends, or SIGINT
	select {
	case err = <-gwDone:
		break
	case err = <-svrDone:
		break
	case <-signals:
		break
	}

	g.Shutdown()

	log.Infof("Shutting down HTTP server")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	_ = g.srv.Shutdown(ctx)
	defer cancel()

	return err
}

func (g *Gateway) Shutdown() {
	if g.sm != nil {
		g.sm.Close()
	}
	g.asyncDispatcher.Close()
	g.rpc.Close()
	g.ws.Close()
}
