#!/usr/bin/env perl

use 5.012; # so readdir assigns to $_

use strict;
use warnings;

use Data::Dumper;
use File::Spec;
use FindBin qw($Bin);

my $appname = shift;
die("[ERROR] appname parameters is required\n") unless ($appname);

#
# File and folder paths
#

my $home_path = $ENV{'HOME'};

my $log_folder_path = File::Spec->catdir($home_path,'/logs/frontend');
die("[ERROR] unable to access: $log_folder_path\n") unless -x ($log_folder_path);

my $awstats_folder_path = File::Spec->catdir($home_path,'/webapps/',$appname);
die("[ERROR] unable to access: $awstats_folder_path\n") unless -x ($awstats_folder_path);

my $logresolvemerge_path = File::Spec->catfile($awstats_folder_path,'tools','logresolvemerge.pl');
die("[ERROR] log tool does not exist: $logresolvemerge_path\n") unless -x ($logresolvemerge_path);

my $awstats_path = File::Spec->catfile($awstats_folder_path,'cgi-bin','awstats.pl');
die("[ERROR] awstats does not exist: $awstats_path\n") unless -x ($awstats_path);

my $data_folder_path = File::Spec->catdir($awstats_folder_path,'data');

#
# Sites and URLs
#

my %url_for_log = (
	# log name > domain name
);

my @log_names = &_log_names($log_folder_path);
foreach my $log_name (@log_names) {
	$url_for_log{$log_name} = $log_name;
}

#
# ...allow customised log name to URL mapping with tab separated file
#

my $custom_path = File::Spec->catfile($Bin,'custom.txt');
if (-e $custom_path) {
	open(CUSTOM,"<$custom_path") or die("[ERROR] unable to open $custom_path for reading: $!\n");
	while(my $line = <CUSTOM>) {
		if (($line !~ /^#/) and ($line =~ /^(?<hostname>.+)\t+(?<log>.+)$/)) {
			if ($+{hostname} eq '.ignore') { # skip if log name is '.ignore'
				delete($url_for_log{$+{log}});
			} else {
				$url_for_log{$+{log}} = $+{hostname};
			}
		}
	}
	close(CUSTOM) or die("[ERROR] unable to close $custom_path after read: $!\n");
}

#
#
#

my $template_config;
while(<DATA>) {	$template_config .= $_; }

foreach my $site (sort keys %url_for_log) {

	# Ensure awstats configuration file exists

	my $config_path = File::Spec->catfile($awstats_folder_path,'cgi-bin','awstats.'.$url_for_log{$site}.'.conf');
		
	if (not -e $config_path) {

		print "[INFO] creating required: ".$config_path."\n";

		my $config_contents = $template_config;
		$config_contents =~ s/HOME/$home_path/gsm;
		$config_contents =~ s/APPNAME/$appname/gsm;
		$config_contents =~ s/DOMAIN/$url_for_log{$site}/gsm;
		open(CONFIG,">$config_path") or die("[ERROR] unable to create $config_path to write: $!\n");
		print CONFIG $config_contents;
		close(CONFIG) or die("[ERROR] unable to close $config_path after write: $!\n");
		
		my $site_data_path = File::Spec->catdir($data_folder_path,$url_for_log{$site});
		mkdir($site_data_path) or die("[ERROR] unable to mkdir $site_data_path: $!\n");
	}

	# Merge logs and process

	my @logmerge = (
		$logresolvemerge_path,
		File::Spec->catfile($log_folder_path,'access_'.$site.'.log'),
		File::Spec->catfile($log_folder_path,'access_'.$site.'.log.1'),
		File::Spec->catfile($log_folder_path,'error_'.$site.'.log'),
		File::Spec->catfile($log_folder_path,'error_'.$site.'.log.1'),
		'>',
		File::Spec->catfile($data_folder_path,'log-'.$url_for_log{$site}),
		'||',
		$logresolvemerge_path,
		File::Spec->catfile($log_folder_path,'access_'.$site.'.log'),
		File::Spec->catfile($log_folder_path,'error_'.$site.'.log'),
		'>',
		File::Spec->catfile($data_folder_path,'log-'.$url_for_log{$site}),
	);
	my $logmerge = join(' ',@logmerge);
	system($logmerge);
	
	my @processlog = (
		$awstats_path,
		'-config='.$url_for_log{$site},
		'-u',
	);
	my $processlog = join(' ',@processlog);
	system($processlog);
}

sub _log_names {
	my( $logs_path ) = @_;
	
	# ...check log directory exists
	die('[ERROR] log directory must exist: '.$logs_path) unless -d $logs_path;
	die('[ERROR] log directory must be accessible: '.$logs_path) unless -x $logs_path;

	# Iterate over files in log directory
	my %path_for_log;
	opendir(my $dh, $logs_path) or die('[ERROR] unable to read directory: '.$logs_path.': '.$!);
	while(readdir($dh)) {
		my $log_filename = $_;
		# Filter out rotated logs and stdout/php logs
		if (($_ !~ /_php\.log$/) and ($_ =~ /^access_(?<log>.+?)\.log$/)) {
			my $log_name = $+{log};
			$path_for_log{$log_name} = $logs_path.'/'.$log_filename;
		}
	}
	closedir $dh;
	
	return sort keys %path_for_log;
}

__DATA__
Include "awstats.conf"
SiteDomain="DOMAIN"
HostAliases="DOMAIN www.DOMAIN"
DirData="HOME/webapps/APPNAME/data/DOMAIN"
LogFile="HOME/webapps/APPNAME/data/log-DOMAIN"