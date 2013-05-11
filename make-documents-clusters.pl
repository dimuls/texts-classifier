#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use YAML qw(Dump DumpFile);

use PDL;
use PDL::IO::FastRaw;

use lib './lib';

use Tools;
use FART;

my $conf = require 'conf.pl';

my $docs = load_processed_docs($conf->{processed_docs_path}, $conf->{docs_limit}, 0);

my $DT = mapfraw("$conf->{data_path}/document-term-model");

my $art = new FART(
  show_progress_bar => 1,
               beta => 0,
             lambda => 1,
                rho => 0.00053,
);

$art->input($DT);

my $clusters = $art->output;

foreach(keys %$clusters) {
  $clusters->{$_} = [ map { $docs->{$_}->{name} } @{$clusters->{$_}} ];
}

say "Clusters count: ", scalar keys %$clusters;

DumpFile("$conf->{data_path}/docs-clusters.yaml", $clusters);
