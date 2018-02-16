#!usr/bin/perl

use warnings;
use strict;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;
use Bio::DB::EUtilities;

my $file;
my $db ;

my $usage = "\n$0 [options] \n
	-file	File to open
	-db	Blast database to use e.g. nr or nt
	-help	Show this message
";#provide options

GetOptions(
	'file=s'	=>\$file,
	'db=s'		=>\$db,
	help		=>sub {pod2usage($usage);}
)or die ($usage);

unless($file){
	die "\nProvide a file with gi numbers -file <file.txt> ", $usage;
}
unless($db){
	die "\nProvide a database name -db nr or nt", $usage;
}#check options. If not provided, die

my $user_name = `whoami`;
chomp $user_name;
my $dir_name = '/home/' . $user_name . '/BIOL6309/LAB_3/TAX_ID_XML_DATA';
unless (-e $dir_name){
	`mkdir -p $dir_name`;
}#create a directory

my $inFH;
unless (open ($inFH, '<', $file)) {
	die "can't open ", $file, " for reading";
}

say join("\t", "Taxon ID", "Commom Name", "scientific Name", "Lineage");
while (<$inFH>){
	chomp $_;
	if ($_ =~ /(\d+)/){
		my $gi = $1;
		my ($taxon_id, $common_name, $scientific_name) = get_taxID_from_gi($gi, $db);
		my $lineage = get_lineage($taxon_id);
		print "$taxon_id\t$common_name\t$scientific_name\t$lineage\n";
	}
}#read gi line by line, parse the information and print out

sub get_taxID_from_gi{#get the taxon ID, common name and scientific name
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

sub get_lineage{#get lineage information
	my $lineage = "NA";
	my $gi;
	my ($taxon_id) = @_;
	my $factory = Bio::DB::EUtilities->new(
			-eutil	=>	'efetch',
			-db	=>	'taxonomy',
			-id	=>	$taxon_id,
			-email	=>	'zhai.we@husky.neu.edu',
			-tool	=>	'get_tax_xml',
	);
	my $file_new;
	my $FH;
	$file_new = $dir_name . '/tax_id.' . $taxon_id . '.xml';
	if (-s $file_new){
		say STDERR "Data existed";
		next;
	}else{
		$factory->get_Response( -file => $file_new);
		say STDERR "Fetching the data from NCBI for taxid: ", $taxon_id;
		sleep(1);

	        unless (open ($FH, '<', $file_new)){
        	        die "Can't open the file ", $file_new, " for reading:", $!
	        }

	        while (<$FH>){
        	        chomp;
                	if ($_ =~ /<Lineage>(.*)<\/Lineage>/){
                        	$lineage = $1;
        	        }
        	}
		return $lineage;
		close $FH;
	}
}
close $inFH;
