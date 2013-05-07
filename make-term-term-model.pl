#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use Term::ProgressBar;

use PDL;
use PDL::IO::FastRaw;
use Inline qw( PDLPP );

use lib './lib';

use Tools;

set_autopthread_targ(4);
set_autopthread_size(5);

my $conf = require 'conf.pl';
my $beta = $conf->{beta} || 0.6;

my $DT = mapfraw("$conf->{data_path}/document-term-model", { ReadOnly => 1 });
my ($words_count, $docs_count) = $DT->dims;

my $TT = mapfraw("$conf->{data_path}/term-term-model", { Creat => 1, Dims => [$words_count, $words_count], Datatype => 6 });

my $progress = new Term::ProgressBar({
  count => $words_count,
  ETA   => 'linear',
});

$progress->max_update_rate(1);
my $next_update = 0;

for my $i ( 0 .. $words_count - 1 ) {
  my $term = $DT->slice("($i),:");
  $TT->slice("($i),:") .= $DT->fuzzy_and($term)->xchg(0,1)->sumover / ( $term->sum + $beta );
  $next_update = $progress->update($i + 1) if $i + 1 > $next_update;
}

$progress->update($words_count) if $words_count >= $next_update;

__DATA__

__PDLPP__

pp_def('fuzzy_and',
  Pars => 'a(n,m); b(m); [o]c(n,m);',
  Code => 'loop(n) %{
    loop(m) %{
      if( $a() < $b() ) {
        $c() = $a();
      } else {
        $c() = $b();
      }
    %}
  %}'
);

