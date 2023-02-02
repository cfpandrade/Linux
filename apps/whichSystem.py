#!/usr/bin/python3
#coding: utf-8

import subprocess
import sys

if len(sys.argv) != 2:
    print("\n[!] Uso: python3 " + sys.argv[0] + " <direccion-ip>\n")
    sys.exit(1)

ip_address = sys.argv[1]
result = subprocess.run(["ping", "-c", "1", ip_address], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
ttl = int(float(result.stdout.split()[7]))

if ttl >= 0 and ttl <= 64:
    os_name = "Linux"
elif ttl >= 65 and ttl <= 128:
    os_name = "Windows"
else:
    os_name = "Not Found"

print("%s (ttl -> %d): %s" % (ip_address, ttl, os_name))

#  ______________________________
# < developed by: Carlos Andrade >
#  ------------------------------
#         \   ^__^
#          \  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||


