class_name SaveSecurity
extends RefCounted
## AES-256-CBC with PKCS#7 padding and HMAC-SHA256 (encrypt-then-MAC over header + ciphertext block).
## Keep [code]open_outer_save_file[/code] and [member OUTER_FORMAT_VERSION] in sync with Lite’s [code]addons/savestate/encrypted_save_reader.gd[/code] (Save Browser health checks).

const OUTER_FORMAT_VERSION: int = 2
const IV_SIZE: int = 16
const HMAC_SIZE: int = 32
const AES_KEY_SIZE: int = 32


static func seal_inner_save_file(
		inner_complete_file: PackedByteArray,
		aes_key: PackedByteArray,
		hmac_key: PackedByteArray
	) -> PackedByteArray:
	if aes_key.size() != AES_KEY_SIZE or hmac_key.size() < 1:
		return PackedByteArray()

	var crypto := Crypto.new()
	var iv := crypto.generate_random_bytes(IV_SIZE)
	var padded := pad_pkcs7(inner_complete_file, 16)
	var enc := aes_cbc_encrypt(padded, aes_key, iv)
	var body := PackedByteArray()
	body.append_array(iv)
	body.append_array(enc)

	var header := SaveFormat.build_header(OUTER_FORMAT_VERSION, 0, 0, body.size())
	var to_mac := PackedByteArray()
	to_mac.append_array(header)
	to_mac.append_array(body)
	var mac := crypto.hmac_digest(HashingContext.HASH_SHA256, hmac_key, to_mac)
	var out := to_mac
	out.append_array(mac)
	return out


static func open_outer_save_file(
		outer_file: PackedByteArray,
		aes_key: PackedByteArray,
		hmac_key: PackedByteArray
	) -> Dictionary:
	if outer_file.size() < SaveFormat.HEADER_SIZE + IV_SIZE + HMAC_SIZE:
		return {"error": ERR_FILE_CORRUPT}

	var h := SaveFormat.parse_header(outer_file)
	if int(h.get("error", OK)) != OK:
		return {"error": ERR_FILE_UNRECOGNIZED}

	var payload_len: int = int(h["payload_len"])
	var expected_total := SaveFormat.HEADER_SIZE + payload_len + HMAC_SIZE
	if outer_file.size() != expected_total:
		return {"error": ERR_FILE_CORRUPT}

	var header := outer_file.slice(0, SaveFormat.HEADER_SIZE)
	var body := outer_file.slice(SaveFormat.HEADER_SIZE, SaveFormat.HEADER_SIZE + payload_len)
	var mac := outer_file.slice(SaveFormat.HEADER_SIZE + payload_len, expected_total)

	var crypto := Crypto.new()
	var to_mac := header.duplicate()
	to_mac.append_array(body)
	var expect_mac := crypto.hmac_digest(HashingContext.HASH_SHA256, hmac_key, to_mac)
	if expect_mac != mac:
		return {"error": ERR_INVALID_DATA}

	if body.size() < IV_SIZE:
		return {"error": ERR_FILE_CORRUPT}
	var iv := body.slice(0, IV_SIZE)
	var ciphertext := body.slice(IV_SIZE, body.size())
	var dec_padded := aes_cbc_decrypt(ciphertext, aes_key, iv)
	if dec_padded.is_empty():
		return {"error": ERR_INVALID_DATA}
	var inner := unpad_pkcs7(dec_padded)
	return {"error": OK, "inner": inner}


static func aes_cbc_encrypt(plaintext: PackedByteArray, key: PackedByteArray, iv: PackedByteArray) -> PackedByteArray:
	var aes := AESContext.new()
	if aes.start(AESContext.MODE_CBC_ENCRYPT, key, iv) != OK:
		return PackedByteArray()
	var out := aes.update(plaintext)
	out.append_array(aes.finalize())
	return out


static func aes_cbc_decrypt(ciphertext: PackedByteArray, key: PackedByteArray, iv: PackedByteArray) -> PackedByteArray:
	var aes := AESContext.new()
	if aes.start(AESContext.MODE_CBC_DECRYPT, key, iv) != OK:
		return PackedByteArray()
	var out := aes.update(ciphertext)
	out.append_array(aes.finalize())
	return out


static func pad_pkcs7(data: PackedByteArray, block_size: int) -> PackedByteArray:
	var pad_len: int = block_size - (data.size() % block_size)
	if pad_len == 0:
		pad_len = block_size
	var out := data.duplicate()
	for i in pad_len:
		out.append(pad_len)
	return out


static func unpad_pkcs7(data: PackedByteArray) -> PackedByteArray:
	if data.is_empty():
		return data
	var pad_len: int = int(data[data.size() - 1])
	if pad_len < 1 or pad_len > data.size():
		return data
	return data.slice(0, data.size() - pad_len)


static func key_from_hex(hex: String) -> PackedByteArray:
	var s := hex.strip_edges().replace(" ", "")
	if s.is_empty() or s.length() % 2 != 0:
		return PackedByteArray()
	var out := PackedByteArray()
	var i := 0
	while i < s.length():
		var hi := _hex_nibble(s.unicode_at(i))
		var lo := _hex_nibble(s.unicode_at(i + 1))
		if hi < 0 or lo < 0:
			return PackedByteArray()
		out.append((hi << 4) | lo)
		i += 2
	return out


static func _hex_nibble(ch: int) -> int:
	if ch >= 48 and ch <= 57:
		return ch - 48
	if ch >= 97 and ch <= 102:
		return 10 + (ch - 97)
	if ch >= 65 and ch <= 70:
		return 10 + (ch - 65)
	return -1
