// Droonialarm backend — pollib SITREP API'd ja saadab push'e.
//
// Käivitamine:
//
//	export FCM_SA_JSON=/path/to/firebase-service-account.json
//	export APNS_KEY_P8=/path/to/AuthKey_XXXX.p8
//	export APNS_KEY_ID=ABCDE12345
//	export APNS_TEAM_ID=ZZZZZZ
//	export APNS_BUNDLE=ee.droonialarm
//	export APNS_PRODUCTION=1
//	export DB_PATH=./alarm.db
//	go run .
package main

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/sideshow/apns2"
	apnsPayload "github.com/sideshow/apns2/payload"
	"github.com/sideshow/apns2/token"
	"google.golang.org/api/option"
	_ "modernc.org/sqlite"
)

const (
	sitrepURL      = "https://api.app.eesti.ee/api/sitrep/v1/full-events"
	pollInterval   = 10 * time.Second
	httpListenAddr = ":8080"
	userAgent      = "Droonialarm/1.0 (+https://github.com/marttirandma/droonialarm)"
)

// SITREP wrapper schema (subset of fields we use).
type sitrepWrapper struct {
	Type string `json:"type"`
	Data struct {
		Event struct {
			ID          int64  `json:"id"`
			Title       string `json:"title"`
			EventStatus string `json:"eventStatus"`
			StartDate   string `json:"startDate"`
		} `json:"event"`
		Alerts []sitrepAlert `json:"alerts"`
	} `json:"data"`
}

type sitrepAlert struct {
	ID                int64           `json:"id"`
	State             string          `json:"state"`     // OPEN | COMPLETED | CANCELLED
	Type              string          `json:"type"`      // NOTIFICATION
	StartDate         string          `json:"startDate"`
	EndDate           string          `json:"endDate"`
	CancelledAt       *string         `json:"cancelledAt"`
	NotificationSound string          `json:"notificationSound"`
	Content           []sitrepContent `json:"content"`
	EhakLocations     []ehakLocation  `json:"ehakLocations"`
}

type sitrepContent struct {
	CountryCode string `json:"countryCode"`
	Title       string `json:"title"`
	Text        string `json:"text"`
}

type ehakLocation struct {
	EhakCode string `json:"ehakCode"`
}

type alertSeen struct {
	ID            int64
	State         string
	ContentDigest string
}

func main() {
	dbPath := getenv("DB_PATH", "./alarm.db")
	db, err := openDB(dbPath)
	if err != nil {
		log.Fatalf("open db: %v", err)
	}
	defer db.Close()

	fcm, err := newFCM(context.Background(), os.Getenv("FCM_SA_JSON"))
	if err != nil {
		log.Fatalf("init FCM: %v", err)
	}

	apnsCli, apnsBundle, err := newAPNS()
	if err != nil {
		log.Fatalf("init APNs: %v", err)
	}

	disp := &dispatcher{db: db, fcm: fcm, apns: apnsCli, apnsBundle: apnsBundle}

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "ok")
	})
	mux.HandleFunc("/v1/register", disp.handleRegister)
	mux.HandleFunc("/v1/test-push", disp.handleTestPush)

	srv := &http.Server{Addr: httpListenAddr, Handler: mux}
	go func() {
		log.Printf("HTTP listening on %s", httpListenAddr)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("http: %v", err)
		}
	}()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	log.Printf("polling %s every %s", sitrepURL, pollInterval)
	pollLoop(ctx, disp)

	shutCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = srv.Shutdown(shutCtx)
}

// pollLoop fetches the SITREP feed on every tick and forwards new alerts.
func pollLoop(ctx context.Context, disp *dispatcher) {
	t := time.NewTicker(pollInterval)
	defer t.Stop()
	pollOnce(ctx, disp)
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			pollOnce(ctx, disp)
		}
	}
}

