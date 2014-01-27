#!/usr/bin/perl

use Getopt::Long;
use Switch;

%wires = (
	'vnesh'		=> {'on' => 1, 'val' => 0},
	'flag'		=> {'on' => 1, 'val' => 0},
	'rez2'		=> {'on' => 1, 'val' => 0},
	'vzap2'		=> {'on' => 1, 'val' => 0},
	'sum'		=> {'on' => 1, 'val' => 0},
	'prznk'		=> {'on' => 1, 'val' => ""},
	'ind'		=> {'on' => 1, 'val' => 0},
	'vzap1'		=> {'on' => 1, 'val' => 0},
	'kop'		=> {'on' => 1, 'val' => ""},
	'rez1'		=> {'on' => 1, 'val' => 0},
	'a'			=> {'on' => 1, 'val' => ""},
	'ia'		=> {'on' => 1, 'val' => 0},
	'pr'		=> {'on' => 1, 'val' => ""},
	'sp'		=> {'on' => 1, 'val' => ""},
	'com'		=> {'on' => 1, 'val' => "", 'adr' => ""},
	'adrcom'	=> {'on' => 1, 'val' => 0},
	'm-ir'		=> {'on' => 1, 'val' => 0},
	'm-alu'		=> {'on' => 1, 'val' => 0},
	'adrcom+'	=> {'on' => 1, 'val' => 0},
	'm-uccom'	=> {'on' => 1, 'val' => 0}
);
%ops = (
	'00' => {'f' => 'запись', 'p' => '0', 'op' => '0', 'gogo' => '0'},
	'11' => {'f' => 'считывание', 'i' => '0', 'p' => '1', 'op' => '1', 'gogo' => '0'},
	'15' => {'f' => 'считывание ИА', 'i' => '1', 'p' => '1', 'op' => '1', 'gogo' => '0'},
	'02' => {'f' => 'запись в ИР', 'p' => '2', 'op' => '0', 'gogo' => '0'},
	'21' => {'f' => 'сложение', 'i' => '0', 'p' => '1', 'op' => '2', 'gogo' => '0'},
	'25' => {'f' => 'сложение с ИА', 'i' => '1', 'p' => '1', 'op' => '2', 'gogo' => '0'},
	'31' => {'f' => 'вычитание', 'i' => '0', 'p' => '1', 'op' => '3', 'gogo' => '0'},
	'FE' => {'f' => 'безусловный переход', 'p' => '4', 'op' => 'F', 'gogo' => '1'},
	'F0' => {'f' => 'переход при =0', 'p' => '4', 'op' => 'F'},
	'F1' => {'f' => 'переход при >0', 'p' => '4', 'op' => 'F'},
	'F4' => {'f' => 'переход при ф=0', 'p' => '4', 'op' => 'F'},
	'F5' => {'f' => 'переход при ф=1', 'p' => '4', 'op' => 'F'}, 
	'FF' => {'f' => 'останов', 'p' => '4', 'op' => 'F', 'gogo' => '0'}
);
%flags = ('start' => 1, 'vzap1' => 0, 'zam1' => 0, 'zam2' => 0, 'clean' => 0, 'op' => "", 'vib' => 0, 'zapp' => 1, 'gogo' => 0);
my @mem = ();
my $prog = "";
my ($uccom, $ir, $ron, $ronf, $rvv) = (0,0,0,"",0);
my $help = "Usage: proc.pl -f program [-c] [-t]\n\t-c redirects output to console\n\t-t writes memory and registers during execution\n";
my $temp = 0;
my $con = 0;

sub help{
	print $help;
	exit;
}
sub	txthex{ # to hex
	my $h = sprintf("%X", $_[0]);
	$h = '0'.$h if (length($h) < 2);
	return $h;
}
sub write_mem{
	my $wm = "";
	my $c = 0;
	foreach $i (0..@mem/16){
		$wm .= txthex($c).":";
		foreach $j (0..15){
			$wm .= " ".$mem[$c+$j];
		}
		$wm .= "\n";
		$c += 16;
	}
	return $wm;
}
sub	flag{
	if ($wires{'pr'}{'on'}){
		my $tt = "";
		$tt = "0" if $_[0] == 0;
		$tt = "1" if $_[0] != 0;
		$tt .= "1" if $_[0] > 0;
		$tt .= "0" if $_[0] <= 0;
		return	$tt;
	}
	return "";
}

