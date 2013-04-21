#!/usr/bin/perl

use POSIX qw(strftime mktime);
use Net::LDAP;
package ldap_acl_syncer;

# Class constructor
sub new {
    my $class = shift;
    my $self  = shift;

    bless $self, $class;

    $self->{'logger_handler'}->writeToLog('We are in ldap_acl_syncer constructor', 5);
    return $self;
}

# This function is just a wrapper for error handeling
# It transfers message to logging class and dies eventually
sub error_handler {
    my ($self, $message) = @_;

    $self->{'logger_handler'}->writeToLog("$message", 0);
    die $message;
}

# This function opens ldap connection and 
# puts LDAP connection handler into $self->{'ldap_handler'}
# Return: nothing
sub get_ldap_handler {
    my ($self) = @_;

    # connect and bind to ldap server
    $self->{'ldap_handler'} = Net::LDAP->new( "$self->{'ldap_host'}" ) || $self->error_handler("Connect to LDAP: $@");

    my $mesg = $self->{'ldap_handler'}->bind( "$self->{'bind'}",  password => "$self->{'password'}" );

    $mesg->code && $self->error_handler("Error during bindin to ldap: $mesg->error");

    return 1;
}

# This funcrion simply close ldap connection
sub close_ldap_connection {
    my ($self) = @_;

    $self->{'ldap_handler'}->unbind;
    return 1;
}

# This function reads "ou=acl,$base" tree
# and stores it into $result hash
# Return: hash $result with next structure:
# $result->{access_list_name}->{'members'} - array of all acl's members
# $result->{access_list_name}->{'hosts'}   - array of all acl's hosts
sub get_acl_list {
    my ($self) = @_;

    my $mesg = $self->{'ldap_handler'}->search( base => "$self->{'acl_tree'}", filter => 'cn=*' );
    $mesg->code && $self->error_handler("Error during fetching acl list: $mesg->error");


    my $result;

    foreach my $acl ($mesg->entries) {
        my $tmp_array = $acl->{'asn'}->{'attributes'};
        my ($cn, $members, $hosts) = '';

        foreach my $entry (@$tmp_array){
            if ($entry->{'type'} eq 'cn'){
                $cn = $entry->{'vals'}->[0];
            }
            elsif ($entry->{'type'} eq 'memberUid') {
                $members = $entry->{'vals'};
            }
            elsif ($entry->{'type'} eq 'host') {
                $hosts = $entry->{'vals'};
            }
        }

        $result->{$cn}->{'members'} = $members;
        $result->{$cn}->{'hosts'} = $hosts;
    }
    return $result;
}

# This function create 'hosts' attributes with '*.:g'
# inside "cn=$member,ou=People,$base"
# Return nothing
sub applies_rules {
    my ($self, $acls) = @_;

    foreach my $acl (keys %$acls){
        my $members = $acls->{$acl}->{'members'};
        my $hosts = $acls->{$acl}->{'hosts'};

        foreach my $member (@$members){
            foreach my $host (@$hosts){
                next if ($host !~ /.*:g/);

                my $mesg = $self->{'ldap_handler'}->modify("cn=$member,$self->{'people_tree'}",
                               add => [ host => $host]
                );
                $mesg->code && $self->error_handler("Error during applied acl list to account cn=$member,$self->{'people_tree'}: $mesg->error");
            }
        }
    }
    return 1;
}

# This function goes through all account in "people_tree"
# and deletes all 'host' attibutes with '*.:g'
# Return: nothing
sub clean_hosts {
    my ($self) = @_;

    my $mesg = $self->{'ldap_handler'}->search( base => "$self->{'people_tree'}", filter => 'host=*:g' );
    $mesg->code && $self->error_handler("Error during searching in people_tree: $mesg->error");

    foreach my $members ($mesg->entries) {
        my $member;
        my $tmp_array = $members->{'asn'}->{'attributes'};

        foreach my $entry (@$tmp_array){
            if ($entry->{'type'} eq 'host'){
                my $hosts = $entry->{'vals'};

                foreach my $host (@$hosts){
                    next if ($host !~ /.*:g/);
                    if ( $member ne ''){
                        my $mesg1 = $self->{'ldap_handler'}->modify( "cn=$member,$self->{'people_tree'}", delete => { 'host' => "$host" } );
                        $mesg1->code && $self->error_handler("Error during deleting $host from cn=$member,$self->{'people_tree'}: $mesg1->error");
                    }
                }
            }
            elsif ($entry->{'type'} eq 'cn'){
                $member = $entry->{'vals'}->[0];
            }
        }
    }
    return 1;
}

# This function is looking for last update in "acl_tree"
# Return: last modify time. $latest_mod_time
sub last_change {
    my ($self) = @_;
    
    my $access_list;
    my $mesg = $self->{'ldap_handler'}->search( base => "$self->{'acl_tree'}", filter => 'cn=*', attrs => ['modifyTimestamp', 'cn'] );
    $mesg->code && $self->error_handler("Error while looking for last modified time: $mesg->error");

    my $latest_mod_time = 0;

    foreach my $members ($mesg->entries) {
        my $tmp_array = $members->{'asn'}->{'attributes'};

        my $current_access_list;
        my $modify_time;

        foreach my $entry (@$tmp_array){
            if ( $entry->{'type'} eq 'modifyTimestamp'){
                $modify_time = $entry->{'vals'}->[0];
                # get rid of trailing Z
                $modify_time =~ s/Z$//g;                
            } elsif ($entry->{'type'} eq 'cn'){
                $current_access_list = $entry->{'vals'}->[0];
            }
        }

        if ( $modify_time > $latest_mod_time ){
            $access_list = $current_access_list;
            $latest_mod_time = $modify_time;
        }
    }

    return ($latest_mod_time, $access_list);
}

# This function converts ldap time format into unixtime
# 20120326121334 -> 1332756814
# Return: converted unixtime
sub conv2unix {
    my ($self, $date) = @_;

    my ($year, $mon, $day, $hour, $min, $sec) =
        $date =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/;
    # due to specific processes inside perl date library
    # there are some adjustment required
    $year -= 1900;
    $mon  -= 1;
    #####

    my $unixtime = POSIX::mktime($sec, $min, $hour, $day, $mon, $year, 0, 0);
    my $testtime = POSIX::mktime('52','21','19','19','03','113');
    my $t1 = time();
    my $t2 = localtime(time);
    return $unixtime;
}

1;