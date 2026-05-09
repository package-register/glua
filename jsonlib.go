package lua

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
)

/* json library {{{ */

var jsonFuncs = map[string]LGFunction{
	"decode": jsonDecode,
	"encode": jsonEncode,
}

func OpenJson(L *LState) int {
	L.RegisterModule("json", jsonFuncs)
	return 1
}

func jsonDecode(L *LState) int {
	str := L.CheckString(1)

	var reader io.Reader
	if strings.HasPrefix(str, "@") {
		f, err := os.Open(strings.TrimPrefix(str, "@"))
		if err != nil {
			L.RaiseError("cannot open file '%s': %v", str, err)
		}
		defer f.Close()
		reader = f
	} else {
		reader = strings.NewReader(str)
	}

	var v interface{}
	decoder := json.NewDecoder(reader)
	if err := decoder.Decode(&v); err != nil {
		L.RaiseError("json decode error: %v", err)
	}

	L.Push(lValueFromJSON(v))
	return 1
}

func jsonEncode(L *LState) int {
	val := L.CheckAny(1)
	pretty := L.OptBool(2, false)

	var b []byte
	var err error
	if pretty {
		b, err = json.MarshalIndent(lValueToJSON(val), "", "  ")
	} else {
		b, err = json.Marshal(lValueToJSON(val))
	}
	if err != nil {
		L.RaiseError("json encode error: %v", err)
	}

	L.Push(LString(string(b)))
	return 1
}

/* json value conversion {{{ */

func lValueFromJSON(v interface{}) LValue {
	switch val := v.(type) {
	case nil:
		return LNil
	case bool:
		if val {
			return LTrue
		}
		return LFalse
	case float64:
		return LNumber(val)
	case string:
		return LString(val)
	case []interface{}:
		tb := &LTable{}
		for i, item := range val {
			tb.RawSetInt(i+1, lValueFromJSON(item))
		}
		return tb
	case map[string]interface{}:
		tb := &LTable{}
		for k, v := range val {
			tb.RawSetString(k, lValueFromJSON(v))
		}
		return tb
	default:
		return LNil
	}
}

func lValueToJSON(val LValue) interface{} {
	switch v := val.(type) {
	case *LNilType:
		return nil
	case LBool:
		return bool(v)
	case LNumber:
		return float64(v)
	case LString:
		return string(v)
	case *LTable:
		// check if purely array-like (consecutive integer keys starting from 1)
		maxN := v.MaxN()
		hasStrKey := false
		arrLen := v.Len()

		v.ForEach(func(key, value LValue) {
			if _, ok := key.(LString); ok {
				hasStrKey = true
			}
		})

		if !hasStrKey && maxN > 0 {
			// purely array-like
			arr := make([]interface{}, arrLen)
			v.ForEach(func(key, value LValue) {
				if n, ok := key.(LNumber); ok {
					idx := int(n) - 1
					if idx >= 0 && idx < arrLen {
						arr[idx] = lValueToJSON(value)
					}
				}
			})
			return arr
		}

		// object
		obj := make(map[string]interface{})
		v.ForEach(func(key, value LValue) {
			if s, ok := key.(LString); ok {
				obj[string(s)] = lValueToJSON(value)
			} else if n, ok := key.(LNumber); ok {
				obj[fmt.Sprintf("%d", int(n))] = lValueToJSON(value)
			}
		})
		return obj
	default:
		return nil
	}
}

/* }}} */

/* }}} */
