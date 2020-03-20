package main

import (
	"bytes"
	"encoding/hex"
	"encoding/json"
	"github.com/eoscanada/eos-go"
	"math/rand"
	"os"
	"time"
)

type EventDataSlice []byte

func (m EventDataSlice) MarshalJSON() ([]byte, error) {
	return json.Marshal(hex.EncodeToString(m))
}

type EventData struct {
	A uint64 `json:"a"`
	B uint32 `json:"b"`
}

type Event struct {
	Sender    string          `json:"sender"`
	CasinoID  uint64          `json:"casino_id"`
	GameID    uint64          `json:"game_id"`
	RequestID uint64          `json:"req_id"`
	EventType uint32             `json:"event_type"`
	Data      EventDataSlice `json:"data"`
}

func encode(v interface{}) ([]byte, error) {
	var buffer bytes.Buffer
	encoder := eos.NewEncoder(&buffer)
	err := encoder.Encode(v)
	if err != nil {
		return nil, err
	}

	return buffer.Bytes(), nil
}

//  возвращает закодированые байты струкуры Event
func encodeSendAction(abi *eos.ABI, eventType uint32) ([]byte, error) {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	eventData := &EventData{
		A: r.Uint64(),
		B: r.Uint32(),
	}

	bytes, err := encode(eventData)
	if err != nil {
		return nil, err
	}

	event := &Event{
		Sender:    "test",
		CasinoID:  r.Uint64(),
		GameID:    r.Uint64(),
		RequestID: r.Uint64(),
		EventType: eventType,
		Data:    bytes,
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
