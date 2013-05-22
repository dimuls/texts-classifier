#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use YAML qw(LoadFile);

use PDL;
use PDL::IO::FastRaw;

use lib './lib';

my $conf = require 'conf.pl';

my $docs = LoadFile("$conf->{data_path}/docs.yml");
my $terms = LoadFile("$conf->{data_path}/terms.yml");

my $docs_count = scalar keys %$docs;
my $terms_count = scalar keys %$terms;

# Init zero document-term similarity matrix
my $DT = mapfraw("$conf->{data_path}/doc-term-matrix", { Creat => 1, Dims => [$terms_count, $docs_count], Datatype => 5 });

# Rows correspond to documents, columns to terms
#   T1 T2 .. Tn
# D1 0  0 ..  0
# D2 0  0 ..  0
# D3 0  0 ..  0
# .. .  . ..  .
# Dm 0  0 ..  0

while( my ($doc_id, $doc) = each %$docs ) {
  while( my ($term_id, $term_count) = each %{$doc->{terms}} ) {
    $DT->set($term_id, $doc->{id},
      ($term_count / $doc->{terms_count}) * log($docs_count / $terms->{$term_id}->{docs_count})
    );
  } 
}
