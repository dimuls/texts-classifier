#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use YAML qw(LoadFile DumpFile);
use List::Util qw(sum);

use lib './lib';

my $conf = require 'conf.pl';
my $docs_path = $conf->{docs_path};

my $term_docs_count_lower_limit = $conf->{term_docs_count_lower_limit};
my $term_docs_count_upper_limit = $conf->{term_docs_count_upper_limit};

my (%docs, %words_docs_counts);

opendir(my $dh, $docs_path) || die "Can't open path $docs_path";
while ( my $doc_name = readdir $dh ) {
  next if $doc_name =~ /^\.+/;
  my $doc = LoadFile("$docs_path/$doc_name");
  $docs{$doc->{id}} = $doc;
  foreach my $word_name ( keys %{ $doc->{words} } ) {
    $words_docs_counts{$word_name}++;
  }
}

my (%terms_ids, %terms);
my $id = 0;
while( my ($word_name, $word_docs_count) = each %words_docs_counts ) {
  if( $word_docs_count >= $term_docs_count_lower_limit and $word_docs_count <= $term_docs_count_upper_limit ) {
    $terms{$id} = {
      id => $id,
      name => $word_name,
      docs_count => $word_docs_count,
    };
    $terms_ids{$word_name} = $id;
    $id++;
  } else {
    delete $words_docs_counts{$word_name};
  }
}

foreach my $doc ( values %docs ) {
  map { 
    $doc->{terms}->{$terms_ids{$_}} = $doc->{words}->{$_};
  } grep {
    defined $words_docs_counts{$_}
  } keys %{$doc->{words}};
  $doc->{terms_count} = sum values %{$doc->{terms}};
  delete $doc->{words};
}

DumpFile("$conf->{data_path}/docs.yml", \%docs);
DumpFile("$conf->{data_path}/terms.yml", \%terms);
DumpFile("$conf->{data_path}/terms-ids.yml", \%terms_ids);
