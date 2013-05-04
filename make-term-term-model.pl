#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use PDL;
use PDL::Sparse;
use Inline qw( PDLPP );

use lib './lib';

use Tools;

set_autopthread_targ(4);
set_autopthread_size(1);

my $conf = require 'conf.pl';
my $beta = $conf->{beta} || 0.6;

my $DT = read_from_dir PDL::Sparse("$conf->{data_path}/document-term-model");
my ($words_count, $docs_count) = $DT->dims;

say $words_count;
say $docs_count;

exit 0;

my $TT = mapfraw("$conf->{data_path}/term-term-model");

for my $i ( 0 .. $words_count - 1 ) {
  for my $j ( 0 .. $words_count - 1  ) {
    my $col_i = $DT->slice("($i),:");
    my $col_j = $DT->slice("($j),:");
    if( $i == $j ) {
      $TT->set($i, $j, 1 + $beta);
    } else {
      $TT->set($i, $j, $col_i->fuzzy_and($col_j)->sum() / ($col_i->sum() + $beta));
    }
  }
}

__DATA__

__PDLPP__

pp_def('fuzzy_and',
  Pars => 'a(n); b(n); [o]c(n);',
  Code => 'loop(n) %{
    if( $a() < $b() ) {
      $c() = $a();
    } else {
      $c() = $b();
    }
  %}'
);

