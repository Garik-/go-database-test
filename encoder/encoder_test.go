package encoder

import (
	"encoding/json"
	"github.com/eoscanada/eos-go"
	"github.com/stretchr/testify/require"
	"testing"
)

type eventEncode struct {
	Sender    string         `json:"sender"`
	CasinoID  string         `json:"casino_id"`
	GameID    string         `json:"game_id"`
	RequestID string         `json:"req_id"`
	EventType uint32         `json:"event_type"`
	Data      eventDataSlice `json:"data"`
}

func TestEncoder_Encode(t *testing.T) {
	e, err := NewEncoder("../abi/contract.abi", "../abi/event.abi")
	require.NoError(t, err)

	eventData, err := e.Encode(0)
	require.NoError(t, err)

	t.Logf("%#X", eventData)

	eventJson, err := e.eventABI.DecodeAction(eventData, eos.ActionName(eventActionName))
	require.NoError(t, err)
	t.Log(string(eventJson))

	ev := new(eventEncode)
	err = json.Unmarshal(eventJson, &ev)
	require.NoError(t, err)

	t.Logf("%#x", ev.Data)

	eventDataJson, err := e.eventDataABI.Decode(eos.NewDecoder(ev.Data), eventStructName)
	t.Log(string(eventDataJson))
}
