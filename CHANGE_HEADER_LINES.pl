#!/usr/bin/perl

######################################################################
#The original data file contains GI number and its sequence.
#This program aims to replace the GI number by 
#the kingdom, phylum and the species name, without any spaces
#and keep the sequence for the construction of tree.
######################################################################

use strict;
use warnings;
use feature qw(say);

use Getopt::Long;
use Pod::Usage;

my $file;

my $usage = "\n$0 [options] \n
        -file   File to open
        -help   Show this messege
";

GetOptions(
        'file=s'        =>\$file,
        help            =>sub{pod2usage($usage);}
)or die ($usage);

unless ($file){
        die "\nProvide a file -file <file.txt>",$usage;
}

my $inFH;
unless (open ($inFH,'<',$file)){
        die "can't open ", $file, " for reading";
}

while(<$inFH>){
        chomp;
        my ($info, $gi, $seq);
        if ($_ =~ />(\d+)/){
                $gi = $1;
                $info = get_info_from_gi($gi);
                say ">" . $info . "_" . $gi;
        }elsif($_ =~ /(\w+)/g){
                $seq = $1;
                say $seq;
        }
}#replace the GI number by the kingdom, phylum and the species name and keep the sequence, then print out

sub get_info_from_gi {
        my ($gi) = @_;
        chomp $gi;
        my $info;

        my $cli = "blastdbcmd -db nr -entry " . $gi .
                      ' -outfmt "%K %S" -target_only | ';

        my $sysFH;
        unless (open ($sysFH, $cli)){
                die "can't open the system call ", $cli, "\n";
        }
        while(<$sysFH>){
                chomp;
                $info = $_;
                $info =~ s/\s/\_/g;
        }
        close $sysFH;
        return $info;
}#get the kingdom, phylum and the species name
