#!/usr/bin/env python3
# monman, the monitor manager
#
# Author: Andreas Lindhé
# Version: 2.1
# License: MIT License

import sys, os, argparse
from subprocess import run, PIPE
import re
import json

###########################     global variables     ###########################
conf_str = os.path.expanduser('~/.config/monitors.json')
dryrun = False
sorting = False
verbose = False
version = "2.1"

#####################     activate connected monitors     #####################
# Returns: nothing, unless failure
def activate(config_file=conf_str):
    with open(config_file) as data:
        config = json.load(data)

    connectedList = connectedMonitors()

    xrandrargs = " --dryrun" if dryrun else ""
    for monitors in config:
        for i,m in enumerate(monitors):
            if m in connectedList:
                xrandrargs += " --output " + str(m)
                if i:
                    xrandrargs += direction + monitors[i-1]
                for setting in monitors[m]:
                    xrandrargs += " --" + setting
                    if (type(monitors[m][setting]) != bool):
                        xrandrargs += " " + str(monitors[m][setting])

    success = run(("xrandr" + xrandrargs).split())
    if verbose:
        print("xrandr" + xrandrargs)
        if (not success.returncode):
            print("Successfully set new screen configuration!")
        else:
            print("Failure to set screen configuration. Returncode: " + str(success.returncode))
    return success.returncode

####################     deactivate connected monitors     ####################
# Returns: nothing, unless failure
def deactivate():
    externalMonitors = allExternalOutputs()

    xrandrargs = " --dryrun" if dryrun else ""
    if externalMonitors:
        for monitor in externalMonitors:
            xrandrargs += " --output " + str(monitor) + " --off "

    success = run(("xrandr" + xrandrargs).split())
    if verbose:
        print("xrandr" + xrandrargs)
        if (not success.returncode):
            print("Successfully disabled all external monitors!")
        else:
            print("Failed disabling all external monitors. Returncode: " + str(success.returncode))
    return success.returncode

#################     return list of all external outputs     #################
# Returns: List
def allExternalOutputs():
    xrandr = run(["xrandr", "--query"], universal_newlines=True, stdout=PIPE)
    if xrandr.returncode:
        exit(1)
    # Save list of monitor names
    externalOutputs = re.compile("(.+) .*connected [^primary]")
    em = externalOutputs.findall(xrandr.stdout)
    # If sorting is on, sort it. Keep primary at the head.
    if sorting:
        em = sorted(em)
    if verbose:
        print("List of connected monitors:")
        print(em)
    return em

##################     return list of connected monitors     ##################
# Returns: List
def connectedMonitors():
    xrandr = run(["xrandr", "--query"], universal_newlines=True, stdout=PIPE)
    if xrandr.returncode:
        exit(1)
    # Save list of monitor names
    primary = re.compile("(.+) connected primary")
    connected = re.compile("(.+) connected [^primary]")
    pm = primary.findall(xrandr.stdout)
    cm = connected.findall(xrandr.stdout)
    # If sorting is on, sort it. Keep primary at the head.
    cm = pm+sorted(cm) if sorting else pm+cm
    if verbose:
        print("List of connected monitors:")
        print(cm)
    return cm

####################     check if monitor is connected     ####################
# Returns: Bool
def checkMonitor(m):
    c = connectedMonitors()
    if verbose:
        if (m in c):
            print(m + " is connected!")
        else:
            print(m + " is not connected!")
    return (m in c)

#################################     Main     #################################
def main():
    global dryrun
    global verbose

# Argument parsing
    p = argparse.ArgumentParser(description="Find and activate monitors via xrandr!")

    p.add_argument('-a', '--activate', action="store_true",
            help="activate monitors from config")

    p.add_argument('config', nargs="?", default=conf_str,
            help="path to configuration file (default " + conf_str +")")

    p.add_argument('-c', '--check', metavar="M",
            help="Check if monitor M is connected")

    p.add_argument('-d', '--deactivate', action="store_true",
            help="deactivate all monitors except for primary")

    p.add_argument('--dryrun', action="store_true",
            help="try action without making any real changes")

    p.add_argument('-s', '--sort', dest="sorting", action="store_true",
            help="sort the list of monitors")

    p.add_argument('-v', '--verbose', action="store_true",
            help="print more stuff")

    p.add_argument('-V', '--version', action="version", version=version)

    args = p.parse_args()
    dryrun = args.dryrun
    sorting = args.sorting
    verbose = args.verbose

# Dynamically choose function
    if (args.activate):
        if verbose: print("Activating monitors from file " + args.config)
        activate(args.config)
    elif (args.check):
        if verbose: print("Checking for monitor " + args.check)
        print(checkMonitor(args.check))
    elif (args.deactivate):
        if verbose: print("Deactivating all external monitors.")
        deactivate()
    else:
        if verbose: print("Looking for connected monitors...")
        connectedMonitors()

    exit(0)

if __name__ == "__main__":
   main()

exit(1)

