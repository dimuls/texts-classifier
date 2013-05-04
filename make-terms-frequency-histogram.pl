#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use PDL;
use PDL::Graphics::PLplot;

use lib './lib';

use Tools;

my $conf = require 'conf.pl';

my ($docs, $words, $words_ids) = load_data($conf->{processed_docs_path});

my @data;

foreach my $word ( values %$words ) {
  push @data, scalar keys $word->{docs};
}

my $pl = new PDL::Graphics::PLplot(DEV => "svg", FILE => "img/terms-frequency-histogram.svg");

my $data = pdl \@data;
my $nbins = 1000;
my $binwidth = ($data->max - $data->min) / $nbins;
my ($x, $y) = hist($data, $data->minmax, $binwidth);
my $fudgefactor = 1.1;

$pl->histogram($data, $nbins, BOX => [1, 500, 0, $y->max * $fudgefactor ], COLOR => 'BLUE', LINEWIDTH => 2, TITLE => 'Гистограмма частот терминов в документах', XLAB => 'Количество документов', YLAB => 'Количество терминов', NXSUB => 10);

$pl->close;
