#!/usr/bin/perl
#close STDERR;
use Sun::Solaris::Kstat;
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at
# http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
#
# zonestat: tool that displays each zone's usage of resources
#           that can be controlled.
#
# Concept, design, implementation: Jeff Victor, Sun Microsystems, Inc.
#
#  Versions:
#   1.0: Initial release
#   1.1: Group zones by resource pool, display in order of pool number
#   1.2: Provide total usage and physical capacity data, improve output precision
#   1.2.1: Various minor fixes:
#        * -h option to swap(1M) not available until S10 5/08 (request by GaelM)
#        * Change $update value for Solaris Nevada to 7
#        * Fixed bugs in CPU cap & FSS output
#        * Added -h (help) (request by ScottD)
#        * Added -P (easily parseable output) (request by JeffS)
#        * Inhibit command-line error messages
#   1.3: Moderately significant improvements:
#        * Limit zonename to 8 characters (request by KevinY)
#        * Clean up some small messes, improve performance
#        * Replace /bin/kstat with Perl Solaris Kstat module (reduced
#          elapsed time 0.05s per zone on 2.2GHz Core Duo)
#        * Get pool assignments dynamically instead of from zonecfg.
#        * Add $DEBUG to display commands being run
#   1.4: Moderately significant improvements:
#        * Bug: Update %shm_use properly
#        * RFE: Detect absence of SUNWpool, SUNWpool[dr] SUNWrcap[ru],
#          handle any absences well. (SUNWpoold in nv, not S10.)
#        * Bug: Didn't work correctly if pools svc was disabled.
#        * Bug: Don't assume that rcap is enabled.
#        * Bug: -lP produces human-readable, not machine-parseable output.
#        * Bug?: Detect and fail if zone != global or user != root
#        * RFE: Prepare for S10 update numbers past U6
#        * RFE: Add option to print entire name of zones with long names.
#          (request by GregK and EdO)
#        * RFE: Add timestamp (seconds) to machine-consumable output
#          (request by StefanP)  !! Changed output format!!
#        * RFE: improve performance and correctness by collecting CPU% with
#          DTrace instead of prstat (request by JeffV)
#
# Usage: zonestat [-h|lNP] [interval [count]]
#        -h: display usage summary
#        -l: display columns showing the configured limits
#        -P: display output in easily parseable format (assumes -l)
#        -N: display zone names longer than 8 characters
#
# Output (with -l):
#
#        |----Pool-----|------CPU-------|----------------Memory----------------|
#        |---|--Size---|-----Pset-------|---RAM---|---Shm---|---Lkd---|---VM---|
#Zonename| IT| Max| Cur| Cap|Used|Shr|S%| Cap|Used| Cap|Used| Cap|Used| Cap|Used
#-------------------------------------------------------------------------------
#  global  0D  66K    8       0.2   1 50      173M            16E    0  16E 318M
#   ozone  0D  66K    1  1.7  0.2   1 50 100M  31M  50M       30M    0 200M  26M
#   zone1  3P    4    4       0.0   1 HH 100M  44M  50M       30M    0 200M  40M
#twilight  5S    8    8  1.7  0.9  50 50 100M  54M  50M       30M    0 200M  45M
#   zone5  5S    8    8  1.7  0.9  50 50 100M  33M  50M       30M  100 200M  43M
#   zone2  6P    3    3       0.0   1 HH 100M  52M  50M       30M    0 200M  43M
#==TOTAL=            32       2.2         32G 387M                 100  48G 515M
#
# Explanation of output:
# Pool: Data about the pool in which the zone's processes run
#   IT: "ID" + "Type"
#     ID: Pool ID number, from poolstat
#     Type: Type of Pool: D=Default, P=Private ("temporary"), S=Shared
#   Size: Number of CPUs
#     Max: Configured for pool (-l)
#     Cur: Currently in pool
# CPU: Data about CPU usage or usage constraints
#   Cap: capped-cpu (-l)
#   Pset Used: amount of CPU 'power' used by the processes sharing the pset
#     in which the zone's processes run - compare to "Cap".
#   Shr: Number of FSS shares (-l)
#   S%: This zone's portion of all shares in all zones in this pool ('HH'=100) (-l)
# Memory: Data about memory usage or limits
#   RAM: Physical memory
#     Cap: capped-memory:physical (-l)
#    Used: RSS of zone
#   Shm: Shared memory
#     Cap: max-shm-memory (-l)
#    Used: amount of shared memory in use by this zone's processes
#   Lkd: Locked memory
#     Cap: capped-memory:locked (-l)
#    Used: amount of memory locked by this zone's processes
#   VM: Virtual memory
#     Cap: capped-memory:swap (-l)
#    Used: amount of virtual memory (RAM+Swap) in use by this zone's processes
# The special row marked "==TOTAL= displays a total or 'absolute maximum'
# value, depending on the object being measured, and the amount used across
# all zones, including the global zone.
#
# Ideas for Future:
#  * Use kernel patch level instead of /etc/release to detect feature
#    availability??
#  * Add -c: list zones that are configured, even if halted (like 'zoneadm list -c')
#  * Add -d: also display disk statistics (fsstat?)
#  * Add -n: also display network statistics
#  * Add -p: only show processor info, but show more, including:
#    * micro-state fields, 1-second sample of mpstat output,
#      poolstat's load factor
#    * queue length for the pset in which that zone resides
#    * one-character column showing the default scheduler for each pool/pset.
#  * Add '-m': only show memory-related info for each zone and its pool,
#    adding these:
#    * paging columns of vmstat (re, mf, pi, p, fr, de, sr)
#    * output of 'vmstat -p'
#    * free swap space
#  * Add optional [<zonename>] argument to limit output to one zone
#  * Report state transitions like mpstat does, e.g.
#    * Changes in pool configuration, new pools, deleted pools
#    * Changes in zone states: boot, halt
#  * Improve efficiency by re-writing in C or D.
#  * Improve robustness by handling error conditions better.