func pollOnce(ctx context.Context, disp *dispatcher) {
	events, err := fetchSitrep(ctx)
	if err != nil {
		log.Printf("fetch sitrep: %v", err)
		return
	}
	for _, w := range events {
		for _, a := range w.Data.Alerts {
			fresh, isNew, err := disp.recordAlert(a)
			if err != nil {
				log.Printf("record alert %d: %v", a.ID, err)
				continue
			}
			if !fresh {
				continue
			}
			text := pickEstonianText(a.Content)
			log.Printf("alert id=%d state=%s new=%v text=%q", a.ID, a.State, isNew, truncate(text, 80))
			if shouldDispatch(a) {
				disp.broadcast(ctx, w.Data.Event.ID, a)
			}
		}
	}
}

func fetchSitrep(ctx context.Context) ([]sitrepWrapper, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", sitrepURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", userAgent)
	req.Header.Set("Accept", "application/json")
	cli := &http.Client{Timeout: 10 * time.Second}
	resp, err := cli.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("status %d", resp.StatusCode)
	}
	var out []sitrepWrapper
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, fmt.Errorf("decode: %w", err)
	}
	return out, nil
}

func pickEstonianText(cs []sitrepContent) string {
	for _, c := range cs {
		if c.CountryCode == "ET" {
			return c.Text
		}
	}
	if len(cs) > 0 {
		return cs[0].Text
	}
	return ""
}

func shouldDispatch(a sitrepAlert) bool {
	// Skip empty-content alerts (administrative-only entries).
	if pickEstonianText(a.Content) == "" {
		return false
	}
	// Don't broadcast already-cancelled alerts on first sighting.
	if a.State == "CANCELLED" && a.CancelledAt != nil {
		return false
	}
	return true
}

func contentDigest(a sitrepAlert) string {
	h := sha256.New()
	h.Write([]byte(a.State))
	h.Write([]byte(a.StartDate))
	h.Write([]byte(a.EndDate))
	for _, c := range a.Content {
		h.Write([]byte(c.CountryCode))
		h.Write([]byte(c.Text))
	}
	return hex.EncodeToString(h.Sum(nil))
}

// dispatcher coordinates dedupe + push delivery.
type dispatcher struct {
	db         *sql.DB
	fcm        *messaging.Client
	apns       *apns2.Client
	apnsBundle string
	mu         sync.Mutex
}

func (d *dispatcher) recordAlert(a sitrepAlert) (fresh bool, isNew bool, err error) {
	d.mu.Lock()
	defer d.mu.Unlock()
	digest := contentDigest(a)
	var prevState, prevDigest string
	row := d.db.QueryRow(`SELECT state, content_digest FROM alerts_seen WHERE alert_id = ?`, a.ID)
	switch err := row.Scan(&prevState, &prevDigest); {
	case errors.Is(err, sql.ErrNoRows):
		_, ierr := d.db.Exec(
			`INSERT INTO alerts_seen(alert_id, state, content_digest, first_seen, last_seen) VALUES(?,?,?,?,?)`,
			a.ID, a.State, digest, time.Now().UTC().Format(time.RFC3339Nano), time.Now().UTC().Format(time.RFC3339Nano))
		if ierr != nil {
			return false, false, ierr
		}
		return true, true, nil
	case err != nil:
		return false, false, err
	}
	if prevState == a.State && prevDigest == digest {
		_, _ = d.db.Exec(`UPDATE alerts_seen SET last_seen=? WHERE alert_id=?`,
			time.Now().UTC().Format(time.RFC3339Nano), a.ID)
		return false, false, nil
	}
	_, err = d.db.Exec(
		`UPDATE alerts_seen SET state=?, content_digest=?, last_seen=? WHERE alert_id=?`,
		a.State, digest, time.Now().UTC().Format(time.RFC3339Nano), a.ID)
	return true, false, err
}

