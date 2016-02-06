#!/usr/bin/env perl
package main;

use strict;
use warnings;
use WWW::Mechanize;
use FindBin qw($RealBin);

use lib "$RealBin/src";

use Ripper;
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
	'lermanga' => 'http://lermangas.com/manga/',
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
		# LerManga URL
		if ($_ =~ /\(\Q$sites{lermanga}\E(.+)\/,\s*(\d*),\s*(\d*)\)/i) {
			push(@mangas, getMangaInformation([$1], $2, $3, "lermanga"));
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
			$ripper = Ripper->new("MangaWebsite::Mangahere");
		}
		elsif ($manga->{site} eq 'tumangaonline') {
			$ripper = Ripper->new("MangaWebsite::TuMangaOnline");
		} 
		elsif ($manga->{site} eq 'lermanga') {
			$ripper = Ripper->new("MangaWebsite::LerManga");
		}

		$ripper->rip($manga);
	}
}

bootstrap();
