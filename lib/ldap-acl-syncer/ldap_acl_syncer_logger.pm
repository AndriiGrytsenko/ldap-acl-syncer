#!/usr/bin/perl

use POSIX qw(strftime mktime);
package ldap_acl_syncer_logger;

# Class constructor
sub new {
    my $class = shift;
    my $self  = shift;

    open($self->{'log_hanler'}, ">>", "$self->{'logfile'}") 
    	or die "cannot open logfile $self->{'logfile'}: $!";

    bless $self, $class;
    $self->{'loglevel'} = 'WARN' if (!defined($self->{'loglevel'}));
    $self->getLogLevel($self);
    
    return $self;
}

# This functions maps alphabetical log level names into digital
# Storing result into $self->{'loglevel'}
# Return: nothing.
sub getLogLevel {
	my ($self) = @_;

	my $loglevel_name = $self->{'loglevel'};
	my %loglevels = (
		'CRIT'  => 1,
		'ERR'   => 2,
		'WARN'  => 3,
		'INFO'  => 4,
		'DEBUG' => 5
	);

	$self->{'loglevel'} = $loglevels{$loglevel_name};
	return 1;
}

# This function accepts log messaage and log level
# and puts it into log file.
# Return: nothing
sub writeToLog {
	my ($self, $message, $loglevel) = @_;

	my $fh = $self->{'log_hanler'};
	if ( $loglevel <= $self->{'loglevel'} ) {
		my $time_shtamp = POSIX::strftime("%Y/%m/%d %H:%M:%S", gmtime);
		
		print $fh "$time_shtamp: $message\n";
	}

	return 1;
}
1;
