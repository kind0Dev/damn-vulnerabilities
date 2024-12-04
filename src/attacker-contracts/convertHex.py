import base64
import binascii

def decode_hex_strings(hex_strings):
    """
    Decode two hex strings through multiple steps:
    1. Convert hex to bytes
    2. Decode bytes as base64
    3. Convert resulting string to hex strings
    
    Args:
        hex_strings (list): List of two hex strings to decode
    
    Returns:
        list: List of final decoded hex strings
    """
    results = []
    
    for hex_str in hex_strings:
        # Remove spaces from hex string
        hex_str = hex_str.replace(" ", "")
        
        try:
            # Step 1: Convert hex to bytes
            hex_bytes = binascii.unhexlify(hex_str)
            
            # Step 2: Decode base64
            base64_decoded = base64.b64decode(hex_bytes)
            
            # Step 3: Convert to hex string
            final_hex = binascii.hexlify(base64_decoded).decode('utf-8')
            
            results.append(final_hex)
            
        except Exception as e:
            print(f"Error decoding string: {str(e)}")
            results.append(None)
    
    return results

# Input hex strings
hex_string1 = "4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30"
hex_string2 = "4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35"

# Run the decoder
decoded_strings = decode_hex_strings([hex_string1, hex_string2])

key1 = decoded_strings[0]
key2 = decoded_strings[1]

# Print results
print("\nDecoded private keys:")
for i, result in enumerate(decoded_strings, 1):
    if result:
        print(f"Key {i}: {result}")
    else:
        print(f"Key {i}: Decoding failed")

def convert_hex_to_uint256(hex_string):
    """
    Convert hex string to uint256 format suitable for Solidity, properly handling double-encoded hex
    
    Args:
        hex_string (str): Hex string to convert
        
    Returns:
        str: Formatted uint256 hex string
    """
    # Remove any '0x' prefix if present
    hex_string = hex_string.replace('0x', '')
    
    # First decode the double-encoded hex string
    # Each pair of characters represents one byte
    decoded = bytes.fromhex(hex_string).decode('utf-8')
    
    # Remove '0x' if present in the decoded string
    decoded = decoded.replace('0x', '')
    
    # Format as 0x prefixed hex string
    formatted_hex = f"0x{decoded}"
    
    # Convert to decimal for verification
    decimal_value = int(decoded, 16)
    
    print(f"Decimal value: {decimal_value}")
    print(f"Hex format for Solidity: {formatted_hex}")
    
    return formatted_hex


print("Converting Key 1:")
result1 = convert_hex_to_uint256(key1)

print("\nConverting Key 2:")
result2 = convert_hex_to_uint256(key2)


""" 
This section is for Curvy Puppet Chanllenge it about the virtual_price calculation 
"""


def calculate_D(xp, amp, N_COINS):
    S = sum(xp)  # total sum of balances
    if S == 0:
        return 0

    D = S  # Initial guess for D
    Ann = amp * N_COINS  # Amplification coefficient

    for _ in range(255):  # Iterate to convergence
        D_P = D
        for x in xp:
            D_P = D_P * D // (x * N_COINS + 1)  # Adjust D_P for balances

        D_prev = D
        numerator = (Ann * S // A_PRECISION + D_P * N_COINS) * D
        denominator = ((Ann - A_PRECISION) * D // A_PRECISION + (N_COINS + 1) * D_P)
        D = numerator // denominator

        # Convergence check
        if abs(D - D_prev) <= 1:
            return D

    raise ValueError("D did not converge")




xp = [23567_652834372746200869 + 200000* 10**18, 28830_973314825299545839 ]  # balances of assets
amp = 90000  # amplification factor
N_COINS = 2  # number of coins in the pool
A_PRECISION = 100  # precision factor
total_supply_lp = 47392_443867221892576908 # total supply of LP tokens

# Calculate D and virtual price
D = calculate_D(xp, amp, N_COINS)
virtual_price = D * 10**18 // total_supply_lp  # Normalize to precision 1e18

print(D)
print(virtual_price)

1_105626245417432119
1_115669380952564000
5_321378110663952943
1_105626245417432119

1_188505189824270346
3_50642196485123253423
1_000000000000000000