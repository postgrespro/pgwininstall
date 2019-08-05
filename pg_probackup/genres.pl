use Win32;
use File::Basename;

sub usage
{
	die(    "Usage: genres.pl <desc> <version> <type>\nFor example:\ngenres.pl \"Pro database backup\" 2.0.26 dll");
}

 usage()
  unless scalar(@ARGV) == 3;

	AddResourceFile($ARGV[0], $ARGV[1], $ARGV[2]);

exit 0;


sub AddResourceFile
{
	my ($desc, $ver, $type) = @_;
	$ver =~ s/\./,/gm;

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
	  localtime(time);
	my $d = sprintf("%02d%03d", ($year - 100), $yday);

		print "Generating win32ver.rc\n";
		open(my $i, '<', 'win32ver_tmp.rc')
		  || die "Could not open win32ver_tmp.rc";
		open(my $o, '>', "win32ver.rc")
		  || die "Could not write win32ver.rc";
		my $icostr = $ico ? "IDI_ICON ICON \"$ico.ico\"" : "";
		while (<$i>)
		{
			s/FILEDESC/"$desc"/gm;
			s/_ICO_/$icostr/gm;
			#s/(VERSION.*),0/$1,$d/;
			s/(VERSION ).*$/$1 $ver,$d/;
			if ($type eq "dll")
			{
				s/VFT_APP/VFT_DLL/gm;
			}
			print $o $_;
		}
		close($o);
		close($i);

	return;
}
