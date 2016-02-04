package MangaWebsite::TuMangaOnline;

use strict;
use warnings;
use parent 'MangaWebsite';
use Helper qw(logMsg);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new($class);
	return $self;
}

1;
