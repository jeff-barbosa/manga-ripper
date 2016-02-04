#!/usr/bin/env perl
package main;

use strict;
use warnings;
use WWW::Mechanize;
use FindBin qw($RealBin);

use lib "$RealBin/src";

use MangaWebsite::Mangahere;
use MangaWebsite::TuMangaOnline;
use Helper;

my $filename = "manga_list.txt";
our $download_folder = "downloads";
our $log_file = "log.txt";
our $verbose = 0;
our $debug = 0;

our $ua;
our @mangas;
our %sites = (
	'mangahere' => 'http://www.mangahere.co/manga/',
	'tumangaonline' => 'http://www.tumangaonline.com/listado-mangas/manga/',
);

sub bootstrap {
	print "Boostrasping...\n";
	# We're just an ordinary user, sir
	$ua = WWW::Mechanize->new(
		autocheck => 0,
		stack_depth => 5,
		agent => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.86 Safari/537.36'
	);

	# Parse the URLs
	open (my $fh, '<', $filename) or die ($!);
	while (<$fh>) {
		my ($manga_title, $start_chapter, $end_chapter) = undef;
		next if ($_ =~ /^#/);

		# Mangahere URL
		if ($_ =~ /\(\Q$sites{mangahere}\E(.+)\/,\s*(\d*),\s*(\d*)\)/i) {
			push(@mangas, getMangaInformation([$1], $2, $3, "mangahere"));
		}
		# TuMangaOnline URL
		if ($_ =~ /\(\Q$sites{tumangaonline}\E(\d+)\/(.+),\s*(\d*),\s*(\d*)\)/i) {
			push(@mangas, getMangaInformation([$1,$2], $3, $4, "tumangaonline"));
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

	my $ripper;

	foreach my $manga (@mangas) {
		print "Attempting to download: ". $manga->{title} ."\n";
		if ($manga->{site} eq 'mangahere') {
			$ripper = MangaWebsite::Mangahere->new();
		}
		elsif ($manga->{site} eq 'tumangaonline') {
			$ripper = MangaWebsite::TuMangaOnline->new();
		}

		$ripper->rip($manga);
	}
}

# Receives a manga name and rips all the chapters to the download folder
# It logs any error (missing chapter/pages) on the log file
sub ripFromMangahere {
	my $ripper = MangaWebsite::Mangahere->new();
	$ripper->checkConstraints();
}

bootstrap();