#
# Variables and arrays.
#
#  @znames: array of zone names. Index has no special meaning.
#  %pool:   name of zone's pool - from poolbind
#  %poolid: integer ID of zone's pool - from poolstat
#  %poolmembers: list of zones in each pool
#  @poolshares: total of FSS shares in all zone of a pool
#  %z_ptype:   type of pool: Private, Shared, Default - derived from zonecfg
#  %pset_cfg_min: minimum CPUs configured for this pool - from zonecfg, poolstat
#  %pset_cfg_max: maximum CPUs configured for this pool - from zonecfg, poolstat
#  %pset_cfg_cur:     current CPUs configured for this pool - from poolstat
#  %cpu_cap:       CPU cap - from prctl
#  %cpu_percent:   Percent of pool in use by this zone - from prstat
#  %cpu_shares:   FSS Shares configured - from prctl
#  %cpu_shrpercent: Portion of pool's shares in this zone - sum of zones' shares
#  $cpus_used_sum Total "CPU power" used, in CPUs
#  %rss_cap:      RAM cap - from rcapstat
#  %rss_use:      RAM used - from rcapstat if rcap enabled, prstat otherwise
#  $rss_use_sum   Total RAM used in system
#  %shm_cap:      Shared memory cap - from prctl
#  %shm_use:      Shared memory used - from ipcs
#  $shm_use_sum   Total shared memory used in system
#  @lkd_cap:      Amount of memory a zone can lock - from kstat lockedmem_zone
#  @lkd_use:      Amount of memory locked by a zone - from kstat lockedmem_zone
#  $lkd_use_sum   Total locked memory in system
#  @vm_cap:       VM cap - from kstat
#  @vm_use:       VM used - from kstat
#  $vm_use_sum   Total (RAM+swap) used in system

use Getopt::Std;

$DEBUG=0;

# Subroutine 'shorten' shortens integers that won't fit into 4 digits, for
# compact, predictable output columns. Example: 234,567==>234K.
# Note that 1K=1,000, not 1,024.
#
# Compute constants once.
$K=1000**1;
$M=1000**2;
$G=1000**3;
$T=1000**4;
$P=1000**5;
$E=1000**6;

sub shorten {
my $n=$_[0];
#if (!defined($n)) { $n=0; }
if ($n < 10)                 { $n = sprintf ("%1.1f", $n); }
if ($n >= 10   && $n < 1000) { $n = sprintf ("%d", $n); }
if ($n >= 1000 && $n < 9500) { $n = sprintf ("%1.1fK", $n/$K);}
if ($n >= 9500 && $n < $M) { $n = int(($n+500)/1000) . "K"; }
if ($n >= $M && $n < 9500000) { $n = sprintf ("%1.1fM", $n/$M);}
if ($n >= 9500000 && $n < $G) { $n = int(($n+500*$K)/$M) . "M"; }
if ($n >= $G && $n < 9500000000) { $n = sprintf ("%1.1fG", $n/$G);}
if ($n >= 9500000000 && $n < $T) { $n = int(($n+500*$M)/$G) . "G"; }
if ($n >= $T && $n < 9500000000000) { $n = sprintf ("%1.1fT", $n/$T); }
if ($n >= 9500000000000 && $n < $P) { $n = int(($n+500*$G)/$T) . "T"; }
if ($n >= $P && $n < 9500000000000000) { $n = sprintf ("%1.1fP", $n/$P);}
if ($n >= 9500000000000000 && $n < $E) { $n = int(($n+500*$T)/$P) . "P"; }
if ($n >= $E ) { $n = int(($n+500*$P)/$E) . "E"; }
$n=$n;
}

sub expand { # Assumes that the argument ends in a metric suffix!
my $n=$_[0];
$suffix=chop($n);
if ($suffix eq 'K' || $suffix eq 'k') {$n *= $K};
if ($suffix eq 'M' || $suffix eq 'm') {$n *= $M};
if ($suffix eq 'G' || $suffix eq 'g') {$n *= $G};
if ($suffix eq 'T' || $suffix eq 't') {$n *= $T};
if ($suffix eq 'P' || $suffix eq 'p') {$n *= $P};
if ($suffix eq 'E' || $suffix eq 'e') {$n *= $E};
$n=$n;
}

