#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use YAML;

use PDL;
use PDL::IO::FastRaw;

use lib './lib';

use Tools;
use ART;

my $conf = require 'conf.pl';

my $beta = 0;
my $lambda = 1;
my $rho = 0.001;

say 'Loading data...';

# Load processed docs
my ($docs, $words, $words_ids) = load_processed_docs($conf->{processed_docs_path}, $conf->{docs_limit});

# Words count
my $words_count = scalar keys $words;

# Term-term similarity matrix
my $TT = readfraw("$conf->{data_path}/term-term-model");

# Term frequency vector
my $TF = zeros($words_count);
# Populate term frequncy vector
for my $i ( 0 .. $words_count - 1 ) {
  # using term docs count
  $TF->set($i, scalar keys %{$words->{$i}->{docs}});
}

say 'Forming term frequency groups...'

# Term frequency vector sorted indexes
my $TFsi = $TF->qsorti();

# Term frequency groups container
my $term_freq_groups = {};

# Generate frequency groups and populate container
my $freq_groups_count = $conf->{frequency_classes_count};
my $freq_groups_parts = $conf->{frequency_classes_parts}

# Get frequency groups 1..r corresponding terms ids
my $last_end = 0;
for( 1 .. $freq_groups_count ) {
  my $start = $last_end;
  my $end = $_ == $freq_groups_count
    : $words_count - 1
    ? $last_end + int($words_count * $freq_groups_parts->{$_});
  $last_end = $end;
  $term_freq_groups->{$_} = {
    ids => $TFsi->range($start, $end),
  }
}

# Frequency groups 12, 123, ..., 123..(r-1) corresponding terms ids
my $group_id = '1';
for( 2 .. $freq_groups_count - 1 ) {
  $term_freq_groups->{$group_id . $_} = {
    ids => $term_freq_groups->{$group_id}->append($term_freq_groups->{$_}),
  };
  $group_id .= $_;
}

# Get term frequency groups corresponding term-term similarity matrix part
for( keys $term_freq_groups ) {
  my $ids = $term_freq_groups->{$_};
  $term_freq_groups->{$_}->{TT} = $TF->dice('X', $ids);
}

# Group 123..r corresponds to whole TT matrix
$group_id .= $freq_groups_count;
$term_freq_groups->{$group_id} = {
  ids => $TFsi,
  TT => $TT,
};

say 'Train ART neural network foreach frequency term group...';

# Foreach term frequency group train ART neural network
foreach( keys $term_freq_groups ) {
  say "\ttraining ART[$_]...";
  my $group = $term_freq_groups->{$_};
  my $art = new ART(beta => $beta, lambda => $lambda, rho => $rho);
  $art->input($group->{TT});
  $group->{classes} = $art->output;
  $art->destroy;
}

say 'Forming compound keys...';

foreach( keys $term_freq_groups ) {
  say "\tfor T[$_]...";
  my $group = $term_freq_groups->{$_};

}


