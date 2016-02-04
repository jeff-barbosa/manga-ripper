package MangaWebsite;

use strict;
use warnings;

use Helper;

sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	return $self;
}

sub rip {
	my ($self, $manga) = @_;
	mkdir($main::download_folder.'/'.$manga->{title}) unless (-d $main::download_folder.'/'.$manga->{title});
	my $url = $main::sites{ $manga->{site} } . $manga->{relative_url};
	print "D: ". $url ."\n";
	my $response = $main::ua->get($url);
	
	if ($response) {
		print "Querying chapter list...\n";

		my @links = $main::ua->links();
		my @manga_chapters = getChapterList(\@links, $manga->{title}, $url);
		my $constraints = checkConstraints($manga->{ch_start}, $manga->{ch_end}, scalar(@manga_chapters));

		# We have the links for the chapter and information from where to start and where to end
		if (@manga_chapters) {
			print "Found ". scalar(@manga_chapters) ." chapters\n";

			# Rip each chapter
			for (my $index = $constraints->{start}; $index < $constraints->{end}; $index++) {
				ripChapter($manga_chapters[$index], $manga->{title});
			}
		} else {
			logMsg("[". $manga->{title} ."] Error: No chapters found");
		}
	} else {
		logMsg("[". $manga->{title} ."] Error: Unable to GET ". $url);
	}
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