# A numeric sort subroutine.
sub numerically { $a <=> $b; }

# This script can only work in the global zone.
#
open (GZ, "/bin/zonename |");
  $z=<GZ>; chop($z);
  if ($z ne "global") {print "This script only works in the global zone.\n"; die;}
close GZ;

# Some of this only works for root users.
#
if ($> != 0) {
  print "You must be root to use zonestat.\n";
  die;
}

# Gather static info
#
if ($DEBUG) { print "/usr/sbin/prtconf\n"; }
open (MEM, "/usr/sbin/prtconf |");
while (<MEM>) {
  if (/Memory size: (\d+) Megabytes/) {
    $RAM=$1*1024*1024;
  }
}
close MEM;
if ($DEBUG) { print "/bin/pagesize\n"; }
open (PGSZ, "/bin/pagesize|");
  $pagesize=<PGSZ>;
close PGSZ;

# Get system info and tunable param's
#
if ($DEBUG) { print "/bin/echo 'pages_pp_maximum/D;segspt_minfree/D' | mdb -k\n"; }
open (MDB, "/bin/echo 'pages_pp_maximum/D;segspt_minfree/D' | mdb -k|");
while (<MDB>) {
  if (/pages_pp_maximum:\s+(\d+)/) {
     $lockable_mem=$RAM - $pagesize * $1;
  }
  if (/segspt_minfree:\s+(\d+)/) {
     $shareable_mem=$RAM - $pagesize * $1;
  }
}
close MDB;

#
# Process the command line
#
# Options...
$opt_h=0;
$opt_l=0;
$opt_N=0;
$opt_P=0;

getopts('hlNP');

if ($opt_P) { $opt_l = 0; }

# ...and [interval [count]]
$decrement=1; # Change to zero (below) if infinite loop
$count=1;     # Default
$interval=1;  # sleeptime between iterations
$doheader=1;  # Display a new header after 25 lines of data.

if ($#ARGV>=0 ) {
  $interval=shift(@ARGV);
  $decrement=0;
  if ($#ARGV>=0 && $ARGV[0]>0) {
    $count=$ARGV[0];
    $decrement=1;
  }
}

# U4 added several RM features
# U5 added CPU Caps
# For U0-U3, we show what you could be doing if you upgrade... ;-)

open (RELEASE, "/etc/release");
$rel=<RELEASE>;
close RELEASE;
if ($rel =~ /3\/05/)  { $update=1; }
if ($rel =~ /6\/06/)  { $update=2; }
if ($rel =~ /11\/06/) { $update=3; }
if ($rel =~ /8\/07/)  { $update=4; }
if ($rel =~ /5\/08/)  { $update=5; }
if ($rel =~ /10\/08/) { $update=6; }
if ($rel =~ /5\/09/)  { $update=7; }
if ($rel =~ /snv/)    { $update=20; }

open (POOLPKG, "/bin/pkginfo SUNWpool SUNWpoolr|");
while (<POOLPKG>) {
  if (/ SUNWpool /)  { $SUNWpool =1; }
  if (/ SUNWpoolr /) { $SUNWpoolr=1; }
}
close POOLPKG;
$POOLpkgs = $SUNWpool && $SUNWpoolr;
if ($update == 20) {
  open (POOLPKG, "/bin/pkginfo SUNWpoold |");
  while (<POOLPKG>) {
    if (/ SUNWpoold /) { $SUNWpoold=1; }
  }
  $POOLpkgs = $POOLpkgs && $SUNWpoold;
  close POOLPKG;
}

if ($update>3) {
  open (RCAPPKG, "/bin/pkginfo SUNWrcapr SUNWrcapu|");
  while (<RCAPPKG>) {
    if (/ SUNWrcapr /)  { $SUNWrcapr =1; }
    if (/ SUNWrcapu /)  { $SUNWrcapu =1; }
  }
  close RCAPPKG;
  $RCAPpkgs = $SUNWrcapr && $SUNWrcapu;
}

