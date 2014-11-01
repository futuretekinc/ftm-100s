package WWW::TheMovieDB::Search;

use 5.008009;
use strict;
use warnings;
use LWP::Simple;
use URI::Escape;

require Exporter;

our @ISA = qw(Exporter);


our %EXPORT_TAGS = ( 'all' => [ qw(
	Movie_getInfo
	Movie_browse
	Movie_getImages
	Movie_getLatest
	Movie_getTranslations
	Movie_getVersion
	Movie_imdbLookup
	Movie_search
	Person_getInfo
	Person_getLatest
	Person_getVersion
	Person_search
	Genres_getList
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.03';


sub new {
	my $package = shift;
	
	$package::key	= '';
	$package::lang	= 'en';	
	$package::ver	= '2.1';
	$package::type	= 'xml';
	$package::uri	= 'http://api.themoviedb.org';
	
	if ($_[0]) {
		$package->key($_[0]);
	}
	
	return bless({}, $package);
}

sub lang {
	my $package = shift;
	$package::lang = shift;
	return;
}

sub ver {
	my $package = shift;
	$pacakge::ver = shift;
	return;
}

sub key {
	my $package = shift;
	$package::key = shift;
	return;
}

sub type {
	my $package = shift;
	$package::type = shift;
	return;
}

sub buildURL {
	my ($package,$method) = @_;
	
	my $url = $package::uri ."/". $package::ver ."/". $method ."/". $package::lang ."/". $package::type ."/". $package::key;
	
	return $url;
}

sub Movie_browse {
	my ($package,%data) = @_;
	
	
	my $url  = $package->buildURL("Movie.browse");
	$url .= "?";
	
	unless ((exists $data{'order'} && $data{'order'} =~ m/^(asc|desc)$/) && (exists $data{'order_by'} && $data{'order_by'} =~ m/^(rating|release|title)$/)) {
		return "Missing order and/or order_by.";
	}
	
	foreach my $key (sort keys %data) {
		$url .= '&order='.				$data{'order'}				if ($key eq 'order');
		$url .= '&order_by='.			$data{'order_by'}			if ($key eq 'order_by');
		
		$url .= '&certifications='.		$data{'certifications'}		if ($key eq 'certifications'	&& $data{'certifications'} ne "");
		$url .= '&companies='.			$data{'companies'}			if ($key eq 'companies'			&& $data{'companies'} =~ m/(\d+,)*\d+$/);
		$url .= '&countries='.			$data{'countries'}			if ($key eq 'countries'			&& $data{'countries'} ne "");
		$url .= '&genres='.				$data{'genres'}				if ($key eq 'genres'			&& $data{'genres'} =~ m/(\d+,)*\d+$/);
		$url .= '&genres_selector='.	$data{'genres_selector'}	if ($key eq 'genres_selector'	&& $data{'genres_selector'} =~ m/^(and|or)$/);
		$url .= '&min_votes='.			$data{'min_votes'}			if ($key eq 'min_votes'			&& $data{'min_votes'} =~ m/^(\d+)$/);
		$url .= '&page='.				$data{'page'}				if ($key eq 'page'				&& $data{'page'} =~ m/^\d+$/);
		$url .= '&per_page='.			$data{'per_page'}			if ($key eq 'per_page'			&& $data{'per_page'} =~ m/^\d+$/);
		$url .= '&query='.				uri_escape($data{'query'})	if ($key eq 'query'				&& $data{'query'} ne "");
		$url .= '&rating_max='.			$data{'rating_max'}			if ($key eq 'rating_max'		&& $data{'rating_max'} =~ m/^\d*\.{0,1}\d+$/);
		$url .= '&rating_min='.			$data{'rating_min'}			if ($key eq 'rating_min'		&& $data{'rating_min'} =~ m/^\d*\.{0,1}\d+$/);
		$url .= '&release_max='.		$data{'release_max'}		if ($key eq 'release_max'		&& $data{'release_max'} =~ m/^-{0,1}\d+$/);
		$url .= '&release_min='.		$data{'release_min'}		if ($key eq 'release_min'		&& $data{'release_min'} =~ m/^-{0,1}\d+$/);
		$url .= '&year='.				$data{'year'}				if ($key eq 'year'				&& $data{'year'} =~ m/^\d+$/);
	}
	
	
	my $content = get($url) || "";
	return $content;
}

sub Movie_getImages {
	my ($package,$movieid) = @_;

	my $url  = $package->buildURL("Movie.getImages");
	$url .= "/". $movieid;
	my $content = get($url) || "";
	return $content;
}

sub Movie_getInfo {
	my ($package,$movieid) = @_;
	
	my $url  = $package->buildURL("Movie.getInfo");
	$url .= "/". $movieid;
	my $content = get($url) || "";
	
	return $content;
}

sub Movie_getLatest {
	my $package = shift;
	
	my $url  = $package->buildURL("Movie.getLatest");

	print $url;
	my $content = get($url) || "";
	
	return $content;
}

sub Movie_getTranslations {
	my ($package,$movieid) = @_;
	
	my $url  = $package->buildURL("Movie.getTranslations");
	$url .= "/". $movieid;
	my $content = get($url) || "";
	
	return $content;
}

sub Movie_getVersion {
	my ($package,$movieid) = @_;
	
	my $url  = $package->buildURL("Movie.getVersion");
	$url .= "/". $movieid;
	my $content = get($url) || "";
	
	return $content;
}

sub Movie_imdbLookup {
	my ($package,$imdbid) = @_;
	
	my $url  = $package->buildURL("Movie.imdbLookup");
	$url .= "/". $imdbid;
	my $content = get($url) || "";
	
	return $content;
}

sub Movie_search {
	my ($package,$query) = @_;
	$query = uri_escape($query);
	
	my $url  = $package->buildURL("Movie.search");
	$url .= "/". $query;
	
	my $content = get($url) || "";
	
	return $content;
}

sub Person_getInfo {
	my ($package,$personid) = @_;
	
	my $url  = $package->buildURL("Person.getInfo");
	$url .= "/". $personid;
	
	my $content = get($url) || "";
	
	return $content;
}

sub Person_getLatest {
	my $package = shift;
	
	my $url  = $package->buildURL("Person.getLatest");

	print $url;
	my $content = get($url) || "";
	
	return $content;
	
}

sub Person_getVersion {
	my ($package,$personid) = @_;
	
	my $url  = $package->buildURL("Person.getInfo");
	$url .= "/". $personid;
	
	my $content = get($url) || "";
	
	return $content;
}

sub Person_search {
	my ($package,$query) = @_;
	$query = uri_escape($query);
	
	my $url  = $package->buildURL("Person.search");
	$url .= "/". $query;
	
	my $content = get($url) || "";
	
	return $content;
}

sub Genres_getList {
	my $package = shift;
	
	my $url = $package->buildURL("Genres.getList");
	
	my $content = get($url) || "";
	
	return $content;
}


1;
__END__

