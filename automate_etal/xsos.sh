#!/bin/bash
# xsos v0.7.11 last mod 2017/03/17
# Latest version at <http://github.com/ryran/xsos>
# RPM packages available at <http://people.redhat.com/rsawhill/rpms>
# Copyright 2012-2016 Ryan Sawhill Aroha <rsaw@redhat.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#    General Public License <gnu.org/licenses/gpl.html> for more details.
#-------------------------------------------------------------------------------

# See https://github.com/ryran/xsos/issues/208
export LC_ALL=en_US.UTF-8

# Get version from line #2
version=$(sed '2q;d' $0)

# Colors and colors and colors oh my (but only for bash v4)
if [[ $BASH_VERSINFO -ge 4 ]]; then
  declare -A c
  c[reset]='\033[0;0m'   c[BOLD]='\033[0;0m\033[1;1m'
  c[dgrey]='\033[0;30m'  c[DGREY]='\033[1;30m'  c[bg_DGREY]='\033[40m'
  c[red]='\033[0;31m'    c[RED]='\033[1;31m'    c[bg_RED]='\033[41m'
  c[green]='\033[0;32m'  c[GREEN]='\033[1;32m'  c[bg_GREEN]='\033[42m'
  c[orange]='\033[0;33m' c[ORANGE]='\033[1;33m' c[bg_ORANGE]='\033[43m'
  c[blue]='\033[0;34m'   c[BLUE]='\033[1;34m'   c[bg_BLUE]='\033[44m'
  c[purple]='\033[0;35m' c[PURPLE]='\033[1;35m' c[bg_PURPLE]='\033[45m'
  c[cyan]='\033[0;36m'   c[CYAN]='\033[1;36m'   c[bg_CYAN]='\033[46m'
  c[lgrey]='\033[0;37m'  c[LGREY]='\033[1;37m'  c[bg_LGREY]='\033[47m'
fi

# ==============================================================================
# ENVIRONMENT VARIABLES -- Modify these by setting them in your shell
# environment, e.g. ~/.bash_profile or /etc/profile.d/xsos.sh

# COLORS
# The following configure defaults for various colors to enhance output

#   XSOS_COLORS (bool: y/n)
#     Controls whether color is enabled or disabled by default
#     Can also be controlled by cmdline arg
      : ${XSOS_COLORS:="y"}

#   XSOS_COLOR_RESET -- color to reset terminal to after using other colors
      : ${XSOS_COLOR_RESET:="reset"}

#   XSOS_COLOR_H1 -- color for content modules' primary header
      : ${XSOS_COLOR_H1:="RED"}

#   XSOS_COLOR_H2 -- color for content modules' secondary header
      : ${XSOS_COLOR_H2:="PURPLE"}

#   XSOS_COLOR_H3 -- color for content modules' tertiary header
      : ${XSOS_COLOR_H3:="BLUE"}

#   XSOS_COLOR_H4 -- color used only for SYSCTL() module
      : ${XSOS_COLOR_H4:="reset"}

#   XSOS_COLOR_IMPORTANT -- color for drawing attention to important data
      : ${XSOS_COLOR_IMPORTANT:="BOLD"}

#   XSOS_COLOR_WARN1 -- color for level-1 warnings
      : ${XSOS_COLOR_WARN1:="orange"}

#   XSOS_COLOR_WARN2 -- color for level-2 warnings
      : ${XSOS_COLOR_WARN2:="ORANGE"}

#   XSOS_COLOR_MEMGRAPH_MEMUSED -- color for MemUsed in MEMINFO() graph
      : ${XSOS_COLOR_MEMGRAPH_MEMUSED:="green"}

#   XSOS_COLOR_MEMGRAPH_HUGEPAGES -- color for HugePages in MEMINFO() graph
      : ${XSOS_COLOR_MEMGRAPH_HUGEPAGES:="cyan"}

#   XSOS_COLOR_MEMGRAPH_BUFFERS -- color for Buffers in MEMINFO() graph
      : ${XSOS_COLOR_MEMGRAPH_BUFFERS:="purple"}

#   XSOS_COLOR_MEMGRAPH_CACHED -- color for Cached in MEMINFO() graph
      : ${XSOS_COLOR_MEMGRAPH_CACHED:="blue"}

#   XSOS_COLOR_MEMGRAPH_DIRTY -- color for Dirty in MEMINFO() graph
      : ${XSOS_COLOR_MEMGRAPH_DIRTY:="red"}

#   XSOS_COLOR_IFUP -- color for ethtool InterFace "up"
      : ${XSOS_COLOR_IFUP:="green"}

#   XSOS_COLOR_IFDOWN -- color for ethtool InterFace "down"
      : ${XSOS_COLOR_IFDOWN:="lgrey"}

# INDENTATION
#   The following variables are not used universally and that might not change

#   XSOS_INDENT_H1 -- 1st level of indentation
      : ${XSOS_INDENT_H1:="  "}

#   XSOS_INDENT_H2 -- 2nd level of indentation
      : ${XSOS_INDENT_H2:="    "}

#   XSOS_INDENT_H3 -- 3rd level of indentation
      : ${XSOS_INDENT_H3:="      "}

# XSOS_FOLD_WIDTH (w, 0, or positive number)
#   Some content modules print line of unpredictable length
#   This setting controls the wrapping width for commands that use it
#   Changing to w causes width of terminal to be used
#   Changing to 0 causes 99999 to be used
    : ${XSOS_FOLD_WIDTH:="w"}

# XSOS_HEADING_SEPARATOR (str)
#   Acts as a separator between content modules
#   Should include at least 1 trailing new-line
    : ${XSOS_HEADING_SEPARATOR:="\n"}

# XSOS_ALL_VIEW (str of variables, space-separated)
#   Controls what content modules to run when -a/--all switch is used
    : ${XSOS_ALL_VIEW:="bios os kdump cpu intrupt mem disks mpath lspci ethtool softirq bonding ip netdev sysctl ps"}

# XSOS_DEFAULT_VIEW (str of variables, space-separated)
#   Controls default content modules, i.e. what to run when none are specififed
    : ${XSOS_DEFAULT_VIEW:="os"}

# XSOS_PS_THREADS (bool: y/n)
#   Controls whether PSCHECK() function parses `ps aux` or `ps auxm` output
    : ${XSOS_PS_THREADS:="n"}

# XSOS_PS_LEVEL (int: 0-4)
#   Controls verbosity level (4 being highest) in PSCHECK() function
    : ${XSOS_PS_LEVEL:="1"}

# XSOS_MULTIPATH_QUERY (string: arbitrary regex)
#   Only a tenuous case can be made for statically setting this
#   It's used by the MULTIPATH() function to restrict display to a particular mpath device
#   Traditionally controled by -q/--wwid option
    : ${XSOS_MULTIPATH_QUERY:=""}

# XSOS_MEM_UNIT (str: b, k, m, g, t)
#   Sets unit used by MEMINFO() function for printing
#   Can also be controlled by cmdline opt -u/--unit
    : ${XSOS_MEM_UNIT:="g"}

# XSOS_NET_UNIT (str: b, k, m, g, t)
#   Sets unit used by NETDEV() function for printing Rx & Tx Bytes
#   Can also be controlled by cmdline opt -u/--unit
    : ${XSOS_NET_UNIT:="m"}

# XSOS_PS_UNIT (str: k, m, g)
#   Sets unit used by PSCHECK() function for printing VSZ & RSS
#   Not affected by cmdline opt -u/--unit option
    : ${XSOS_PS_UNIT:="m"}

# XSOS_OUTPUT_HANDLER (str: application name)
#   Sets name of application to handle output
    : ${XSOS_OUTPUT_HANDLER:="cat"}

# XSOS_OS_RHT_CENTRIC (bool: y/n)
#   Configures whether OSINFO() focuses on Red Hat support issues
    : ${XSOS_OS_RHT_CENTRIC:="n"}

# XSOS_IP_VERSION (int: 4/6)
#   Configures whether IPADDR() shows ipv4 or ipv6 addresses
    : ${XSOS_IP_VERSION:="4"}

# XSOS_SCRUB_IP_HN (bool: y/n)
#   Configures whether IP addrs & hostnames should be removed from output
    : ${XSOS_SCRUB_IP_HN:="n"}

# XSOS_SCRUB_MACADDR (bool: y/n)
#   Configures whether HW MAC addresses should be removed from output
    : ${XSOS_SCRUB_MACADDR:="n"}

# XSOS_SCRUB_SERIAL (bool: y/n)
#   Configures whether serial numbers should be removed from output
    : ${XSOS_SCRUB_SERIAL:="n"}

# XSOS_SCRUB_PROXYUSERPASS (bool: y/n)
#   Configures whether RHN/RHSM proxy user/pass should be removed from output
    : ${XSOS_SCRUB_PROXYUSERPASS:="n"}

# XSOS_ETHTOOL_ERR_REGEX (str: regular expression)
#   Configures what ETHTOOL() uses to generate the data under the "Interface Errors" heading
    : ${XSOS_ETHTOOL_ERR_REGEX:="Missing ethtool_-S file|(drop|disc|err|fifo|buf|fail|miss|OOB|fcs|full|frags|hdr|tso|pause).*: [^0]"}

# XSOS_LSPCI_NET_REGEX (str: regular expression)
#   Configures what LSPCI() uses to search for peripherals under the "Net" heading
    : ${XSOS_LSPCI_NET_REGEX:="(Ethernet controller|Network controller|InfiniBand):"}

# XSOS_LSPCI_STORAGE_REGEX (str: regular expression)
#   Configures what LSPCI() uses to search for peripherals under the "Storage" heading
    : ${XSOS_LSPCI_STORAGE_REGEX:="(Fibre Channel|RAID bus controller|Mass storage controller|SCSI storage controller|SATA controller|Serial Attached SCSI controller):"}

# ==============================================================================


VERSINFO() {
  echo "Version info: ${version:2}
See <github.com/ryran/xsos> to report bugs or suggestions"
  exit
}

HELP_USAGE() {
  echo "Usage: xsos [DISPLAY OPTIONS] [-6abokcfmdtlerngisp] [SOSREPORT ROOT]
  or:  xsos [DISPLAY OPTIONS] {--B|--C|--F|--M|--D|--T|--L|--R|--N|--G|--I|--P FILE}...
  or:  xsos [-?|-h|--help]
Display system info from localhost or extracted sosreport"
}

HELP_OPTS_CONTENT() {
  echo "
Content options:"
  echo "
 -a, --all❚show everything
 -b, --bios❚show info from dmidecode
 -o, --os❚show hostname, distro, SELinux, kernel info, uptime, etc
 -k, --kdump❚inspect kdump configuration
 -c, --cpu❚show info from /proc/cpuinfo
 -f, --intrupt❚show info from /proc/interrupts
 -m, --mem❚show info from /proc/meminfo
 -d, --disks❚show info from /proc/partitions + dm-multipath synopsis
 -t, --mpath❚show info from dm-multipath
 -l, --lspci❚show info from lspci
 -e, --ethtool❚show info from ethtool
 -r, --softirq❚show info from /proc/net/softnet_stat
 -n, --netdev❚show info from /proc/net/dev
 -g, --bonding❚show info from /proc/net/bonding
 -i, --ip❚show info from ip addr (BASH v4+ required)
     --net❚alias for: --lspci --ethtool --softirq --netdev --bonding --ip
 -s, --sysctl❚show important kernel sysctls
 -p, --ps❚inspect running processes via ps" | column -ts❚
}

