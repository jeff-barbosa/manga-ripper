package MangaWebsite;

use strict;
use warnings;

sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	return $self;
}

# Check constraints (such as starting chapter, ending chapter, etc)
sub checkConstraints {
	my (undef, $start, $end, $total) = @_;

	# Default setup
	$start = 0 unless(defined($start) && $start);
	$end = $total unless (defined($end) && $end);

	# Making sure the limits (if any) for the chapters are within the constraint
	if ($start > $total) {
		print "You want to download starting from chapter ". $start .", but there's only ". $total ." available\n";
		print "Skipping this manga...\n";
		return undef;
	}
	if ($end > $total) {
		print "You want to download until chapter ". $end .", but there's only ". $total ." available\n";
		print "Changing to adapt to the current number of chapters...\n";
		$end = $total;
	}
	if ($start > $end) {
		print "You're trying to download from a bigger chapter number to a smaller one. Messed up config?\n";
		print "Skipping this manga...\n";
		return undef;
	}

	return { start => $start, end => $end };
}

1;