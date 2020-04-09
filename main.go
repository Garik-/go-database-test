package main

import (
	"context"
	"fmt"
	"github.com/Garik-/go-database-test/encoder" // TODO: change
	// "github.com/eoscanada/eos-go"
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

/*
Задача
три минуты интервал ESPt от 100 до 500
*/

const (
	eventABIFileName     = "abi/contract.abi"
	eventDataABIFileName = "abi/event.abi"

	waitConnectionToClose = 2 * time.Second
	periodDuration        = 3 * time.Minute

	sqlInsertAction    = "INSERT INTO chain.action_trace(transaction_id, action_ordinal, act_name, act_data, block_num, receipt_global_sequence) VALUES ('A229C41BF5974D45E2EB11D9987B92E980C68AF9A0C170F71CFF868469EF3DC5',1,'send', $1, $2, $3)"
	sqlInsertBlockInfo = "INSERT INTO chain.block_info(block_num, timestamp) VALUES ($1, now())"
)

var (
	eventsTotal = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "events_total",
		})

	conn *pgx.Conn
	enc  *encoder.Encoder
)

func init() {
	prometheus.MustRegister(eventsTotal)
}

func insertEvent(ctx context.Context, increment int) error {
	data, err := enc.Encode(0)
	if err != nil {
		return err
	}

	batch := &pgx.Batch{}
	batch.Queue(sqlInsertAction, data, increment, increment)
	batch.Queue(sqlInsertBlockInfo, increment)

	br := conn.SendBatch(ctx, batch)
	defer func() {
		br.Close()
	}()

	for i := 0; i < batch.Len(); i++ {
		_, err = br.Exec()
		if err != nil {
			break
		}
	}

	return err
}

func main() {
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

	router := mux.NewRouter()
	router.Handle("/metrics", promhttp.Handler())

	server := &http.Server{Addr: os.Getenv("METRICS_ADDR"), Handler: router}

	enc, err = encoder.NewEncoder(eventABIFileName, eventDataABIFileName)
	if err != nil {
		log.Fatal(err)
	}

	mainContext := context.Background()
	parentContext, parentCancel := context.WithCancel(mainContext)
	conn, err = pgx.Connect(parentContext, dataSource)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("connected to database: %s", dataSource)

	waitShutdownContext, cancelWaitShutdown := context.WithTimeout(mainContext, waitConnectionToClose)
	defer func() {
		cancelWaitShutdown()
		parentCancel()

		if err := conn.Close(parentContext); err != nil {
			log.Fatal(err)
		}
		log.Println("database connection closed")
	}()

	truncates := [...]string{"TRUNCATE TABLE chain.action_trace", "TRUNCATE TABLE chain.block_info"}
	for _, truncate := range truncates {
		_, err := conn.Exec(parentContext, truncate)
		if err != nil {
			log.Fatal(err)
		}
		log.Println(truncate)
	}

	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Printf("start listen HTTP on %s", server.Addr)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	intervalDurations := [...]time.Duration{time.Second / 5, time.Second / 200, time.Second / 300, time.Second / 400, time.Second / 500}

	// periodTicker := time.NewTicker(periodDuration)
	periodCounter := 0

	intervalTicker := time.NewTicker(intervalDurations[periodCounter])
	log.Printf("start interval with %v", intervalDurations[periodCounter])

	increment := 0

loop:
	for {
		select {
		case <-done:
			intervalTicker.Stop()
			// periodTicker.Stop()
			break loop
		case <-intervalTicker.C:
			if err := insertEvent(parentContext, increment); err != nil {
				log.Fatal(err)
			}
			log.Printf("insert block_num %d", increment)
			increment++
			eventsTotal.Inc()

			//case <-periodTicker.C:
			//	log.Printf("period %v cancel", periodDuration)
			//	intervalTicker.Stop()
			//
			//	periodCounter++
			//
			//	if periodCounter == len(intervalDurations) {
			//		periodTicker.Stop()
			//		break loop
			//	}
			//
			//	intervalTicker = time.NewTicker(intervalDurations[periodCounter])
			//	log.Printf("start interval with %v", intervalDurations[periodCounter])
		}
	}

	if err := server.Shutdown(waitShutdownContext); err != nil {
		log.Fatal(err)
	}

	log.Println("listening stopped")
}
