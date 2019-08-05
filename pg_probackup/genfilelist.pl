use Win32;
use File::Basename;

sub usage
{
	die(    "Usage: genfilelist.pl <filemask> <outputfile>\n");
}

 usage()
  unless scalar(@ARGV) == 2;

my $filename = $ARGV[1];
open(OUT, ">>$filename") || die "Could not open output file ($filename)!\n";


my @files = glob($ARGV[0]);
my $file2 = "";

    foreach my $file (@files) {

	$file2 = basename($file);
	$file2 =~ s/-//ig;
	print OUT "<File Id=\'$file2\' DiskId=\'1\' Source=\'$file\'/>\n";
	

    }

close(OUT);
exit 0;
