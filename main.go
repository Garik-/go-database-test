package main

import (
	"context"
	"flag"
	"fmt"
	"github.com/eoscanada/eos-go"
	"github.com/gorilla/mux"
	"github.com/jackc/pgx/v4"
	"github.com/joho/godotenv"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"log"
	"net/http"
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

	waitConnectionToClose = 2 * time.Second

	sqlTruncate = "TRUNCATE TABLE chain.action_trace"
	sqlInsert   = "INSERT INTO chain.action_trace(transaction_id, action_ordinal, act_name, act_data, block_num, receipt_global_sequence) VALUES ('A229C41BF5974D45E2EB11D9987B92E980C68AF9A0C170F71CFF868469EF3DC5',1,'send', $1, $2, $3)"
)

var (
	eventsTotal = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "events_total",
		})
)

func init() {
	prometheus.MustRegister(eventsTotal)
}

func main() {
	interval := flag.Duration("interval", flagIntervalValue, flagIntervalUsage)
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

	fmt.Printf("database: %s\n%s: %v\n", dataSource, flagIntervalUsage, *interval)

	var (
		conn *pgx.Conn
		abi  *eos.ABI
	)

	abi, err = loadAbiFromFile(contractAbiFileName)
	if err != nil {
		log.Fatal(err)
	}

	conn, err = pgx.Connect(context.Background(), dataSource)
	if err != nil {
		log.Fatal(err)
	}

	ticker := time.NewTicker(*interval)

	ctx, cancel := context.WithTimeout(context.Background(), waitConnectionToClose)
	defer func() {
		ticker.Stop()
		if err := conn.Close(context.Background()); err != nil {
			log.Print(err)
		}

		cancel()
	}()

	// truncate table
	_, err = conn.Exec(context.Background(), sqlTruncate)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Print("truncate table action_trace: OK\n\n")

	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	router := mux.NewRouter()
	router.Handle("/metrics", promhttp.Handler())

	server := &http.Server{Addr: os.Getenv("METRICS_ADDR"), Handler: router}

	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	increment := 0

	for {
		select {
		case <-ticker.C:
			var data []byte
			data, err = encodeSendAction(abi, 0)
			if err != nil {
				log.Println(err)
				break
			}

			if _, err := conn.Exec(context.Background(), sqlInsert, data, increment, increment); err == nil {
				log.Printf("insert block_num %d\tOK\n", increment)
				increment++
				eventsTotal.Inc()
			}

		case <-done:
			if err := server.Shutdown(ctx); err != nil {
				log.Fatal(err)
			}
			return
		}
	}
}
