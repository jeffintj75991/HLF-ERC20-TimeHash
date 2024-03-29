// Code generated by mockery v2.29.0. DO NOT EDIT.

package mocktx

import (
	client "github.com/hyperledger/firefly-fabconnect/internal/fabric/client"
	mock "github.com/stretchr/testify/mock"

	tx "github.com/hyperledger/firefly-fabconnect/internal/tx"
)

// Processor is an autogenerated mock type for the Processor type
type Processor struct {
	mock.Mock
}

// GetRPCClient provides a mock function with given fields:
func (_m *Processor) GetRPCClient() client.RPCClient {
	ret := _m.Called()

	var r0 client.RPCClient
	if rf, ok := ret.Get(0).(func() client.RPCClient); ok {
		r0 = rf()
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(client.RPCClient)
		}
	}

	return r0
}

// Init provides a mock function with given fields: _a0
func (_m *Processor) Init(_a0 client.RPCClient) {
	_m.Called(_a0)
}

// OnMessage provides a mock function with given fields: _a0
func (_m *Processor) OnMessage(_a0 tx.Context) {
	_m.Called(_a0)
}

type mockConstructorTestingTNewProcessor interface {
	mock.TestingT
	Cleanup(func())
}

// NewProcessor creates a new instance of Processor. It also registers a testing interface on the mock and a cleanup function to assert the mocks expectations.
func NewProcessor(t mockConstructorTestingTNewProcessor) *Processor {
	mock := &Processor{}
	mock.Mock.Test(t)

	t.Cleanup(func() { mock.AssertExpectations(t) })

	return mock
}
