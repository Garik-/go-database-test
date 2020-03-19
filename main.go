package main

import (
	"fmt"
	"github.com/eoscanada/eos-go"

	"github.com/jackc/pgx/v4"
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"
)

const (
	contractAbiFileName = "contract.abi"
	contractActionName = "send"
	dataSource = "postgres://test:test@localhost/test"
	interval = time.Millisecond * 500
	sqlTruncate = "TRUNCATE TABLE chain.action_trace"
	sqlInsert = "INSERT INTO chain.action_trace(transaction_id, action_ordinal, act_name, act_data, block_num, receipt_global_sequence) VALUES ('A229C41BF5974D45E2EB11D9987B92E980C68AF9A0C170F71CFF868469EF3DC5',1,'send', $1, $2, $3)"
)

func main() {
	var conn *pgx.Conn
	var abi *eos.ABI
	var increment int
	var err error

	abi, err = loadAbiFromFile(contractAbiFileName)
	if err != nil {
		log.Fatal(err)
	}

	conn, err = pgx.Connect(context.Background(), dataSource)
	if err != nil {
		log.Fatal(err)
	}

	ticker := time.NewTicker(interval)

	defer func() {
		ticker.Stop()
		conn.Close(context.Background())
	}()

	// truncate table
	_, err = conn.Exec(context.Background(), sqlTruncate)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("truncate table action_trace\tOK")

	increment = 0

	var data []byte
	data, err = encodeSendAction(abi, 0)

	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	for {
		select {
		case <-ticker.C:
			_, err = conn.Exec(context.Background(), sqlInsert, data, increment, increment)
			if err != nil {
				log.Fatal(err)
			}
			fmt.Printf("insert block_num %d\tOK\n", increment)
			increment++
		case <-done:
			return
		}
	}
}