if (!(@ARGV)){
	print $help;
	exit;
}
GetOptions("help" => \&help, # viewing help
	"file=s" => \$prog, # program
	"temp" => \$temp, # print mediate values
	"console" => \$con, # output to the console
);

open $p, "$prog" or die "Can not open file: $!"; # reading file
while (<$p>){ # reading commands & writing into mem
	next if ($_ eq "\n"); # empty string
	s/\s//g;
	tr/a-f/A-F/;
	for (my $i = 0; $i < length; $i += 2){
		push @mem, substr ($_, $i, 2);
	}
}
close $p or die "Error with closing file $prog";

if (!$con) {open $f, ">$prog"." result.txt" or die "Can not create file for results: $!";} # file for result
while (1){ # executing
	last if !($flags{'start'}); # got stop command
	$wires{'adrcom'}{'val'} = $uccom if $wires{'adrcom'}{'on'}; # uccom to mem
	if ($wires{'com'}{'on'}){ #mem to regcom
		$wires{'com'}{'val'} = $mem[$uccom];
		$wires{'com'}{'adr'} = $mem[$uccom+1].$mem[$uccom+2];
	}
	$wires{'kop'}{'val'} = $wires{'com'}{'val'} if $wires{'kop'}{'on'}; # regcom to deccom
	$wires{'ind'}{'val'} = $ir if $wires{'ind'}{'on'}; # ir value
	$wires{'a'}{'val'} = $wires{'com'}{'adr'} if $wires{'a'}{'on'}; # command address part
	$wires{'ia'}{'val'} = (hex ($wires{'a'}{'val'}) + $wires{'ind'}{'val'}) if $wires{'ia'}{'on'};# count ia
	$wires{'sp'}{'val'} = $mem[$wires{'ia'}{'val'}].$mem[$wires{'ia'}{'val'}+1] if $wires{'sp'}{'on'}; # mem to m1
	foreach my $k (keys %flags){ $flags{$k} = 0; } # flushing flags
	$flags{'start'} = 1 if ($wires{'kop'}{'val'} ne "FF");#deccom
	$flags{'vzap1'} = 1 if ($ops{$wires{'kop'}{'val'}}{'p'} == 3);#deccom
	$flags{'zam1'} = 1 if ($ops{$wires{'kop'}{'val'}}{'p'} == 1);#deccom
	$flags{'zam2'} = 1 if ($ops{$wires{'kop'}{'val'}}{'p'} != 3);#deccom
	$flags{'clean'} = 1 if !($ops{$wires{'kop'}{'val'}}{'p'} == 2 || $ops{$wires{'kop'}{'val'}}{'p'} == 3);#deccom
	$flags{'op'} = $ops{$wires{'kop'}{'val'}}{'op'};#deccom
	$flags{'vib'} = $ops{$wires{'kop'}{'val'}}{'i'};#deccom
	$flags{'zapp'} = 1 if !($ops{$wires{'kop'}{'val'}}{'p'});#deccom
	if ($wires{'m-alu'}{'on'}){ #multiplexor 1
		switch ($flags{'vib'}){
			case 0	{$wires{'m-alu'}{'val'} = hex($wires{'sp'}{'val'})}
			case 1	{$wires{'m-alu'}{'val'} = $wires{'ia'}{'val'}}
			case 2	{$wires{'m-alu'}{'val'} = $wires{'vnesh'}{'val'}}
		}
	}
	$wires{'sum'}{'val'} = $ron if $wires{'sum'}{'on'}; # ron value
	if ($wires{'rez1'}{'on'}){
		switch ($flags{'op'}){ #alu
			case "0" {$wires{'rez1'}{'val'} = $wires{'sum'}{'val'}};
			case "1" {$wires{'rez1'}{'val'} = $wires{'m-alu'}{'val'}}
			case "2" {$wires{'rez1'}{'val'} = $wires{'sum'}{'val'} + $wires{'m-alu'}{'val'}}
			case "3" {$wires{'rez1'}{'val'} = $wires{'sum'}{'val'} - $wires{'m-alu'}{'val'}}
			case "F" {$wires{'rez1'}{'val'} = $wires{'sum'}{'val'}}
		}
	}
	$wires{'pr'}{'val'} = flag($wires{'sum'}{'val'}) if ($wires{'pr'}{'on'}); #alu flags
	if ($flags{'zapp'}){ # write to mem
		$r = txthex($wires{'rez1'}{'val'});
		$r = "00".$r if length($r) == 2;
		$mem[$wires{'ia'}{'val'}] = substr ($r, 0, 2);
		$mem[$wires{'ia'}{'val'}+1] = substr ($r, 2, 2);
	}
	if ($flags{'zam1'}){ # setting ron | ronf
		$ron = $wires{'rez1'}{'val'};
	}
	else{
		$ronf = $wires{'pr'}{'val'};
	}
	$wires{'prznk'}{'val'} = $ronf if $wires{'prznk'}{'on'};
	$flags{'gogo'} = 1 if ((($wires{'prznk'}{'val'} =~ /0\w/) && ($wires{'kop'}{'val'} eq "F0")) ||
								(($wires{'prznk'}{'val'} =~ /\w1/) && ($wires{'kop'}{'val'} eq "F1"))||
								(($wires{'prznk'}{'val'} eq "0") && ($wires{'kop'}{'val'} eq "F4")) ||
								(($wires{'prznk'}{'val'} eq "1") && ($wires{'kop'}{'val'} eq "F5")) ||
								($wires{'kop'}{'val'} eq "FE"));#deccom
	if ($wires{'m-ir'}{'on'}){ # multiplexor 2 - val to ir
		if ($flags{'clean'}){
			$wires{'m-ir'}{'val'} = 0; 
		}
		else{
			$wires{'m-ir'}{'val'} = $wires{'rez1'}{'val'};
		}
	}
	$ir = $wires{'m-ir'}{'val'} if ($flags{'zam2'}); # changing ir
	$wires{'adrcom+'}{'val'} = $uccom + 3 if $wires{'adrcom+'}{'on'}; # to the next command
	if ($wires{'m-uccom'}{'on'}){ # multiplexor 3 - next to start
		if ($flags{'gogo'}){
			$wires{'m-uccom'}{'val'} = $wires{'ia'}{'val'};
		}
		else{
			$wires{'m-uccom'}{'val'} = $wires{'adrcom+'}{'val'};
		}
	}
	$uccom = $wires{'m-uccom'}{'val'};	# changing uccom
	foreach my $k (keys %wires){ $wires{$k}{'val'} = 0; } # flushing wires
	$wires{'com'}{'adr'} = 0;
	if ($temp){
		$str = "Memory:\n".write_mem()."\n\nRegisters:\n\tUCCOM\t\t$uccom\n\tIR\t\t$ir\n\tRON\t\t$ron\n\tRON_F\t\t$ronf\n\tRVV\t\t$rvv\n--------------------\n\n";
		if ($con) {print $str;}
		else {print $f $str;}
	}
}

$str = "\n=====FINAL STATE=====\n\nMemory:\n".write_mem()."\nRegisters:\n\tUCCOM\t\t$uccom\n\tIR\t\t$ir\n\tRON\t\t$ron\n\tRON_F\t\t$ronf\n\tRVV\t\t$rvv\nWires:\n";
map {$str .= "\t$_\t\t$wires{$_}{'on'}\n"} keys %wires;
if ($con) {print $str;}
else {print $f $str;}
if (!$con) {close $f or die "Error with closing file with results";}
