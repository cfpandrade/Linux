#!/usr/bin/python3
#coding: utf-8

import subprocess
import sys
from termcolor import colored


def print_colored(string, color):
    print(colored(string, color))

if len(sys.argv) != 2:
    print_colored("\n[!] Uso: python3 " + sys.argv[0] + " <direccion-ip>\n", "red")
    sys.exit(1)

ip_address = sys.argv[1]
result = subprocess.run(["ping", "-c", "1", ip_address], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
stdout = result.stdout.decode("utf-8")

try:
    ttl_index = stdout.index("ttl=") + 4
    ttl = int(stdout[ttl_index:stdout.index(" ", ttl_index)])
except ValueError:
    ttl = None

if ttl >= 0 and ttl <= 64:
    os_name = "Linux"
    color = "blue"
    print_colored("\n                                    ", "cyan")
    print_colored(" █████        ███                                   ", "cyan")
    print_colored("░░███        ░░░                                    ", "cyan")
    print_colored(" ░███        ████  ████████   █████ ████ █████ █████", "cyan")
    print_colored(" ░███       ░░███ ░░███░░███ ░░███ ░███ ░░███ ░░███ ", "cyan")
    print_colored(" ░███        ░███  ░███ ░███  ░███ ░███  ░░░█████░  ", "cyan")
    print_colored(" ░███      █ ░███  ░███ ░███  ░███ ░███   ███░░░███ ", "cyan")
    print_colored(" ███████████ █████ ████ █████ ░░████████ █████ █████", "cyan")
    print_colored("░░░░░░░░░░░ ░░░░░ ░░░░ ░░░░░   ░░░░░░░░ ░░░░░ ░░░░░ ", "cyan")
    print_colored("\n\n", "cyan")
elif ttl >= 65 and ttl <= 128:
    os_name = "Windows"
    color = "yellow"
    print_colored("\n                                   ", "cyan")
    print_colored(" █████   ███   █████  ███                 █████                                 ", "cyan")
    print_colored("░░███   ░███  ░░███  ░░░                 ░░███                                  ", "cyan")
    print_colored(" ░███   ░███   ░███  ████  ████████    ███████   ██████  █████ ███ █████  █████ ", "cyan")
    print_colored(" ░███   ░███   ░███ ░░███ ░░███░░███  ███░░███  ███░░███░░███ ░███░░███  ███░░  ", "cyan")
    print_colored(" ░░███  █████  ███   ░███  ░███ ░███ ░███ ░███ ░███ ░███ ░███ ░███ ░███ ░░█████ ", "cyan")
    print_colored("  ░░░█████░█████░    ░███  ░███ ░███ ░███ ░███ ░███ ░███ ░░███████████   ░░░░███", "cyan")
    print_colored("    ░░███ ░░███      █████ ████ █████░░████████░░██████   ░░████░████    ██████ ", "cyan")
    print_colored("     ░░░   ░░░      ░░░░░ ░░░░ ░░░░░  ░░░░░░░░  ░░░░░░     ░░░░ ░░░░    ░░░░░░  ", "cyan")
    print_colored("\n\n", "cyan")
else:
    os_name = "Not Found"
    color = "red"

if ttl is None:
    print_colored("%s (ttl -> Not Found): %s" % (ip_address, os_name), color)
else:
    print_colored("%s (ttl -> %d): %s" % (ip_address, ttl, os_name), color)

print_colored("\n\nDeveloped by: Carlos Andrade", "green")
