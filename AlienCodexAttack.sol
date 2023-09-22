/**
    // calculate slot-1 location
    hash := sha3.NewLegacyKeccak256()
	h, _ := hex.DecodeString("0000000000000000000000000000000000000000000000000000000000000001")
	hash.Write(h)
	sig := hash.Sum(nil)
	location := hex.EncodeToString(sig)
	fmt.Println(location)
 */