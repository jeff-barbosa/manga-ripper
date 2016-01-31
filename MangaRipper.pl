#!/usr/bin/env perl
use strict;
use warnings;
use WWW::Mechanize;

my $filename = "manga_list.txt";
my $download_folder = "downloads";
my $log_file = "log.txt";
my $verbose = 0;
my $debug = 0;

my $ua;
my @mangas;
my %sites = (
	'mangahere' => 'http://www.mangahere.co/manga/'
);

sub bootstrap {
	print "Boostrasping...\n";
	# We're just an ordinary user, sir
	$ua = WWW::Mechanize->new(
		autocheck => 0,
		agent => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.86 Safari/537.36'
	);

	# Parse the URLs
	open (my $fh, '<', $filename) or die ($!);
	while (<$fh>) {
		my ($manga_title, $start_chapter, $end_chapter) = undef;
		next if ($_ =~ /^#/);
		# Mangahere URL
		if ($_ =~ /\(\Q$sites{mangahere}\E(.+)\/,\s*(\d*),\s*(\d*)\)/i) {
			# Get the information
			$manga_title = $1;
			$start_chapter = ($2 - 1) if(defined($2));
			$end_chapter = ($3 - 1) if (defined($3));

			# Remove trailing slash
			$manga_title = $1 if ($manga_title =~ /(.+)\/$/);

			push(@mangas, { 
				title => $manga_title, 
				site => 'mangahere', 
				ch_start => $start_chapter,
				ch_end => $end_chapter
			});
		}
	}
	close($fh);

	main();
}

sub main {
	if (!-d $download_folder) {
		print "Creating ". $download_folder ." folder\n";
		mkdir("downloads");
	}

	foreach my $manga (@mangas) {
		print "Attempting to download: ". $manga->{title} ."\n";
		if ($manga->{site} eq 'mangahere') {
			ripFromMangahere($manga);
		}
	}
}

# Receives a manga name and rips all the chapters to the download folder
# It logs any error (missing chapter/pages) on the log file
sub ripFromMangahere {
	my $manga = shift;
	mkdir($download_folder.'/'.$manga->{title}) unless (-d $download_folder.'/'.$manga->{title});
	my $url = $sites{mangahere} . $manga->{title};
	my $response = $ua->get($url);

	if ($response) {
		print "Chapter list for ". $manga->{title} ."\n";
		my @manga_chapters;

		# Get links for each chapter
		foreach ($ua->links()) {
			if ($_->url() =~ /$url.*\/c([0-9.]+)/) {
				print "Chapter ". $1 .": ". $_->url() ."\n" if ($verbose);
				unshift(@manga_chapters, {chapter => $1, url => $_->url() });
			}
		}

		print "Found ". @manga_chapters ." chapters\n";

		$manga->{ch_start} = 0 unless(defined($manga->{ch_start}) && $manga->{ch_start});
		$manga->{ch_end} = scalar(@manga_chapters) unless (defined($manga->{ch_end}) && $manga->{ch_end});

		# Making sure the limits (if any) for the chapters are within the constraint
		if ($manga->{ch_start} > @manga_chapters) {
			print "You want to download starting from chapter ". $manga->{ch_start} .", but there's only ". @manga_chapters ." available\n";
			print "Skipping this manga...\n";
			return;
		}
		if ($manga->{ch_end} > @manga_chapters) {
			print "You want to download until chapter ". $manga->{ch_end} .", but there's only ". @manga_chapters ." available\n";
			print "Changing to adapt to the current number of chapters...\n";
			$manga->{ch_end} = scalar(@manga_chapters);
		}
		if ($manga->{ch_start} > $manga->{ch_end}) {
			print "You're trying to download from a bigger chapter number to a smaller one. Messed up config?\n";
			print "Skipping this manga...\n";
			return;
		}

		for (my $index = $manga->{ch_start}; $index < $manga->{ch_end}; $index++) {
			my $current_chapter = $manga_chapters[$index];

			my $chapter_folder = $download_folder.'/'.$manga->{title}.'/'.$current_chapter->{chapter};
			mkdir($chapter_folder);

			my $visit = $ua->get($current_chapter->{url});

			# Get number of pages
			my $num_pages;
			if ($visit) {
				if ($visit->decoded_content() =~ /(\d+)<\/option>\s*<\/select>/) {
					print "Number of pages for chapter ". $current_chapter->{chapter} .": ". $1 ."\n";
					$num_pages = $1;
				} else {
					logMsg("[". $manga ."]Couldn't find the number of pages for chapter ". $current_chapter->{chapter} ."\n");
					next;
				}
			}

			print "Downloading pages...\n";

			# Download pages
			for (my $i = 1; $i <= $num_pages; $i++) {
				my $page_url = $current_chapter->{url} . $i .'.html';
				my $response = $ua->get($page_url);
				if ($response) {
					my $image_obj = $ua->find_image(alt_regex => qr/page \d+$/i);
					if ($image_obj) {
						print "Downloading page: ". $i ."\n" if ($verbose);
						my $image = $ua->get($image_obj->url());
						open (my $fh, '>', $chapter_folder .'/'. $i .'.jpg');
						print $fh $image->content();
						close($fh);
					} else {
						logMsg("[". $manga ." | Ch ". $current_chapter->{chapter} ."]Error: Couldn't find image on ". $i ." page link\n");
					}
				} else {
					logMsg("[". $manga ." | Ch ". $current_chapter->{chapter} ."]Error: Couldn't download page ". $i ."\n");
				}
			}

			print "Download complete.\n";
		}
	} else {
		logMsg("[". $manga ."]Error: Unable to GET '". $url ."'\n");
	}
}

sub logMsg {
	my $message = shift;

	print $message if ($debug);

	open (my $fh, '>', $log_file) or die ($!);
	print $fh $message;
	close ($fh);
}

bootstrap();