HELP_OPTS_DISPLAY() {
  echo "
Display options:"
# --rhsupport❚tweak os output to focus on RHEL-centric support issues
  echo "
     --scrub❚remove from output: IP/MAC addrs, hostnames, serial numbers,
            ❚proxy user & passwords
 -6, --ipv6❚parse ip addr output for IPv6 addresses instead of IPv4
 -q, --wwid=ID❚restrict dm-multipath output to a particular mpath device,
              ❚where ID is a wwid, friendly name, or LUN identifier
 -u, --unit=P❚change byte display for /proc/meminfo & /proc/net/dev,
             ❚where P is \"b\" for byte, or else \"k\", \"m\", \"g\", or \"t\"
     --threads❚make ps take threads into account (via \`ps auxm\`)
 -v, --verbose=NUM❚specify ps verbosity level (0-4, default: 1)
 -w, --width=NUM❚change fold-width, in columns (positive number, e.g., 80)
                ❚\"0\" disables wrapping, \"w\" autodetects width (default)
 -x, --nocolor❚disable output colorization
 -y, --less❚send output to \`less -SR\`
 -z, --more❚send output to \`more\`" | column -ts❚
}

HELP_OPTS_SPECIAL() {
  echo "
Special options (BASH v4+ required):"
  echo "
 --B=FILE❚read from FILE containing \`dmidecode\` dump
 --C=FILE❚read from FILE containing /proc/cpuinfo dump
 --F=FILE❚read from FILE containing /proc/interrupts dump
 --M=FILE❚read from FILE containing /proc/meminfo dump
 --D=FILE❚read from FILE containing /proc/partitions dump
 --T=FILE❚read from FILE containing \`multipath -v4 -ll\` dump
 --L=FILE❚read from FILE containing \`lspci\` dump
 --R=FILE❚read from FILE containing /proc/net/softnet_stat dump
 --N=FILE❚read from FILE containing /proc/net/dev dump
 --G=FILE❚read from FILE containing /proc/net/bonding/xxx dump
 --I=FILE❚read from FILE containing \`ip addr\` dump
 --P=FILE❚read from FILE containing \`ps aux\` dump" | column -ts❚
}

HELP_SHORT() {
  HELP_USAGE
  HELP_OPTS_CONTENT
  HELP_OPTS_DISPLAY
  HELP_OPTS_SPECIAL
  echo -e "\nRun with \"--help\" to see full help page\n"
  VERSINFO
}

HELP_EXTENDED() {
  HELP_USAGE
  echo "Run with \"-h\" to see simplified help page"
  HELP_OPTS_CONTENT
  HELP_OPTS_DISPLAY
  echo "
If no content options are specified, xsos parses the environment variable
XSOS_DEFAULT_VIEW to figure out what information to display. If this variable
is unset at runtime, it is initialized internally as follows:
   XSOS_DEFAULT_VIEW='os'
Tweak it to preference by adding additional space-separated MODULE statements,
where MODULE is the same as the long option (e.g. mem, ethtool, netdev). Note
that the --net alias option cannot be used for this purpose. Also note that the
-a / --all option has it's own environment variable: XSOS_ALL_VIEW
If SOSREPORT ROOT isn't provided, the data will be gathered from the localhost;
however, bios, multipath, and ethtool output will only be displayed if running
as root (UID 0). When executing in this manner as non-root, those modules will
be skipped, and a warning printed to stderr.
Sometimes a full sosreport isn't available; sometimes you simply have a
dmidecode-dump or the contents of /proc/meminfo and you'd like a summary..."
  HELP_OPTS_SPECIAL
  echo "
As is hopefully clear, each of these options requires a filename as an
argument. These options can be used together, but cannot be used in concert
with regular \"Content options\" -- Content opts are ignored if Special options
are detected. Also note: the \"=\" can be replaced with a space if desired.
Re BASH v4+:
 BASH associative arrays are used for various things. In short, if running
 xsos on earlier BASH versions (e.g. RHEL5), you get ...
  * No output colorization
  * No -i/--ip
  * No parsing of \"Special options\"
Environment variables:
 For details of all configurable env variables, view first page of xsos
 source. There are vars to change default colors as well as other settings.
 Each variable name is prefixed with \"XSOS_\" and the important ones follow.
  COLORS  FOLD_WIDTH  ALL_VIEW  DEFAULT_VIEW  HEADING_SEPARATOR  IP_VERSION
  MEM_UNIT  NET_UNIT  PS_UNIT  PS_LEVEL  PS_THREADS  OUTPUT_HANDLER
  SCRUB_IP_HN  SCRUB_MACADDR  ETHTOOL_ERR_REGEX
"
  VERSINFO
}

WARN_NO_UPDATE() {
  echo "Warning: v0.6.0 dropped the built-in update feature triggered by -U/--update"
  echo "Future v1.x versions might repurpose the -U option"
  echo "See https://github.com/ryran/xsos/issues/155 for more info"
  exit 64
}

# Help? Version?
case $1 in
  -V|--vers|--version)  echo "Version info: ${version:2}"; exit ;;
  -\?|-h)               HELP_SHORT ;;
  --help|help)          HELP_EXTENDED ;;
  -U|--update)          WARN_NO_UPDATE >&2 ;;
esac

# GNU getopt short and long options:
sopts='6q:u:v:w:xyzabokcfmdtlerngisp'
lopts='scrub,ipv6,rhsupport,wwid:,unit:,threads,verbose:,width:,nocolor,less,more,all,bios,os,kdump,cpu,intrupt,mem,disks,mpath,lspci,ethtool,softirq,netdev,bonding,ip,net,sysctl,ps,B:,C:,F:,M:,D:,T:,L:,R:,N:,G:,I:,P:'

# Check for bad switches
getopt -Q --name=xsos -o $sopts -l $lopts -- "$@" || { HELP_USAGE; exit 64; }

# Setup assoc array for single-file options
unset sfile
[[ $BASH_VERSINFO -ge 4 ]] && declare -A sfile

# Checker for cmdline options
_OPT_CHECK() {
  local option chosen_opt check_type valid_opts n s
  option=$1
  chosen_opt=$(tr '[:upper:]' '[:lower:]' <<<"$2")
  check_type=$3
  valid_opts=$4
  if [[ $check_type == regex ]]; then
    egrep -qs "$valid_opts" <<<"$chosen_opt" && return
    case $option in
      width)
        echo "xsos: option '$option' expects a positive number or 'w' (auto-detect width) or '0' (disable wrapping)"
        ;;
      *)
       echo "xsos: option '$option' expects other input, i.e., matching regex '$valid_opts'"=
    esac
  
  elif [[ $check_type == range ]]; then
    for n in $(seq $valid_opts); do
      [[ $n == $chosen_opt ]] && return
    done
    echo "xsos: option '$option' expects number from range: { ${valid_opts// /-} }"
    
  elif [[ $check_type == naturalnumber ]]; then
    egrep -qs '^[0-9]+$' <<<"$chosen_opt" && return
    echo "xsos: option '$option' expects any natural number, including zero"
    
  elif [[ $check_type == string ]]; then
    for s in $valid_opts; do
      [[ $s == $chosen_opt ]] && return
    done
    echo "xsos: option '$option' expects one of: { $valid_opts } "
  
  elif [[ $check_type == anystring ]]; then
    [[ -n $2 ]] && return
    echo "xsos: option '$option' expects a non-null string value"
  fi
  
  exit 64
}


# Parse command-line arguments
PARSE() {
  unset opts all bios os kdump cpu intrupt mem disks mpath lspci ethtool softirq netdev bonding ip net sysctl ps
  until [[ $1 == -- ]]; do
    case $1 in
      --scrub)      XSOS_SCRUB_IP_HN=y XSOS_SCRUB_MACADDR=y XSOS_SCRUB_SERIAL=y XSOS_SCRUB_PROXYUSERPASS=y ;;
      -6|--ipv6)    XSOS_IP_VERSION=6 ;;
      -q|--wwid)    _OPT_CHECK "wwid" "$2" anystring
                      XSOS_MULTIPATH_QUERY=$2; shift
                    ;;
      -u|--unit)    _OPT_CHECK "unit" "$2" string "b k m g t"
                      XSOS_MEM_UNIT=$2; XSOS_NET_UNIT=$2; shift
                    ;;
      --threads)    XSOS_PS_THREADS=y ;;
      -v|--verbose) _OPT_CHECK "verbose" "$2" range "0 4"
                      XSOS_PS_LEVEL=$2; shift
                    ;;
      -w|--width)   _OPT_CHECK "width" "$2" regex '^[0-9]*$|^w$'
                      XSOS_FOLD_WIDTH=$2; shift
                    ;;
      -x|--nocolor) XSOS_COLORS=n     ;;
      -y|--less)    XSOS_OUTPUT_HANDLER='less -SR' ;;
      -z|--more)    XSOS_OUTPUT_HANDLER='more'     ;;
      --rhsupport)  XSOS_OS_RHT_CENTRIC=y          ;;
      -a|--all)     opts=y all=y     ;;
      -b|--bios)    opts=y bios=y    ;;
      -o|--os)      opts=y os=y      ;;
      -k|--kdump)   opts=y kdump=y   ;;
      -c|--cpu)     opts=y cpu=y     ;;
      -f|--intrupt) opts=y intrupt=y ;;
      -m|--mem)     opts=y mem=y     ;;
      -d|--disks)   opts=y disks=y   ;;
      -t|--mpath)   opts=y mpath=y   ;;
      -l|--lspci)   opts=y lspci=y   ;;
      -e|--ethtool) opts=y ethtool=y ;;
      -r|--softirq) opts=y softirq=y ;;
      -n|--netdev)  opts=y netdev=y  ;;
      -g|--bonding) opts=y bonding=y ;;
      -i|--ip)      opts=y ip=y      ;;
      -s|--sysctl)  opts=y sysctl=y  ;;
      -p|--ps)      opts=y ps=y      ;;
      --net)        opts=y lspci=y ethtool=y softirq=y netdev=y ip=y bonding=y ;;
      
      --B)  sfile[B]=$2; shift ;;
      --F)  sfile[F]=$2; shift ;;
      --C)  sfile[C]=$2; shift ;;
      --M)  sfile[M]=$2; shift ;;
      --D)  sfile[D]=$2; shift ;;
      --T)  sfile[T]=$2; shift ;;
      --L)  sfile[L]=$2; shift ;;
      --R)  sfile[R]=$2; shift ;;
      --N)  sfile[N]=$2; shift ;;
      --G)  sfile[G]=$2; shift ;;
      --I)  sfile[I]=$2; shift ;;
      --P)  sfile[P]=$2; shift ;;
    esac
    shift
  done
  shift #(to get rid of the '--')
  # Set sosroot
  sosroot=$@
}

# Call the parser
PARSE $(getopt -u --name=xsos -o $sopts -l $lopts -- "$@")

# If any special option was used appropriately with a file, do that instead of other opts
if [[ $BASH_VERSINFO -ge 4 && -n ${sfile[*]} ]]; then
  :
# If BASH is not v4+ and special options were used, fail
elif [[ $BASH_VERSINFO -lt 4 && -n $sfile ]]; then
  echo "Special options require use of BASH associative arrays" >&2
  echo "i.e., BASH v4.0 or higher (RHEL6/Fedora11 and above)" >&2
  exit 32
# Use default view if no content options specified
elif [[ -z $opts ]]; then
  for module in $XSOS_DEFAULT_VIEW; do eval $module=y; done
# Else, if "all" option specified, set full view
elif [[ -n $all ]]; then
  for module in $XSOS_ALL_VIEW; do eval $module=y; done
fi

# If color should be enabled, taste the rainbow
if [[ $XSOS_COLORS == y && $BASH_VERSINFO -ge 4 ]]; then
  c[0]=${c[$XSOS_COLOR_RESET]}
  c[H1]=${c[$XSOS_COLOR_H1]}
  c[H2]=${c[$XSOS_COLOR_H2]}
  c[H3]=${c[$XSOS_COLOR_H3]}
  c[H4]=${c[$XSOS_COLOR_H4]}
  c[Imp]=${c[$XSOS_COLOR_IMPORTANT]}
  c[Warn1]=${c[$XSOS_COLOR_WARN1]}
  c[Warn2]=${c[$XSOS_COLOR_WARN2]}
  c[Up]=${c[$XSOS_COLOR_IFUP]}
  c[Down]=${c[$XSOS_COLOR_IFDOWN]}
  c[MemUsed]=${c[$XSOS_COLOR_MEMGRAPH_MEMUSED]}
  c[HugePages]=${c[$XSOS_COLOR_MEMGRAPH_HUGEPAGES]}
  c[Buffers]=${c[$XSOS_COLOR_MEMGRAPH_BUFFERS]}
  c[Cached]=${c[$XSOS_COLOR_MEMGRAPH_CACHED]}
  c[Dirty]=${c[$XSOS_COLOR_MEMGRAPH_DIRTY]}
else
  unset c
fi

# Properly setup fold setting
if [[ $XSOS_FOLD_WIDTH == w ]]; then
  if tty &>/dev/null; then
    XSOS_FOLD_WIDTH=$(( $(tput cols) - 8 ))
  else
    XSOS_FOLD_WIDTH=80
  fi
elif [[ $XSOS_FOLD_WIDTH == 0 ]]; then
  XSOS_FOLD_WIDTH=99999
fi



# ON TO THE CONTENT MODULE FUNCTIONS!
# -----------------------------------
# ===================================

DMIDECODE() {
  # Local vars:
  local dmidecode_input
  
  if [[ -z $1 ]]; then
    dmidecode_input=$(dmidecode 2>/dev/null)
  elif [[ -f $1 ]]; then
    dmidecode_input=$(<"$1")
  elif [[ -r $1/dmidecode ]]; then
    dmidecode_input=$(<"$1/dmidecode")
  elif [[ -r $1/sos_commands/kernel.dmidecode ]]; then
    dmidecode_input=$(<"$1/sos_commands/kernel.dmidecode")
  fi
  
  # If bad dmidecode input, return
  if head -n3 <<<"$dmidecode_input" | egrep -qs 'No such file or directory|No SMBIOS nor DMI entry point found'; then
    echo -e "${c[Warn2]}Warning:${c[Warn1]} dmidecode input invalid; skipping bios check${c[0]}" >&2
    echo -en $XSOS_HEADING_SEPARATOR >&2
    return 1
  fi
  
  if [[ $XSOS_SCRUB_SERIAL == y ]]; then
      dmidecode_input=$(
        gawk -F: '
          BEGIN { OFS = ":" }
          /^\s+(UUID|Serial Number):/ {
            gsub(/[^- ]/, "⣿", $2)
          }
          {print}
        ' <<<"$dmidecode_input")
  fi
  
  echo -e "${c[H1]}DMIDECODE${c[0]}"
  
  # Prints "<BIOS Vendor>, <BIOS Version>, <BIOS Release Date>"
  echo -e "${c[H2]}  BIOS:${c[0]}"
  gawk 'BEGIN { RS="\nHandle" } /BIOS Information/' <<<"$dmidecode_input" |
    gawk -F: -vH3="${c[H3]}" -vH2="${c[H2]}" -vH0="${c[0]}" -vH_IMP="${c[Imp]}" '
      /Vendor:/            { Vendor  = $2; gsub(/  */, " ", Vendor) }
      /Version:/           { Version = $2; gsub(/  */, " ", Version) }
      /Release Date:/      { RelDate = $2; gsub(/  */, " ", RelDate) }
      /BIOS Revision:/     { BiosRev = $2; gsub(/  */, " ", BiosRev) }
      /Firmware Revision:/ { FirmRev = $2; gsub(/  */, " ", FirmRev) }
      END {
        printf "    %sVend:%s%s\n", H3, H0, Vendor
        printf "    %sVers:%s%s\n", H3, H0, Version
        printf "    %sDate:%s%s\n", H3, H0, RelDate
        printf "    %sBIOS Rev:%s%s\n", H3, H0, BiosRev
        printf "    %sFW Rev:%s  %s\n", H3, H0, FirmRev
      }
    '
  # Prints <SYSTEM Manufacturer>, <SYSTEM Product Name>, <SYSTEM Version>, <SYSTEM Serial Number>, <SYSTEM UUID>
  echo -e "${c[H2]}  System:${c[0]}"
  gawk 'BEGIN { RS="\nHandle" } /System Information/' <<<"$dmidecode_input" |
    gawk -F: -vH3="${c[H3]}" -vH2="${c[H2]}" -vH0="${c[0]}" -vH_IMP="${c[Imp]}" '
      /Manufacturer:/ { Mfr     = $2; gsub(/  */, " ", Mfr) }
      /Product Name:/ { Product = $2; gsub(/  */, " ", Product) }
      /Version:/      { Version = $2; gsub(/  */, " ", Version) }
      /Serial Number:/{ Serial  = $2 }
      /UUID:/         { UUID    = $2 }
      END {
        printf "    %sMfr:%s %s\n", H3, H0, Mfr
        printf "    %sProd:%s%s\n", H3, H0, Product
        printf "    %sVers:%s%s\n", H3, H0, Version
        printf "    %sSer:%s %s\n", H3, H0, Serial
        printf "    %sUUID:%s%s\n", H3, H0, UUID
      }
    '
  # Prints <CPU Manufacturer>, <CPU Family>, <CPU Current Speed>, <CPU Version>
  # Prints "<N> of <N> CPU sockets populated, <N> cores/<N> threads per CPU"
  # Prints "<N> total cores, <N> total threads"
  echo -e "${c[H2]}  CPU:${c[0]}"
  gawk 'BEGIN { RS="\nHandle" } /Processor Information/' <<<"$dmidecode_input" |
    gawk -F: -vH3="${c[H3]}" -vH2="${c[H2]}" -vH0="${c[0]}" -vH_IMP="${c[Imp]}" '
      /Status:/       { SumSockets ++; if ($2 ~ /Populated/) PopulatedSockets ++ }
      /Core Count:/   { SumCores   += $2; CoresPerCpu = $2 }
      /Thread Count:/ { SumThreads += $2; ThreadsPerCpu = $2 }
      /Manufacturer:/ { if ($2 ~ /^ *$/)         next; Mfr      = $2; gsub(/  */, " ", Mfr) }
      /Family:/       { if ($2 ~ /^ *$|Other/)   next; Family   = $2; gsub(/  */, " ", Family) }
      /Current Speed:/{ if ($2 ~ /^ *$|Unknown/) next; CpuFreq  = $2; gsub(/  */, " ", CpuFreq) }
      /Version:/      { if ($2 ~ /^ *$/)         next; Version  = $2; gsub(/  */, " ", Version) }
      END {
        printf "    %s%d of %d CPU sockets populated, %d cores/%d threads per CPU\n",
          H_IMP, PopulatedSockets, SumSockets, CoresPerCpu, ThreadsPerCpu
        printf "    %d total cores, %d total threads\n", SumCores, SumThreads, H0
        printf "    %sMfr:%s %s\n", H3, H0, Mfr
        printf "    %sFam:%s %s\n", H3, H0, Family
        printf "    %sFreq:%s%s\n", H3, H0, CpuFreq
        printf "    %sVers:%s%s\n", H3, H0, Version
      }
    '
  # Prints "<N> MB (<N> GB) total"
  # Prints "<N> of <N> DIMMs populated (max capacity <N>)"
  echo -e "${c[H2]}  Memory:${c[0]}"
  gawk 'BEGIN { RS="\nHandle" } /Physical Memory Array|Memory Device/' <<<"$dmidecode_input" |
    gawk -vH3="${c[H3]}" -vH2="${c[H2]}" -vH0="${c[0]}" -vH_IMP="${c[Imp]}" '
      /Size:/ {
        NumDimmSlots ++
        if ($2 ~ /^[0-9]/) {
          NumDimms ++
          if ($3 ~ /^P/)
            SumRam += $2 * 1024 * 1024 * 1024
          else if ($3 ~ /^T/)
            SumRam += $2 * 1024 * 1024
          else if ($3 ~ /^G/)
            SumRam += $2 * 1024
          else if ($3 ~/^[kK]/)
            SumRam += $2 / 1024
          else if ($3 ~/^[bB]/)
            SumRam += $2 / 1024 / 1024
          else
            SumRam += $2
        }
      }
      /Maximum Capacity:/ {
        if ($3 ~ /^[0-9]/) {
          if ($4 ~ /^P/)
            SumMaxRam += $3 * 1024 * 1024 * 1024
          else if ($4 ~ /^T/)
            SumMaxRam += $3 * 1024 * 1024
          else if ($4 ~ /^G/)
            SumMaxRam += $3 * 1024
          else if ($4 ~/^[kK]/)
            SumMaxRam += $3 / 1024
          else if ($4 ~/^[bB]/)
            SumMaxRam += $3 / 1024 / 1024
          else
            SumMaxRam += $3
        }
      }
      END {
        printf "    %sTotal:%s %d MiB (%.0f GiB)\n", H3, H0, SumRam, SumRam/1024
        printf "    %sDIMMs:%s %d of %d populated\n", H3, H0, NumDimms, NumDimmSlots
        printf "    %sMaxCapacity:%s %d MiB (%.0f GiB / %.2f TiB)\n", H3, H0, SumMaxRam, SumMaxRam/1024, SumMaxRam/1024/1024
      }
    '
  echo -en $XSOS_HEADING_SEPARATOR
}


_CHECK_DISTRO() {
  # Local vars:
  local OS_INDENT files file
  
  OS_INDENT="            "
  # Parse redhat-release if we have it
  if [[ ! -r $1/etc/redhat-release ]]; then
    distro_release="${c[Imp]}[redhat-release]${c[0]} ${c[RED]}(missing)${c[0]}"
    
  else
    # If release is RHEL 4,5,6,7 in standard expected format ...
    if egrep -e 'Red Hat Enterprise Linux (AS|ES|Desktop|WS) release 4 \((Nahant|Nahant Update [1-9])\)' \
             -e 'Red Hat Enterprise Linux (Client|Server) release 5\.?[0-9]* \(Tikanga\)' \
             -e 'Red Hat Enterprise Linux (Client|Workstation|Server) release 6\.?[0-9]* \(Santiago\)' \
             -e 'Red Hat Enterprise Linux (Client|Workstation|Server) release 7\.[0-9] \(Maipo\)' \
             -qs "$1/etc/redhat-release"; then
    
      # ... And if redhat-release file has more than 1 line ...
      [[ $(wc -l <"$1/etc/redhat-release") -gt 1 ]] &&
      
        # ... Then print it in orange
        distro_release=${c[ORANGE]}$(sed "1!s/^/$OS_INDENT/" <"$1/etc/redhat-release") ||
        
          # Otherwise, if only 1 line, all is well -- print it normally
          distro_release=$(sed "1!s/^/$OS_INDENT/" <"$1/etc/redhat-release")
          
    # If release is not RHEL 4,5,6,7 in standard expected format, freak out
    else
      distro_release=$(sed "1!s/^/$OS_INDENT/" "$1/etc/redhat-release" 2>/dev/null)
      
      if grep -qi fedora <<<"$distro_release"; then
        distro_release=${c[bg_BLUE]}$distro_release
      
      elif egrep -qi 'alpha|beta' <<<"$distro_release"; then
        distro_release=${c[bg_RED]}${c[ORANGE]}$distro_release
        
      else
        distro_release=${c[bg_DGREY]}${c[RED]}$distro_release
      fi
    fi
    # Prepend the distro information with "[redhat-release] " and do a little color fun
    distro_release="${c[Imp]}[redhat-release]${c[0]} $distro_release${c[0]}"
  fi

  # Check for any /etc/*-release or /etc/*_version files and add their content to the distro_release variable
  files=$(ls "$1"/etc/*{-release,_version} 2>/dev/null | egrep -sv '/etc/(os|redhat|system|lsb)-release')
  if [[ -n $files ]]; then
    for file in $files; do
      if [[ -r $file ]]; then
        distro_release="$distro_release\n$OS_INDENT${c[Imp]}[${file##*/}]${c[0]} $(sed "1!s/^/$OS_INDENT/" <"$file")"
      elif [[ -L $file ]]; then
        distro_release="$distro_release\n$OS_INDENT${c[Imp]}[${file##*/}]${c[0]} ${c[RED]}(error: broken link)${c[0]}"
      else
        distro_release="$distro_release\n$OS_INDENT${c[Imp]}[${file##*/}]${c[0]} ${c[RED]}(error: file exists, but cannot read it)${c[0]}"
      fi
    done
  fi
  
  # I don't like blindly sourcing a file -- that provides a vector to screw with this script...
  # But in modern Linux boxen this file is standard
  # If able to source the new standard /etc/os-release, list it out
  if source "$1/etc/os-release" 2>/dev/null; then
    distro_release="$distro_release\n$OS_INDENT${c[Imp]}[os-release]${c[0]} $PRETTY_NAME $VERSION"
  fi
}


_CHECK_KERNELBUILD() {
  # Get kernel build version somehow or another, making sure not to use build offered by rescue mode kernel
  
  # if localhost: get it from the best place, yay
  if [[ $1 == / ]]; then
    kernel_build=$(</proc/version)
  
  # sosreport: sosreports don't normally contain this.. yet
  elif [[ -r "$1/proc/version" ]] && ! grep -qsw rescue "$1/proc/cmdline"; then
    kernel_build=$(<"$1/proc/version")
  
  # sosreport: if find it via `dmesg` output file, great
  elif ! grep -qsw rescue "$1/proc/cmdline" && kernel_build=$(cat "$1/sos_commands/general/dmesg" "$1/sos_commands/kernel/dmesg" 2>/dev/null | grep -as 'Linux version'); then
    :
    
  # sosreport: if find it in var/log/dmesg, woo hoo
  elif grep -qs 'Linux version' "$1/var/log/dmesg"; then
    kernel_build=$(grep -a 'Linux version' "$1/var/log/dmesg" | tail -n1)
  
  # sosreport: if find it in var/log/messages, lovely
  elif grep -qs 'kernel: Linux version' "$1/var/log/messages"; then
    kernel_build=$(grep 'kernel: Linux version' "$1/var/log/messages" | tail -n1)
  
  # sosreport: final option: search in all old messages files -- this might be a bad idea
  else
    # To explain this last one: The goal is to find the most recent instance of "Linux version"
    # So this reverse-sorts by filename, searches through all files ending with the most recent file
    # This is obviously not very efficient, but it's the only way I've thought of to do it so far
    kernel_build=$(find "$1/var/log" -name 'messages?*' 2>/dev/null | sort -r | xargs zgrep -sh 'kernel: Linux version' 2>/dev/null | tail -n1)
  fi
  
  # Fix format if necessary
  if [[ -n $kernel_build ]]; then
    kernel_build=$(sed -e 's,^\[.*\] Linux,Linux,' -e 's,^.*kernel: Linux,Linux,' <<<"$kernel_build")
    kernel_buildhost=$(gawk '{print $4}' <<<"$kernel_build")
  fi
}


_CHECK_SELINUX() {
  # Local vars:
  local input_sestatus have_dmesg input_seconfig selinux enforcing selinux_dmesg sestatus_status sestatus_mode sestatus_cfgmode sestatus_policy seconfig_cfgmode seconfig_policy
  
  __cond_print_cfgmode() {
    [[ -n $seconfig_cfgmode ]] &&
      printf "  (default $seconfig_cfgmode)" || printf "  (default unknown)"
  }
  
  # Grab input from sestatus command if localhost
  if [[ $1 == / ]]; then
    input_sestatus=$(sestatus 2>/dev/null)
    
  # Else, from $sosroot/sestatus or $sosroot/sos_commands/selinux/sestatus_-b & dmesg
  else
    input_sestatus=$(gawk '!/\/.*bin/ && NF!=0' "$1/sestatus" 2>/dev/null; gawk '!/\/.*bin/ && NF!=0' "$1/sos_commands/selinux/sestatus_-b" 2>/dev/null)
    cat "$1"/var/log/dmesg "$1"/sos_commands/general/dmesg* "$1"/sos_commands/kernel/dmesg 2>/dev/null | egrep -qis '^SELinux: *Disabled at (boot|runtime)' && selinux_dmesg=disabled
    # Could also check /var/log/messages, but it would be too expensive and complicated
    # to ensure any hits were for the current boot-cycle
  fi
  
  # Read in /etc/selinux/config from sosroot or localhost
  input_seconfig=$(cat "$1"/etc/selinux/config 2>/dev/null)
  
  # Set "selinux" and "enforcing" variables per kernel args
  eval $(egrep -ios 'selinux=.|enforcing=.' "$1"/proc/cmdline | tr '[:upper:]' '[:lower:]')
  
  # Check /etc/selinux/config input
  if [[ -n $input_seconfig ]]; then
    eval $(gawk -F= '
      /^SELINUX=/     { cfgmode = $2 }
      /^SELINUXTYPE=/ { policy  = $2 }
      END {
        printf "seconfig_cfgmode=%s; seconfig_policy=%s", cfgmode, policy
      }
    ' <<<"$input_seconfig")
  fi
  
  # Check sestatus input
  if [[ -n $input_sestatus ]]; then
    eval $(gawk '
      /SELinux status/                    { status  = $NF }
      /Current mode/                      { mode    = $NF }
      /Mode from config file/             { cfgmode = $NF }
      /Loaded policy|Policy from config/  { policy  = $NF }
      END {
        printf "sestatus_status=%s; sestatus_mode=%s; sestatus_cfgmode=%s; sestatus_policy=%s",
          status, mode, cfgmode, policy
      }
    ' <<<"$input_sestatus")
    
    # Since we have sestatus input, primarily rely on that
    if [[ $sestatus_status == disabled ]]; then
      # If sestatus says disabled, need to rely on config file for default mode
      printf "disabled"; __cond_print_cfgmode
    else
      # Otherwise, just use sestatus output
      printf "$sestatus_mode  (default $sestatus_cfgmode)"
    fi
  
  # If we don't have sestatus input, things are more complicated...
  else
  
    # If we have selinux/enforcing kernel args, use those for current status
    if [[ -n $selinux || -n $enforcing ]]; then
      case $selinux in
        0)  printf "disabled"   ;;
        1)  printf "enforcing"  ;;
      esac
      case $enforcing in
        0)  printf "permissive" ;;
        1)  printf "enforcing"  ;;
      esac
      __cond_print_cfgmode
      
    # If dmesg from sosreport says disabled, print it out
    elif [[ $selinux_dmesg == disabled ]]; then
      printf "dmesg says disabled"; __cond_print_cfgmode
      
    # If we only have stuff from /etc/selinux/config
    elif [[ -n $seconfig_cfgmode ]]; then
      printf "${c[Warn1]}status unknown${c[0]} (default $seconfig_cfgmode)"
    
    # Otherwise, we have no clue ... :(
    else
      printf "${c[Warn1]}status unknown (default unknown)${c[0]}"
    fi
  fi
}


_CHECK_GRUB() {
  # Local vars:
  local grubcfg default
  
  # Other vars that we want to be global, so no local here and no local in modules that call them:
  ## bad_grubcfg default_missing grub_kernel grub_cmdline
  
  # Find the grub config file
  if [[ -f $1/boot/grub/grub.conf ]]; then
    # Set grubcfg for grub1
    grubcfg=$1/boot/grub/grub.conf
  elif [[ -f $1/boot/efi/EFI/redhat/grub.conf ]]; then
    # Set grubcfg for rhel UEFI grub1
    grubcfg=$1/boot/efi/EFI/redhat/grub.conf
  elif [[ -f $1/boot/grub2/grub.cfg ]]; then
    # Set grubcfg for rhel grub2
    grubcfg=$1/boot/grub2/grub.cfg
  elif [[ -f $1/boot/efi/EFI/redhat/grub.cfg ]]; then
    # Set grubcfg for rhel UEFI grub2
    grubcfg=$1/boot/efi/EFI/redhat/grub.cfg
  elif [[ -f $1/boot/grub/grub.cfg ]]; then
    # Set grubcfg for debian grub2
    grubcfg=$1/boot/grub/grub.cfg
  else
    # Else, we have nothing
    bad_grubcfg="${c[Warn1]}unknown  (no grub config file)${c[0]}"
    return 1
  fi
  
  # Check for read permission
  if [[ ! -r $grubcfg ]]; then
    # Set a message for later and stop here
    bad_grubcfg="${c[Warn1]}unknown (no read permission on ${grubcfg##*/})${c[0]}"
    return 1
  fi
  
  case "${grubcfg##*/}" in
    grub.conf)
      # If we have grub.conf, use that
      default=$(gawk -F= '/^default=/{print$2}' "$grubcfg" 2>/dev/null)
      [[ -z $default ]] && {
        default=0; default_missing="${c[Warn1]}(Warning: grub.conf lacks \"default=\"; showing title 0)${c[0]}"
      }
      # Get the full kernel line for the default title statement
      grub_cmdline=$(gawk /^title/,G "$grubcfg" | egrep -v '^#|^ *#' | sed '1!s/^title.*/\n&/' | gawk -vDEFAULT=$((default+1)) -vRS="\n\n" 'NR==DEFAULT' | grep -o '/vmlinuz-.*')
      ;;
    grub.cfg)
      # Otherwise, if we have a grub2 config (grub.cfg), use that
      default=$(gawk -F\" '/^set default=/{print$2}' "$grubcfg")
      grub_cmdline=$(gawk '/^menuentry.*{/,/^}/' "$grubcfg" | gawk -vRS="\n}\n" -vDEFAULT="$((default+1))" 'NR==DEFAULT' | grep -o '/vmlinuz-.*')
  esac
  
  grub_kernel=$(gawk {print\$1} <<<"${grub_cmdline#/vmlinuz-}" 2>/dev/null)
  grub_cmdline=$(cut -d' ' -f2- <<<"$grub_cmdline")
}


OSINFO() {
  # Local vars:
  local distro_release kernel_build kernel_buildhost num_cpu btime hostname hntmp kernel total_plugins yum_plugins num_enabled f rhn_serverURL sURLtmp a rhn_enableProxy rhn_httpProxy rhn_enableProxyAuth rhn_proxyUser rhn_proxyPassword rhnProxyStuff rhsm_hostname rhsm_proxy_hostname rhsm_proxy_port rhsm_proxy_user rhsm_proxy_password rhsmProxyStuff uname systime boottime uptime_input runlevel initdefault timezone
  
  # These functions populate variables for later use
  _CHECK_DISTRO "$1"
  _CHECK_KERNELBUILD "$1"
  _CHECK_GRUB "$1"
  
  # Grab number of cpus from proc/stat
  num_cpu=$(gawk '/^cpu[[:graph:]]+/{n++} END{print n}' "$1/proc/stat" 2>/dev/null)
  
  # Grab btime (in seconds since U.Epoch) from proc/stat
  btime=$(gawk '/^btime/{print $2}' "$1/proc/stat" 2>/dev/null)
  
  # Grab system hostname & kernel version from /proc first
  hostname=$(cat "$1/proc/sys/kernel/hostname" 2>/dev/null)
  kernel=$(cat "$1/proc/sys/kernel/osrelease" 2>/dev/null)
  
  # Grab yum plugin stuff
  if total_plugins=$(ls "$1"/etc/yum/pluginconf.d/*.conf 2>/dev/null); then
    total_plugins=$(wc -l <<<"$total_plugins")
    yum_plugins=$(
      cd "$1"/etc/yum/pluginconf.d/
      gawk -F= '
        /^enabled *= */ {
          sub(" ", "")
          if ($2==1) printf FILENAME" "
        }
      ' *.conf
    )
    if [[ -n $yum_plugins ]]; then
      num_enabled=$(wc -w <<<"$yum_plugins")
      yum_plugins=$(sed 's/\.conf /, /g' <<<"$yum_plugins")
      yum_plugins=${yum_plugins%, }
      yum_plugins="$num_enabled enabled plugins: $yum_plugins"
    else
      yum_plugins="0 enabled plugins"
    fi
  else
    yum_plugins="${c[Warn1]}No yum plugin info (missing etc/yum/pluginconf.d/*.conf)${c[0]}"
  fi
  
  # Grab RHN settings
  _get_rhn_cfg() {
    local directive=$1 file="$2/etc/sysconfig/rhn/up2date" result=
    result=$(gawk -F= "/^$directive *=/{print\$2}" "$file" 2>/dev/null)
    result=${result/ /}
    if [[ -n $result ]]; then
      echo "$directive = $result"
    else
      return 1
    fi
  }
  a="\n            "
  if rhn_serverURL=$(_get_rhn_cfg serverURL "$1"); then
    sURLtmp=$(egrep --color=always -si 'oracle' <<<"$serverURL") && rhn_serverURL=$sURLtmp
    [[ $XSOS_SCRUB_IP_HN == y ]] && rhn_serverURL="serverURL = ${c[Warn2]}SCRUBBED${c[0]}"
    if rhn_enableProxy=$(_get_rhn_cfg enableProxy "$1") && [[ $rhn_enableProxy -eq 1 ]]; then
      rhnProxyStuff="${a}$rhn_enableProxy"
      if rhn_httpProxy=$(_get_rhn_cfg httpProxy "$1"); then
        [[ $XSOS_SCRUB_IP_HN == y ]] && rhnProxyStuff+="${a}httpProxy = ${c[Warn2]}SCRUBBED${c[0]}" || rhnProxyStuff+="${a}$rhn_httpProxy"
        if rhn_enableProxyAuth=$(_get_rhn_cfg enableProxyAuth "$1") && [[ $rhn_enableProxyAuth -eq 1 ]]; then
          rhnProxyStuff+="${a}$rhn_enableProxyAuth"
          if rhn_proxyUser=$(_get_rhn_cfg proxyUser "$1"); then
            [[ $XSOS_SCRUB_PROXYUSERPASS == y ]] && rhnProxyStuff+="${a}proxyUser = ${c[Warn2]}SCRUBBED${c[0]}" || rhnProxyStuff+="${a}$rhn_proxyUser"
          fi
          if rhn_proxyPassword=$(_get_rhn_cfg proxyPassword "$1"); then
            [[ $XSOS_SCRUB_PROXYUSERPASS == y ]] && rhnProxyStuff+="${a}proxyPassword = ${c[Warn2]}SCRUBBED${c[0]}" || rhnProxyStuff+="${a}$rhn_proxyPassword"
          fi
        else
          rhnProxyStuff+="${a}$rhn_enableProxyAuth"
        fi
      else
        rhnProxyStuff+="${a}httpProxy ="
      fi
    else
      rhnProxyStuff="${a}$rhn_enableProxy"
    fi
  else
    rhn_serverURL="${c[red]}(missing)${c[0]}"
  fi
  
  # Grab RHSM settings
  _get_rhsm_cfg() {
    local directive=$1 file="$2/etc/rhsm/rhsm.conf" result=
    result=$(gawk -F= "/^$directive *=/{print\$2}" "$file" 2>/dev/null)
    result=${result/ /}
    if [[ -n $result ]]; then
      echo "$directive = $result"
    else
      return 1
    fi
  }
  a="\n            "
  if rhsm_hostname=$(_get_rhsm_cfg hostname "$1"); then
    [[ $XSOS_SCRUB_IP_HN == y ]] && rhsm_hostname="hostname = ${c[Warn2]}SCRUBBED${c[0]}"
    if rhsm_proxy_hostname=$(_get_rhsm_cfg proxy_hostname "$1"); then
      [[ $XSOS_SCRUB_IP_HN == y ]] && rhsmProxyStuff+="${a}proxy_hostname = ${c[Warn2]}SCRUBBED${c[0]}" || rhsmProxyStuff="${a}$rhsm_proxy_hostname"
      if rhsm_proxy_port=$(_get_rhsm_cfg proxy_port "$1"); then
        [[ $XSOS_SCRUB_IP_HN == y ]] && rhsmProxyStuff+="${a}proxy_port = ${c[Warn2]}SCRUBBED${c[0]}" || rhsmProxyStuff+="${a}$rhsm_proxy_port"
      fi
      if rhsm_proxy_user=$(_get_rhsm_cfg proxy_user "$1"); then
        [[ $XSOS_SCRUB_PROXYUSERPASS == y ]] && rhsmProxyStuff+="${a}proxy_user = ${c[Warn2]}SCRUBBED${c[0]}" || rhsmProxyStuff+="${a}$rhsm_proxy_user"
      fi
      if rhsm_proxy_password=$(_get_rhsm_cfg proxy_password "$1"); then
        [[ $XSOS_SCRUB_PROXYUSERPASS == y ]] && rhsmProxyStuff+="${a}proxy_password = ${c[Warn2]}SCRUBBED${c[0]}" || rhsmProxyStuff+="${a}$rhsm_proxy_password"
      fi
    else
      rhsmProxyStuff="${a}proxy_hostname ="
    fi
  else
    rhsm_hostname="${c[red]}(missing)${c[0]}"
  fi
  
  # If running on localhost
  if [[ $1 == / ]]; then
    uname=$(uname -a | gawk '{printf "mach=%s  cpu=%s  platform=%s\n", $(NF-3), $(NF-2), $(NF-1)}')
    systime=$(date)
    [[ $(wc -w <<<"$systime") == 6 ]] &&
      systime=$(gawk -vH0="${c[0]}" -vH_IMP="${c[Imp]}" '{if ($3 < 10) space=" "; printf "%s %s %s%s %s %s%s%s %s\n", $1,$2,space,$3,$4,H_IMP,$5,H0,$6}' <<<"$systime")
    boottime=$(date --date=@$btime 2>/dev/null)
    [[ $(wc -w <<<"$boottime") == 6 ]] &&
      boottime=$(gawk -vH0="${c[0]}" -vH_IMP="${c[Imp]}" -vbtime=$btime '{if ($3 < 10) space=" "; printf "%s %s %s%s %s %s%s%s %s  (epoch: %s)\n", $1,$2,space,$3,$4,H_IMP,$5,H0,$6,btime}' <<<"$boottime")
    uptime_input=$(uptime)
    runlevel=$(runlevel)
    initdefault=$(basename $(readlink -q /etc/systemd/system/default.target) 2>/dev/null) &&
      initdefault=${initdefault%.target} ||
        initdefault=$(gawk -F: '/^id.*initdefault/ {print $2}' </etc/inittab)
    
  # Otherwise, running on sosreport
  else
    # If sosreport ran in rescue mode, try to get good hostname
    if grep -qsw rescue "$1/proc/cmdline"; then
      hostname=$(gawk -F= /^HOSTNAME=/{print\$2}  "$1/etc/sysconfig/network" 2>/dev/null) ||
        hostname="${c[Warn1]}unknown${c[0]}  (sosreport collected from rescue mode)"
    # Otherwise, if no hostname from proc/, try to get from sosroot/hostname or sosroot/uname
    else
      [[ -z $hostname ]] && {
        hostname=$(gawk '!/\/.*bin/ && NF!=0' "$1/hostname" 2>/dev/null) ||
          hostname=$(gawk '!/\/.*bin/ && NF!=0 {print $2}' "$1/uname" 2>/dev/null) ||
            hostname="${c[Warn1]}unknown${c[0]}"
      }
    fi
    # If sosreport ran in rescue mode, leave it to the kernel-build funness
    if grep -qsw rescue "$1/proc/cmdline"; then
      kernel="$kernel  ${c[Warn1]}(Rescue mode kernel version)${c[0]}"
    # Otherwise, if no kernel version from proc/, try to get from sosroot/uname
    else
      [[ -z $kernel ]] && {
        kernel=$(gawk '!/\/.*bin/ && NF!=0 {print $3}' "$1/uname" 2>/dev/null) ||
          kernel="${c[Warn1]}unknown${c[0]}"
      }
    fi
    uname=$(gawk '!/\/.*bin/ && NF!=0 {printf "mach=%s  cpu=%s  platform=%s\n", $(NF-3), $(NF-2), $(NF-1)}' "$1/uname" 2>/dev/null) ||
      uname="${c[Warn1]}unknown${c[0]}"
    # Check kernel for uek
    grep -qsi uek <<<"$kernel" && kernel=$(grep --color=always -i uek <<<"$kernel")
    grep -qsi uek <<<"$grub_kernel" && grub_kernel=$(grep --color=always -i uek <<<"$grub_kernel")
    
    systime=$(gawk '!/\/.*bin/ && NF!=0' "$1/date" 2>/dev/null)
    [[ $(wc -w <<<"$systime") == 6 ]] &&
      systime=$(gawk -vH0="${c[0]}" -vH_IMP="${c[Imp]}" '{if ($3 < 10) space=" "; printf "%s %s %s%s %s %s%s%s %s\n", $1,$2,space,$3,$4,H_IMP,$5,H0,$6}' <<<"$systime")
    
    timezone=$(gawk -F= '/^ZONE=/{print $2}' "$1/etc/sysconfig/clock" 2>/dev/null | tr -d \")
    [[ -n $timezone && -f /usr/share/zoneinfo/$timezone ]] &&
      boottime=$(echo -n $(TZ=$timezone date --date=@$btime 2>/dev/null)) ||
        boottime=$(echo -n $(TZ= date --date=@$btime 2>/dev/null))
    
    [[ $(wc -w <<<"$boottime") == 6 ]] &&
      boottime=$(gawk -vH0="${c[0]}" -vH_IMP="${c[Imp]}" -vbtime=$btime '{if ($3 < 10) space=" "; printf "%s %s %s%s %s %s%s%s %s  (epoch: %s)\n", $1,$2,space,$3,$4,H_IMP,$5,H0,$6,btime}' <<<"$boottime")
    
    uptime_input=$(gawk '!/\/.*bin/ && NF!=0' "$1/uptime")
    [[ -r $1/sos_commands/startup/runlevel ]] && runlevel=$(<"$1/sos_commands/startup/runlevel")
    [[ -r $1/etc/inittab ]] &&
      initdefault=$(gawk -F: '/^id.*initdefault/ {print $2}' <"$1/etc/inittab") ||
        initdefault=unknown
  fi
  
  [[ $XSOS_SCRUB_IP_HN == y ]] && hostname="${c[Warn2]}SCRUBBED${c[0]}"
  
  # Start printing stuff
  echo -e "${c[H1]}OS${c[0]}"
  echo -e "  ${c[H2]}Hostname:${c[0]} $hostname"
  echo -e "  ${c[H2]}Distro:${c[0]}   $distro_release"
  echo -e "  ${c[H2]}RHN:${c[0]}      $rhn_serverURL$rhnProxyStuff"
  echo -e "  ${c[H2]}RHSM:${c[0]}     $rhsm_hostname$rhsmProxyStuff"
  echo -e "  ${c[H2]}YUM:${c[0]}      $yum_plugins"
  [[ -n $runlevel ]] &&
  echo -e "  ${c[H2]}Runlevel:${c[0]} $runlevel  (default $initdefault)"
  echo -e "  ${c[H2]}SELinux:${c[0]}  $(_CHECK_SELINUX "$1")"
  echo -e "  ${c[H2]}Arch:${c[0]}     $uname"
  echo -e "  ${c[H2]}Kernel:${c[0]}"
  echo -e "    ${c[H3]}Booted kernel:${c[0]}  $kernel"
  echo -e "    ${c[H3]}GRUB default:${c[0]}   $bad_grubcfg$grub_kernel  $default_missing"
  
  # Print and format kernel version
  echo -e "    ${c[H3]}Build version:${c[0]}"
  # If kernel build was detected ...
  if [[ -n $kernel_build ]]; then
    # Print a notice if rescue mode
    grep -qsw rescue "$1/proc/cmdline" &&
      echo -e "${c[Warn1]}     (Rescue mode detected; build info captured from logs of last boot)${c[0]}"
    # Format it to fit properly
    kernel_build=$(fold -sw$XSOS_FOLD_WIDTH <<<"$kernel_build" | sed 's,^,      ,')
    # Change color to warning color (orange) if can't find "build.redhat.com"
    grep -qe '\.z900\.redhat\.com' -e '\.build\.redhat\.com' -e '\.bos\.redhat\.com' -e '\.perf\.redhat\.com' <<<"$kernel_buildhost" ||
      kernel_build="${c[Warn1]}$kernel_build${c[0]}"
    echo -e "$kernel_build"
  else
    echo -e "$XSOS_INDENT_H3${c[Warn1]}unknown${c[0]}"
  fi
  
  # Print kernel cmdline from proc/cmdline
  echo -e "    ${c[H3]}Booted kernel cmdline:${c[0]}"
  # If rescue mode detected, print a warning
  grep -qsw rescue "$1/proc/cmdline" &&
    echo -e "     ${c[Warn1]}(Rescue mode detected)${c[0]}"
  if [[ -r $1/proc/cmdline ]]; then
    proc_cmdline=$(sed -r 's,^BOOT_IMAGE=/[[:graph:]]+ ,,' "$1"/proc/cmdline)
    [[ $XSOS_SCRUB_IP_HN == y ]] && proc_cmdline=$(sed "s/${hostname%%.*}/HOSTNAME/g" <<<"$proc_cmdline")
    fold -sw$XSOS_FOLD_WIDTH <<<"$proc_cmdline" 2>/dev/null | sed -e "s,^,$XSOS_INDENT_H3,"
  else
    echo -e "$XSOS_INDENT_H3${c[Warn1]}unknown${c[0]}"
  fi

  echo -e "    ${c[H3]}GRUB default kernel cmdline:${c[0]}  $default_missing"
  if [[ -n $bad_grubcfg ]]; then
    echo -e "      $bad_grubcfg"
  else
    if grep -qs 'unknown.*rescue mode' <<<"$grub_cmdline"; then
      echo -e "$XSOS_INDENT_H3$grub_cmdline"
    else
      [[ $XSOS_SCRUB_IP_HN == y ]] && grub_cmdline=${grub_cmdline//${hostname%%.*}/HOSTNAME}
      fold -sw$XSOS_FOLD_WIDTH <<<"$grub_cmdline" 2>/dev/null | sed -e "s,^,$XSOS_INDENT_H3,"
    fi
  fi
    
  # Print kernel tainted-status
  echo -e "    ${c[H3]}Taint-check:${c[0]} $(CHECK_TAINTED --noquote "$1" H3)"
  # End the kernel section
  echo -e "    ${c[DGREY]}- - - - - - - - - - - - - - - - - - -${c[0]}"
  
  ##echo -e "  ${c[H2]}Supportability:${c[0]}"
  
  [[ -n $systime ]] &&
  echo -e "  ${c[H2]}Sys time:${c[0]}  $systime"
  
  # Assuming have uptime input and detected num of cpus, print uptime, loadavg, etc
  [[ -n $uptime_input && -n $num_cpu ]] &&
  gawk -vSYSTIME="$systime" -vBTIME="$boottime" -vNUM_CPU="$num_cpu" -vREDBOLD="${c[RED]}" -vRED="${c[red]}" -vORANGE="${c[orange]}" -vGREEN="${c[green]}" -vH2="${c[H2]}" -vH0="${c[0]}" -vH_IMP="${c[Imp]}" '
      !/load average/ { next }
      {
      Time = $1
      
      Uptime = gensub(/^ *[[:graph:]]+ up +(.+users?),.+/, "\\1", 1)
      
      Load[15] = $(NF)
      Load[5]  = $(NF-1)
      Load[1]  = $(NF-2)
      for (i in Load) {
        sub(/,/, "", Load[i])
        LP[i] = Load[i] * 100 / NUM_CPU
      }
      for (i in LP) {
        if (LP[i] < 70) Color[i] = GREEN
        if (LP[i] > 69) Color[i] = ORANGE
        if (LP[i] > 89) Color[i] = RED
        if (LP[i] > 99) Color[i] = REDBOLD
      }
      
      if (SYSTIME == "")
        printf "  %sSys time:%s  %s\n", H2, H0, Time
      printf   "  %sBoot time:%s %s\n", H2, H0, BTIME
      printf   "  %sUptime:%s    %s\n", H2, H0, Uptime
      printf   "  %sLoadAvg:%s   %s[%d CPU]%s %s (%s%.0f%%%s), %s (%s%.0f%%%s), %s (%s%.0f%%%s)\n",
        H2, H0, H_IMP, NUM_CPU, H0, Load[1], Color[1], LP[1], H0, Load[5], Color[5], LP[5], H0, Load[15], Color[15], LP[15], H0
    }' <<<"$uptime_input"
    
  # Print info from proc/stat
  [[ -n $btime ]] &&
  gawk -vH3="${c[H3]}" -vH2="${c[H2]}" -vH0="${c[0]}" -vH_IMP="${c[Imp]}" '
    /^cpu / {
      TotalTime = $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9 + $10 + $11
      user    = $2 * 100 / TotalTime
      nice    = $3 * 100 / TotalTime
      sys     = $4 * 100 / TotalTime
      idle    = $5 * 100 / TotalTime
      iowait  = $6 * 100 / TotalTime
      irq     = $7 * 100 / TotalTime
      softirq = $8 * 100 / TotalTime
      steal   = $9 * 100 / TotalTime
     #guest      = $10
     #guest_nice = $11
    }
    /^cpu[[:graph:]]+/ { num_cpu++ }
    /procs_running/    { procs_running = $2 }
    /procs_blocked/    { procs_blocked = $2 }
    /processes/        { processes = $2 }
    
    END {
      printf "  %s/proc/stat:%s\n",
        H2, H0
      printf "    %sprocs_running:%s %d   %sprocs_blocked:%s %d", H3, H0, procs_running, H3, H0, procs_blocked
      printf "    %sprocesses [Since boot]:%s %d\n", H3, H0, processes
      printf "    %scpu [Utilization since boot]:%s\n      us %.0f%%, ni %.0f%%, sys %.0f%%, idle %.0f%%, iowait %.0f%%, irq %.0f%%, sftirq %.0f%%, steal %.0f%%\n",
        H3, H0, user, nice, sys, idle, iowait, irq, softirq, steal
    }
  ' <"$1/proc/stat"
  
  echo -en $XSOS_HEADING_SEPARATOR
}


KDUMP() {
  # Local vars
  local kexec_tools_vers kdump_initrd path kdump_cfg target MemTotal PathAvailableSpace ColorAvailable lsbootfile
  
  # If the os module was called, grub config was already inspected; otherwise, we need to do it
  [[ -n $os ]] || _CHECK_GRUB "$1"
        
  # If running on localhost ....
  if [[ $1 == / ]]; then
    __rpm_check_kexec() {
      kexec_tools_vers=$(rpm -q kexec-tools) \
        && echo $kexec_tools_vers \
        || echo -e "${c[Warn1]}$kexec_tools_vers${c[0]}"
    }
    __svc_check_kdump() {
      if command -v systemctl >/dev/null; then
        if systemctl list-unit-files | grep -qs kdump.service; then
          systemctl list-unit-files | gawk '/kdump.service/ { printf "UNIT STATE\n" $0 }' | column -t | gawk -vH0="${c[0]}" -vgreen="${c[green]}" -vwarn="${c[Warn1]}" '
            { gsub(".*disabled", warn "&" H0)
              gsub(".*enabled", green "&" H0)
              print
            }'
        else
          echo -e "${c[Warn1]}Unit kdump.service not-found (Reason: No such file or directory)${c[0]}"
        fi
      else
        if chkconfig --list kdump &>/dev/null; then
          chkconfig --list kdump | column -t | gawk -vH0="${c[0]}" -vgreen="${c[green]}" -vwarn="${c[Warn1]}" '
            { for (i=3; i<6; i++) {
                gsub(i ":on", i ":" green "on" H0)
                gsub(i ":off", i ":" warn "off" H0)
              }
              print
            }'
        else
          echo -e "${c[Warn1]}$(chkconfig --list kdump 2>&1)${c[0]}"
        fi
      fi
    }
    __initrd_file_check() {
      ls /boot/initr*kdump.img &>/dev/null \
        && ls -l /boot/initr*kdump.img | sed -r 's@^........... +[0-9]+ \w+ *\w+ *([0-9]+ .*)@\1@' | sed -r 's,/+boot/,,' \
        || echo -e "${c[Warn1]}missing '/boot/initr*kdump.img'${c[0]}"
    }
    __get_df_for_parent_fs_of_path() {
      df_output=$(df "$path" | gawk '{if (NF==1) {dev=$1; getline; print dev $0} else if (NR==2) print}')
    }
    
      
  # If running on sosreport ....
  else
    __rpm_check_kexec() {
      if [[ -r "$sosroot"/installed-rpms ]]; then
        grep -q kexec-tools "$sosroot"/installed-rpms \
          && gawk '/kexec-tools/{print$1}' "$sosroot"/installed-rpms \
          || echo -e "${c[Warn1]}package kexec-tools is not installed${c[0]}"
      else
        echo -e "${c[Warn1]}missing '$sosroot/installed-rpms'${c[0]}"
      fi
    }
    __svc_check_kdump() {
      if [[ -r "$sosroot"/sos_commands/systemd/systemctl_list-unit-files ]]; then
        if grep -qs kdump.service "$sosroot"/sos_commands/systemd/systemctl_list-unit-files; then
          gawk '/kdump.service/ { printf "UNIT STATE\n" $0 }' "$sosroot"/sos_commands/systemd/systemctl_list-unit-files | column -t | gawk -vH0="${c[0]}" -vgreen="${c[green]}" -vwarn="${c[Warn1]}" '
            { gsub(".*disabled", warn "&" H0)
              gsub(".*enabled", green "&" H0)
              print
            }'
        else
          echo -e "${c[Warn1]}Unit kdump.service not-found (Reason: No such file or directory)${c[0]}"
        fi
      else
        if [[ -r "$sosroot"/chkconfig ]]; then
          if grep -q ^kdump "$sosroot"/chkconfig; then
            grep ^kdump "$sosroot"/chkconfig | column -t | gawk -vH0="${c[0]}" -vgreen="${c[green]}" -vwarn="${c[Warn1]}" '
              { for (i=3; i<6; i++) {
                  gsub(i ":on", i ":" green "on" H0)
                  gsub(i ":off", i ":" warn "off" H0)
                }
                print
              }'
          else
            echo -e "${c[Warn1]}kdump not present in chkconfig output${c[0]}"
          fi
        else
          echo -e "${c[Warn1]}missing '$sosroot/chkconfig'${c[0]}"
        fi
      fi
    }
    __initrd_file_check() {
      [[ -r "$sosroot"/sos_commands/bootloader/ls_-laR_.boot ]] && lsbootfile="$sosroot"/sos_commands/bootloader/ls_-laR_.boot
      [[ -r "$sosroot"/sos_commands/boot/ls_-lanR_.boot ]] && lsbootfile="$sosroot"/sos_commands/boot/ls_-lanR_.boot
      if [[ -z $lsbootfile ]]; then
        echo -e "${c[Warn1]}missing '$sosroot/sos_commands/bootloader/ls_-laR_.boot' & '$sosroot/sos_commands/boot/ls_-lanR_.boot'${c[0]}"
      else
        kdump_initrd=$(grep 'initr.*kdump.img$' "$lsbootfile") \
          && sed -r 's@^........... +[0-9]+ \w+ *\w+ *([0-9]+ .*)@\1@' <<<"$kdump_initrd" | sed -r 's,/+boot/,,' \
          || echo -e "${c[Warn1]}missing '/boot/initr*kdump.img' according to '$lsbootfile'${c[0]}"
      fi
    }
    __get_df_for_parent_fs_of_path() {
      local dfpath lastloop
      dfpath=$path
      while [[ $(grep -v ^rootfs "$sosroot"/sos_commands/filesys/df_-al | gawk -vP=$dfpath '{if ($6==P || $5==P) n+=1} END{if (n>0) print 0; else print 255}') -eq 255 ]]; do
        if [[ $lastloop == y ]]; then
          echo "DEBUG: This should never happen unless sos_commands/filesys/df_-al is missing an entry for '/'"
          return 2
        fi
        dfpath=${dfpath%/*}
        if [[ -z $dfpath ]]; then
          dfpath=/
          lastloop=y
        fi
      done
      df_output=$(grep -v ^rootfs "$sosroot"/sos_commands/filesys/df_-al | gawk -vP=$dfpath '{if (NF==6 && $6==P) print; else if (NF==1) {dev=$1; getline; if ($5==P) print dev $0} }')
    }
  fi
  
  # A couple functions that work regardless of localhost/sosreport
  __get_crashkernel_proc_cmdline() {
    local out
    if [[ -r "$sosroot"/proc/cmdline ]]; then
      out=$(egrep -o 'crashkernel=[[:graph:]]+' "$sosroot"/proc/cmdline)
    else
      out="${c[Warn1]}file missing${c[0]}"
    fi
    [[ -n $out ]] && echo -e "$out" || echo -e "${c[Warn1]}crashkernel param not present${c[0]}"
  }
  __get_crashkernel_grub_cmdline() {
    local out
    if [[ -n $bad_grubcfg ]]; then
      out="$bad_grubcfg"
    else
      out=$(egrep -o 'crashkernel=[[:graph:]]+' <<<"$grub_cmdline")
    fi
    [[ -n $out ]] && echo -e "$out" || echo -e "${c[Warn1]}crashkernel param not present${c[0]}"
  }
  __P() {
    echo -e "$XSOS_INDENT_H2${c[H3]}${1} =  $(gawk -vW="${c[Warn1]}" -vG="${c[green]}" '{ if ($1==0) print W 0; else print G $1 }' "$sosroot"/proc/sys/${1//.//} 2>/dev/null)${c[0]}"
  }
  __Pa() {
    echo -e "$XSOS_INDENT_H2${c[H3]}${1} ${c[H4]}$2${c[H3]}=  $(gawk -vW="${c[Warn1]}" -vG="${c[green]}" -vH0="${c[0]}" "$3" "$4" "$sosroot"/proc/sys/${1//.//} 2>/dev/null)${c[0]}"
  }
  __get_proc_iomem() {
    local out
    if [[ ! -r "$sosroot"/proc/iomem ]]; then
      echo -e "$XSOS_INDENT_H2${c[Warn1]}Missing $sosroot/proc/iomem${c[0]}"
      return
    fi
    if out=$(grep Crash.kernel "$sosroot"/proc/iomem); then
      echo -e "$XSOS_INDENT_H2${c[green]}${out}${c[0]}"
    else
      echo -e "$XSOS_INDENT_H2${c[Warn1]}Memory IS NOT reserved, according to $sosroot/proc/iomem${c[0]}"
    fi
  }
  
  echo -e "${c[H1]}KDUMP CONFIG${c[0]}"
  echo -e "$XSOS_INDENT_H1${c[H2]}kexec-tools rpm version:${c[0]}"
    __rpm_check_kexec | sed "s,^,$XSOS_INDENT_H2,"
  echo -e "$XSOS_INDENT_H1${c[H2]}Service enablement:${c[0]}"
    __svc_check_kdump | sed "s,^,$XSOS_INDENT_H2,"
  echo -e "$XSOS_INDENT_H1${c[H2]}kdump initrd/initramfs:${c[0]}"
    __initrd_file_check | gawk '{ print gensub(/^([0-9]+) *([[:upper:]][[:lower:]]+) *([0-9]{1,2}) *([0-9]{4}) *(initrd.*)$/, "\\1  \\2 \\3 \\4  \\5", 1) }' | sed "s,^,$XSOS_INDENT_H2,"
    # The extra gawk command above reformats spacing in the ls -l output
  echo -e "$XSOS_INDENT_H1${c[H2]}Memory reservation config:${c[0]}"
    grep -qsw rescue "$1/proc/cmdline" && echo -e "$XSOS_INDENT_H1 ${c[Warn2]}(Rescue mode detected)${c[0]}"
    echo -e "$XSOS_INDENT_H2${c[H3]}/proc/cmdline {${c[0]} $(__get_crashkernel_proc_cmdline) ${c[H3]}}${c[0]}"
    echo -e "$XSOS_INDENT_H2${c[H3]}GRUB default  {${c[0]} $(__get_crashkernel_grub_cmdline) ${c[H3]}}${c[0]}"
  echo -e "$XSOS_INDENT_H1${c[H2]}Actual memory reservation per /proc/iomem:${c[0]}"
    __get_proc_iomem
  echo -e "$XSOS_INDENT_H1${c[H2]}kdump.conf:${c[0]}"
  
    if [[ -r "$sosroot"/etc/kdump.conf ]]; then
      kdump_cfg=$(egrep -v '^[[:space:]]*$|^#' "$sosroot"/etc/kdump.conf)
      if [[ -n $kdump_cfg ]]; then
        sed "s,^,$XSOS_INDENT_H2," <<<"$kdump_cfg"
        path=$(gawk '/^path / {print$2}' <<<"$kdump_cfg" | tail -n1)
        [[ -z $path ]] && path=/var/crash
        
        for target in raw net nfs nfs4 ssh minix ext2 ext3 ext4 btrfs xfs; do
          if grep -q ^$target <<<"$kdump_cfg"; then
            path=
            break
          fi
        done
        
      else
        echo -e "$XSOS_INDENT_H2${c[DGREY]}[All commented]${c[0]}"
        path=/var/crash
      fi
      
      if [[ -n $path ]]; then
        __get_df_for_parent_fs_of_path
        if [[ -n $df_output ]]; then
          echo -e "$XSOS_INDENT_H1${c[H2]}kdump.conf \"path\" available space:${c[0]}"
          MemTotal=$(gawk '/^MemTotal/{printf "%.2f\n", $2/1024/1024}' "$sosroot"/proc/meminfo)
          PathAvailableSpace=$(gawk '{printf "%.2f\n", $4/1024/1024}' <<<"$df_output")
          ColorAvailable=$(gawk -vP=$path -vMemtotal=$(gawk /MemTotal/{print\$2} "$sosroot"/proc/meminfo) '
                            { if ($4 > Memtotal) print "green"; else print "orange" }
                           '  <<<"$df_output")
          echo -e "$XSOS_INDENT_H2${c[H3]}System MemTotal (uncompressed core size) {${c[0]} $MemTotal GiB ${c[H3]}}${c[0]}"
          echo -e "$XSOS_INDENT_H2${c[H3]}Available free space on target path's fs {${c[0]} ${c[$ColorAvailable]}$PathAvailableSpace GiB ${c[H3]}}${c[0]}  (fs=$(gawk '{print$6}' <<<"$df_output"))"
        else
          echo "DEBUG: no df_output .. shouldn't happen"
        fi
      fi
      
    else
      echo -e "$XSOS_INDENT_H2${c[Warn1]}missing '$1/etc/kdump.conf'${c[0]}"
    fi

  echo -e "$XSOS_INDENT_H1${c[H2]}Panic sysctls:${c[0]}"
  if grep -qsw rescue "$sosroot/proc/cmdline"; then
    echo -e "$XSOS_INDENT_H1${c[Warn2]}  WARNING: RESCUE MODE DETECTED${c[0]}"
    echo -e "$XSOS_INDENT_H1${c[Warn1]}  sysctls below reflect rescue env; inspect sysctl.conf manually${c[0]}"
  fi
  __Pa kernel.sysrq "[bitmask] "  '{if ($1==0) printf "\"0\"%s  (disallowed)", H0; else if ($1==1) printf "\"1\"%s  (all SysRqs allowed)", H0; else printf "\"%s\"%s  (see proc man page)", $1, H0}'
  __Pa kernel.panic "[secs] "  '{if ($1>0) printf "%s%s%s  (secs til autoreboot after panic)", W, $1, H0; else printf "%s0%s  (no autoreboot on panic)", G, H0}'
  __P kernel.hung_task_panic
  __P kernel.panic_on_oops
  __P kernel.panic_on_io_nmi
  __P kernel.panic_on_unrecovered_nmi
  __P kernel.panic_on_stackoverflow
  __P kernel.softlockup_panic
  __P kernel.unknown_nmi_panic
  __P kernel.nmi_watchdog
  __Pa vm.panic_on_oom "[0-2] "  '{if ($1==0) printf "%s0%s  (no panic)", W, H0; else if ($1==1) printf "%s1%s  (no panic if OOM-triggering task limited by mbind/cpuset)", G, H0; else if ($1==2) printf "%s2%s  (always panic)", G, H0}'
  
  echo -en $XSOS_HEADING_SEPARATOR
}


CPUINFO() {
  # Local vars:
  local cpuinfo_input model_cpu vendor family num_cpu num_cpu_phys num_threads_per_cpu cpu_cores core_id num_cores_per_cpu cores1 cores2 coresNthreads cpu_flags
  
  [[ -f $1 ]] && cpuinfo_input=$1 || cpuinfo_input=$1/proc/cpuinfo
  
  # Get model of cpu
  model_cpu=$(gawk -F: '/^model name/{print $2; exit}' <"$cpuinfo_input")
  
  # If no model detected (e.g. on Itanium), try to use vendor+family
  [[ -z $model_cpu ]] && {
    vendor=$(gawk -F: '/^vendor /{print $2; exit}' <"$cpuinfo_input")
    family=$(gawk -F: '/^family /{print $2; exit}' <"$cpuinfo_input")
    model_cpu="$vendor$family"
  }
  
  # Clean up cpu model string
  model_cpu=$(sed -e 's,(R),,g' -e 's,(TM),,g' -e 's,  *, ,g' -e 's,^ ,,' <<<"$model_cpu")
  
  # Get number of logical processors
  num_cpu=$(gawk '/^processor/{n++} END{print n}' <"$cpuinfo_input")
  
  # Get number of physical processors
  num_cpu_phys=$(grep '^physical id' <"$cpuinfo_input" | sort -u | wc -l)
  
  # If "physical id" not found, we cannot make any assumptions (Virtualization--)
  # But still, multiplying by 0 in some crazy corner case is bad, so set it to 1
  # If num of physical *was* detected, add it to the beginning of the model string
  [[ $num_cpu_phys == 0 ]] && num_cpu_phys=1 || model_cpu="$num_cpu_phys $model_cpu"
  
  # If number of logical != number of physical, try to get info on cores & threads
  if [[ $num_cpu != $num_cpu_phys ]]; then
    
    # Detect number of threads (logical) per cpu
    num_threads_per_cpu=$(gawk '/^siblings/{print $3; exit}' <"$cpuinfo_input")
    
    # Two possibile ways to detect number of cores
    cpu_cores=$(gawk '/^cpu cores/{print $4; exit}' <"$cpuinfo_input")
    core_id=$(grep '^core id' <"$cpuinfo_input" | sort -u | wc -l)
    
    # The first is the most accurate, if it works
    if [[ -n $cpu_cores ]]; then
      num_cores_per_cpu=$cpu_cores
    
    # If "cpu cores" doesn't work, "core id" method might (e.g. Itanium)
    elif [[ $core_id -gt 0 ]]; then
      num_cores_per_cpu=$core_id
    fi
    
    # If found info on cores, setup core variables for printing
    if [[ -n $num_cores_per_cpu ]]; then
      cores1="($((num_cpu_phys*num_cores_per_cpu)) CPU cores)"
      cores2=" / $num_cores_per_cpu cores"
    # If didn't find info on cores, assume single-core cpu(s)
    else
      cores2=" / 1 core"
    fi
    
    # If found siblings (threads), setup the variable for the final line
    [[ -n $num_threads_per_cpu ]] &&
      coresNthreads="\n  └─$num_threads_per_cpu threads${cores2} each"
  fi
  
  # Check important cpu flags
  # pae=physical address extensions  *  lm=64-bit  *  vmx=Intel hw-virt  *  svm=AMD hw-virt
  # ht=hyper-threading  *  aes=AES-NI  *  constant_tsc=Constant Time Stamp Counter
  cpu_flags=$(egrep -o "pae|lm|vmx|svm|ht|aes|constant_tsc|rdrand|nx" <"$cpuinfo_input" | sort -u | sed ':a;N;$!ba;s/\n/,/g')
  [[ -n $cpu_flags ]] && cpu_flags="(flags: $cpu_flags)"
  
  # Print it all out
  echo -e "${c[H1]}CPU${c[0]}"
  echo -e "  ${c[Imp]}${num_cpu} logical processors${c[0]} ${cores1}"
  echo -e "  ${model_cpu} ${cpu_flags} ${coresNthreads}"
  echo -en $XSOS_HEADING_SEPARATOR
}


INTERRUPT() {
  # Local vars:
  local interrupts_input longest_len_interupt_field_one indent
  [[ -f $1 ]] && interrupts_input=$1 || interrupts_input=$1/proc/interrupts
  longest_len_interupt_field_one=$(gawk 'NR > 1 {print length($1)}' $interrupts_input | sort -nr | head -1)
  indent=$(( longest_len_interupt_field_one + $(printf "$XSOS_INDENT_H1" | wc -m) ))
  echo -e "${c[H1]}INTERRUPTS${c[0]}"
  gawk '
    NR > 1 {
      printf "%'$indent's ", $1
      for (i=2; i <= NF; i++) {
        if ($i ~ "[a-zA-Z]")
          printf " %s", $i
        else if($i > 0)
          printf "▊"
        else
          printf "."
      }
      printf "\n"
    }
  ' <"$interrupts_input"
  echo -en $XSOS_HEADING_SEPARATOR
}


MEMINFO() {
  # Local vars:
  local meminfo_input
  
  [[ -f $1 ]] && meminfo_input=$1 || meminfo_input=$1/proc/meminfo
  
  echo -e "${c[H1]}MEMORY${c[0]}"
  if grep -qsw rescue "$1/proc/cmdline"; then
    echo -e "${c[Warn2]}  WARNING: RESCUE MODE DETECTED${c[0]}"
    echo -e "${c[Warn1]}  meminfo reflects rescue env; inspect sysctl.conf manually for HugePages${c[0]}"
  fi
  
  gawk -vu=$(tr '[:lower:]' '[:upper:]' <<<$XSOS_MEM_UNIT) -vcolor_MemUsed="${c[MemUsed]}" -vcolor_HugePages="${c[HugePages]}" -vcolor_Buffers="${c[Buffers]}" -vcolor_Cached="${c[Cached]}" -vcolor_Dirty="${c[Dirty]}" -vcolor_warn="${c[Warn1]}" -vH_IMP="${c[Imp]}" -vH3="${c[H3]}" -vH2="${c[H2]}" -vH0="${c[0]}" '
    # These will come in handy
    
    function round(num, places) {
      places = 10 ^ places
      return int(num * places + .5) / places
    }
          
    function memgraph_special(PercentA, PercentB, Color, PrettyName) {
      PercentTotal = PercentA + PercentB
      printf "    %s%s ", Color, PrettyName
      for (i=0; i <    round(PercentA/2, 0); i++) printf "▊"
      for (i=0; i <    round(PercentB/2, 0); i++) printf "."
      printf H0
      for (i=0; i < 50-round(PercentTotal/2, 0); i++) printf "."
      if      (round(PercentTotal,1) > 99.9) j=" "
      else if (round(PercentTotal,1) > 9)    j="  "
      else                                   j="   "
      printf "%s%s%.1f%%%s\n", j, Color, PercentTotal, H0
    }
    
    function memgraph(Percent, Color, PrettyName) {
      printf "    %s%s ", Color, PrettyName
      for (i=0; i <    round(Percent/2, 0); i++) printf "▊"
      printf H0
      for (i=0; i < 50-round(Percent/2, 0); i++) printf "."
      if      (round(Percent,1) > 99.9) j=" "
      else if (round(Percent,1) > 9)    j="  "
      else                          j="   "
      printf "%s%s%.1f%%%s\n", j, Color, Percent, H0
    }
        
    # Grab variables from meminfo
    
    /^MemTotal:/        { MemTotal  = $2 }
    /^MemFree:/         { MemFree   = $2 }
    /^Buffers:/         { Buffers   = $2 }
    /^Cached:/          { Cached   += $2 }
    /^SwapCached:/      { Cached   += $2 }
    /^LowTotal:/        { LowTotal  = $2 }
    /^LowFree:/         { LowFree   = $2 }
    /^SwapTotal:/       { SwapTotal = $2 }
    /^SwapFree:/        { SwapFree  = $2 }
    /^Dirty:/           { Dirty     = $2 }
    /^Shmem:/           { Shmem     = $2 }
    /^Slab:/            { Slab      = $2 }
    /^PageTables:/      { PageTables     = $2 }
    /^Hugepagesize:/    { Hugepagesize   = $2 }
    /^HugePages_Total:/ { HugepagesTotal = $2 }
    /^HugePages_Free:/  { HugepagesFree  = $2 }
    
    END {
      
      # Compute additional variables
      
      MemUsed         = MemTotal - MemFree
      Mem_Percent     = MemUsed * 100 / MemTotal
      Buffers_Percent = Buffers * 100 / MemTotal
      Cached_Percent  = Cached * 100 / MemTotal
      MemUsedNoBC     = MemUsed - Buffers - Cached
      MemNoBC_Percent = MemUsedNoBC * 100 / MemTotal
      Dirty_Percent   = Dirty * 100 / MemTotal
      Shmem_Percent   = Shmem * 100 / MemTotal
      Slab_Percent    = Slab * 100 / MemTotal
      PT_Percent      = PageTables * 100 / MemTotal
      HP              = Hugepagesize * HugepagesTotal
      HP_PercentRam   = HP * 100 / MemTotal
      
      # If have hugepages, calculate in-use
      
      if (HugepagesTotal > 0) {
        HP_Used         = (HugepagesTotal - HugepagesFree) * Hugepagesize
        HP_Used_Percent = (HugepagesTotal - HugepagesFree) * 100 / HugepagesTotal
      }
      
      # Else, need to avoid divide-by-zero errors
      
      else {
        HP_Used         = 0
        HP_Used_Percent = 0
      }
      
      # If meminfo has LowTotal (modern x86_64 boxes do not)...
      
      if (LowTotal ~ /[0-9]+/) {
        SHOW_Lowmem=1
        LowUsed         = LowTotal - LowFree
        LowUsed_Percent = LowUsed * 100 / LowTotal
      }
      
      # Else, avoid divide-by-zero and hide it
      
      else {
        SHOW_Lowmem=0
        LowTotal        = 0
        LowUsed         = 0
        LowUsed_Percent = 0
      }
      
      # If have swap-space...
      
      if (SwapTotal > 0) {
        SwapUsed      = SwapTotal - SwapFree
        Swap_Percent  = SwapUsed * 100 / SwapTotal
      }
      
      # Else, avoid divide-by-zero errors
      
      else {
        SwapUsed      = 0
        Swap_Percent  = 0
      }
      
      # If meminfo has Shmem, we show it; otherwise not
      
      if (Shmem ~ /[0-9]+/)
        SHOW_Shmem=1
      else
        SHOW_Shmem=0
      
      # If unit is set to B, convert native KiB to bytes
      
      if (u == "B") {
        MemUsed     *= 1024
        MemTotal    *= 1024
        MemUsedNoBC *= 1024
        Dirty       *= 1024
        Shmem       *= 1024
        Slab        *= 1024
        PageTables  *= 1024
        HP          *= 1024
        if (HugepagesTotal > 0) HP_Used *= 1024
        if (LowTotal > 0) { LowUsed *= 1024; LowTotal *= 1024 }
        if (SwapTotal > 0) { SwapUsed *= 1024; SwapTotal *= 1024 }
      }
      
      # Figure out what number to divide by to end up with MiB, GiB, or TiB
      
      if      (u == "M") divisor = 1024
      else if (u == "G") divisor = 1024 ** 2
      else if (u == "T") divisor = 1024 ** 3
      
      # If unit is set to M or G or T, do the division to convert from native KiB
      
      if (u == "M" || u == "G" || u == "T") {
        MemUsed     /= divisor
        MemTotal    /= divisor
        MemUsedNoBC /= divisor
        Dirty       /= divisor
        Shmem       /= divisor
        Slab        /= divisor
        PageTables  /= divisor
        HP          /= divisor
        if (HugepagesTotal > 0) HP_Used /= divisor
        if (LowTotal > 0)  { LowUsed  /= divisor; LowTotal  /= divisor }
        if (SwapTotal > 0) { SwapUsed /= divisor; SwapTotal /= divisor }
      }
      
      # The unit string used just for printing
      
      if (u == "B")
        Unit = " "u
      else
        Unit = " "u"iB"
      
      
      # ASCII-ART fun
      
      printf "  %sStats graphed as percent of MemTotal:%s\n", H2, H0
      # The following line is disabled because it would kinda suck for people that run with NOCOLOR
      # Or people that run with color and then copy the output to text -- uncomment it to see what I mean
      #memgraph_special(MemNoBC_Percent, Buffers_Percent+Cached_Percent, color_MemUsed, "MemUsed   ")
      memgraph(Mem_Percent,     color_MemUsed,   "MemUsed   ")
      memgraph(Buffers_Percent, color_Buffers,   "Buffers   ")
      memgraph(Cached_Percent,  color_Cached,    "Cached    ")
      memgraph(HP_PercentRam,   color_HugePages, "HugePages ")
      memgraph(Dirty_Percent,   color_Dirty,     "Dirty     ")
      
      # If unit is T, print percentages with no decimal & byteunits with 2-3 decimal-points of precision
      
      if (u == "T") {
        Prec_Percent = 0
        Prec_BytesLo = 2
        Prec_BytesHi = 3
      }
      
      # If unit is G, print percentages with no decimal & byteunits with 1-2 decimal-points of precision
      
      else if (u == "G") {
        Prec_Percent = 0
        Prec_BytesLo = 1
        Prec_BytesHi = 2
      }
      
      # If unit is B or K or M, print percentages with 1 decimal-point of precision & byteunits with no decimal
      
      else {
        Prec_Percent = 1
        Prec_BytesLo = 0
        Prec_BytesHi = 0
      }
      
      # Now time to round off the numbers
      
      Mem_Percent     = round(Mem_Percent,     Prec_Percent)
      MemNoBC_Percent = round(MemNoBC_Percent, Prec_Percent)
      Dirty_Percent   = round(Dirty_Percent,   Prec_Percent)
      HP_PercentRam   = round(HP_PercentRam,   Prec_Percent)
      HP_Used_Percent = round(HP_Used_Percent, Prec_Percent)
      LowUsed_Percent = round(LowUsed_Percent, Prec_Percent)
      Slab_Percent    = round(Slab_Percent,    Prec_Percent)
      PT_Percent      = round(PT_Percent,      Prec_Percent)
      Shmem_Percent   = round(Shmem_Percent,   Prec_Percent)
      Swap_Percent    = round(Swap_Percent,    Prec_Percent)
      
      MemTotal    = round(MemTotal,    Prec_BytesLo)
      MemUsed     = round(MemUsed,     Prec_BytesLo)
      MemUsedNoBC = round(MemUsedNoBC, Prec_BytesLo)
      Dirty       = round(Dirty,       Prec_BytesHi)
      HP          = round(HP,          Prec_BytesLo)
      HP_Used     = round(HP_Used,     Prec_BytesLo)
      LowUsed     = round(LowUsed,     Prec_BytesLo)
      LowTotal    = round(LowTotal,    Prec_BytesLo)
      Slab        = round(Slab,        Prec_BytesHi)
      PageTables  = round(PageTables,  Prec_BytesHi)
      Shmem       = round(Shmem,       Prec_BytesHi)
      SwapUsed    = round(SwapUsed,    Prec_BytesLo)
      SwapTotal   = round(SwapTotal,   Prec_BytesLo)
              
      printf    "  %sRAM:%s\n", H2, H0
      printf    "    %s%s%s total ram%s\n", H_IMP, MemTotal, Unit, H0
      printf    "    %s%s (%s%%) used\n", MemUsed, Unit, Mem_Percent
      printf    "    %s%s%s (%s%%) used excluding Buffers/Cached%s\n", H_IMP, MemUsedNoBC, Unit, MemNoBC_Percent, H0
      if (Dirty_Percent > 10)
        printf  "    %s%s%s (%s%%) dirty%s\n", color_warn, Dirty, Unit, Dirty_Percent, H0
      else
        printf  "    %s%s (%s%%) dirty\n", Dirty, Unit, Dirty_Percent
      
      printf    "  %sHugePages:%s\n", H2, H0
      if (HugepagesTotal == 0)
        printf  "    No ram pre-allocated to HugePages\n"
      else {
        printf  "    %s%s%s pre-allocated to HugePages (%s%% of total ram)%s\n", H_IMP, HP, Unit, HP_PercentRam, H0
        printf  "    %s%s of HugePages (%s%%) in-use by applications\n", HP_Used, Unit, HP_Used_Percent
      }
      
      printf    "  %sLowMem/Slab/PageTables/Shmem:%s\n", H2, H0
      if (SHOW_Lowmem == 1)
        printf  "    %s%s (%s%%) of %s%s LowMem in-use\n", LowUsed, Unit, LowUsed_Percent, LowTotal, Unit
      printf    "    %s%s (%s%%) of total ram used for Slab\n", Slab, Unit, Slab_Percent
      printf    "    %s%s (%s%%) of total ram used for PageTables\n", PageTables, Unit, PT_Percent
      if (SHOW_Shmem == 1)
        printf  "    %s%s (%s%%) of total ram used for Shmem\n", Shmem, Unit, Shmem_Percent
      
      printf    "  %sSwap:%s\n", H2, H0
      if (SwapTotal == 0)
        printf  "    %sNo system swap space configured%s\n", color_warn, H0
      else
        printf  "    %s%s (%s%%) used of %s%s total\n", SwapUsed, Unit, Swap_Percent, SwapTotal, Unit
     
    }
  ' <"$meminfo_input"
  echo -en $XSOS_HEADING_SEPARATOR
}


STORAGE() {
  # Local vars:
  local mpath_input scsi_blacklist bl partitions_input
  
  echo -e "${c[H1]}STORAGE${c[0]}"
  
  # Get mpath input if necessary
  if [[ $2 != --no-mpath ]]; then
    if [[ $1 == / && $UID -eq 0 ]]; then
      # Get multipath input from command, because $1 is system
      mpath_input=$(multipath -v4 -ll 2>/dev/null)
    elif [[ -r $1/sos_commands/devicemapper/multipath_-v4_-ll || -r $1/sos_commands/multipath/multipath_-v4_-ll ]]; then
      # Get multipath input from sosreport file, if present
      mpath_input=$(cat "$1"/sos_commands/{devicemapper,multipath}/multipath_-v4_-ll 2>/dev/null)
    fi
  fi
  
  # If have good mpath data ..
  if [[ -n $mpath_input ]] && ! egrep -q 'no.paths|multipath.conf.*not.exist' <<<"$mpath_input"; then
    echo -e "${c[H2]}  Multipath:${c[0]}"
    
    # Print out names & sizes of each multipath map
    egrep -B1 '^\[?size=' <<<"$mpath_input" |
      gawk -vRS="--" '
        {
          printf "    %s;%s\n",
            $1, gensub(/.*size=([0-9]+\.?[0-9]*) ?([MGT]).*/, "\\1  \\2iB", 1)
        }
      ' | sort | column -ts\;
    
    # Also, create a blacklist containing all paths to LUNS used for multipath
    # This will be used to hide certain devices in the plain "whole disk" output
    scsi_blacklist=$(gawk '
      # The beginning of this regex is quite odd .. we are matching lines starting with:
      #   \_  OR  |-  OR  `-
      
      /(\\_|\|-|`-) [0-9]+:[0-9]+:[0-9]+:[0-9]+ +[[:graph:]]+ +[0-9]+:/ {
        printf gensub(/.*:[0-9]+ +([[:graph:]]+) +[0-9].*/, "\\1|", 1)
      }
    ' <<<"$mpath_input")
  fi
  
  # If we have linux swraid info, let's use it to expand our blacklist
  if [[ -r $1/proc/mdstat ]]; then
    # Append software raid component disks to the blacklist
    scsi_blacklist=$scsi_blacklist$(grep -s ^md "$1/proc/mdstat" | cut -d\  -f5- | egrep -o '[[:alpha:]]+' | sort -u | gawk '{printf "%s|", $1}')
  fi
  
  # Yay, let's go.
  [[ -n $scsi_blacklist ]] && bl=y || { bl=n; scsi_blacklist=NULL; }
  [[ -f $1 ]] && partitions_input=$1 || partitions_input=$1/proc/partitions
  echo -e "  ${c[H2]}Whole Disks from /proc/partitions:${c[0]}"
  egrep -v "${scsi_blacklist%?}" "$partitions_input" |
    gawk -vblacklisted=$bl -vblacklist_devcount=$(wc -w <<<"${scsi_blacklist//|/ }") -vcolor_grey="${c[DGREY]}" -vH_IMP="${c[Imp]}" -vH3="${c[H3]}" -vH2="${c[H2]}" -vH0="${c[0]}" '
      # For starters, we search /proc/partitions for certain types of devices
      # These block types are from devices.txt in the linux kernel documentation
      # Updated 2015/08/18 from kernel-doc-3.10.0-229.7.2.el7
      BEGIN {
        blkdevs = "^("  \
                  "(vd|hd|sd|mfm|ad|ftl|pd|i2o/hd|nftl|dasd|inftl|ubd|cbd/|iseries/vd|ub|xvd|rfd|ssfdc)[[:alpha:]]+"  \
                  "|"  \
                  "(ramdisk|ram|loop|md|rr?om|r?flash|nb|ppdd|amiraid/ar|ataraid/d|nwfs/v|umem/d|drbd|etherd/|emd/|carmel/|mmcblk|blockrom)[0-9]+"  \
                  "|"  \
                  "(rd|ida|cciss)/c[0-9]+d[0-9]+"  \
                  "|"  \
                  "vx/dsk/.*/.*|vx/dmp/.*"  \
                  ")$"
      }
      $4 ~ blkdevs {
        
        # For each thing found, increment the total number of disks
        numdisks ++
        
        # Name a key in the array after the disk and then store its size in GiB there
        disk[$4] = $3/1024/1024
        
        # Also, add to the total sum of disk-storage
        sum_gb  += disk[$4]
      }
      
      END {
        # All done with the data-gathering; so print out a summary
        printf   "    %s%d disks, totaling %.0f GiB (%.2f TiB)%s\n", H_IMP, numdisks, sum_gb, sum_gb/1024, H0
        
        # Print a notice if devices were hidden due to blacklist
        if (blacklisted == "y")
          printf "    %s(%d multipath/mdraid components hidden)%s\n", H_IMP, blacklist_devcount, H0
        
        # Some pretty header-fun
        printf   "    %s- - - - - - - - - - - - - - - - - - - - -%s\n", color_grey, H0
        printf   "    %sDisk \tSize in GiB\n", H3
        printf   "    ----\t-----------%s\n", H0
        
        # Finally, print all the disks & their sizes
        n = asorti(disk, disk_sorted)
        for (i = 1; i <= n; i++)
          printf "    %s \t%.0f\n", disk_sorted[i], disk[disk_sorted[i]]
      }
    '
  echo -en $XSOS_HEADING_SEPARATOR
}


MULTIPATH() {
  # Local vars:
  local mpath_input search_cmd mpath_output
  
  # If localhost, grab output from multipath
  if [[ -z $1 ]]; then
    mpath_input=$(multipath -v4 -ll 2>/dev/null)

  # If directory, assume sosreport and look for multipath output
  elif [[ -d $1 ]]; then
    mpath_input=$(cat "$1"/sos_commands/{devicemapper,multipath}/multipath_-v4_-ll 2>/dev/null)

  # Otherwise grab file
  elif [[ -f $1 ]]; then
    mpath_input=$(<$1)
  fi

  echo -e "${c[H1]}DM-MULTIPATH${c[0]}"
  
  # If we have a specific query, we'll use gawk for post-processing
  # Otherwise simply use cat
  if [[ -n $XSOS_MULTIPATH_QUERY ]]; then
    search_cmd="gawk -vRS=\n\n /$XSOS_MULTIPATH_QUERY/"
  else
    search_cmd=cat
  fi
  
  # Need to parse through `multipath -v4 -ll` output from multiple version of rhel
  mpath_output=$(gawk '
    /^[[:graph:]]+ \([[:alnum:][:punct:]]+\) *dm-/
    /^[[:graph:]]+ *dm-/
    /^\[?size=/
    /(\\_|\|-|`-)/
  ' <<<"$mpath_input")
  
  if [[ -n $mpath_output ]]; then
    sed '1!s,^[[:alnum:]].*dm-,\n&,' <<<"$mpath_output" | $search_cmd | sed "s/^/$XSOS_INDENT_H1/"
  else
    echo -e "${XSOS_INDENT_H1}${c[DGREY]}[No paths detected]${c[0]}"
  fi
  
  echo -en $XSOS_HEADING_SEPARATOR
}


LSPCI() {
  # Local vars:
  local lspci_input
  
  if [[ -z $1 ]]; then
    lspci_input=$(lspci)
  elif [[ -f $1 ]]; then
    lspci_input=$(gawk '{print} /^lspci -n/{exit}' "$1" 2>/dev/null)
  else
    lspci_input=$(gawk '{print} /^lspci -n/{exit}' "$1/lspci" 2>/dev/null)
  fi
  
  _parse_periphs() {
    local regex=${1}
    gawk -vH_IMP="${c[Imp]}" -vH2="${c[H2]}" -vH0="${c[0]}" "
      /${regex}/"'{
        # Save
        split($1, slot, ":")
        $1 = ""
        sub(" ", "")
        split($0, type, ":")
        dev[type[2]] ++
        if (!(slot[1] SUBSEP type[2] in slots)) {
          slots[slot[1], type[2]]
          slotcount[type[2]] ++
        }
      }
      END {
        for (devtype in dev) {
          slotc = slotcount[devtype]
          typec = dev[devtype]
          ports = ""
          if (typec > 1) {
            numports = typec/slotc
            if      (numports == 1) numports = "single"
            else if (numports == 2) numports = "dual"
            else if (numports == 3) numports = "triple"
            else if (numports == 4) numports = "quad"
            ports = " "slotc " " numports "-port"
          }
          printf "   %s%s (%s)%s%s\n", H_IMP, ports, typec, H0, devtype
        }
      }
    ' <<<"$lspci_input"
  }
  
  echo -e "${c[H1]}LSPCI${c[0]}"
  
  echo -e "${c[H2]}  Net:${c[0]}"
  _parse_periphs "${XSOS_LSPCI_NET_REGEX}"
  
  echo -e "${c[H2]}  Storage:${c[0]}"
  _parse_periphs "${XSOS_LSPCI_STORAGE_REGEX}"
  
  echo -e "${c[H2]}  VGA:${c[0]}"
  gawk '/VGA compatible controller:/ {$1=$2=$3=$4=""; print}' <<<"$lspci_input"
  echo -en $XSOS_HEADING_SEPARATOR
}


