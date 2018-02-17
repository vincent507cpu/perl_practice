#!usr/bin/perl
#I borrowed somebody's idea to wrap up this script

use warnings;
use strict;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;
use Bio::DB::EUtilities;

my $file;
my $downloadOption = 0;

my $usage = "\n$0 [options] \n

        -file           File to open
        -downloadOption By default is 0, if you use 1, it will download the life regardless of weather the file exists or not
        -help           Show this message

";

GetOptions(
        'file=s'                =>\$file,
        'downloadOption=i'      =>\$downloadOption,
        help            =>sub {pod2usage($usage);}
)or die ($usage);
#set up options

unless($file){
        die "\nProvide a file with gi numbers -file <file.txt> ", $usage;
}

if ($downloadOption != 0 and $downloadOption != 1){
        die "Only recognize dowload option 1 or 0. Use a 1 in you want to download\n" ,
            "XML files which have previously been downloaded (updated XML files", $usage;
}
#check if the values of option are provided. If not, die

get_taxonomy_report($file, $downloadOption);

sub get_taxonomy_report{
        my ($file, $downloadOption) = @_;
        my $lineage;

        my $output_dir = create_download_dir();

        say join("\t", 'Tax_ID', 'Common_Name', 'Scientific_Name');

        my $FH;
        unless (open ($FH, '<', $file)) {
                die "can't open ", $file, " for reading";
        }

        while (<$FH>){
                chomp $_;
                my (@data) = split/\t/, $_;
                my $taxID = $data[1];
                if ($taxID !~ /\d+/){
                        print STDERR "This does not appear to be a taxid (", $taxID, ")\n";
                        next;
                }

                my %lineage;
                if (exists $lineage{$taxID}) {
                        $lineage = $lineage{$taxID};
                }else{
                        my $xmlfile = get_taxon_xml_file($taxID, $output_dir, $downloadOption);
                        if (! $xmlfile){
                                next;
                        }

                        $lineage = parse_xml_file($xmlfile);
                        $lineage{$taxID} = $lineage;
                }
                push @data, $lineage;
                say join("\t", @data);
        }
        close $FH;
}

sub create_download_dir {
        my $username = `whoiai`;
        chomp $username;
        my $output_dir;
        if (-e '/home/$suername'){
                $output_dir = join ("/", "/home", $username, 'BIOL6309/LAB_4/TAX_ID_XML_DATA');
        }elsif (-e '/Users'){
                $output_dir = join ("/", "Users", $username, 'BIOL6309/LAB_4/TAX_ID_XML_DATA');
        }else{
                die "Cannot process with making this directory";
        }
        if (!(-e $output_dir)){
                my @arr = split/ /, "mkdir -p $output_dir";
                system(@arr) == 0 or die "Problem with system call: ", join(" ",@arr);
        }
        return $output_dir;
}

sub get_taxon_xml_file {
        my ($taxID, $dir, $dl) = @_;
        my $factory = Bio::DB::EUtilities->new(
                -eutil  =>'efetch',
                -db     =>'taxonomy'
                -id     =>$taxID,
                -email  =>'zhai.we@husky.neu.edu'
        );

        my $file = join('.',$dir.'/taxID',$taxID,'xml');
        if (-s $file and $dl == 0){
                say STDERR "Data existed";
        }else{
                eval {factory->get_Response(-file => $file);
                }
                if ($@){
                        print STDERR $@, "\nHad a problem getting the file for id :", $taxID;
                        return;
                }
                say STDERR "Fetching the data from NCBI";
                sleep(3);
        }
        return $file;
}

sub parse_xml_file {
        ($file) = @_;
        my $FH;
        unless (open($FH,'<',$file)){
                die "Can't open XML file: ", $file, " for reading";
        }
        my $lineage = 'N/A';
        while(<$FH>){
                chomp $_;
                if ($_ =~ /<Lineage(.*)<\/Lineage>/){
                        $lineage = $1;
                }
        }
        close $FH;
        return $lineage;
}
