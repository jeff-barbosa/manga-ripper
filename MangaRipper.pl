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
	# We're just an ordinary user, sir
	$ua = WWW::Mechanize->new(
		agent => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.86 Safari/537.36'
	);

	# Parse the URLs
	open (my $fh, '<', $filename) or die ($!);
	while (<$fh>) {
		next if ($_ =~ /^#/);
		# Mangahere URL
		if ($_ =~ /\Q$sites{mangahere}\E(.+)\/?$/i) {
			my $manga_title = $1;
			$manga_title = $1 if ($manga_title =~ /(.+)\/$/);
			push(@mangas, { title => $manga_title, site => 'mangahere' });
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
			ripFromMangahere($manga->{title});
		}
	}
}

# Receives a manga name and rips all the chapters to the download folder
# It logs any error (missing chapter/pages) on the log file
sub ripFromMangahere {
	my $manga = shift;
	mkdir($download_folder.'/'.$manga) unless (-d $download_folder .'/'. $manga);
	my $url = $sites{mangahere} . $manga;
	my $response = $ua->get($url);

	if ($response) {
		print "Chapter list for ". $manga ."\n";
		my @manga_chapters;

		# Get links for each chapter
		foreach ($ua->links()) {
			if ($_->url() =~ /$url.*\/c([0-9.]+)/) {
				print "Chapter ". $1 .": ". $_->url() ."\n" if ($verbose);
				push(@manga_chapters, {chapter => $1, url => $_->url() });
			}
		}

		print "Found ". @manga_chapters ." chapters\n";

		# Parse each chapter
		foreach (@manga_chapters) {
			my $chapter_folder = $download_folder.'/'.$manga.'/'.$_->{chapter};
			mkdir($chapter_folder);

			my $visit = $ua->get($_->{url});

			# Get number of pages
			my $num_pages;
			if ($visit) {
				if ($visit->decoded_content() =~ /(\d+)<\/option>\s*<\/select>/) {
					print "Number of pages for chapter ". $_->{chapter} .": ". $1 ."\n";
					$num_pages = $1;
				} else {
					logMsg("[". $manga ."]Couldn't find the number of pages for chapter ". $_->{chapter} ."\n");
					next;
				}
			}

			print "Downloading pages...\n";

			# Download pages
			for (my $i = 1; $i <= $num_pages; $i++) {
				my $page_url = $_->{url} . $i .'.html';
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
						logMsg("[". $manga ." | Ch ". $_->{chapter} ."]Error: Couldn't find image on ". $i ." page link\n");
					}
				} else {
					logMsg("[". $manga ." | Ch ". $_->{chapter} ."]Error: Couldn't download page ". $i ."\n");
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