if ($opt_h) {
  print "
 Usage: zonestat [-h] | [-l|-P] [-N] [interval [count]]
        -h: usage information
        -l: display columns showing the configured limits
        -P: \"machine-parseable\" format: separate fields with colons
        -N: display long zone names instead of truncating them

 Output with -l option:
        |----Pool-----|------CPU-------|----------------Memory----------------|
        |---|--Size---|-----Pset-------|---RAM---|---Shm---|---Lkd---|---VM---|
Zonename| IT| Max| Cur| Cap|Used|Shr|S%| Cap|Used| Cap|Used| Cap|Used| Cap|Used

Pool: information about the Solaris Resource Pool to which the zone is assigned.
   I: Pool identification number for this zone's pool
   T: Type of pool: D=Default, P=Private (temporary), S=Shared
 Max: Maximum number of CPUs configured for this zone's pool
 Cur: Current number of CPUs configured for this zone's pool

CPU: information about CPU controls and usage
  Cap: CPU-cap for the zone
 Used: Amount of CPU power consumed by the zone recently
  Shr: Number of FSS shares assigned to this zone
   S%: Percentage of this pool's CPU cycles for this zone ('HH' = 100%)

Memory: information about memory controls and usage
 RAM: Physical memory information
   Cap: Maximum amount of RAM this zone can use
  Used: Amount of RAM this zone is using
 Shm: Shared memory information
   Cap: Maximum amount of shared memory this zone can use
  Used: Amount of shared memory this zone is using
 Lkd: Locked memory information
   Cap: Maximum amount of locked memory this zone can use
  Used: Amount of locked memory this zone is using
 VM: Virtual memory information
   Cap: Maximum amount of virtual memory this zone can use
  Used: Amount of virtual memory this zone is using

";
  exit;
}


#
# Initialize kstats
$kstat = Sun::Solaris::Kstat->new();

