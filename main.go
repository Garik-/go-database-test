package main

import (
	"context"
	"flag"
	"fmt"
	"github.com/eoscanada/eos-go"
	"github.com/jackc/pgx/v4"
	"github.com/joho/godotenv"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"
)

const (
	contractAbiFileName = "contract.abi"
	contractActionName  = "send"

	flagIntervalValue = time.Millisecond * 500
	flagIntervalUsage = "event creation interval"

	sqlTruncate = "TRUNCATE TABLE chain.action_trace"
	sqlInsert   = "INSERT INTO chain.action_trace(transaction_id, action_ordinal, act_name, act_data, block_num, receipt_global_sequence) VALUES ('A229C41BF5974D45E2EB11D9987B92E980C68AF9A0C170F71CFF868469EF3DC5',1,'send', $1, $2, $3)"
)

var interval = flag.Duration("interval", flagIntervalValue, flagIntervalUsage)

func init() {
	flag.DurationVar(interval, "i", flagIntervalValue, flagIntervalUsage)
}

func main() {
	flag.Parse()

	err := godotenv.Load()
	if err != nil {
		log.Fatal("error loading .env file")
	}

	dataSource := fmt.Sprintf(
		"postgres://%s:%s@localhost:%s/%s",
		os.Getenv("POSTGRES_USER"),
		os.Getenv("POSTGRES_PASSWORD"),
		os.Getenv("POSTGRES_PORT"),
		os.Getenv("POSTGRES_DB"),
	)

	fmt.Printf("database: %s\n%s: %v\n\n", dataSource, flagIntervalUsage, *interval)

	var conn *pgx.Conn
	var abi *eos.ABI

	var increment int

	abi, err = loadAbiFromFile(contractAbiFileName)
	if err != nil {
		log.Fatal(err)
	}

	conn, err = pgx.Connect(context.Background(), dataSource)
	if err != nil {
		log.Fatal(err)
	}

	ticker := time.NewTicker(*interval)

	defer func() {
		ticker.Stop()
		if err := conn.Close(context.Background()); err != nil {
			log.Fatal(err)
		}
	}()

	// truncate table
	_, err = conn.Exec(context.Background(), sqlTruncate)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("truncate table action_trace\tOK")

	increment = 0

	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	for {
		select {
		case <-ticker.C:
			var data []byte
			data, err = encodeSendAction(abi, 0)
			if err != nil {
				log.Fatal(err)
			}

			if _, err := conn.Exec(context.Background(), sqlInsert, data, increment, increment); err == nil {
				log.Printf("insert block_num %d\tOK\n", increment)
				increment++
			}

		case <-done:
			return
		}
	}
}
