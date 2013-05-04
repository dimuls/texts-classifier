#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use PDL;
use PDL::Sparse;

use lib './lib';
use Tools;

my $conf = require 'conf.pl';
my $DT_data_path = "$conf->{data_path}/document-term-model";

my ($docs, $words, $words_ids) = load_data($conf->{processed_docs_path}, $conf->{docs_limit});

my $words_count = scalar keys %$words;
my $docs_count = scalar keys %$docs;

# Init zero document-term similarity matrix
my $DT = new PDL::Sparse($words_count, $docs_count);

# Rows correspond to documents, columns to terms
#   T1 T2 .. Tn
# D1 0  0 ..  0
# D2 0  0 ..  0
# D3 0  0 ..  0
# .. .  . ..  .
# Dm 0  0 ..  0

for my $doc ( values %$docs ) {
  for my $word ( values %$words ) {
    next unless defined $word->{docs}->{$doc->{id}};
    $DT->set($word->{id}, $doc->{id},
      ($word->{docs}->{$doc->{id}} / $doc->{words_count}) * log($docs_count / scalar keys $word->{docs})
    );
  } 
}

$DT->write_to_dir($DT_data_path);