#
# Outer loop
#
for ($n=$count; $n>0; $n -= $decrement) {

$start = time;

# Nmaxznamelen and friends provide the -N feature.
$Nmaxznamelen = 8;

#
# Gather list of zones, their status and pool type and association.
if ($DEBUG) { print "/usr/sbin/zoneadm list -v\n"; }
open (NAMES, "/usr/sbin/zoneadm list -v|");
$znum=0;
while (<NAMES>) {
  if (/^\s+(\S+)\s+(\S+)/) {
    if ($1 eq "ID") { next; }
    $znames[$znum++]=$2;
    $zoneid{$2}=$1;
    if ($opt_N) {
      $zlen = length ($znames[$znum-1]);
      $Nmaxznamelen = $zlen > $Nmaxznamelen ? $zlen : $Nmaxznamelen;
    }
  }
}
close NAMES;

# Update vCPU count.
$total_cpus=0;
if ($DEBUG) { print "/usr/sbin/psrinfo \n"; }
open (PSR, "/usr/sbin/psrinfo |");
while (<PSR>) { $total_cpus++; }
close PSR;

# Are we using pools?
if ($POOLpkgs) {
  if ($DEBUG) { print "/usr/bin/svcs -H pools\n"; }
  open (POOLS, "/usr/bin/svcs -H pools|");
  $pools_enabled=<POOLS>;
  close POOLS;
}

# Does rcap exist and is it enabled?
if ($update>3 && $RCAPpkgs) {
  if ($DEBUG) { print "/usr/bin/svcs -H rcap\n"; }
  open (RCAP, "/usr/bin/svcs -H rcap|");
  $rcap_enabled=<RCAP>;
  close RCAP;
}

# Get pool minima, maxima, current sizes.
# Get pset ranges from poolstat
if ($pools_enabled =~ /online/) {
  if ($DEBUG) { print "/usr/bin/poolstat -r pset \n"; }
  open (POOLS, "/usr/bin/poolstat -r pset |");
  while (<POOLS>) {
    if (/^\s+(\d+)\s(\S+)\s+pset\s+(\S+)\s(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
      $poolid{$2} =$1;
      $poolname{$1} =$2;
      $psetname{$3} = $4;
      $pset_cfg_min{$2} = $5;
      $pset_cfg_max{$2} = $6;
      $pset_cfg_cur{$2} = $7;
    }
  }
  close POOLS;
} else {
  $poolid{"pool_default"} = 0;
  $pset_cfg_cur{"pool_default"} = $total_cpus;
}

# Collect mapping of zones to pools.
if ($DEBUG) { print "/bin/ps -eo zone,pset,pid,comm \| grep ' [z]*sched'\n"; }
open (ZSCHED, "/bin/ps -eo zone,pset,pid,comm \| grep ' [z]*sched'|");
while (<ZSCHED>) {
  if (/(\S+)\s+(\S+)\s+(\S+)\s+\S+/) {
    my $z=$1;
    $pset_zone{$z} = $2;
    $pid_sched{$z} = $3;
    if ($pset_zone{$z} eq "-") {
      $pset_zone{$z}="0";
      $z_ptype{$z} = "D";
    } elsif ($psetname{$2} =~ /^SUNWtmp_(\S+)/) {
      $z_ptype{$z} = "P";
    } else {
      $z_ptype{$z} = "S";
    }
  }
}
close ZSCHED;

foreach $z (@znames) {
  if ($pools_enabled =~ /online/) {
    if ($DEBUG) { print "/usr/sbin/poolbind -q $pid_sched{$z}\n"; }
    open (POOL, "/usr/sbin/poolbind -q $pid_sched{$z}|");
    while (<POOL>) {
      if (/(\S+)\s+(\S+)/) {
        $pool{$z} =  $2;
        $poolmembers{$pool{$z}} .= $z . ' ';
      }
    }
    close POOL;
  } else  {
    $pool{$z} = "pool_default";
    $poolmembers{0} .= $z . ' ';
  }
}


# Get amount of shared memory in use by each zone.
if ($DEBUG) { print "/usr/bin/ipcs -mbZ \n"; }
open(IPCS, "/usr/bin/ipcs -mbZ |");
while (<IPCS>) {
  if (/^m\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)\s+(\S+)/) {
    $shm_use{$2} += $1;
    $shm_use_sum += $1;
  }
}
close IPCS;

# Get amount and cap of memory locked by processes in each zone.
$kstat->update();
foreach my $z (keys(%zoneid)) {
  $statname = sprintf "lockedmem_zone_%d", $zoneid{$z};
  $lkd_use[$zoneid{$z}] = $kstat->{caps}{$zoneid{$z}}{$statname}{usage};
  $lkd_use_sum += $lkd_use[$zoneid{$z}];
  $lkd_cap[$zoneid{$z}] = $kstat->{caps}{$zoneid{$z}}{$statname}{value};

  $statname = sprintf "swapresv_zone_%d", $zoneid{$z};
  $vm_use[$zoneid{$z}] = $kstat->{caps}{$zoneid{$z}}{$statname}{usage};
  $vm_use_sum += $vm_use[$zoneid{$z}];
  $vm_cap[$zoneid{$z}] = $kstat->{caps}{$zoneid{$z}}{$statname}{value};
}


# For zones with RAM caps (U4+), get current values for RAM usage and Cap.
# Determine if all zones have caps: if not, need to use prstat to get mem usage.
if ($update>3) {
  if ($rcap_enabled =~ /online/) {
    if ($DEBUG) { print "/usr/bin/rcapstat -z 1 1\n"; }
    open (RCAP, "/usr/bin/rcapstat -z 1 1|");
    while (<RCAP>) {
      if (/^\s+\d+\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s+(\S+)/) {
        $zones_memcaps++;
        $mem=&expand($2);
        $rss_use{$1} = $mem;
        $rss_use_sum += $mem;
        $rss_cap{$1} = $3;
      }
    }
    close RCAP;
  }
}


# If needed, use prstat to get per-zone memory consumption.

if ( $update<4 || !$rcap_enabled || $zones_memcaps < $znum) {
  if ($DEBUG) { print "/bin/prstat -cZn 1 0 1\n"; }
  open (PRSTAT, "/bin/prstat -cZn 1 0 1|");
  do { $_ = <PRSTAT>; } until $_ =~ "^ZONEID";
  while (<PRSTAT>) {
    /\s+\d+\s+\d+\s+(\S+)\s+(\S+)\s+\S+\s+\S+\s+([0-9\.]+)% (\S+)/;
    $mem = &expand($2);
    $rss_use{$4} = $mem;
    $rss_use_sum += $mem;
  }
  close PRSTAT;
}

# Use DTrace to collect CPU% consumed per zone.
# It would be much more efficient to run DTrace once in the background and
# collect its output each time through the outer loop, but this would require
# a synchronization method of some kind.

# Get a significant sample size for CPU%
if ($interval < 10) { $cpu_interval = 1; }
else                { $cpu_interval = int($interval/2-1); }
$cpu_int_str = $cpu_interval . "s";

$script = "/usr/sbin/dtrace -i '
#pragma D option quiet

profile-1007hz
{ total_probes++; }

profile-1007hz
/arg1/
{ \@u[zonename]=sum(100) }

profile-1007hz
/arg0 && curthread->t_pri != -1/
{ \@k[zonename]=sum(100) }

profile:::tick-$cpu_int_str
{
  normalize(\@k,total_probes);
  normalize(\@u,total_probes);
  printa(\"CPU-System: %-32s %\@10d\\n\", \@k);
  printa(\"CPU-User:   %-32s %\@10d\\n\", \@u);
  exit(0);
}
'";

open (D, "$script |");
while (<D>) {
  if (/CPU-System:\s+(\S+)\s+(\d+)/) {  # System time
    $cpu_system{$1} = $2 * $total_cpus / $pset_cfg_cur{$pool{$1}};
  }
  if (/CPU-User:\s+(\S+)\s+(\d+)/) {  # User time
    $cpu_user{$1} = $2 * $total_cpus / $pset_cfg_cur{$pool{$1}};
  }
}
close D;

# For each zone, gather some caps.
if ($opt_l || $opt_P) {
  foreach $z (@znames) {
    my $priv=0; $system=0;

    if ($update>4) {
      if ($DEBUG) { print "/bin/prctl -Pi zone -n zone.cpu-cap $z\n"; }
      open(PRCTL, "/bin/prctl -Pi zone -n zone.cpu-cap $z|");
      while (<PRCTL>) {
        if (/.*privileged (\d+)/) {
          $cpu_cap{$z} = $1/100;
        }
      }
      close PRCTL;
    }

    if ($DEBUG) { print "/bin/prctl -Pi zone -n zone.cpu-shares $z\n"; }
    open(PRCTL, "/bin/prctl -Pi zone -n zone.cpu-shares $z|");
    while (<PRCTL>) {
      if (/.*privileged (\d+)/) {
        $cpu_shares{$z} = $1;
      }
    }
    close PRCTL;

    if ($DEBUG) { print "/bin/prctl -Pi zone -n zone.max-shm-memory $z\n"; }
    open(PRCTL, "/bin/prctl -Pi zone -n zone.max-shm-memory $z|");
    while (<PRCTL>) {
      if (/.*system (\d+)/) {  # Only use if no privileged entry.
        $system = $1;
      }
      if (/.*privileged (\d+)/) {
        $priv = $1;
      }
      $shm_cap{$z} = $priv ? $priv : $system;
    }
    close PRCTL;
  }
}

# Summarize shares per pool to display the minimum portion of a pool
# which can be used by that zone.
for $z (@znames) {
   $poolshares[$poolid{$pool{$z}}] = 0;
}
for $z (@znames) {
   $poolshares[$poolid{$pool{$z}}] += $cpu_shares{$z};
}


# Note that swap(1M) doesn't report memory pages that the kernel has locked.
if ($DEBUG) { print "/usr/sbin/swap -s\n"; }
open (SWAP, "/usr/sbin/swap -s|");
  while (<SWAP>) {
    if (/= (\S+) used, (\S+)/) {
      $VM=&expand($1) + &expand($2);
    }
  }
close SWAP;

# Now that all data manipulation is complete, modify output data
# to match field sizes.
$VM            = &shorten ($VM);
$rss_use_sum   = &shorten ($rss_use_sum);
$shm_use_sum   = &shorten ($shm_use_sum);
$lkd_use_sum   = &shorten ($lkd_use_sum);
$vm_use_sum    = &shorten ($vm_use_sum);
$lockable_mem  = &shorten ($lockable_mem);
$shareable_mem = &shorten ($shareable_mem);


foreach $z (@znames) {
# $pset_cfg_max{$pool{$z}} = &shorten ($pset_cfg_max{$pool{$z}});
  if ($cpu_shares{$z} > 999) { $cpu_shares{$z} = ">1K"; }
  $cpu_percent{$z}  = $cpu_system{$z} + $cpu_user{$z};
  $cpus_used_sum   += $cpu_percent{$z}*$pset_cfg_cur{$pool{$z}}/100,
  $rss_use{$z}      = &shorten ($rss_use{$z});
  $shm_cap{$z}      = &shorten ($shm_cap{$z});
  $shm_use{$z}      = &shorten ($shm_use{$z});
  $lkd_cap[$zoneid{$z}] = &shorten ($lkd_cap[$zoneid{$z}]);
  $lkd_use[$zoneid{$z}] = &shorten ($lkd_use[$zoneid{$z}]);
  $vm_cap[$zoneid{$z}]  = &shorten ($vm_cap[$zoneid{$z}]);
  $vm_use[$zoneid{$z}]  = &shorten ($vm_use[$zoneid{$z}]);
  if ($opt_l || $opt_P) {
    $sh_in_pool{$z}       =  int(100*$cpu_shares{$z}/$poolshares[$poolid{$pool{$z}}]);
  }
  if ($sh_in_pool{$z} == 100) { $sh_in_pool{$z} = 'HH'; }
}


#
# Display data
#         |----Pool-----|------CPU-------|----------------Memory----------------|
#         |---|--Size---|----------------|---RAM---|---Shm---|---Lkd---|---VM---|
# Zonename| IT| Max| Cur| Cap|Used|Shr|S%| Cap|Used| Cap|Used| Cap|Used| Cap|Used
#
# Data fields, ranges and sizes:
#   Zonename: 8 chars
#   PoolID: 2 chars. If >99, replace with HH
#   PoolType: 1 char.
#   Size:Max: 4 characters: 1-3 digits, optional suffix K, M, G, T, P, E
#   Size:Cur: 3 chars: "ddd"
#   CPU:Cap: 4 chars, one of "dddd", "d.dd", "dd.d"
#   CPU:Use: (same as CPU:Cap)
#   CPU:Shr: 3 chars. If >999, replace with ">1K"
#   CPU:Sh%: 2 chars. If =100, replace with 'H'
#   Memory:RAM:Cap: 4 chars: 1-3 digits, optional suffix K, M, G, T, P, E
#   Memory:RAM:Use: (same format as RAM:Cap)
#   Memory:Shm:Cap: (same format as RAM:Cap)
#   Memory:Shm:Use: (same format as RAM:Cap)
#   Memory:Lkd:Cap: (same format as RAM:Cap)
#   Memory:Lkd:Use: (same format as RAM:Cap)
#   Memory:VM:Cap: (same format as RAM:Cap)
#   Memory:VM:Use: (same format as RAM:Cap)

  $Nspaces = " " x $Nmaxznamelen;
  $Ndashes = "-" x $Nmaxznamelen;
  $NremZ   = " " x ($Nmaxznamelen - 8);
  $NremeqZ = "=" x ($Nmaxznamelen - 8);

if ($doheader) {
  $doheader=0;
  if ($update<5) {
    if ($opt_l) {
printf ("$Nspaces|----Pool-----|---CPU-----|----------------Memory----------------|\n");
printf ("$Nspaces|---|--Size---|Pset-------|---RAM---|---Shm---|---Lkd---|---VM---|\n");
printf ("Zonename$NremZ| IT| Max| Cur|Used|Shr|S%| Cap|Used| Cap|Used| Cap|Used| Cap|Used\n");
printf ("$Ndashes------------------------------------------------------------------\n");

    } elsif ($opt_P) {
printf ("Timestamp:Zonename:IT:Max:Cur:Used:Shr:S%:RAMCap:Used:ShmCap:Used:LkdCap:Used:VMCap:Used\n");
    } else {
printf ("$Nspaces|--Pool--|Pset|-------Memory-----|\n");
printf ("Zonename$NremZ| IT|Size|Used| RAM| Shm| Lkd| VM|\n");
printf ("$Ndashes----------------------------------\n");
    }
  } else {
    if ($opt_l) {
printf ("$Nspaces|----Pool-----|------CPU-------|----------------Memory----------------|\n");
printf ("$Nspaces|---|--Size---|-----Pset-------|---RAM---|---Shm---|---Lkd---|---VM---|\n");
printf ("Zonename$NremZ| IT| Max| Cur| Cap|Used|Shr|S%| Cap|Used| Cap|Used| Cap|Used| Cap|Used\n");
printf ("$Ndashes-----------------------------------------------------------------------\n");
    } elsif ($opt_P) {
printf ("Timestamp:Zonename:IT:Max:Cur:Cap:Used:Shr:S%:RAMCap:Used:ShmCap:Used:LkdCap:Used:VMCap:Used\n");
    } else {
printf ("$Nspaces|--Pool--|Pset|-------Memory-----|\n");
printf ("Zonename$NremZ| IT|Size|Used| RAM| Shm| Lkd| VM|\n");
printf ("$Ndashes----------------------------------\n");
    }
  }
} else {
  if (!$opt_P) { print ("--------\n"); }
}

$Nl=$Nmaxznamelen;  # Shorthand.

# Group the zones by pool and print the pools in numerical order.
foreach $p (sort numerically keys (%poolmembers)) {
  $zones = $poolmembers{$p};
  foreach $z (split (/ /, $zones)) {
    if ($lines++ > 25 && !$opt_P) { $doheader=1; $lines=0; }
    if ($update<5) {
      if ($opt_l || $opt_P) {
        if ($opt_l) {
          $format = "%${Nl}.${Nl}s %2s%1s %4s %4s %4.1f %3s %2s %4s %4s %4s %4s %4s %4s %4s %4s\n";
          printf ($format,
                $z, $poolid{$pool{$z}}, $z_ptype{$z},
                $pset_cfg_max{$pool{$z}}, $pset_cfg_cur{$pool{$z}},
                $cpu_percent{$z}*$pset_cfg_cur{$pool{$z}}/100,
                $cpu_shares{$z}, $sh_in_pool{$z},
                $rss_cap{$z}, $rss_use{$z}, $shm_cap{$z}, $shm_use{$z},
                $lkd_cap[$zoneid{$z}], $lkd_use[$zoneid{$z}],
                $vm_cap[$zoneid{$z}],  $vm_use[$zoneid{$z}]);
        } else {
          $format = "%s:%s:%s:%s:%s:%s:%.1f:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s\n";
          printf ($format,
                time, $z, $poolid{$pool{$z}}, $z_ptype{$z},
                $pset_cfg_max{$pool{$z}}, $pset_cfg_cur{$pool{$z}},
                $cpu_percent{$z}*$pset_cfg_cur{$pool{$z}}/100,
                $cpu_shares{$z}, $sh_in_pool{$z},
                $rss_cap{$z}, $rss_use{$z}, $shm_cap{$z}, $shm_use{$z},
                $lkd_cap[$zoneid{$z}], $lkd_use[$zoneid{$z}],
                $vm_cap[$zoneid{$z}],  $vm_use[$zoneid{$z}]);
        }
      } else {
        printf ("%${Nl}.${Nl}s %2s%1s %4s %4.1f %4s %4s %4s %4s\n",
                $z, $poolid{$pool{$z}}, $z_ptype{$z},
                $pset_cfg_cur{$pool{$z}},
                $cpu_percent{$z}*$pset_cfg_cur{$pool{$z}}/100,
                $rss_use{$z}, $shm_use{$z},
                $lkd_use[$zoneid{$z}],
                $vm_use[$zoneid{$z}]);
       }
    } else  {
      if ($opt_l || $opt_P) {
        if ($opt_l) {
          $format = "%${Nl}.${Nl}s %2s%1s %4s %4s %4.1f %4.1f %3s %2s %4s %4s %4s %4s %4s %4s %4s %4s\n";
          printf ($format,
                $z, $poolid{$pool{$z}}, $z_ptype{$z},
                $pset_cfg_max{$pool{$z}}, $pset_cfg_cur{$pool{$z}},
                $cpu_cap{$z}, $cpu_percent{$z}*$pset_cfg_cur{$pool{$z}}/100,
                $cpu_shares{$z}, $sh_in_pool{$z},
                $rss_cap{$z}, $rss_use{$z}, $shm_cap{$z}, $shm_use{$z},
                $lkd_cap[$zoneid{$z}], $lkd_use[$zoneid{$z}],
                $vm_cap[$zoneid{$z}],  $vm_use[$zoneid{$z}]);
        } else {
          $format = "%s:%s:%s:%s:%s:%s:%.1f:%.1f:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s\n",
          printf ($format,
                time, $z, $poolid{$pool{$z}}, $z_ptype{$z},
                $pset_cfg_max{$pool{$z}}, $pset_cfg_cur{$pool{$z}},
                $cpu_cap{$z}, $cpu_percent{$z}*$pset_cfg_cur{$pool{$z}}/100,
                $cpu_shares{$z}, $sh_in_pool{$z},
                $rss_cap{$z}, $rss_use{$z}, $shm_cap{$z}, $shm_use{$z},
                $lkd_cap[$zoneid{$z}], $lkd_use[$zoneid{$z}],
                $vm_cap[$zoneid{$z}],  $vm_use[$zoneid{$z}]);
        }
      } else {
        printf ("%${Nl}.${Nl}s %2s%1s %4s %4.1f %4s %4s %4s %4s\n",
                $z, $poolid{$pool{$z}}, $z_ptype{$z},
                $pset_cfg_cur{$pool{$z}},
                $cpu_percent{$z}*$pset_cfg_cur{$pool{$z}}/100,
                $rss_use{$z}, $shm_use{$z},
                $lkd_use[$zoneid{$z}],
                $vm_use[$zoneid{$z}]);
      }
    }
  }
}
#
# Display totals and maxima
#
    $lines++;
    if ($update<5) {
      if ($opt_l || $opt_P) {
        if ($opt_l) {
          $format = "==TOTAL=$NremeqZ --- ---- %4s %4.1f --- -- %4s %4s %4s %4s %4s %4s %4s %4s\n";
          printf ($format, $total_cpus, $cpus_used_sum,
                &shorten($RAM), $rss_use_sum, $shareable_mem, $shm_use_sum,
                $lockable_mem, $lkd_use_sum,
                $VM, $vm_use_sum);
        } else {
          $format = "%s:==TOTAL=:::%s:%.1f:::%s:%s:%s:%s:%s:%s:%s:%s\n";
          printf ($format, time, $total_cpus, $cpus_used_sum,
                &shorten($RAM), $rss_use_sum, $shareable_mem, $shm_use_sum,
                $lockable_mem, $lkd_use_sum,
                $VM, $vm_use_sum);
        }
      } else {
        printf ("==TOTAL=$NremeqZ --- %4s %4.1f %4s %4s %4s %4s\n",
                $total_cpus, $cpus_used_sum,
                $rss_use_sum, $shm_use_sum,
                $lkd_use_sum, $vm_use_sum);
      }
    } else  {
      if ($opt_l || $opt_P) {
        if ($opt_l) {
          $format = "==TOTAL=$NremeqZ --- ---- %4s ---- %4.1f --- -- %4s %4s %4s %4s %4s %4s %4s %4s\n";
          printf ($format, $total_cpus, $cpus_used_sum,
                &shorten($RAM), $rss_use_sum, $shareable_mem, $shm_use_sum,
                $lockable_mem, $lkd_use_sum,
                $VM,  $vm_use_sum);
        } else {
          $format = "%s:==TOTAL=:::%s::%.1f:::%s:%s:%s:%s:%s:%s:%s:%s\n";
          printf ($format, time, $total_cpus, $cpus_used_sum,
                &shorten($RAM), $rss_use_sum, $shareable_mem, $shm_use_sum,
                $lockable_mem, $lkd_use_sum,
                $VM,  $vm_use_sum);
        }
      } else {
        printf ("==TOTAL=$NremeqZ === %4s %4.1f %4s %4s %4s %4s\n",
                $total_cpus, $cpus_used_sum,
                $rss_use_sum, $shm_use_sum,
                $lkd_use_sum, $vm_use_sum);
      }
    }

if ($n>1) {
    if ($start + $interval <= time) { $sleep_time= 1; }
    else                            { $sleep_time= $interval - (time-$start); }
  sleep $sleep_time;
}

undef @znames;  # Handle zone transitions.
undef %poolmembers;
undef %rss_use;
undef %shm_use;
$cpus_used_sum=0;
$rss_use_sum=0;
$shm_use_sum=0;
$lkd_use_sum=0;
$vm_use_sum=0;
$total_cpus=0;
$zones_memcaps=0;

}
