#!/usr/bin/perl

use strict;
use warnings;
use feature qw(say);

use Getopt::Long;
use Pod::Usage;

my ($file, $column_gi, $column_lineage, $keyword, $db);
my $usage = "\n\n$0 [options] \n

        -file           input file,
        -column_gi      a column number that the GI number in the input file is in
        -column_lineage a column number that the lineage information in the input file is in
        -keyword        a keyword that should be parsed from the lineage information
        -db             the database to use
        -help           show this message
";
#set up options

GetOptions(
        '-file=s'               =>\$file,
        'column_gi=i'           =>\$column_gi,
        'column_lineage=i'      =>\$column_lineage,
        'keyword=s'             =>\$keyword,
        'db=s'                  =>\$db,
        'help'                  =>sub {pod2usage($usage)},
) or die ($usage);
#set up options

unless ($file){
        die "Please provide a file: -file <file.txt>"
}
unless ($column_gi = 1){
        die "Please provide a column gi number: -column_gi <number>"
}
unless ($column_lineage = 4){
        die "Please provide a column lineage number: -column_lineage <number>"
}
unless ($db eq 'nr' || $db eq 'nt'){
        die "Please provide a correct database name: -db nr (or nt)"
}
unless ($keyword){
        die "Please provide a keyword"
}
#check if variables are provided. If not, die

my $inFH;
unless (open($inFH, '<', $file)){
        die "Can't open $file for reading!"
}
#write the file into filehandle

my $n =1;
while (<$inFH>){
        my @info = split("\t", $_);
        if ($info[4] =~ /$keyword\;/){
                say '>' . $n . "_" . $info[2] . "_[" . $info[3] . "]_" . $info[0];
                get_fasta($db, $info[0]);
                $n++;
        }
}
#print the information I want

sub get_fasta{
        my ($db, $gi) = @_;
        chomp;
        my $cli = 'blastdbcmd -db ' . $db . ' -entry ' .  $gi . ' -outfmt %s |';
        my $sysFH;
        unless (open ($sysFH,$cli)) {
                die "Can't open the system call ", $cli, "\n";
        }

        while(<$sysFH>){
                chomp;
                say $_;
        }
}
#get fasta information for the species I want
