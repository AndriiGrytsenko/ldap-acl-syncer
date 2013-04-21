#!/usr/bin/perl

# Written by Andrii Grytsenko 2012
use strict;
use Clone qw(clone);

use lib '/usr/lib/ldap-acl-syncer';
use ldap_acl_syncer;
use ldap_acl_syncer_logger;

# This function is goes through configuration file
# and puts into hash called $conf
sub read_conf {
    my $config_file = shift;
    my ($conf,$key,$val);

    open(CONF, "<$config_file");

    while(<CONF>){
        chomp();
        # skip if line starting from #
        next if (/^#/);
        # skip if empty line
        next if (/^\s*$/);
        # remove leading whitespace
        $line =~ s/^\s+//;
        # remove trailing whitespace
        $line =~ s/\s+$//;

        # delete all ' and "
        $_ =~ s/'//g;
        $_ =~ s/"//g;

        ($key, $val) = split(/\s*=>\s*/);
        $conf->{$key} = $val;
    }

    close(CONF);
    return $conf;
}

# set path to configuration file
# set to /etc/ldap-acl-syncer.conf if nothing else declared by user
my $config_file = $ARGV[0] || '/etc/ldap-acl-syncer.conf';

# check if configuration file exists
if ( ! -f $config_file ) {
    die "configu file $config_file is not found\n";
}

# parse configuration file 
my $conf = read_conf("$config_file");

# we have to clone $conf hash otherwise it will be share 
# between two classes ldap_acl_syncer_logger and ldap_acl_syncer
# and could be unexpectedly overwritten by any of classes
my $log_conf_copy = clone $conf ;
my $logger = new ldap_acl_syncer_logger($log_conf_copy);

$logger->writeToLog("Configuration file $config_file is read", 4);

$conf->{'logger_handler'} = $logger;
# call basic class
my $ldap_sync = new ldap_acl_syncer($conf);

# connect to ldap and get ldap handler ($self->{ldap_handler})
$ldap_sync->get_ldap_handler();
$logger->writeToLog("Connected to ldap server $conf->{'ldap_host'}", 4);

# time calculation
# get last modification time and convert it into unixtime 
my ($modify_time, $last_acl) = $ldap_sync->last_change();
$modify_time = $ldap_sync->conv2unix($modify_time);

# this is ugly solution but I don't know how to solve
# problem with timezones difference between time() and mktime() function results
my $current_time = strftime "%Y%m%d%H%M%S", gmtime;
$current_time = $ldap_sync->conv2unix($current_time);
# my $current_time = time();
my $time_diff = $current_time - $modify_time;

$logger->writeToLog("Last change in ACL tree $conf->{'acl_tree'} was done at $modify_time. $time_diff seconds ago", 4);
#####

# if there were any changes in last *interval_time* seconds
# clean up all group access from users
# re-read acl tree and apply to all users
# who was mentioned in acl as member
if ( $time_diff < $conf->{interval_time}) {
    $logger->writeToLog("Access list cn=${last_acl},$conf->{'acl_tree'} was changed $time_diff seconds ago. New rules are going to be applied", 4 );
    $ldap_sync->clean_hosts();
    $logger->writeToLog('Old groups rules are cleaned up', 4);
    my $acls = $ldap_sync->get_acl_list();
    $logger->writeToLog('Acccess hash tree is done', 4);
    $ldap_sync->applies_rules($acls);
    $logger->writeToLog('Applied new rules to users accounts', 4);
}

# disconnect from ldap
$ldap_sync->close_ldap_connection();
$logger->writeToLog('Close ldap connection', 4);
