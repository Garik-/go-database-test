package main

import (
	"encoding/json"
	"github.com/eoscanada/eos-go"
	"math/rand"
	"os"
	"time"
)

type Event struct {
	Sender    string          `json:"sender"`
	CasinoID  uint64          `json:"casino_id"`
	GameID    uint64          `json:"game_id"`
	RequestID uint64          `json:"req_id"`
	EventType int             `json:"event_type"`
	Data      json.RawMessage `json:"data"`
}

//  возвращает закодированые байты струкуры Event
func encodeSendAction(abi *eos.ABI, eventType int) ([]byte, error) {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	event := &Event{
		Sender:    "test",
		CasinoID:  r.Uint64(),
		GameID:    r.Uint64(),
		RequestID: r.Uint64(),
		EventType: eventType,
		Data:      nil,
	}

	data, err := json.Marshal(event)
	if err != nil {
		return nil, err
	}

	return abi.EncodeAction(eos.ActionName(contractActionName), data)
}

func loadAbiFromFile(filename string) (*eos.ABI, error) {
	f, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	abi, err := eos.NewABI(f)
	if err != nil {

		return nil, err
	}

	return abi, nil
}