BONDING() {
  # Local vars:
  local files netscriptsdir bond_input f mode bonding_opts active slaves slave s
  
  # If passed a file (i.e. xsos --G <file>), use that
  if [[ -f $1 ]]; then
    files=($1)
  # If localhost or sosreport, use that
  else
    files=("$1"/proc/net/bonding/*)
    if [[ ! -r ${files[0]} ]]; then
      echo -e "${c[Warn2]}Warning:${c[Warn1]} '/proc/net/bonding/' files unreadable; skipping bonding check${c[0]}" >&2
      echo -en $XSOS_HEADING_SEPARATOR >&2
      return
    fi
    [[ -d "$1"/etc/sysconfig/network-scripts ]] && netscriptsdir="$1"/etc/sysconfig/network-scripts
  fi
  
  __transform_mode() {
    # Could be vastly improved by using bashV4 associative array, but KISS for rhel5 peeps
    if grep -q "load balancing (round-robin)" <<<"$1"; then
      mode="0 (balance-rr)"
    
    elif grep -q "fault-tolerance (active-backup)" <<<"$1"; then
      mode="1 (active-backup)"
    
    elif grep -q "load balancing (xor)" <<<"$1"; then
      mode="2 (balance-xor)"
    
    elif grep -q "fault-tolerance (broadcast)" <<<"$1"; then
      mode="3 (broadcast)"
    
    elif grep -q "IEEE 802.3ad Dynamic link aggregation" <<<"$1"; then
      mode="4 (802.3ad)"
    
    elif grep -q "transmit load balancing" <<<"$1"; then
      mode="5 (balance-tlb)"
    
    elif grep -q "adaptive load balancing" <<<"$1"; then
      mode="6 (balance-alb)"
    
    else
      mode="unrecognized: $1"
    fi
  }
  
  if [[ $XSOS_SCRUB_MACADDR == y ]]; then
    __scrub_mac() { sed -r 's/[0-9abcdef]/⣿/g' ; }
  else
    __scrub_mac() { cat ; }
  fi
  
  echo -e "${c[H1]}BONDING${c[0]}"
    
  # The bracket here is like using parens to make a subshell -- allows to capture all stdout
  {
    # Header info ("❚" is used later by `column` to columnize the output)
    echo "  Device❚Mode❚ifcfg-File BONDING_OPTS❚Partner MAC Addr❚Slaves (*=active; [n]=AggID)"
    echo "  ========❚=================❚========================❚==================❚==============================="
    
    f=0; for bond_input in ${files[@]}; do
      
      echo -n "  ${bond_input##*/}❚"
      
      __transform_mode "$(gawk -F: '/Bonding Mode/ {printf $2}' $bond_input | sed -e 's/^ //')"
      echo -n "$mode❚"
      
      bonding_opts=$(gawk '/^BONDING_OPTS=/' "$netscriptsdir/ifcfg-${bond_input##*/}" 2>/dev/null | tail -n1 | sed s/BONDING_OPTS=// | tr -d \"\')
      [[ -z $bonding_opts ]] && bonding_opts=-
      echo -n "$bonding_opts❚"
      
      if [[ ${mode::1} == 4 ]]; then
        active_agg_info=$(gawk 'BEGIN{RS="\n\n"} /Active Aggregator Info:/ {print}' $bond_input)
        partner_mac=$(gawk '/Partner Mac Address:/ {print $4}' <<<"$active_agg_info" | __scrub_mac)
        echo -n "${partner_mac:--}❚"
        active=$(gawk '/Aggregator ID:/ {print $3}' <<<"$active_agg_info")
      else
        echo -n "-❚"
        active=$(gawk '/Active Slave/ {printf $4}' $bond_input)
      fi
      
      slaves=( $(gawk '/^Slave Interface:/ {print $3}' $bond_input) )
      
      [[ ${#slaves[@]} -eq 0 ]] && echo "[None]"
      
      s=0; until [[ $s -eq ${#slaves[@]} ]]; do
        if [[ ${mode::1} == 4 ]]; then
          agg_id=$(gawk 'BEGIN{RS="\n\n"} /Slave Interface: '"${slaves[s]}/" $bond_input | gawk '/Aggregator ID:/ {print $3}')
        fi
        # First line
        if [[ $s -eq 0 ]]; then
          if [[ ${mode::1} == 4 ]]; then
            if [[ $active == $agg_id ]]; then
              echo -n "* [$agg_id] ${slaves[s]}"
            else
              echo -n "  [$agg_id] ${slaves[s]}"
            fi
          elif [[ $active == ${slaves[s]} ]]; then
            echo -n "* ${slaves[s]}"
          else
            echo -n "  ${slaves[s]}"
          fi
        # Not first line
        else
          if [[ ${mode::1} == 4 ]]; then
            if [[ $active == $agg_id ]]; then
              echo -n " ❚ ❚ ❚ ❚* [$agg_id] ${slaves[s]}"
            else
              echo -n " ❚ ❚ ❚ ❚  [$agg_id] ${slaves[s]}"
            fi
          elif [[ $active == ${slaves[s]} ]]; then
            echo -n " ❚ ❚ ❚ ❚* ${slaves[s]}"
          else
            echo -n " ❚ ❚ ❚ ❚  ${slaves[s]}"
          fi
        fi
        
        gawk 'BEGIN { RS="\n\n" } /Slave Interface: '${slaves[s]}'\>/' $bond_input |
          gawk '/Permanent HW addr/ {printf " (%s)", $4}' | __scrub_mac
        s=$((s+1))
        echo
      done
    f=$((f+1))
    [[ $f -lt ${#files[@]} ]] && echo " ❚ ❚ ❚ ❚- - - - - - - - - - - - - - - -"
    done
  } |
    column -ts❚ |
    
      # And then we need to do some color funness!
      # This colorizes the first 2 lines with the H2 color and the interfaces with H3
      gawk -vH0="${c[0]}" -vH2="${c[H2]}" -vH3="${c[H3]}" '
        {
          if (NR <= 2) print H2 $0 H0
          else printf gensub(/(^  [[:graph:]]+ )/,   H3"\\1"H0, 1)"\n"
        }' |
          gawk -vU="${c[Up]}" -vH0="${c[0]}" -vgrey="${c[DGREY]}" '
            {
              if (NR <= 2) print
              else if ($1 == "-") print grey $0 H0
              else printf gensub(/( \*.*)/,   U"\\1"H0, 1)"\n"
            }'
        
  echo -en $XSOS_HEADING_SEPARATOR
}


IPADDR() {
# I spent a long time wondering how I would end up implementing ip-addr functionality
# I couldn't think of a lovely elegant gawk-way and in the end I wrote this in 2 hours
# (And later added brctl, ipv6, scrubbing, MTU)
# This is probably one of the most expensive of the functions and the one most ripe for
# being rewritten in Python

  # Require BASH v4
  if [[ -z ${BASH_VERSINFO} || ${BASH_VERSINFO} -lt 4 ]]; then
    echo "The -i/--ip option requires use of BASH associative arrays" >&2
    echo "i.e., BASH v4.0 or higher (RHEL6/Fedora11 and above)" >&2
    echo -en ${XSOS_HEADING_SEPARATOR} >&2
    return
  fi
  
  # Local vars:
  local ip_a_input brctl_show_input ipdevs bridge interface i n ipaddr scope alias
  
  # Declare our 7 associative arrays:
  local -A lookup_bridge iface_input slaveof state ipv4 ipv4_alias mtu mac
  
  # If localhost, use ip addr
  if [[ -z $1 ]]; then
    ip_a_input=$(ip a)
    brctl_show_input=$(brctl show)
  # If passed a file (i.e. xsos --I <file>), use that
  elif [[ -f $1 ]]; then
    ip_a_input=$(<"${1}")
  # Otherwise, use file from $sosroot
  else
    ip_a_input=$(<"${1}/sos_commands/networking/ip_address")
    brctl_show_input=$(cat "${1}/sos_commands/networking/brctl_show" 2>/dev/null)
  fi
  
  # Prepare ip addr input for gawk by separating each interface block
  ip_a_input=$(sed -e 's,^[0-9]*: ,\n&,' -e '1s,^,\n,' <<<"${ip_a_input}")
  
  # Grab a list of the interface names
  ipdevs=$(gawk -F: 'BEGIN {RS="\n\n"} {print $2}' <<<"${ip_a_input}" | egrep -v 'sit0')
  
  # Prepare brctl input for gawk by separating each bridge block & filling in empty columns
  brctl_show_input=$(sed -e 1d -e 's,^[[:graph:]],\n&,' <<<"${brctl_show_input}" | sed -r 's,^[[:space:]]+[[:graph:]]+,1 2 3&,')
  
  # Populate a dict where each slave interface is key & value is the controlling bridge
  for bridge in $(gawk 'BEGIN {RS="\n\n"} {print $1}' <<<"${brctl_show_input}"); do
    for interface in $(gawk 'BEGIN {RS="\n\n"} $1=="'${bridge}'"' <<<"${brctl_show_input}" | gawk  '{print $4}'); do
      lookup_bridge[$interface]=${bridge}
    done
  done
    
  # Begin ...
  echo -e "${c[H1]}IP$XSOS_IP_VERSION${c[0]}"
  
  # The bracket here is like using parens to make a subshell -- allows to capture all stdout
  {
    # Header info ("❚" is used later by `column` to columnize the output)
    if [[ $XSOS_IP_VERSION -eq 6 ]]; then
      echo "  Interface❚Master IF❚MAC Address❚MTU❚State❚IPv6 Address❚Scope"
      echo "  =========❚=========❚=================❚======❚=====❚===========================================❚====="
    else
      echo "  Interface❚Master IF❚MAC Address❚MTU❚State❚IPv4 Address"
      echo "  =========❚=========❚=================❚======❚=====❚=================="
    fi
    
    # For each interface ($i) found in ip addr output
    for i in ${ipdevs}; do
      
      # Pull out input for specific interface and save to interface key in array
      iface_input[$i]=$(gawk "BEGIN {RS=\"\n\n\"} /^[0-9]+: ${i}:/" <<<"${ip_a_input}")

      # Figure out if $i is a slave of some bond / bridge device
      slaveof[$i]=$(
        if egrep -q 'SLAVE|master' <<<"${iface_input[$i]}"; then
          egrep -o 'master [[:graph:]]+' <<<"${iface_input[$i]}" | gawk '{print $2}'
        elif [[ -n $brctl_show_input && -n ${lookup_bridge[$i]} ]]; then
          echo ${lookup_bridge[$i]}
        else
          echo "-"
        fi
      )
      
      # Get MTU for $i
      mtu[$i]=$(egrep -o 'mtu [0-9]+' <<<"${iface_input[$i]}" | gawk '{print $2}')
      
      # Get up/down state for $i
      state[$i]=$(grep -q "${i}: <.*,UP.*>"  <<<"${iface_input[$i]}" && echo up || echo DOWN)
      
      # Get macaddr for $i (don't show if all zeros)
      mac[$i]=$(egrep -q 'link/[[:graph:]]+ ..:..:..:..:..:..' <<<"${iface_input[$i]}" &&
                gawk -v scrub="${XSOS_SCRUB_MACADDR}" '
                    /link\/[[:graph:]]+ ..:..:..:..:..:../ {
                        if ($2 == "00:00:00:00:00:00") print "-"
                        else if (scrub == "y") print "⣿⣿:⣿⣿:⣿⣿:⣿⣿:⣿⣿:⣿⣿"
                        else print $2
                    }
                ' <<<"${iface_input[$i]}" || echo "-")
      
      if [[ ${XSOS_IP_VERSION} -eq 6 ]]; then
        
        # If $i has an ipv6 address, time to figure out what it is
        if grep -q "inet6" <<<"${iface_input[$i]}"; then
          
          # We could have more than one ipv6addr...
          # So we need to set up a counter and do a loop
          n=0; while read ipaddr scope; do
            if [[ $n -eq 0 ]]; then
              echo "  ${i}❚${slaveof[$i]}❚${mac[$i]}❚${mtu[$i]}❚${state[$i]}❚${ipaddr}❚${scope}"
            else
              echo "   ❚ ❚ ❚ ❚ ❚${ipaddr}❚${scope}"
            fi
            ((n++))
          done < <(gawk -v scrub="${XSOS_SCRUB_IP_HN}" '
                       /inet6/ {
                           if (scrub == "y") print "⣿⣿⣿⣿:⣿⣿⣿⣿:⣿⣿⣿⣿:⣿⣿⣿⣿:⣿⣿⣿⣿:⣿⣿⣿⣿:⣿⣿⣿⣿:⣿⣿⣿⣿/⣿⣿⣿ " $4
                           else print $2,$4
                       }
                   ' <<<"${iface_input[$i]}")
        
        # Otherwise, print out all info with ipaddr set to "-"
        else
          echo "  ${i}❚${slaveof[$i]}❚${mac[$i]}❚${mtu[$i]}❚${state[$i]}❚-❚-"
        fi
        
      else
      
        # If $i has an ipv4 address, time to figure out what it is
        if grep -q "inet .* ${i%@*}\$" <<<"${iface_input[$i]}"; then
          
          # We could have more than one non-alias ip4addr...
          # So we need to set up a counter and do a loop
          n=0; while read ipaddr; do
            if [[ ${n} -eq 0 ]]; then
              echo "  ${i}❚${slaveof[$i]}❚${mac[$i]}❚${mtu[$i]}❚${state[$i]}❚${ipaddr}"
            else
              echo "   ❚ ❚ ❚ ❚ ❚${ipaddr}"
            fi
            ((n++))
          done < <(gawk -v scrub="${XSOS_SCRUB_IP_HN}" "
                        /inet .* ${i%@*}\$/ {
                            if (scrub == \"y\") print \"⣿⣿⣿.⣿⣿⣿.⣿⣿⣿.⣿⣿⣿/⣿⣿\"
                            else print \$2
                        }
                   " <<<"${iface_input[$i]}")
        
        # Otherwise, print out all info with ipaddr set to "-"
        else
          echo "  ${i}❚${slaveof[$i]}❚${mac[$i]}❚${mtu[$i]}❚${state[$i]}❚-"
          # ... And Continue on to the next interface, i.e., skip looking for aliases
          continue
        fi

        # If $i had an ipv4 addr, it's ALIAS time!
        if grep -q "inet .* ${i}:" <<<"${iface_input[$i]}"; then
        
          # For each "alias" (additional address) found ...
          for alias in $(gawk "/inet .* ${i}:/ {print \$NF}" <<<"${iface_input[$i]}" | sort -u); do
            ipv4_alias[$alias]=$(gawk -v scrub="${XSOS_SCRUB_IP_HN}" "
                                    /inet .* ${alias}\$/ {
                                        if (scrub == \"y\") print \"⣿⣿⣿.⣿⣿⣿.⣿⣿⣿.⣿⣿⣿/⣿⣿\"
                                        else print \$2
                                    }
                                 " <<<"${iface_input[$i]}" | sed -e '1!s/.*/   ❚ ❚ ❚ ❚ ❚&/')
            # The sed nonsense at the end of the above line allows for multiple new-style global addresses on top of an old-style alias (https://github.com/ryran/xsos/issues/103)
            # Thankfully we don't need to do a while loop like above because in the case of aliases we don't need to display mtu, state, mac

            # ... Print out a new line with its ipv4 addr
            # No extra columns at the end needed because they're added by sed in above line
            echo "  ${alias}❚ ❚ ❚ ❚ ❚${ipv4_alias[$alias]}"
          done
        fi
      
      fi
      
    done
  } |
  
    # All output from above needs to be columnized
    column -ts❚ |
    
      # And then we need to do some color funness!
      # This colorizes the first 2 lines with the H2 color and the interfaces with H3
      # Plus DOWN interfaces with Down color and up interfaces with Up color
      gawk -vH0="${c[0]}" -vH2="${c[H2]}" -vH3="${c[H3]}" -vU="${c[Up]}" -vD="${c[Down]}" '
        {
          if (NR <= 2) printf H2 $0
          else {
            if ($5 == "DOWN") printf D $0
            else if ($0 ~ /^  [[:graph:]]/) printf gensub(/(^  [[:graph:]]+ )/,  H3"\\1"U, 1)
            else printf U $0
          }
          print H0
        }'
  echo -en ${XSOS_HEADING_SEPARATOR}
}


ETHTOOL() {
  # Local vars:
  local changedir ethdevs i errsfound count ethindent multiqueue_header
  
  # If localhost, grab interfaces from /sys
  if [[ -z $1 ]]; then
    ethdevs=$(ls /sys/class/net | egrep -v 'lo|sit0|bonding_masters')
    # Setup local functions for ethtool & ethtool -i & ethtool -S
    __ethtool()   { ethtool $1; }
    __ethtool_i() { ethtool -i $1; }
    __ethtool_S() { ethtool -S $1 2>&1; }
    __ethtool_g() { ethtool -g $1 2>&1; }
    
  # If sosreport, determine interfaces from ethtool_<iface> files
  else
    changedir=1
    pushd "$1"/sos_commands/networking &>/dev/null
    ethdevs=$(ls ethtool_[[:alpha:]]* | cut -d_ -f2-)
    # Setup local functions for ethtool & ethtool -i & ethtool -S
    __ethtool()   { cat ethtool_$1; }
    __ethtool_i() { [[ -r ethtool_-i_$1 ]] && cat ethtool_-i_$1; }
    __ethtool_S() { [[ -r ethtool_-S_$1 ]] && cat ethtool_-S_$1 || echo "     Missing ethtool_-S file"; }
    __ethtool_g() { [[ -r ethtool_-g_$1 ]] && cat ethtool_-g_$1; }
  fi
  
  # If have ethdevs to work on ...
  if [[ -n $ethdevs ]]; then
    echo -e "${c[H1]}ETHTOOL${c[0]}"
    echo -e "${c[H2]}${XSOS_INDENT_H1}Interface Status:${c[0]}"
    for i in $ethdevs; do
      echo -e "${XSOS_INDENT_H2}$i❚$(__ethtool_i $i |
      gawk '
        BEGIN { pci = "PCI UNKNOWN" }
        /^bus-info:/ { pci = $2 }
        END { printf pci }
      '
      )❚$(__ethtool $i |
      gawk '
        /Link detected:/    { link = $3; sub(/yes/, "up", link); sub(/no/, "DOWN", link) }
        /Speed:/            { spd = $2 }
        /Duplex:/           { dup = tolower($2) }
        /Auto-negotiation:/ { aneg = $2; sub(/on/, "Y", aneg); sub(/off/, "N", aneg) }
        END {
          if (link == "up" && spd != "")
            linkdetails = " "spd" "dup" (autoneg="aneg")"
          else if (link == "")
            link = "UNKNOWN"
          printf "link=%s%s", link, linkdetails
        }
      '
      )❚$(__ethtool_g $i |
      gawk '
        /Pre-set maximums:/          { getline; if ($1 == "RX:") rx_max=$2 }
        /Current hardware settings:/ { getline; if ($1 == "RX:") rx_now=$2 }
        END {
          if (rx_now == "" && rx_max == "") {
            print "rx ring UNKNOWN"
            exit
          }
          else if (rx_now == "")
            rx_now = "?"
          else if (rx_max == "")
            rx_max = "?"
          printf "rx ring %s/%s\n", rx_now, rx_max
        }
      '
      )❚$(__ethtool_i $i |
      gawk -F: '
        BEGIN { driver="UNKNOWN"; drv_vers=""; fw_vers="UNKNOWN" }
        /^driver:/           { if ($2 !~ /^ *$/) driver=$2;   sub(/^ /, "", driver) }
        /^version:/          { if ($2 !~ /^ *$/) drv_vers=$2; sub(/^ /, " v", drv_vers) }
        /^firmware-version:/ { if ($2 !~ /^ *$/) fw_vers=$2;  sub(/^ /, "", fw_vers) }
        END { printf "drv %s%s / fw %s", driver, drv_vers, fw_vers }
      '
      )"
    done | column -ts❚ |
      gawk -vH0="${c[0]}" -vU="${c[Up]}" -vD="${c[Down]}" -vE="${c[Warn1]}" '
        /link=DOWN/     { print D $0 H0 }
        /link=up/       { print U $0 H0 }
        /link=UNKNOWN/  { print E $0 H0 }
      '
      
    echo -e "${c[H2]}${XSOS_INDENT_H1}Interface Errors:${c[0]}"
    echo -en "${c[Warn1]}"
    multiqueue_header='^[[:space:]]+[RT]x.Queue#:'
    for i in $ethdevs; do
      errsfound=
      ethindent=$(tr '[[:graph:]]'   ' ' <<<"$i ")
      if __ethtool_S $i | egrep -q "$XSOS_ETHTOOL_ERR_REGEX"; then
        [[ -n $count ]] && echo -e "${XSOS_INDENT_H2}${c[DGREY]}- - - - - - - - - - - - - - - - - - -"
        echo -en "${c[Warn1]}"
        errsfound=$(__ethtool_S $i |
          tac |
            gawk "
              BEGIN { found = 0 }
              /$XSOS_ETHTOOL_ERR_REGEX/ {
                print ; found = 1
              }
              /$multiqueue_header/ {
                if (found == 1) {
                  print ; found = 0
                }
              }
            " |
              tac
        )
        sed -e "1s/[[:space:]][[:graph:]]/$i &/" -e "1!s/^/$ethindent/" <<<"$errsfound"
        count+=1
      fi
    done
    [[ -z $count ]] && echo -e "${XSOS_INDENT_H2}${c[DGREY]}[None]"
    echo -en "${c[0]}"
    
    [[ -n $changedir ]] && popd &>/dev/null
  fi
  echo -en $XSOS_HEADING_SEPARATOR
}


SOFTIRQ() {
  # Local vars:
  local softirq_input_file suffix= backlog= budget=
  
  if [[ -f $1 ]]; then
    softirq_input_file=$1
  else
    softirq_input_file=$1/proc/net/softnet_stat
    if [[ ! -r $softirq_input_file ]]; then
      echo -e "${c[Warn2]}Warning:${c[Warn1]} '/proc/net/softnet_stat' unreadable; skipping softirq check${c[0]}" >&2
      echo -en $XSOS_HEADING_SEPARATOR >&2
      return
    fi
    backlog=$(cat "$1"/proc/sys/net/core/netdev_max_backlog 2>/dev/null) \
      && backlog=" (Current value: net.core.netdev_max_backlog = $backlog)" \
      || backlog=" (However, proc/sys/net/core/netdev_max_backlog is missing)"
    budget=$(cat "$1"/proc/sys/net/core/netdev_budget 2>/dev/null) \
      && budget=" (Current value: net.core.netdev_budget = $budget)" \
      || budget=" (However, proc/sys/net/core/netdev_budget is missing)"
  fi
  
  echo -e "${c[H1]}SOFTIRQ${c[0]}"
  
  gawk '{if (strtonum("0x" $2) > 0) exit 177}' "$softirq_input_file"
  
  if [[ $? -eq 177 ]]; then
    echo -e "${XSOS_INDENT_H1}${c[Warn1]}Backlog max has been reached, consider reviewing backlog tunable.${c[0]}$backlog"
  else
    echo -e "${XSOS_INDENT_H1}Backlog max is sufficient${c[0]}$backlog"
  fi
  
  
  gawk '{if (strtonum("0x" $3) > 0) exit 177}' "$softirq_input_file"
  if [[ $? -eq 177 ]]; then
    echo -e "${XSOS_INDENT_H1}${c[Warn1]}Budget is not sufficient, consider reviewing budget tunable.${c[0]}$budget"
  else
    echo -e "${XSOS_INDENT_H1}Budget is sufficient${c[0]}$budget"
  fi
  echo "${XSOS_INDENT_H1}(see https://access.redhat.com/solutions/1241943)"
  echo -en $XSOS_HEADING_SEPARATOR
}


NETDEV() {
  # Local vars:
  local netdev_input_file
  
  [[ -f $1 ]] && netdev_input_file=$1 || netdev_input_file=$1/proc/net/dev
  
  echo -e "${c[H1]}NETDEV${c[0]}"
  tail -n+3 "$netdev_input_file" | egrep -v 'lo:|sit0:' | sed 's,:, ,' |
    gawk -vu=$(tr '[:lower:]' '[:upper:]' <<<$XSOS_NET_UNIT) '
      function round(num, places) {
        places = 10 ^ places
        return int(num * places + .5) / places
      }
      {
        # Set variables based on fields
        
        Interface[$1] = $1
        RxBytes[$1]   = $2
        RxPackets[$1] = $3
        RxErrs[$1]    = $4
        RxDrop[$1]    = $5
        RxFifo[$1]    = $6
        RxFram[$1]    = $7
        RxComp[$1]    = $8
        RxMult[$1]    = $9
        RxTotal[$1]   = $3 + $4 + $5 + $6 + $7 + $8 + $9
        TxBytes[$1]   = $10
        TxPackets[$1] = $11
        TxErrs[$1]    = $12
        TxDrop[$1]    = $13
        TxFifo[$1]    = $14
        TxCols[$1]    = $15
        TxCarr[$1]    = $16
        TxComp[$1]    = $17
        TxTotal[$1]   = $11 + $12 + $13 + $14 + $15 + $16 + $17
        
        # Calculate percentages only if rx/tx packets gt 0
        
        if  (RxTotal[$1] > 0) {
          if  ($4 > 0) RxErrsPercent[$1] = "(" round($4  * 100 / RxTotal[$1],  0) "%)"
          if  ($5 > 0) RxDropPercent[$1] = "(" round($5  * 100 / RxTotal[$1],  0) "%)"
          if  ($6 > 0) RxFifoPercent[$1] = "(" round($6  * 100 / RxTotal[$1],  0) "%)"
          if  ($7 > 0) RxFramPercent[$1] = "(" round($7  * 100 / RxTotal[$1],  0) "%)"
          if  ($8 > 0) RxCompPercent[$1] = "(" round($8  * 100 / RxTotal[$1],  0) "%)"
          if  ($9 > 0) RxMultPercent[$1] = "(" round($9  * 100 / RxTotal[$1],  0) "%)"
        }
        if (TxTotal[$1] > 0) {
          if ($12 > 0) TxErrsPercent[$1] = "(" round($12 * 100 / TxTotal[$1], 0) "%)"
          if ($13 > 0) TxDropPercent[$1] = "(" round($13 * 100 / TxTotal[$1], 0) "%)"
          if ($14 > 0) TxFifoPercent[$1] = "(" round($14 * 100 / TxTotal[$1], 0) "%)"
          if ($15 > 0) TxColsPercent[$1] = "(" round($15 * 100 / TxTotal[$1], 0) "%)"
          if ($16 > 0) TxCarrPercent[$1] = "(" round($16 * 100 / TxTotal[$1], 0) "%)"
          if ($17 > 0) TxCompPercent[$1] = "(" round($17 * 100 / TxTotal[$1], 0) "%)"
        }
        
        # Figure out what number to divide by to end up with KiB, MiB, GiB, or TiB
        
        if      (u == "K") { bytes_divisor = 1024 }
        else if (u == "M") { bytes_divisor = 1024 ** 2 ; packets_divisor = 1000      ; Packets_Unit = " k" }
        else if (u == "G") { bytes_divisor = 1024 ** 3 ; packets_divisor = 1000 ** 2 ; Packets_Unit = " M" }
        else if (u == "T") { bytes_divisor = 1024 ** 4 ; packets_divisor = 1000 ** 2 ; Packets_Unit = " M" }
        
        # Figure out decimal precision
        
        if (u == "T")
          # For T, round Bytes field to nearest hundredth (.nn)
          Precision_Bytes = 2
          
        else if (u == "G")
          # For G, round Bytes field to nearest tenth (.n)
          Precision_Bytes = 1
          
        else
          # For K/M, keep Bytes as whole numbers
          Precision_Bytes = 0
        
        # Never show decimal for Packets
        Precision_Pckts = 0
        
        # If unit is anything but bytes, perform the necessary division
        
        if (u == "K" || u == "M" || u == "G" || u == "T") {
          U = u"iB"
          RxBytes[$1] /= bytes_divisor
          TxBytes[$1] /= bytes_divisor
        }
        
        # If unit is MiB, GiB, or TiB, perform division on packets as well
        
        if (u == "M" || u == "G" || u == "T") {
          RxPackets[$1] /= packets_divisor
          TxPackets[$1] /= packets_divisor
        }
        
        # Now that we have our numbers, time to do rounding
        
        RxBytes[$1]   = round(RxBytes[$1],   Precision_Bytes)
        TxBytes[$1]   = round(TxBytes[$1],   Precision_Bytes)
        RxPackets[$1] = round(RxPackets[$1], Precision_Pckts)
        TxPackets[$1] = round(TxPackets[$1], Precision_Pckts)
        
        # If U (pretty printing unit) was never set, it should be bytes
        
        if (U == "")
          U = "B"
      }
      
      END {
        print "  Interface❚Rx"U"ytes❚RxPackets❚RxErrs❚RxDrop❚RxFifo❚RxComp❚RxFrame❚RxMultCast"
        print "  =========❚=========❚=========❚======❚======❚======❚======❚=======❚=========="
        n = asorti(Interface, IF)
        for (i = 1; i <= n; i++) {
          printf "  %s❚",   IF[i]
          printf "%s❚",     RxBytes[IF[i]]
          printf "%s%s❚",   RxPackets[IF[i]], Packets_Unit
          printf "%s %s❚",  RxErrs[IF[i]],    RxErrsPercent[IF[i]]
          printf "%s %s❚",  RxDrop[IF[i]],    RxDropPercent[IF[i]]
          printf "%s %s❚",  RxFifo[IF[i]],    RxFifoPercent[IF[i]]
          printf "%s %s❚",  RxComp[IF[i]],    RxCompPercent[IF[i]]
          printf "%s %s❚",  RxFram[IF[i]],    RxFramPercent[IF[i]]
          printf "%s %s", RxMult[IF[i]],    RxMultPercent[IF[i]]
          printf "\n"
        }
        print "  Interface❚Tx"U"ytes❚TxPackets❚TxErrs❚TxDrop❚TxFifo❚TxComp❚TxColls❚TxCarrier "
        print "  =========❚=========❚=========❚======❚======❚======❚======❚=======❚=========="
        n = asorti(Interface, IF)
        for (i = 1; i <= n; i++) {
          printf "  %s❚",   IF[i]
          printf "%s❚",     TxBytes[IF[i]]
          printf "%s%s❚",   TxPackets[IF[i]], Packets_Unit
          printf "%s %s❚",  TxErrs[IF[i]],    TxErrsPercent[IF[i]]
          printf "%s %s❚",  TxDrop[IF[i]],    TxDropPercent[IF[i]]
          printf "%s %s❚",  TxFifo[IF[i]],    TxFifoPercent[IF[i]]
          printf "%s %s❚",  TxComp[IF[i]],    TxCompPercent[IF[i]]
          printf "%s %s❚",  TxCols[IF[i]],    TxColsPercent[IF[i]]
          printf "%s %s",  TxCarr[IF[i]],    TxCarrPercent[IF[i]]
          printf "\n"
        }
      }
    ' | column -ts❚ |
      gawk -vH0="${c[0]}" -vH2="${c[H2]}" -vH3="${c[H3]}" -vGREY="${c[DGREY]}" '
        {
          if (NR <= 2)
            print H2 $0 H0
          else if ($1 == "Interface") {
            print GREY "  - - - - - - - - - - - - - - - - -" H0
            print H2 $0 H0
          }
          else if ($1 == "=========")
            print H2 $0 H0
          else
            printf gensub(/(^  [[:graph:]]+ )/,   H3"\\1"H0, 1)"\n"
        }'

# Disabled this cuz ... well, it took up space and I had no evidence that anyone uses it
  if [[ -d $1 ]]; then
    echo -en $XSOS_HEADING_SEPARATOR
    echo -e "${c[H1]}SOCKSTAT${c[0]}"
    gawk -vS="  " -vH3="${c[H3]}" -vH0="${c[0]}" '
      { printf gensub(/^(.*:)/, S H3"\\1"H0, 1)"\n" }' <"$1/proc/net/sockstat"
  fi
  echo -en $XSOS_HEADING_SEPARATOR
}


CHECK_TAINTED() {
  # Local vars:
  local quote sys_tainted_status sys_kernel_version taint_states taintbit taintval indent t
  
  [[ $1 == --quote ]] && quote=1 || quote=
  
  sys_tainted_status=$(<"$2/proc/sys/kernel/tainted")
  sys_kernel_version=$(<"$2/proc/sys/kernel/osrelease")
  
  if [[ -n $quote ]]; then
    echo -en "\"$sys_tainted_status\"${c[0]}"
  else
    echo -en "$sys_tainted_status${c[0]}"
  fi

  if [[ $sys_tainted_status == 0 ]]; then
    echo "  (kernel untainted)"
    return
  else
    echo "  (see https://access.redhat.com/solutions/40594)"
  fi
    
  case $3 in
    H0) indent=                ;;
    H1) indent=$XSOS_INDENT_H1 ;;
    H2) indent=$XSOS_INDENT_H2 ;;
    H3) indent=$XSOS_INDENT_H3
  esac
  
  # See /usr/share/doc/kernel-doc*/Documentation/sysctl/kernel.txt
  #     kernel source: linux/kernel/panic.c
  #     kernel source: include/linux/kernel.h
  #     https://access.redhat.com/solutions/40594

  t[0]="PROPRIETARY_MODULE: Proprietary module has been loaded"
  t[1]="FORCED_MODULE: Module has been forcibly loaded"
  t[2]="UNSAFE_SMP: SMP with CPUs not designed for SMP"
  t[3]="FORCED_RMMOD: User forced a module unload"
  t[4]="MACHINE_CHECK: System experienced a machine check exception"
  t[5]="BAD_PAGE: System has hit bad_page"
  if grep -qs '^2\.6\.18-.*el5' <<<"$sys_kernel_version"; then
    t[6]="UNSIGNED_MODULE: Unsigned module has been loaded (RHEL5-specific)"
  else
    t[6]="USER: Userspace-defined naughtiness (RHEL6+)"
  fi
  t[7]="DIE: Kernel has oopsed before"
  t[8]="OVERRIDDEN_ACPI_TABLE: ACPI table overridden"
  t[9]="WARN: Taint on warning"
  t[10]="CRAP: Modules from drivers/staging are loaded"
  t[11]="FIRMWARE_WORKAROUND: Working around severe firmware bug"
  t[12]="OOT_MODULE: Out-of-tree module has been loaded"
  t[13]="UNSIGNED_MODULE: Unsigned module has been loaded"
  t[14]="SOFTLOCKUP: A soft lockup has previously occurred"
  t[15]="LIVEPATCH: Kernel has been live patched"
  t[16]="16: undefined"
  t[17]="17: undefined"
  t[18]="18: undefined"
  t[19]="19: undefined"
  t[20]="20: undefined"
  t[21]="21: undefined"
  t[22]="22: undefined"
  t[23]="23: undefined"
  t[24]="24: undefined"
  t[25]="25: undefined"
  t[26]="26: undefined"
  t[27]="BIT_BY_ZOMBIE: Kernel booted with OMGZOMBIES param"
  t[28]="HARDWARE_UNSUPPORTED: Hardware is unsupported"
  t[29]="TECH_PREVIEW: Technology Preview code is loaded"
  t[30]="RESERVED30: undefined"
  t[31]="RESERVED31: undefined"
  
  taint_states=$(
    for taintbit in $(sed 's, ,\n,g' <<<"${!t[@]}" | tac); do
      taintval=$((2**taintbit))
      if [[ $sys_tainted_status -gt $taintval ]]; then
        echo $taintbit
        sys_tainted_status=$((sys_tainted_status-taintval))
      elif [[ $sys_tainted_status == $taintval ]]; then
        echo $taintbit
        break
      fi
    done
  )
  
  for taintbit in $(tac <<<"$taint_states"); do
    printf "$indent%2s  ${t[$taintbit]}\n" $taintbit
  done
}


SYSCTL() {
  # Local vars:
  local pgsz hpgsz
  
  # VM PageSize (don't know how to find this from a sosreport, but I doubt that will often be a problem)
  [[ $1 == / ]] && pgsz=$(($(getconf PAGESIZE)/1024)) || pgsz=4     # Saved as KiB
  
  # HugePage size
  hpgsz=$(gawk '/Hugepagesize:/{print $2/1024}' <"$1/proc/meminfo")  # Saved as MiB
  
  __P() {
    echo -e "$XSOS_INDENT_H2${c[H3]}${1#*.} ${c[H4]}$2${c[H3]}=${c[Imp]}  $( [[ ! -f "$sosroot"/proc/sys/${1//.//} ]] && echo -e "${c[Warn1]}{sysctl not present}" || echo \"$(<"$sosroot"/proc/sys/${1//.//})\" )${c[0]}"
  }
  
  __Pa() {
    echo -e "$XSOS_INDENT_H2${c[H3]}${1#*.} ${c[H4]}$2${c[H3]}=${c[Imp]}  $( [[ ! -f "$sosroot"/proc/sys/${1//.//} ]] && echo -e "${c[Warn1]}{sysctl not present}" || gawk -vH0="${c[0]}" "$3" "$4" <"$sosroot"/proc/sys/${1//.//} )${c[0]}"
  }
  
  echo -e "${c[H1]}SYSCTLS${c[0]}"
  if grep -qsw rescue "$1/proc/cmdline"; then
    echo -e "${c[Warn2]}  WARNING: RESCUE MODE DETECTED${c[0]}"
    echo -e "${c[Warn1]}  sysctls below reflect rescue env; inspect sysctl.conf manually${c[0]}"
  fi
  
  echo -e "$XSOS_INDENT_H1${c[H2]}kernel.${c[0]}"
  [[ $XSOS_SCRUB_IP_HN == y ]] \
    && echo -e "$XSOS_INDENT_H2${c[H3]}hostname =  ${c[Warn2]}HOSTNAME SCRUBBED${c[0]}" \
    || __P kernel.hostname
  __P kernel.osrelease
  echo -e "$XSOS_INDENT_H2${c[H3]}tainted =${c[Imp]}  $(CHECK_TAINTED --quote "$1" H3)"
  __P kernel.random.boot_id
  __P kernel.random.entropy_avail "[bits] "
  __P kernel.hung_task_panic "[bool] "
  __Pa kernel.hung_task_timeout_secs ""  '{if ($1>0) printf "\"%s\"%s  (secs task must be D-state to trigger)", $1, H0; else printf "\"0\"%s  (khungtaskd disabled)", H0}'
  __P kernel.msgmax "[bytes] "
  __P kernel.msgmnb "[bytes] "
  __P kernel.msgmni "[msg queues] "
  __Pa kernel.panic "[secs] "  '{if ($1>0) printf "\"%s\"%s  (secs til autoreboot after panic)", $1, H0; else printf "\"0\"%s  (no autoreboot on panic)", H0}'
  __P kernel.panic_on_oops "[bool] "
  __P kernel.nmi_watchdog "[bool] "
  __P kernel.panic_on_io_nmi "[bool] "
  __P kernel.panic_on_unrecovered_nmi "[bool] "
  __P kernel.unknown_nmi_panic "[bool] "
  __P kernel.panic_on_stackoverflow "[bool] "
  __P kernel.softlockup_panic "[bool] "
  __P kernel.softlockup_thresh "[secs] "
  __P kernel.pid_max
  __P kernel.threads-max
  __Pa kernel.sem "[array] "  "-vS=$XSOS_INDENT_H3"  '{printf "\"%s  %s  %s  %s\"%s\n", $1,$2,$3,$4,H0; printf "%sSEMMSL (max semaphores per array) =  %d\n%sSEMMNS (max sems system-wide)     =  %d\n%sSEMOPM (max ops per semop call)   =  %d\n%sSEMMNI (max number of sem arrays) =  %d\n", S,$1, S,$2, S,$3, S,$4}'
  __Pa kernel.shmall "[$pgsz-KiB pages] "  "-vPGSZ=$pgsz"  '{printf "\"%s\"%s  (%.1f GiB max total shared memory)", $1, H0, $1*PGSZ/1024/1024}'
  __Pa kernel.shmmax "[bytes] "  '{printf "\"%s\"%s  (%.2f GiB max segment size)", $1, H0, $1/1024/1024/1024}'
  __Pa kernel.shmmni "[segments] "  '{printf "\"%s\"%s  (max number of segs)", $1, H0}'
  __Pa kernel.sysrq "[bitmask] "  '{if ($1==0) printf "\"0\"%s  (disallowed)", H0; else if ($1==1) printf "\"1\"%s  (all SysRqs allowed)", H0; else printf "\"%s\"%s  (see proc man page)", $1, H0}'
  __Pa kernel.sched_min_granularity_ns "[nanosecs] "  '{printf "\"%s\"%s  (%.5f sec)\n", $1, H0, $1*10^-9}'
  __Pa kernel.sched_latency_ns "[nanosecs] "  '{printf "\"%s\"%s  (%.5f sec)", $1, H0, $1*10^-9}'
  
  echo -e "$XSOS_INDENT_H1${c[H2]}fs.${c[0]}"
  __Pa fs.file-max "[fds] "  '{printf "\"%s\"%s  (system-wide limit for num open files [file descriptors])", $1,H0}'
  __Pa fs.nr_open  "[fds] "  '{printf "\"%s\"%s  (per-process limit for num open files [see also RLIMIT_NOFILE])", $1,H0}'
  __Pa fs.file-nr "[fds] "  '{printf "\"%s  %s  %s\"%s  (num allocated fds, N/A, num free fds)", $1,$2,$3,H0 }'
  __Pa fs.inode-nr "[inodes] "  '{printf "\"%s  %s\"%s  (nr_inodes allocated, nr_free_inodes)", $1,$2,H0}'
  
  echo -e "$XSOS_INDENT_H1${c[H2]}net.${c[0]}"
  __Pa net.core.busy_read "[microsec] "  '{printf "\"%s\"%s  ", $1, H0; if ($1==0) printf "(off)"}'
  __Pa net.core.busy_poll "[microsec] "  '{printf "\"%s\"%s  ", $1, H0; if ($1==0) printf "(off)"}'
  __P net.core.netdev_budget "[packets] "
  __P net.core.netdev_max_backlog "[packets] "
  __Pa net.core.rmem_default "[bytes] "  '{printf "\"%s\"%s  (%d KiB)", $1, H0, $1/1024}'
  __Pa net.core.wmem_default "[bytes] "  '{printf "\"%s\"%s  (%d KiB)", $1, H0, $1/1024}'
  __Pa net.core.rmem_max "[bytes] "  '{printf "\"%s\"%s  (%d KiB)", $1, H0, $1/1024}'
  __Pa net.core.wmem_max "[bytes] "  '{printf "\"%s\"%s  (%d KiB)", $1, H0, $1/1024}'
  __P net.ipv4.icmp_echo_ignore_all "[bool] "
  __P net.ipv4.ip_forward "[bool] "
  __Pa net.ipv4.ip_local_port_range "[ports] "  '{printf "\"%s  %s\"%s  (defines ephemeral port range used by TCP/UDP)", $1,$2,H0}'
  __Pa net.ipv4.ip_local_reserved_ports "[ports] "  '{printf "\"%s\"%s  (comma-separated ports/ranges to exclude from automatic port assignments)", $0,H0}'
  __Pa net.ipv4.tcp_max_orphans "[sockets] "  '{printf "\"%s\"%s  (%d MiB @ max 64 KiB per orphan)", $1, H0, $1*64/1024}'
  __Pa net.ipv4.tcp_mem "[$pgsz-KiB pages] "  "-vPGSZ=$pgsz"  '{printf "\"%s  %s  %s\"%s  (%.2f GiB, %.2f GiB, %.2f GiB)", $1, $2, $3, H0, $1*PGSZ/1024/1024, $2*PGSZ/1024/1024, $3*PGSZ/1024/1024}'
  __Pa net.ipv4.udp_mem "[$pgsz-KiB pages] "  "-vPGSZ=$pgsz"  '{printf "\"%s  %s  %s\"%s  (%.2f GiB, %.2f GiB, %.2f GiB)", $1, $2, $3, H0, $1*PGSZ/1024/1024, $2*PGSZ/1024/1024, $3*PGSZ/1024/1024}'
  __P net.ipv4.tcp_window_scaling "[bool] "
  __Pa net.ipv4.tcp_rmem "[bytes] "  '{printf "\"%s  %s  %s\"%s  (%d KiB, %d KiB, %d KiB)", $1, $2, $3, H0, $1/1024, $2/1024, $3/1024}'
  __Pa net.ipv4.tcp_wmem "[bytes] "  '{printf "\"%s  %s  %s\"%s  (%d KiB, %d KiB, %d KiB)", $1, $2, $3, H0, $1/1024, $2/1024, $3/1024}'
  __Pa net.ipv4.udp_rmem_min "[bytes] "  '{printf "\"%s\"%s  (%d KiB)", $1, H0, $1/1024}'
  __Pa net.ipv4.udp_wmem_min "[bytes] "  '{printf "\"%s\"%s  (%d KiB)", $1, H0, $1/1024}'
  __P net.ipv4.tcp_sack "[bool] "
  __P net.ipv4.tcp_timestamps "[bool] "
  __Pa net.ipv4.tcp_fastopen "[bitmap] " '{printf "\"%s\"%s  (", $1, H0; if ($1==0) printf "disabled"; else if ($1==1) printf "enable send"; else if ($1==2) printf "enable receive"; else if ($1==3 || $1==7) printf "enable send/receive"; else if ($1==4) printf "invalid value"; else printf "no logic for higher values"; if ($1==7) printf " + send regardless of cookies"; printf "; see ip-sysctl.txt)"}'
  __Pa net.ipv4.ipfrag_high_thresh "[bytes] "  '{printf "\"%s\"%s  (%d KiB)", $1, H0, $1/1024}'
  __Pa net.ipv4.ipfrag_low_thresh "[bytes] "  '{printf "\"%s\"%s  (%d KiB)", $1, H0, $1/1024}'
  __Pa net.ipv6.ip6frag_high_thresh "[bytes] "  '{printf "\"%s\"%s  (%d KiB)", $1, H0, $1/1024}'
  __Pa net.ipv6.ip6frag_low_thresh "[bytes] "  '{printf "\"%s\"%s  (%d KiB)", $1, H0, $1/1024}'

  echo -e "$XSOS_INDENT_H1${c[H2]}vm.${c[0]}"
  __Pa vm.dirty_ratio ""  '{if ($1>0) printf "\"%s\"%s  (%% of total system memory)", $1, H0; else printf "\"0\"%s  (disabled -- check dirty_bytes)", H0}'
  __Pa vm.dirty_bytes ""  '{if ($1>0) printf "\"%s\"%s  (%.1f MiB)", $1, H0, $1/1024/1024; else printf "\"0\"%s  (disabled -- check dirty_ratio)", H0}'
  __Pa vm.dirty_background_ratio ""  '{if ($1>0) printf "\"%s\"%s  (%% of total system memory)", $1, H0; else printf "\"0\"%s  (disabled -- check dirty_background_bytes)", H0}'
  __Pa vm.dirty_background_bytes ""  '{if ($1>0) printf "\"%s\"%s  (%.1f MiB)", $1, H0, $1/1024/1024; else printf "\"0\"%s  (disabled -- check dirty_background_ratio)", H0}'
  __P vm.dirty_expire_centisecs
  __P vm.dirty_writeback_centisecs
  __Pa vm.nr_hugepages "[$hpgsz-MiB pages] "   "-vHPGSZ=$hpgsz"  '{if ($1>0) printf "\"%s\"%s  (%.1f GiB total)", $1, H0, $1*HPGSZ/1024; else printf "\"%s\"%s", $1, H0}'
  __Pa vm.nr_overcommit_hugepages "[$hpgsz-MiB pages] "   "-vHPGSZ=$hpgsz"  '{if ($1>0) printf "\"%s\"%s  (%.1f GiB total)", $1, H0, $1*HPGSZ/1024; else printf "\"%s\"%s", $1, H0}'
  __Pa vm.overcommit_memory "[0-2] "   '{if ($1==0) printf "\"0\"%s  (heuristic overcommit)", H0; else if ($1==1) printf "\"1\"%s  (always overcommit, never check)", H0; else if ($1==2) print "\"2\"%s  (always check, never overcommit)", H0}'
  __P vm.overcommit_ratio
  __Pa vm.oom_kill_allocating_task "[bool] "  '{if ($1==0) printf "\"0\"%s  (scan tasklist)", H0; else printf "\"1\"%s  (kill OOM-triggering task)", H0}'
  __Pa vm.panic_on_oom "[0-2] "  '{if ($1==0) printf "\"0\"%s  (no panic)", H0; else if ($1==1) printf "\"1\"%s  (no panic if OOM-triggering task limited by mbind/cpuset)", H0; else if ($1==2) printf "\"2\"%s  (always panic)", H0}'
  __P vm.swappiness "[0-100] "
  echo -en $XSOS_HEADING_SEPARATOR
}


PSCHECK() {
  # Local vars:
  local ps_input_procs ps_input_thrds_raw ps_input_thrds num_sleepers_procs=? num_zombies_procs=? num_sleepers_thrds=? num_zombies_thrds=? ps_input noun top_threads_ps_header top_threads ps_header num_top_users num_comm_args num_process_lines process_line_length Dsleepers Zombies msg_sleepers_thrds msg_zombies_thrds top_users top_users_header
  
  # Get input from proper place dependent on what was passed
  if [[ -z $1 ]]; then
    ps_input_thrds_raw=$(ps auxm)
    ps_input_procs=$(ps aux)
  elif [[ -f $1 ]]; then
    # If passed a single file
    if [[ $XSOS_PS_THREADS == y ]]; then
      ps_input_thrds_raw=$(gawk '$1!="/bin/ps"{print}' <"$1")
    else
      ps_input_procs=$(gawk '$1!="/bin/ps"{print}' <"$1")
    fi
  else
    ps_input_thrds_raw=$(gawk '$1!="/bin/ps"{print}' <"$1/sos_commands/process/ps_auxwwwm")
    ps_input_procs=$(gawk '$1!="/bin/ps"{print}' <"$1/ps")
  fi
  # Need to protect any percent signs by doubling them up
  if [[ -n $ps_input_procs ]]; then
    ps_input_procs=$(sed '1!s/%/%%/g' <<<"$ps_input_procs")
    num_sleepers_procs=$(gawk 'BEGIN{n=0} $8~/D/{n++} END{print n}' <<<"$ps_input_procs")
    num_zombies_procs=$(gawk 'BEGIN{n=0} $8~/Z/{n++} END{print n}' <<<"$ps_input_procs")
  fi
  if [[ -n $ps_input_thrds_raw ]]; then
    ps_input_thrds_raw=$(sed '1!s/%/%%/g' <<<"$ps_input_thrds_raw")
    num_sleepers_thrds=$(gawk 'BEGIN{n=0} $8~/D/{n++} END{print n}' <<<"$ps_input_thrds_raw")
    num_zombies_thrds=$(gawk 'BEGIN{n=0} $8~/Z/{n++} END{print n}' <<<"$ps_input_thrds_raw")
    if [[ $XSOS_PS_THREADS != y ]]; then
      [[ $num_sleepers_thrds -gt $num_sleepers_procs ]] && msg_sleepers_thrds="\n$XSOS_INDENT_H2${c[Warn1]}Blocked threads detected; run with --threads option for full detail${c[0]}"
      [[ $num_zombies_thrds -gt $num_zombies_procs ]] && msg_zombies_thrds="\n$XSOS_INDENT_H2${c[Warn1]}Defunct threads detected; run with --threads option for full detail${c[0]}"
    fi
    # Threads in ps m output show with "-" for PID ($2) and COMMAND ($11), so let's fix that
    ps_input_thrds=$(
      gawk '
        {
          if ($2=="-") {
            $2 = pid; $11 = "[thread_of_pid_"pid"]"
          }
          else pid = $2
          print
        }
      ' <<<"$ps_input_thrds_raw"
    )
  fi
  
  if [[ $XSOS_PS_THREADS == y ]]; then
    noun="threads"
    ps_input=$ps_input_thrds
  else
    noun="processes"
    ps_input=$ps_input_procs
  fi
  
  # Verbosity? We den need no stinkin' verbosity!
  if [[ $XSOS_PS_LEVEL == 0 ]]; then
    # V-level 0: Less than default
    num_top_users=3
    num_comm_args=0
    num_process_lines=5
    process_line_length=100
  elif [[ -z $XSOS_PS_LEVEL || $XSOS_PS_LEVEL == 1 ]]; then
    # V-level 1: Default
    num_top_users=10
    num_comm_args=2
    num_process_lines=10
    process_line_length=150
  elif [[ $XSOS_PS_LEVEL == 2 ]]; then
    # V-level 2: Verbose
    num_top_users=30
    num_comm_args=10
    num_process_lines=30
    process_line_length=512
  elif [[ $XSOS_PS_LEVEL == 3 ]]; then
    # V-level 3: MOOOAAAARR
    num_top_users=60
    num_comm_args=1023
    num_process_lines=60
    process_line_length=2047  # This is the max that `column` can handle
  elif [[ $XSOS_PS_LEVEL == 4 ]]; then
    # V-level 4: Eerrryting
    num_top_users=
    num_comm_args=1023
    num_process_lines=
    process_line_length=2047  # This is the max that `column` can handle
  fi
  
  __conditional_head() {
  [[ -n $1 ]] &&
    echo head -n$1 ||
    echo cat
  }
  
  # First, we need to convert VSZ & RSS in the ps input to MiB or GiB (if necessary)
  # We also need to perfectly columnize the input and chop off extra command args based on above options
  _convert_and_columize() {
    gawk -vMAX_fields=$((num_comm_args+12)) -vu=$(tr '[:lower:]' '[:upper:]' <<<"$XSOS_PS_UNIT") '
      BEGIN {
        # Not going to worry about down-converting to bytes or up-converting to TiB
        if      (u == "B") u = "K"
        else if (u == "T") u = "G"
        else if (u == "K" || u == "G") u = u
        else u = "M"
        
        # Figure out what number to divide by to end up with KiB or MiB or GiB
        if      (u == "K") divisor = 1
        else if (u == "M") divisor = 1024
        else if (u == "G") divisor = 1024 ** 2
        
        # Set pretty printing unit
        U = u"iB"
      }
      NR==1 {
        if ($1=="USER")
          j = 0
        else if ($1=="#") {
          j = 1
          MAX_fields ++
        }
        fieldvsz = j + 5
        fieldrss = j + 6
        fieldtty = j + 7
        fieldcmd = j + 11
      }
      {
        # Print fields up through %MEM
        for (i=1; i<fieldvsz; i++)
          printf $i"❚"
        
        # Print fields VSZ & RSS
        for (i=fieldvsz; i<fieldtty; i++) {
          if      (NR == 1)  printf "%s-%s❚", $i, U
          else if (u == "G") printf "%.1f❚", $i/divisor
          else               printf "%.0f❚", $i/divisor
        }
        
        # Print fields up through TIME
        for (i=fieldtty; i<fieldcmd; i++)
          printf $i"❚"
        
        # For the last field (command) we need to chop things up
        for (i=fieldcmd; i<=NF && i<MAX_fields; i++)
          printf $i" "
        printf "\n"
      }
    ' <<<"$1" | cut -c-$process_line_length | column -ts❚ | sed "s,^,$XSOS_INDENT_H2,"
  }
  
  ps_input=$(_convert_and_columize "$ps_input")
  # Deal with header
  ps_header=$(head -n1 <<<"$ps_input")
  ps_input=$(tail -n+2 <<<"$ps_input")
  
  if [[ -n $ps_input_thrds_raw ]]; then
    # Let's get a count of how many threads each PID has
    top_threads=$(
      gawk '
        NR==1 {
          printf "# %s\n", $0
        }
        NR>1 {
          if ($2 ~ /^[0-9]+$/) {
            pid = $2
            line[pid] = $0
          }
          else if ($2 == "-") {
            nthreads[pid] ++
          }
          else
            pid = "NULL"
        }
        END {
          for (pid in line)
            printf ("%d %s\n", nthreads[pid], line[pid]) | "sort -rn"
        }
      ' <<<"$ps_input_thrds_raw"
    )
    top_threads=$(_convert_and_columize "$top_threads")
    top_threads_ps_header=$(head -n1 <<<"$top_threads")
    top_threads="${c[H3]}$top_threads_ps_header${c[0]}\n$(tail -n+2 <<<"$top_threads" | $(__conditional_head $num_process_lines))"
  else
    top_threads="$XSOS_INDENT_H2${c[DGREY]}[No thread info]${c[0]}"
  fi
  
  # Format and prepare sleeping/zombie processes
  Dsleepers=$(gawk -vcolor_warn="${c[Warn1]}" -vc_0="${c[0]}" '$8~/D/ {print color_warn $0 c_0}' <<<"$ps_input")
  Zombies=$(gawk -vc_grey="${c[DGREY]}" -vc_0="${c[0]}" '$8~/Z/ {print c_grey $0 c_0}' <<<"$ps_input")
  if [[ -n $Dsleepers ]]; then
    Dsleepers="${c[H3]}$ps_header${c[0]}\n$Dsleepers$msg_sleepers_thrds"
  else
    Dsleepers="$XSOS_INDENT_H2${c[DGREY]}[None]${c[0]}$msg_sleepers_thrds"
  fi
  if [[ -n $Zombies ]]; then
    Zombies="${c[H3]}$ps_header${c[0]}\n$Zombies$msg_zombies_thrds"
  else
    Zombies="$XSOS_INDENT_H2${c[DGREY]}[None]${c[0]}$msg_zombies_thrds"
  fi
  
  # Calculate top cpu-using & mem-using users
  if [[ $XSOS_PS_LEVEL < 3 ]]; then  # If verbosity level 0-2, restrict number of users shown
    # Process ps input to generate summary user-list of top-users
    top_users=$(
      gawk -vu=$(tr '[:lower:]' '[:upper:]' <<<"$XSOS_PS_UNIT") '
        BEGIN { print "USER❚%CPU❚%MEM❚RSS" }
        { pCPU[$1]+=$3; pMEM[$1]+=$4; sRSS[$1]+=$6 }
        END {
          # Figure out what number to divide by to end up with GiB
          if      (u == "K") divisor = 1024 ** 2
          else if (u == "M") divisor = 1024
          else if (u == "G") divisor = 1
          for (user in pCPU)
            # Only show if greater than 0% CPU and 0.1% MEM
            if (pCPU[user]>0 || pMEM[user]>0.1)
              printf "%s❚%.1f%%❚%.1f%%❚%.2f GiB\n", user, pCPU[user], pMEM[user], sRSS[user]/divisor
        }
      ' <<<"$ps_input" | column -ts❚ | sed "s,^,$XSOS_INDENT_H2,")
    # Grab header from the top
    top_users_header=$(head -n1 <<<"$top_users")
  
  else  # If verbosity level 3-4, show all users
    # Process ps input to generate summary user-list of top-users
    top_users=$(
      gawk -vu=$(tr '[:lower:]' '[:upper:]' <<<"$XSOS_PS_UNIT") '
        BEGIN { print "USER❚%CPU❚%MEM❚RSS" }
        { pCPU[$1]+=$3; pMEM[$1]+=$4; sRSS[$1]+=$6 }
        END {
          # Figure out what number to divide by to end up with GiB
          if      (u == "K") divisor = 1024 ** 2
          else if (u == "M") divisor = 1024
          else if (u == "G") divisor = 1
          for (user in pCPU)
            printf "%s❚%.1f%%❚%.1f%%❚%.2f GiB\n", user, pCPU[user], pMEM[user], sRSS[user]/divisor
        }
      ' <<<"$ps_input" | column -ts❚ | sed "s,^,$XSOS_INDENT_H2,")
    # Grab header from the top
    top_users_header=$(head -n1 <<<"$top_users")
  fi
  
  # Remove header from the top and sort everything else by %CPU, potentially trimming down list
  top_users=$(tail -n+2 <<<"$top_users" | sort -rnk2 | $(__conditional_head $num_top_users))
    ps_input=$(tail -n+2 <<<"$ps_input")
  
  # Print!
  echo -e "${c[H1]}PS CHECK${c[0]}
$XSOS_INDENT_H1${c[H2]}Total number of threads/processes:${c[0]} \n$XSOS_INDENT_H2${c[Imp]}$(tail -n+2 <<<"$ps_input_thrds" | wc -l) / $(tail -n+2 <<<"$ps_input_procs" | wc -l)${c[0]}
$XSOS_INDENT_H1${c[H2]}Top users of CPU & MEM:${c[0]} \n${c[H3]}$top_users_header${c[0]} \n$top_users
$XSOS_INDENT_H1${c[H2]}Uninteruptible sleep threads/processes ($num_sleepers_thrds/$num_sleepers_procs):${c[0]} \n$Dsleepers
$XSOS_INDENT_H1${c[H2]}Defunct zombie threads/processes ($num_zombies_thrds/$num_zombies_procs):${c[0]} \n$Zombies
$XSOS_INDENT_H1${c[H2]}Top CPU-using ${noun}:${c[0]} \n${c[H3]}$ps_header${c[0]} \n$(sort -rnk3 <<<"$ps_input" | $(__conditional_head $num_process_lines))
$XSOS_INDENT_H1${c[H2]}Top MEM-using ${noun}:${c[0]} \n${c[H3]}$ps_header${c[0]} \n$(sort -rnk6 <<<"$ps_input" | $(__conditional_head $num_process_lines))
$XSOS_INDENT_H1${c[H2]}Top thread-spawning processes:${c[0]} \n$top_threads"
  echo -en $XSOS_HEADING_SEPARATOR
}


#-------------------------------------------------------------------------------
# BLEH
# Eventually I'll probably replace all of this with a python loader.
# Python's argparse is so much better than dealing with all this crap.

# Used to check for existence of files on a sosreport and print errors to stderr
SOS_CHECKFILE() {
  local module firstfile
  # $1: module name, e.g. bios, os, cpu, mem
  # $2+: file names, i.e. potential files to be found in sosreport root
  module=$1; shift; firstfile=$1
  # If module needs to be called, check for files
  if [[ $(eval echo \$$module) == y ]]; then
    while [[ $# -gt 0 ]]; do
      # If ethtool module being called, do something specific
      if [[ $module == ethtool ]] && ls "$sosroot"/$1 &>/dev/null; then
          return  # Return successfully if ethtool files found
      # If file ends in slash, look for dir
      elif [[ $1 =~ /$ ]]; then
        [[ -d $sosroot/$1 ]] && return  # Return successfully if dir found
      else
        [[ -r $sosroot/$1 ]] && return  # Return successfully if file readable
      fi
      shift
    done
  else
    return  # If module doesn't need to be called, return success
  fi
  # If we're still here, a module for which we don't have files was requested -- warn
  echo -e "${c[Warn2]}Warning:${c[Warn1]} '$sosroot/$firstfile' file unreadable; skipping $module check${c[0]}" >&2
  echo -en $XSOS_HEADING_SEPARATOR >&2
  return 1
}

# Used to conditionally run certain functions when running on localhost
COND_RUN() {
  if [[ $2 == --require_root && $UID != 0 ]]; then
    echo -e "${c[Warn2]}Warning:${c[Warn1]} Need root access to run $1 command on localhost${c[0]}" >&2
    echo -en $XSOS_HEADING_SEPARATOR >&2
  elif command -v $1 &>/dev/null; then
    # The following tr command translates $1 to the uppercase function name, e.g. lspci --> LSPCI
    # In a BASHv4-only world, this could be done with simply: ${1^^}
    $(tr '[:lower:]' '[:upper:]' <<<"$1")
  else
    echo -e "${c[Warn2]}Warning:${c[Warn1]} $1 command not present in PATH${c[0]}" >&2
    echo -en $XSOS_HEADING_SEPARATOR >&2
  fi
}


# Create sub tempdir in /dev/shm (tons of bash constructs use TMPDIR)
[[ -d /dev/shm && -w /dev/shm ]] && parent=/dev/shm || parent=/tmp
export TMPDIR=$(mktemp -d -p $parent)
# Create tmp file for capturing stderr
stderr_file=$TMPDIR/stderr
# Remove temp dir when we're done
trap "rm -rf $TMPDIR 2>/dev/null" EXIT

{
  # Redirect stderr to temp file
  exec 7>&2 2>$stderr_file
  
  # If special options and files were provided ....
  if [[ $BASH_VERSINFO -ge 4 && -n ${sfile[*]} ]]; then
    [[ -r ${sfile[B]} ]] && DMIDECODE "${sfile[B]}"
    [[ -r ${sfile[C]} ]] && CPUINFO   "${sfile[C]}"
    [[ -r ${sfile[F]} ]] && INTERRUPT "${sfile[F]}"
    [[ -r ${sfile[M]} ]] && MEMINFO   "${sfile[M]}"
    [[ -r ${sfile[D]} ]] && STORAGE   "${sfile[D]}" --no-mpath
    [[ -r ${sfile[T]} ]] && MULTIPATH "${sfile[T]}"
    [[ -r ${sfile[L]} ]] && LSPCI     "${sfile[L]}"
    [[ -r ${sfile[R]} ]] && SOFTIRQ   "${sfile[R]}"
    [[ -r ${sfile[N]} ]] && NETDEV    "${sfile[N]}"
    [[ -r ${sfile[G]} ]] && BONDING   "${sfile[G]}"
    [[ -r ${sfile[I]} ]] && IPADDR    "${sfile[I]}"
    [[ -r ${sfile[P]} ]] && PSCHECK   "${sfile[P]}"

  # If SOSREPORT-ROOT provided, use that
  elif [[ -n $sosroot ]]; then
    SOS_CHECKFILE bios    {,sos_commands/kernel.}dmidecode     && DMIDECODE "$sosroot"
    SOS_CHECKFILE os      "proc/"                              && OSINFO    "$sosroot"
    SOS_CHECKFILE kdump   ""                                   && KDUMP     "$sosroot"
    SOS_CHECKFILE cpu     "proc/cpuinfo"                       && CPUINFO   "$sosroot"
    SOS_CHECKFILE intrupt "proc/interrupts"                    && INTERRUPT "$sosroot"
    SOS_CHECKFILE mem     "proc/meminfo"                       && MEMINFO   "$sosroot"
    SOS_CHECKFILE disks   "proc/partitions"                    && STORAGE   "$sosroot"
    SOS_CHECKFILE mpath   sos_commands/{devicemapper,multipath}/multipath_-v4_-ll \
                                                               && MULTIPATH "$sosroot"
    SOS_CHECKFILE lspci   "lspci"                              && LSPCI     "$sosroot"
    SOS_CHECKFILE ethtool "sos_commands/networking/ethtool*"   && ETHTOOL   "$sosroot"
    SOS_CHECKFILE softirq "proc/net/softnet_stat"              && SOFTIRQ   "$sosroot"
    SOS_CHECKFILE netdev  "proc/net/dev"                       && NETDEV    "$sosroot"
    SOS_CHECKFILE bonding "proc/net/bonding/"                  && BONDING   "$sosroot"
    SOS_CHECKFILE ip      "sos_commands/networking/ip_address" && {
                                                                  IPADDR    "$sosroot"
                                                                  XSOS_IP_VERSION=6
                                                                  IPADDR    "$sosroot"; }
    SOS_CHECKFILE sysctl  "proc/sys/"                          && SYSCTL    "$sosroot" 2>/dev/null
    SOS_CHECKFILE ps      "ps"                                 && PSCHECK   "$sosroot"
    
  # If no SOSREPORT-ROOT provided, run checks against local system
  else
    [[ -n $bios ]]    && COND_RUN dmidecode --require_root
    [[ -n $os ]]      && OSINFO /
    [[ -n $kdump ]]   && KDUMP /
    [[ -n $cpu ]]     && CPUINFO /
    [[ -n $intrupt ]] && INTERRUPT /
    [[ -n $mem ]]     && MEMINFO /
    [[ -n $disks ]]   && STORAGE /
    [[ -n $mpath ]]   && COND_RUN multipath --require_root
    [[ -n $lspci ]]   && COND_RUN lspci
    [[ -n $ethtool ]] && COND_RUN ethtool --require_root
    [[ -n $softirq ]] && SOFTIRQ /
    [[ -n $netdev ]]  && NETDEV /
    [[ -n $bonding ]] && BONDING /
    [[ -n $ip ]]      && IPADDR
    [[ -n $all ]]     && XSOS_IP_VERSION=6 IPADDR
    [[ -n $sysctl ]]  && SYSCTL / 2>/dev/null
    [[ -n $ps ]]      && PSCHECK

  fi
  
  # If sending output to less or more, let's just append stderr to stdout
  # If just outputting to term (cat), redirect fd2 to tty
  case $XSOS_OUTPUT_HANDLER in
    less*|more)  cat $stderr_file ;;
    cat)         exec 2>&7
  esac

} | $XSOS_OUTPUT_HANDLER

# If output going to term (cat), print stderr tmp file contents to stderr
[[ $XSOS_OUTPUT_HANDLER == cat ]] && cat $stderr_file >&2 || :