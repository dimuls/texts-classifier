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

my $DT = mapfraw("$conf->{data_path}/document-term-model");

my $art = new FART(
  show_progress_bar => 1,
               beta => 0,
             lambda => 1,
                rho => 0.00053,
);

$art->input($DT);

my $clusters = $art->output;

say "Clusters count: ", scalar keys %$clusters;

DumpFile("$conf->{data_path}/docs-clusters.yaml", $clusters);
