package Helper;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(logMsg getMangaInformation);

sub logMsg {
	my $message = shift;

	print $message ."\n" if ($main::debug);

	open (my $fh, '>', $main::log_file) or die ($!);
	print $fh $message."\n";
	close ($fh);
}

sub getMangaInformation {
	my ($url, $start, $end, $website) = @_;
	my $title = $url->[-1];

	# Remove trailing slash
	$title = $1 if ($title =~ /(.+)\/$/);

	# Correct information for the start and end chapter
	$start = $start - 1 if (defined($start) && $start);
	$end = $end - 1 if (defined($end) && $end);

	return { title => $title, relative_url => join('/',@$url), site => $website, ch_start => $start, ch_end => $end };
}