#!/usr/bin/perl

# This script creates buckets and v1 compatibility user for InfluxDB 2.0.
# Perl is used because it's available on the InfluxDB 2.0 image.

use strict;
use warnings;
use JSON;

# Fetch environment variables
my $org = $ENV{'DOCKER_INFLUXDB_INIT_ORG'} or die "DOCKER_INFLUXDB_INIT_ORG not set";
my $username = $ENV{'DOCKER_INFLUXDB_INIT_USERNAME'} or die "DOCKER_INFLUXDB_INIT_USERNAME not set";
my $password = $ENV{'DOCKER_INFLUXDB_INIT_PASSWORD'} or die "DOCKER_INFLUXDB_INIT_PASSWORD not set";

# Define buckets with their properties
my @buckets = (
    { name => 'cache_stats/daily', retention => '26h', rp => 'daily', db => 'cache_stats' },
    { name => 'cache_stats/monthly', retention => '30d', rp => 'monthly', db => 'cache_stats' },
    { name => 'cache_stats/indefinite', retention => '0s', rp => 'indefinite', db => 'cache_stats' },

    { name => 'daily_stats/indefinite', retention => '0s', rp => 'indefinite', db => 'daily_stats' },

    { name => 'deliveryservice_stats/daily', retention => '26h', rp => 'daily', db => 'deliveryservice_stats' },
    { name => 'deliveryservice_stats/monthly', retention => '30d', rp => 'monthly', db => 'deliveryservice_stats' },
    { name => 'deliveryservice_stats/indefinite', retention => '0s', rp => 'indefinite', db => 'deliveryservice_stats' },
);

my %bucket_ids;

# Create buckets and store their IDs
foreach my $bucket (@buckets) {
    my $bucket_name = $bucket->{name};
    my $retention = $bucket->{retention};

    my $cmd = "influx bucket create --json --name '$bucket_name' --retention $retention --org '$org'";
    my $output = `$cmd 2>&1`;
    my $exit_code = $? >> 8;
    if ($exit_code != 0) {
        die "Error creating bucket $bucket_name: $output";
    }

    my $json;
    eval { $json = decode_json($output); };
    if ($@) {
        die "Failed to parse JSON output for bucket $bucket_name: $@";
    }

    unless (ref $json eq 'HASH') {
        die "Unexpected JSON output for bucket $bucket_name: $output";
    }

    my $bucket_id = $json->{id};
    $bucket_ids{$bucket_name} = $bucket_id;
}

# Create v1 DBRP mappings
foreach my $bucket (@buckets) {
    my $bucket_name = $bucket->{name};
    my $bucket_id = $bucket_ids{$bucket_name};
    my $db = $bucket->{db};
    my $rp = $bucket->{rp};

    my $cmd = "influx v1 dbrp create --bucket-id $bucket_id --db '$db' --rp '$rp' --org '$org'";
    if ($rp eq 'daily') {
        $cmd .= " --default";
    }
    my $output = `$cmd 2>&1`;
    my $exit_code = $? >> 8;
    if ($exit_code != 0) {
        die "Error creating v1 dbrp mapping for bucket $bucket_name: $output";
    }
}

# Create v1 compatibility user with permissions
my $cmd = "influx v1 auth create --username '$username' --password '$password' --org '$org'";
foreach my $bucket_id (values %bucket_ids) {
    $cmd .= " --read-bucket $bucket_id --write-bucket $bucket_id";
}
my $output = `$cmd 2>&1`;
my $exit_code = $? >> 8;
if ($exit_code != 0) {
    die "Error creating v1 compatibility user: $output";
}

print "Setup complete\n";
