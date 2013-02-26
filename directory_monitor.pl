#!/usr/bin/perl



# Monitors a directory for file changes.
#
# Usage: directory_monitor.pl <directory>
#
# -- http://www.nooblet.org/blog

# -------------------------------------------------------------------------------------------------------------
## Default directory to be monitored.
my $directory = "/tmp/";

## How long to sleep between checks, in seconds
my $sleeptime = 1;
# -------------------------------------------------------------------------------------------------------------

use POSIX qw(ceil floor);

$| = 1;
# Directory on command-line
if ($#ARGV >= 0) { $directory = join(' ', @ARGV); }

# Directories need to have a trailing slash
if (substr($directory,-1) ne "/") { $directory .= "/"; }

# Check if the directory exists
if (!-e $directory) {
  print STDERR "'$directory' does not exist.\n";
	exit(-1);
}

# Store file info here
my %data;
# individual file statistics placed in this global array
my @gstat;

# begin
print "\nMonitoring directory: ".$directory."\n";
print "\t(ctrl+c to halt)\n\n";

# loop forever
while (true) {
	my $first = 0;
	# Get directory handle
	opendir(DIR, $directory) or die "Unable to open directory, $directory : $!";
	# And loop through the contents
	while (defined(my $filename = readdir(DIR))) {
		# We only want files, not sub-directories
		if (-d $directory.$filename) { next; }
		# Get inode statistics
		@gstat = &getstat($filename);
		# If this is the first time it is being run, don't want to spam that every file is new, just add it to the hash
		if (!scalar(%data)) { $first = 1; &update($filename); }
		# subsequent files are added on first run
		elsif ($first == 1) { &update($filename); }
		# Not first run, and new file found
		elsif (!scalar($data{$filename})) { &doPrint($filename, "Created. [".&printBytes($gstat[7])."]"); &update($filename); }
		# The size has changed
		elsif ($data{$filename}{'size'} != $gstat[7]) {
			my $increase = $gstat[7] - $data{$filename}{'size'};
			my $text = "Size changed to ".&printBytes($gstat[7]);
			if ($increase > 0) { $text .= " (up ".&printBytes($increase).")"; }
			elsif ($increase < 0) { $text .= " (down ".&printBytes($increase * -1).")"; }
			&doPrint($filename, $text);
			&update($filename);
		}
		# The modified time has changed
		elsif ($data{$filename}{'mtime'} != $gstat[9]) {
				&doPrint($filename, "Modified, size unchanged");
			&update($filename);
		}
	}
	# Clean up the directory handle
	closedir(DIR);
	# Check for files in the hash which are no longer in the directory
	foreach $key (keys %data) {
		if (! -e $directory.$key) {
			&doPrint($key, "Deleted. Last modified at ".readTime($data{$key}{'mtime'})." (".&duration(time() - $data{$key}{'mtime'}).") [".&printBytes($data{$key}{'size'})."]");
			delete($data{$key});
		}
	}
	# Sleep for a bit, else it eats up the CPU
	sleep($sleeptime);
}

# returns the time in the format <year><month><day>.<hour><minute><second> .. hardly readable but concise
sub readTime {
	my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime(shift(@_));
	my $time = (1900+ $yearOffset).sprintf("%02d", $month).sprintf("%02d", $dayOfMonth).".".sprintf("%02d", $hour).sprintf("%02d", $minute).sprintf("%02d", $second);
	return $time;
}

# Print out a file change in a consistent format
sub doPrint {
	my $fn = shift(@_);
	my $t = shift(@_);
	my $time = readTime(time());
	print $time." : ".$fn."\t".$t."\n";
}

# Takes bytes are returns kilobytes, megabytes, gigabyte values instead based on set limits
sub printBytes {
	my $bytes = shift(@_);
	if ($bytes <= 4096) { return $bytes."b"; }
	$bytes = sprintf("%.2f",$bytes / 1024);
	if ($bytes <= 1024) { return $bytes."k"; }
	$bytes = sprintf("%.2f",$bytes / 1024);
	if ($bytes <= 1024) { return $bytes."m"; }
	$bytes = sprintf("%.2f",$bytes / 1024);
	return $bytes."g";
}

# Take number of seconds and return duration, ie. 2d 4h 5m 14s
sub duration {
	my $time = shift(@_);
	if ($time == 0) { return "just now"; }
	my $string = "";
	my $days = floor($time / 86400); $time = $time - ($days * 86400);
	if ($days > 0) { $string .= $days."d "; }
	my $hours = floor($time / 3600); $time = $time - ($hours * 3600);
	if ($hours > 0) { $string .= $hours."h "; }
	my $mins = floor($time / 60); $time = $time - ($mins * 60);
	if ($mins > 0) { $string .= $mins."m "; }
	my $secs = $time;
	if ($secs > 0) { $string .= $secs."s "; }
	$string .= "ago";
	return $string;
}

# Populate array with inode statistics
sub getstat {
	my $fn = $_[0];
	open(FILE, $directory.$fn);
	my @stat = stat(FILE);
	close(FILE);
	return @stat;
}

# update the has with file info
sub update {
	my $fn = $_[0];
	$data{$fn} = {
		size => $gstat[7],
		mtime => $gstat[9],
	};
}