func (d *dispatcher) broadcast(ctx context.Context, eventID int64, a sitrepAlert) {
	text := pickEstonianText(a.Content)
	title := "EE-ALARM"
	if len(a.Content) > 0 && a.Content[0].Title != "" {
		title = a.Content[0].Title
	}
	ehaks := make([]string, 0, len(a.EhakLocations))
	for _, e := range a.EhakLocations {
		if e.EhakCode != "" {
			ehaks = append(ehaks, e.EhakCode)
		}
	}
	if len(ehaks) == 0 {
		ehaks = append(ehaks, "national")
	}

	for _, ehak := range ehaks {
		go d.pushFCM(ctx, ehak, eventID, a, title, text)
	}
	go d.pushAPNsAll(ctx, eventID, a, title, text)
}

func (d *dispatcher) pushFCM(ctx context.Context, ehak string, eventID int64, a sitrepAlert, title, text string) {
	if d.fcm == nil {
		return
	}
	topic := fmt.Sprintf("ehak_%s", strings.ToLower(ehak))
	msg := &messaging.Message{
		Topic: topic,
		Data: map[string]string{
			"event_id":   fmt.Sprintf("%d", eventID),
			"alert_id":   fmt.Sprintf("%d", a.ID),
			"state":      a.State,
			"title":      title,
			"text":       text,
			"start_date": a.StartDate,
			"end_date":   a.EndDate,
			"sound":      a.NotificationSound,
		},
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				ChannelID: "alarm_channel",
				Title:     title,
				Body:      text,
				Sound:     "siren",
			},
		},
	}
	id, err := d.fcm.Send(ctx, msg)
	if err != nil {
		log.Printf("FCM send topic=%s err=%v", topic, err)
		return
	}
	log.Printf("FCM sent topic=%s msgID=%s", topic, id)
}

// pushAPNsAll sends a Critical Alert push to all registered iOS tokens.
//
// Requires the `com.apple.developer.usernotifications.critical-alerts`
// entitlement granted by Apple. The payload's `aps.sound` includes
// `critical: 1` and `volume`, which iOS honours only when the
// entitlement is present.
func (d *dispatcher) pushAPNsAll(ctx context.Context, eventID int64, a sitrepAlert, title, text string) {
	if d.apns == nil {
		return
	}
	rows, err := d.db.Query(`SELECT token FROM ios_tokens WHERE active = 1`)
	if err != nil {
		log.Printf("query ios tokens: %v", err)
		return
	}
	defer rows.Close()
	pl := apnsPayload.NewPayload().
		AlertTitle(title).
		AlertBody(text).
		// Critical Alert sound dictionary — bypasses silent + DND.
		Sound(map[string]any{
			"critical": 1,
			"name":     "siren.caf",
			"volume":   1.0,
		}).
		InterruptionLevel(apnsPayload.InterruptionLevelCritical).
		Custom("event_id", fmt.Sprintf("%d", eventID)).
		Custom("alert_id", fmt.Sprintf("%d", a.ID)).
		Custom("title", title).
		Custom("text", text).
		Custom("state", a.State)
	for rows.Next() {
		var tok string
		if err := rows.Scan(&tok); err != nil {
			continue
		}
		notif := &apns2.Notification{
			DeviceToken: tok,
			Topic:       d.apnsBundle,
			PushType:    apns2.PushTypeAlert,
			Priority:    apns2.PriorityHigh,
			Payload:     pl,
		}
		res, err := d.apns.PushWithContext(ctx, notif)
		if err != nil {
			log.Printf("APNs push err token=%s err=%v", truncate(tok, 8), err)
			continue
		}
		if res.StatusCode == 410 || res.Reason == "BadDeviceToken" {
			_, _ = d.db.Exec(`UPDATE ios_tokens SET active=0 WHERE token=?`, tok)
		}
		log.Printf("APNs token=%s status=%d reason=%s", truncate(tok, 8), res.StatusCode, res.Reason)
	}
}

// HTTP handlers ─────────────────────────────────────────────────────────────

type registerReq struct {
	Platform string   `json:"platform"` // "android" | "ios"
	Token    string   `json:"token"`
	Counties []string `json:"counties"` // EHAK codes user subscribed to
}

