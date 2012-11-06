#!/usr/bin/perl -w
# nagios: -epn

#######################################################
#                                                     #
#  Name:    check_vmax                                #
#                                                     #
#  Version: 0.1.0                                     #
#  Created: 2012-11-06                                #
#  License: GPL - http://www.gnu.org/licenses         #
#  Copyright: (c)2012 ovido gmbh                      #
#  Author:  Rene Koch <r.koch@ovido.at>               #
#  URL: https://labs.ovido.at/monitoring              #
#                                                     #
#######################################################

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use Getopt::Long;

# for debugging only
use Data::Dumper;

# Configuration
# all values can be overwritten via command line options
my $symcfg	= "/usr/local/bin/symcfg";	# default path to symcfg
my $sid		= 97;				# default sid

# create performance data
# 0 ... disabled
# 1 ... enabled
my $perfdata	= 1;


# Variables
my $prog	= "check_vmax";
my $version	= "0.1";
my $projecturl  = "https://labs.ovido.at/monitoring/wiki/check_vmax";

my $o_verbose	= undef;	# verbosity
my $o_help	= undef;	# help
my $o_version	= undef;	# version
my $o_timeout	= undef;	# timeout
my $o_symcfg	= undef;	# symcfg binary
my $o_sid	= undef;	# symmetrix ID
my $o_warn;			# warning
my $o_crit;			# critical
my $o_check	= undef;

my %status	= ( ok => "OK", warning => "WARNING", critical => "CRITICAL", unknown => "UNKNOWN");
my %ERRORS	= ( "OK" => 0, "WARNING" => 1, "CRITICAL" => 2, "UNKNOWN" => 3);
my $statuscode  = undef;


#***************************************************#
#  Function: parse_options                          #
#---------------------------------------------------#
#  parse command line parameters                    #
#                                                   #
#***************************************************#

sub parse_options(){
  Getopt::Long::Configure ("bundling");
  GetOptions(
	'v+'	=> \$o_verbose,		'verbose+'	=> \$o_verbose,
	'h'	=> \$o_help,		'help'		=> \$o_help,
	'V'	=> \$o_version,		'version'	=> \$o_version,
	'l:s'	=> \$o_check,		'check:s'	=> \$o_check,
	's:s'	=> \$o_symcfg,		'symcfg:s'	=> \$o_symcfg,
	'S:i'	=> \$o_sid,		'sid:i'		=> \$o_sid,
	'w:f'	=> \$o_warn,		'warning:f'	=> \$o_warn,
	'c:f'	=> \$o_crit,		'critical:f'	=> \$o_crit
  );

  # process options
  print_help()		if defined $o_help;
  print_version()	if defined $o_version;

  $o_verbose = 0	if (! defined $o_verbose);
  $o_verbose = 0	if $o_verbose <= 0;
  $o_verbose = 3	if $o_verbose >= 3;

  $symcfg = $o_symcfg if defined $o_symcfg;
  $sid	  = $o_sid    if defined $o_sid;
  
  $o_warn = 90 unless defined $o_warn;
  $o_crit = 95 unless defined $o_crit;
}


#***************************************************#
#  Function: print_usage                            #
#---------------------------------------------------#
#  print usage information                          #
#                                                   #
#***************************************************#

sub print_usage(){
  print "Usage: $0 [-s <symcfg>] [-S <sid>] [-v] [-w <warn>] [-c <critical>] [-V] -l <check> \n"; 
}


#***************************************************#
#  Function: print_help                             #
#---------------------------------------------------#
#  print help text                                  #
#                                                   #
#***************************************************#

sub print_help(){
  print "\nEMC Symmetrix VMAX checks for Icinga/Nagios version $version\n";
  print "GPL license, (c)2012 - Rene Koch <r.koch\@ovido.at>\n\n";
  print_usage();
  print <<EOT;

Options:
 -h, --help
    Print detailed help screen
 -V, --version
    Print version information
 -s, --symcfg
    Path to symcfg binary (default: $symcfg)
 -S, --sid
    Unique Symmetrix ID (default: $sid)
 -l, --check
    Adapter/Power Supply Status/Thin Pool Usage Checks
    see $projecturl or README for details
    possible checks:
    adapter: get RF and RA adapter status
    psu: get power supply status
    thinpool: get thin pool usage
 -w, --warning=DOUBLE
    Value to result in warning status
 -c, --critical=DOUBLE
    Value to result in critical status
 -v, --verbose
    Show details for command-line debugging
    (Icinga/Nagios may truncate output)

Send email to r.koch\@ovido.at if you have questions regarding use
of this software. To submit patches of suggest improvements, send
email to r.koch\@ovido.at
EOT

exit $ERRORS{$status{'unknown'}};
}


