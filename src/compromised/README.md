# Compromised

While poking around a web service of one of the most popular DeFi projects in the space, you get a strange response from the server. Here’s a snippet:

```
HTTP/2 200 OK
content-type: text/html
content-language: en
vary: Accept-Encoding
server: cloudflare

4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30

4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35
```

A related on-chain exchange is selling (absurdly overpriced) collectibles called “DVNFT”, now at 999 ETH each.

This price is fetched from an on-chain oracle, based on 3 trusted reporters: `0x188...088`, `0xA41...9D8` and `0xab3...a40`.

Starting with just 0.1 ETH in balance, pass the challenge by rescuing all ETH available in the exchange. Then deposit the funds into the designated recovery account.


    * @dev
     * Exploit Overview:
     * 
     * We are given two random hex strings to start with 
        The python `convertHex.py` script I've created:

        Takes the two hex strings as input
        For each string:

        Removes spaces from the hex string
        Converts the hex to bytes
        Decodes the bytes as base64
        Converts the result back to a hex string

        Returns the final decoded hex strings (private keys)
        You can run this script directly with the provided hex strings. The script will output the decoded private keys in hex format along side
        the unint256 of the private which can be used directly in foundry.

     * which turn out to be the private keys of two of the oracles
     * 
     * Since we then control 2/3 oracles we can control the median price, as the median is 
     * will be the middle price of the 3.
     * 
     * So since we control price we can set the price to be super low, purchase the NFT
     * and then sell it back to the exchange at the price of the balance of the exchange 
     * to steal all the funds of the exchange.
     * 
     * Then to meet the final condition of the success condition we just need to reset 
     * the oracle price
     * 
     * So the exploit goes:
     * 
     * 1. Setup oracle wallets with private keys
     * 2. Set median price to something small but > 0
     * 3. Purchase NFT at new low price
     * 4. Set median price to the balance of the Exchange contract
     * 5. Sell NFT back to exchange for the new median price of the exchange
     * 6. Reset oracle price to initial conditions
     */