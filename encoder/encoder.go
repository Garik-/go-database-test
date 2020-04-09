package encoder

import (
	"encoding/hex"
	"encoding/json"
	"github.com/eoscanada/eos-go"
	"log"
	"math/rand"
	"os"
	"time"
)

const (
	eventActionName = "send"
	eventStructName = "event"
)

type eventDataSlice []byte

func (m *eventDataSlice) MarshalJSON() ([]byte, error) {
	return json.Marshal(hex.EncodeToString(*m))
}

func (m *eventDataSlice) UnmarshalJSON(data []byte) error {
	str := ""
	err := json.Unmarshal(data, &str)
	if err != nil {
		return err
	}

	b, err := hex.DecodeString(str)
	if err != nil {
		return err
	}

	*m = b
	return nil
}

type eventData struct {
	A uint64 `json:"a"`
	B uint32 `json:"b"`
	C string `json:"c"`
}

type event struct {
	Sender    string         `json:"sender"`
	CasinoID  uint64         `json:"casino_id"`
	GameID    uint64         `json:"game_id"`
	RequestID uint64         `json:"req_id"`
	EventType uint32         `json:"event_type"`
	Data      eventDataSlice `json:"data"`
}

type Encoder struct {
	eventABI     *eos.ABI
	eventDataABI *eos.ABI
}

func NewEncoder(event string, eventData string) (*Encoder, error) {
	e := &Encoder{}
	var err error
	if e.eventABI, err = loadAbiFromFile(event); err != nil {
		return nil, err
	}
	if e.eventDataABI, err = loadAbiFromFile(eventData); err != nil {
		return nil, err
	}

	return e, nil
}

func (e *Encoder) Encode(eventType uint32) ([]byte, error) {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	encodeBytes, err := e.encodeEventData()
	if err != nil {
		return nil, err
	}

	event := &event{
		Sender:    "test",
		CasinoID:  r.Uint64(),
		GameID:    r.Uint64(),
		RequestID: r.Uint64(),
		EventType: eventType,
		Data:      encodeBytes,
	}

	data, err := json.Marshal(event)
	if err != nil {
		return nil, err
	}

	return e.eventABI.EncodeAction(eos.ActionName(eventActionName), data)
}

func (e *Encoder) encodeEventData() ([]byte, error) {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	eventData := &eventData{
		A: r.Uint64(),
		B: r.Uint32(),
		C: "test_string",
	}

	jsonBytes, err := json.Marshal(eventData)
	if err != nil {
		return nil, err
	}

	return e.eventDataABI.EncodeStruct(eventStructName, jsonBytes)
}

func loadAbiFromFile(filename string) (*eos.ABI, error) {
	f, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer func() {
		if err := f.Close(); err != nil {
			log.Fatal(err)
		}
	}()

	abi, err := eos.NewABI(f)
	if err != nil {

		return nil, err
	}

	return abi, nil
}