#***************************************************#
#  Function: print_version                          #
#---------------------------------------------------#
#  Display version of plugin and exit.              #
#                                                   #
#***************************************************#

sub print_version{
  print "$prog $version\n";
  exit $ERRORS{$status{'unknown'}};
}


#***************************************************#
#  Function: main                                   #
#---------------------------------------------------#
#  The main program starts here.                    #
#                                                   #
#***************************************************#

# parse command line options
parse_options();

# symcfg commands
my $sym_adapter_ra	= $symcfg . " -sid " . $sid . " list -ra all";
my $sym_adapter_sa	= $symcfg . " -sid " . $sid . " list -sa all";
my $sym_psu		= $symcfg . " -sid " . $sid . " list -env_data";
my $sym_thinpool	= $symcfg . " -sid " . $sid . " list -pool -thin -mb";

# check if symcfg is executable
if (! -e $symcfg){
  print "VMAX: symcfg (path: $symcfg) isn't executable.\n";
  exit $ERRORS{$status{'unknown'}};
}

# What to check?
&print_unknown("missing") if ! defined $o_check;
&check_adapter	if $o_check eq "adapter";
&check_psu	if $o_check eq "psu";
&check_thinpool	if $o_check eq "thinpool";
&print_unknown($o_check);


#***************************************************#
#  Function check_adapter                           #
#---------------------------------------------------#
# Get status of FA and RA adapters.                 #
#                                                   #
#***************************************************#

sub check_adapter{

  my ($text, $verbtext) = undef;
  my $perfdata = "|";

  # get RA status
  ($text, $statuscode, $verbtext) = &get_adapter("ra");
  # status is ok if not defined, otherwise critical
  my $tmpstatus = $statuscode if defined $statuscode;
     $tmpstatus = "ok" if ! defined $statuscode;
  my $output = $text if defined $text;
     $output = $verbtext if defined $verbtext;

  # get SA status
  ($text, $statuscode, $verbtext) = &get_adapter("sa");
  $tmpstatus = $statuscode if defined $statuscode;
  $output .= $text if defined $text;
  $output .= $verbtext if defined $verbtext;

  chop $output;
  chop $output;
  exit_plugin($tmpstatus, $output . $perfdata);

}


#***************************************************#
#  Function get_adapter                             #
#---------------------------------------------------#
#  Get status of FA and RA adapters (# online)      #
#  ARG1: ra/sa                                      #
#***************************************************#

sub get_adapter{

  my ($return,$exec,$match,$field) = undef;
  if ($_[0] eq "ra"){
    $exec	= $sym_adapter_ra;
    $match	= "RF";
    $field	= 11;
  }elsif ($_[0] eq "sa"){
    $exec	= $sym_adapter_sa;
    $match	= "FA";
    $field	= 5;
  }else{
    &exit_plugin("unknown","function get_adapter called with unknown argument");
  }

  $return = `$exec`;
  &exit_plugin("unknown","symcfg exit code $?") if $? > 0;

  my ($online,$total,$text,$verbtext) = undef;

  for (split /^/, $return) {
    $_ =~ tr/ //s;
    $_ =~ s/^\s+//;

    # get lines which match RF* - e.g.
    #                                          Remote        Local    Remote        
    # Ident  Symb  Num  Slot  Type       Attr  SymmID        RA Grp   RA Grp  Status
    # RF-5H   05H  117     5  RDF-BI-DIR   -   000292602827   1 (00)   1 (00) Online

    # or FA* - e.g.
    # Ident  Symbolic  Numeric  Slot  Type          Status
    # FA-5E     05E      69       5   FibreChannel  Online

    if ($_ =~ /^$match/){
      chomp $_;
      my @tmp = split / /, $_;
      if ($tmp[$field] ne "Online"){
	$verbtext .= "$tmp[0] ($tmp[$field]) ";
      }else{
        $verbtext .= "$tmp[0] ($tmp[$field]) " if $o_verbose >= 1;
	$online++;
      }
      $total++;
    }
  }

  if ($total - $online eq 0){
    $text = "$online/$total $match Adapters Online; ";
  }else{
    my $text = "$online/$total $match Adapters Online";
    $verbtext = $text . ": " . $verbtext . "; ";
    $statuscode = "critical";
  }

  return ($text, $statuscode, $verbtext);

}


#***************************************************#
#  Function check_psu                               #
#---------------------------------------------------#
# Check status of power supplies and standby power  #
# supplies.                                         #
#***************************************************#

