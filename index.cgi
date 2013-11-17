#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);

use CGI::Carp qw( fatalsToBrowser );
use CGI qw( :standard escapeHTML );

# Iterate over configuration files
my @configurations;
my $configs_path = File::Spec->catdir($Bin,'cgi-bin');
opendir(my $dh, $configs_path) or die('[ERROR] unable to read directory: '.$configs_path.': '.$!);
while(my $filename = readdir($dh)) {
	if ($filename =~ /^awstats\.(.+)\.conf$/) {
		push(@configurations,$1) if ($1 ne 'model');
	}
}
closedir $dh;

print( header(), start_html( 'Awstats - Configurations' ) );
print "<ul>\n";
foreach my $configuration ( sort @configurations ) {
	print <<_html;
	<li><a href="cgi-bin/awstats.pl?config=$configuration">$configuration</a></li>
_html
}
print "</ul>\n";
print( end_html() );
