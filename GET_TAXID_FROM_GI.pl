#!/usr/bin/perl

use strict;
use warnings;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;

my $file;
my $db;
my $usage = "\n$0 [options] \n

Options:

e.g. usage: perl $0 -file NP_001319.nr.blastp.xml.parsed.gi \
-db nr >NP_001319.nr.blastp.xml.parsed.gi.taxID.txt

        -file   File with gi numbers - one on each file
        -db     Blast database to use e.g. nr or nt
        -help   Show this message

";

GetOptions(
        'file=s'        =>\$file,
        'db=s'          =>\$db,
        help            => sub { pod2usage($usage) },
) or die($usage);
#set up options

unless ($file){
        die "\nProvide a file with gi numbers - one on each line, -file <infile.txt>",
        $usage;
}

unless ($db){
        die "\nBlast database to use e.g. nr or nt, -db <nr>", $usage;
}
#check if values of option are provided. If not, die

my $inFH;
unless (open ($inFH, '<', $file)){
        die "can't open $file", $! ;
}

say join("\t", "Taxon Id", "Common Name", "Scientific Name");
#print the headline

while(<$inFH>){
        my $gi = $_;
        if ($gi !~ /\d+/){
                say STDERR "This is not a gi (", $gi, "), skipping\n";
                next;
        }
        my ($taxon_id, $common_name,$scientific_name) = getTaxidFromGi($gi, $db);
        say join ("\t", $taxon_id, $common_name, $scientific_name);
}
close $inFH;
#print the information I need

sub getTaxidFromGi{
        my ($gi, $db) = @_;
        chomp $gi;
        my $cli = 'blastdbcmd -db ' . $db . ' -entry ' .  $gi . ' -outfmt "NCBI Taxonomy id: %T; Common name: %L; Scientific name: %S" -target_only | ';

        my $sysFH;
        my ($taxon_id, $common_name,$scientific_name) = ("NA", "NA", "NA");
        unless (open($sysFH, $cli)){
                die "Can't open the system call ", $cli, "\n";
        }
        while(<$sysFH>){
                chomp;
                if ($_ =~ /NCBI Taxonomy ID:\s+(\d+)/i){
                        $taxon_id = $1;
                }
                if ($_ =~ /Common Name:\s+(.*?);/i){
                        $common_name = $1;
                }
                if ($_ =~ /Scientific Name:\s(.*)/i){
                        $scientific_name = $1;
                }
                my ($taxon_id, $common_name, $scientific_name);
        }
        close $sysFH;
        return ($taxon_id, $common_name, $scientific_name);
}
#get taxon ID, common name and scientific name