sub check_psu{

  my $return = `$sym_psu`;
  &exit_plugin("unknown","symcfg exit code $?") if $? > 0;

#  print $return;
  my %rethash;
  my $bay_name = undef;
  my $i=0;
  $statuscode = "ok";
  my $statustext = undef;

  for (split /^/, $return) {
    $_ =~ tr/ //s;
    $_ =~ s/^\s+//;
    if ($_ =~ /Bay Name/){
      my @tmp = split / /, $_;
      $bay_name = $tmp[3];
      chomp $bay_name;
      $i = 0;
    }

    # get status of power supplies
    # info: All Power Supplies can occur multiple times for System Bays
    if ($_ =~ /Power Supplies/){
      next if $_ =~ /Number/;
      if ($_ =~ /Standby Power Supplies/){
        my @tmp = split / /, $_;
	chomp $tmp[5];
        $rethash{$bay_name}{'standby'}[0] = $tmp[5];
	if ($tmp[5] ne "Normal"){
	  $statuscode = "critical";
	  $statustext .= "Bay $bay_name: Standby PSUs $tmp[5]; ";
        }
      }elsif ($_ =~ /All Power Supplies/){
        my @tmp = split / /, $_;
	chomp $tmp[4];
        $rethash{$bay_name}{'all'}[$i] = $tmp[4];
	if ($tmp[4] ne "Normal"){
	  $statuscode = "critical";
	  $statustext .= "Bay $bay_name: All PSUs $tmp[4]; ";
        }
	$i++;
      }
    }
  }

  $statustext = "All power supplies in status Normal." if $statuscode eq "ok";
  $statustext = "" if $o_verbose >= 1;
  my $perfdata = "|";

  # go through hash for status of all psu's
  if ($o_verbose >= 1){
    foreach my $bay (keys %rethash){
      $statustext .= "Bay $bay: Standby PSUs $rethash{$bay}{'standby'}[0], ";
      for (my $i=0;$i<@{ $rethash{$bay}{'all'} };$i++){
        $statustext .= "All PSUs $rethash{$bay}{'all'}[$i], ";
      }
      chop $statustext;
      chop $statustext;
      $statustext .= "; ";
    }
  }

  chop $statustext;
  exit_plugin($statuscode, $statustext . $perfdata);

}


#***************************************************#
#  Function check_thinpool                          #
#---------------------------------------------------#
# Get usage of all Pools.                           #
#                                                   #
#***************************************************#

sub check_thinpool{

  my $return = `$sym_thinpool`;
  &exit_plugin("unknown","symcfg exit code $?") if $? > 0;

  $statuscode = "unknown";
  my %rethash;

  for (split /^/, $return) {
    $_ =~ tr/ //s;
    $_ =~ s/^\s+//;
    
    # get lines which contain RAID - e.g.
    #              T T                                                        F   S
    #              y e                                                        u   t
    #  Pool        p c Dev   Dev             Total  Enabled     Used     Free ll  a
    #  Name        e h Emul  Config            MBs      MBs      MBs      MBs (%) te
    # ------------ - - ----- ------------ -------- -------- -------- -------- --- ---
    # EFD_Pool     T E FBA   RAID-5(7+1)   3944610  3944610  3684329   260281  93 Ena
    if ($_ =~ /RAID/){
      chomp $_;
      my @tmp = split / /, $_;

      # get status
      $statuscode = "critical"	if $tmp[9] >= $o_crit;
      $statuscode = "warning"	if $tmp[9] >= $o_warn && $statuscode ne "critical";
      $statuscode = "ok"	if $tmp[9] <  $o_warn && $statuscode ne "critical" && $statuscode ne "warning";

      # put result into hash
      $rethash{$tmp[0]} = $tmp[9];
    }
  }

  my $statustext = "";
  my $perfdata = "|";
  foreach my $pool (keys %rethash){
    $statustext .= "$pool $rethash{$pool}% used; ";
    $perfdata   .= "\'" . lc($pool) . "\'=$rethash{$pool}%;$o_warn;$o_crit ";
  }

  chop $statustext;
  exit_plugin($statuscode, $statustext . $perfdata);

}


#***************************************************#
#  Function print_unknown                           #
#---------------------------------------------------#
#  Prints an error message that the given check is  #
#  invalid and prints help page.                    #
#  ARG1: check                                      #
#***************************************************#

sub print_unknown{
  print "VMAX $status{'unknown'}: Unknown check ($_[0]) is given.\n" if $_[0] ne "missing";
  print "VMAX $status{'unknown'}: Missing check.\n" if $_[0] eq "missing";
  print_help;
  exit $ERRORS{$status{'unknown'}};
}


#***************************************************#
#  Function exit_plugin                             #
#---------------------------------------------------#
#  Prints plugin output and exits with exit code.   #
#  ARG1: status code (ok|warning|cirtical|unknown)  #
#  ARG2: additional information                     #
#***************************************************#

sub exit_plugin{
  print "VMAX $status{$_[0]}: $_[1]\n";
  exit $ERRORS{$status{$_[0]}};
}


exit $ERRORS{$status{'unknown'}};

