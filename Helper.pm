package Helper;

use strict;
use warnings;
use Exporter;

our @EXPORT = qw(logMsg);

sub logMsg {
	my $message = shift;

	print $message ."\n" if ($main::debug);

	open (my $fh, '>', $main::log_file) or die ($!);
	print $fh $message."\n";
	close ($fh);
}