func (d *dispatcher) handleRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "method", 405)
		return
	}
	var req registerReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), 400)
		return
	}
	if req.Token == "" {
		http.Error(w, "token required", 400)
		return
	}
	switch req.Platform {
	case "ios":
		_, err := d.db.Exec(
			`INSERT INTO ios_tokens(token, counties, active, last_seen) VALUES(?,?,?,?)
			 ON CONFLICT(token) DO UPDATE SET counties=excluded.counties, active=1, last_seen=excluded.last_seen`,
			req.Token, strings.Join(req.Counties, ","), 1, time.Now().UTC().Format(time.RFC3339))
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
	case "android":
		// Android relies on FCM topics — backend stores token only for analytics.
		_, err := d.db.Exec(
			`INSERT INTO android_tokens(token, counties, last_seen) VALUES(?,?,?)
			 ON CONFLICT(token) DO UPDATE SET counties=excluded.counties, last_seen=excluded.last_seen`,
			req.Token, strings.Join(req.Counties, ","), time.Now().UTC().Format(time.RFC3339))
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
	default:
		http.Error(w, "platform must be android|ios", 400)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
}

func (d *dispatcher) handleTestPush(w http.ResponseWriter, r *http.Request) {
	a := sitrepAlert{
		ID:                -1,
		State:             "OPEN",
		StartDate:         time.Now().UTC().Format(time.RFC3339),
		NotificationSound: "PHONE_DEFAULT",
		Content: []sitrepContent{
			{CountryCode: "ET", Title: "TEST EE-ALARM", Text: "Droonialarm — testpush. See on harjutus."},
			{CountryCode: "EN", Title: "TEST EE-ALARM", Text: "Droonialarm — test push. This is a drill."},
		},
		EhakLocations: []ehakLocation{{EhakCode: "national"}},
	}
	d.broadcast(r.Context(), 0, a)
	fmt.Fprintln(w, "test dispatched")
}

// FCM init ──────────────────────────────────────────────────────────────────

func newFCM(ctx context.Context, saPath string) (*messaging.Client, error) {
	if saPath == "" {
		log.Println("FCM_SA_JSON not set — skipping FCM (Android push disabled)")
		return nil, nil
	}
	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsFile(saPath))
	if err != nil {
		return nil, err
	}
	return app.Messaging(ctx)
}

// APNs init ─────────────────────────────────────────────────────────────────

func newAPNS() (*apns2.Client, string, error) {
	keyPath := os.Getenv("APNS_KEY_P8")
	keyID := os.Getenv("APNS_KEY_ID")
	teamID := os.Getenv("APNS_TEAM_ID")
	bundle := os.Getenv("APNS_BUNDLE")
	if keyPath == "" || keyID == "" || teamID == "" || bundle == "" {
		log.Println("APNS env not set — skipping APNs (iOS push disabled)")
		return nil, "", nil
	}
	authKey, err := token.AuthKeyFromFile(keyPath)
	if err != nil {
		return nil, "", err
	}
	tok := &token.Token{AuthKey: authKey, KeyID: keyID, TeamID: teamID}
	cli := apns2.NewTokenClient(tok)
	if os.Getenv("APNS_PRODUCTION") == "1" {
		cli = cli.Production()
	} else {
		cli = cli.Development()
	}
	return cli, bundle, nil
}

// DB init ───────────────────────────────────────────────────────────────────

func openDB(path string) (*sql.DB, error) {
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	if _, err := db.Exec(`
CREATE TABLE IF NOT EXISTS alerts_seen (
  alert_id        INTEGER PRIMARY KEY,
  state           TEXT NOT NULL,
  content_digest  TEXT NOT NULL,
  first_seen      TEXT NOT NULL,
  last_seen       TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS ios_tokens (
  token       TEXT PRIMARY KEY,
  counties    TEXT,
  active      INTEGER DEFAULT 1,
  last_seen   TEXT
);
CREATE TABLE IF NOT EXISTS android_tokens (
  token       TEXT PRIMARY KEY,
  counties    TEXT,
  last_seen   TEXT
);
`); err != nil {
		return nil, err
	}
	return db, nil
}

// helpers ───────────────────────────────────────────────────────────────────

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "…"
}
