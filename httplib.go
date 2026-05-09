package lua

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

/* http library {{{ */

var httpFuncs = map[string]LGFunction{
	"get":     httpGet,
	"post":    httpPost,
	"put":     httpPut,
	"delete":  httpDelete,
	"request": httpRequest,
	"stream":  httpStream,
}

func OpenHttp(L *LState) int {
	L.RegisterModule("http", httpFuncs)
	return 1
}

func httpGet(L *LState) int {
	url := L.CheckString(1)
	return doHTTPRequest(L, "GET", url, "", nil)
}

func httpPost(L *LState) int {
	url := L.CheckString(1)
	body := L.OptString(2, "")
	headers := parseHeaders(L, 3)
	return doHTTPRequest(L, "POST", url, body, headers)
}

func httpPut(L *LState) int {
	url := L.CheckString(1)
	body := L.OptString(2, "")
	headers := parseHeaders(L, 3)
	return doHTTPRequest(L, "PUT", url, body, headers)
}

func httpDelete(L *LState) int {
	url := L.CheckString(1)
	headers := parseHeaders(L, 2)
	return doHTTPRequest(L, "DELETE", url, "", headers)
}

func httpRequest(L *LState) int {
	method := L.CheckString(1)
	url := L.CheckString(2)
	body := L.OptString(3, "")
	headers := parseHeaders(L, 4)
	return doHTTPRequest(L, method, url, body, headers)
}

func parseHeaders(L *LState, idx int) map[string]string {
	headers := make(map[string]string)
	tb := L.OptTable(idx, nil)
	if tb != nil {
		tb.ForEach(func(key, value LValue) {
			if skey, ok := key.(LString); ok {
				if sval, ok := value.(LString); ok {
					headers[string(skey)] = string(sval)
				}
			}
		})
	}
	return headers
}

func doHTTPRequest(L *LState, method, url, body string, headers map[string]string) int {
	var reqBody io.Reader
	if body != "" {
		reqBody = strings.NewReader(body)
	}

	req, err := http.NewRequest(method, url, reqBody)
	if err != nil {
		L.RaiseError("http request error: %v", err)
	}

	for k, v := range headers {
		req.Header.Set(k, v)
	}

	client := &http.Client{
		Timeout: 10000 * 1000000, // 10 seconds
	}
	resp, err := client.Do(req)
	if err != nil {
		L.RaiseError("http request error: %v", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		L.RaiseError("http read error: %v", err)
	}

	// build response table
	tb := &LTable{}
	tb.RawSetString("status", LNumber(resp.StatusCode))
	tb.RawSetString("body", LString(string(respBody)))
	tb.RawSetString("headers", headersToTable(resp.Header))

	L.Push(tb)
	return 1
}

func headersToTable(h http.Header) *LTable {
	tb := &LTable{}
	for k, vals := range h {
		if len(vals) == 1 {
			tb.RawSetString(strings.ToLower(k), LString(vals[0]))
		} else {
			arr := &LTable{}
			for i, v := range vals {
				arr.RawSetInt(i+1, LString(v))
			}
			tb.RawSetString(strings.ToLower(k), arr)
		}
	}
	return tb
}

func httpStream(L *LState) int {
	method := L.CheckString(1)
	url := L.CheckString(2)
	body := L.OptString(3, "")
	headers := parseHeaders(L, 4)
	callback := L.CheckFunction(5)

	var reqBody io.Reader
	if body != "" {
		reqBody = strings.NewReader(body)
	}

	req, err := http.NewRequest(method, url, reqBody)
	if err != nil {
		callStreamCallback(L, callback, fmt.Sprintf("http request error: %v", err), "")
		return 0
	}

	for k, v := range headers {
		req.Header.Set(k, v)
	}
	if req.Header.Get("Accept") == "" {
		req.Header.Set("Accept", "text/event-stream")
	}

	// 30 second timeout for streaming requests
	ctx, cancel := context.WithTimeout(req.Context(), 30*time.Second)
	defer cancel()
	req = req.WithContext(ctx)

	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	resp, err := client.Do(req)
	if err != nil {
		callStreamCallback(L, callback, fmt.Sprintf("http request error: %v", err), "")
		return 0
	}
	defer resp.Body.Close()

	scanner := bufio.NewScanner(resp.Body)
	// increase max line length for large JSON chunks
	scanner.Buffer(make([]byte, 0, 4096), 1024*1024)

	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "data:") {
			data := strings.TrimSpace(strings.TrimPrefix(line, "data:"))
			if data == "[DONE]" {
				callStreamCallback(L, callback, "", "")
				break
			}
			action := callStreamCallback(L, callback, "", data)
			if action == "stop" {
				break
			}
		}
	}
	if err := scanner.Err(); err != nil {
		callStreamCallback(L, callback, fmt.Sprintf("http read error: %v", err), "")
	}

	return 0
}

// callStreamCallback calls the Lua callback with (err, data).
// Returns the callback's first return value as string (e.g. "stop").
func callStreamCallback(L *LState, callback *LFunction, err, data string) string {
	L.Push(callback)
	if err != "" {
		L.Push(LString(err))
		L.Push(LNil)
	} else {
		L.Push(LNil)
		if data == "" {
			L.Push(LNil)
		} else {
			L.Push(LString(data))
		}
	}
	if pcallErr := L.PCall(2, 1, nil); pcallErr != nil {
		return "stop"
	}
	ret := L.Get(1)
	if ret == LString("stop") {
		return "stop"
	}
	return ""
}

/* }}} */
