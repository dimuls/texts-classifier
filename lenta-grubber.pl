#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use v5.14.2;

use YAML qw(LoadFile DumpFile);
use File::Path qw(make_path);
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Text::Unidecode;
use Unicode::Normalize;

my $conf = require('conf.pl');
my $docs_path = $conf->{docs_path};
my $base_url = "http://lenta.ru";

my $http_client = LWP::UserAgent->new();
$http_client->timeout(30);
$http_client->agent('Opera/9.80 (Windows NT 6.1; U; ru) Presto/2.9.168 Version/11.52');

my $referer = $base_url;
my $path = '/news/2013/02/08';

sub slugify($) {
    my ($text) = @_;
    $text = NFKD($text);
    $text =~ s/[^\w\s-]//g;
    $text =~ s/^\s+|\s+$//g;
    $text = lc($text);
    $text =~ s/[-\s]+/-/g;
    return unidecode $text;
}

sub http_get($;$) {
  my ($url, $referer) = @_;
  my $request = HTTP::Request->new(GET => $url);
  $request->referer($referer) if defined $referer;
  my $response = $http_client->request($request);
  sleep 0.5;
  return undef unless $response->is_success;
  return $response->decoded_content;
}

sub parse_feed($) {
  my ( $content ) = @_;
  my $tree = HTML::TreeBuilder::XPath->new_from_content($content);
  my $next_path = $tree->findvalue('//a[@class="icons-sprite icons-gallery_prev_mini control"]/@href');
  #my @article_paths = $tree->findvalues('//section[@class="b-layout b-layout_archive"]//div[@class="g-layout"]//div[@class="titles"]//a/@href');
  my @article_paths = $tree->findvalues('//div[@class="g-layout"]//div[@class="titles"]/h3/a/@href');
  return $next_path, @article_paths;
}

sub parse_article($) {
  my ( $content ) = @_;
  $content =~ /"bloc_slug":"([^"]+)","tag_slug":"([^"]+)"/;
  my ($class, $subclass) = ($1, $2);
  my $tree = HTML::TreeBuilder::XPath->new_from_content($content);
  my $header = $tree->findvalue('//h1[@class="b-topic__title"]/text()');
  my $text = join ' ', @{ [$tree->findnodes_as_strings('//div[@class="b-text clearfix"]//./text()')] };
  $tree->delete;
  $text = $header . ".\n" . $text;
  $text =~ s/ +/ /;
  return $class, $subclass, $header, $text;
}

sub save_file($$$) {
	my ( $path, $filename, $content ) = @_;
	open FILE, '>:utf8', "$path/$filename" or die "Can't write open $path";
	print FILE $content;
	close FILE;
}

my $docs = LoadFile('docs.yaml');

eval {
  my $docs_count = 0;
  while( $docs_count <= 10000 ) {
    say "loading feed $path";
    my $url = $base_url . $path;
    my $content = http_get($url, $referer);
    die "Can't get feed $path" unless defined $content;
    my ( $next_path, @article_paths ) = parse_feed($content);
    $referer = $url;
    $path = $next_path;
    foreach my $article_path ( @article_paths ) {
      next unless $article_path =~ /\/news\/\d{4}\/\d{2}\/\d{2}\/\w+\//;
      print "\tloading article #$docs_count $article_path...";
      my $article_content = http_get($base_url . $article_path, $url);
      say ' ERROR #1' and next unless defined $article_content;
      my ($article_class, $article_subclass, $article_header, $article_text) = parse_article($article_content);
      say ' ERROR #2' and next unless $article_class and $article_subclass and $article_header and $article_text;
      my $article_path = "$docs_path/$article_class/$article_subclass";
      my $article_header_slug = slugify $article_header;
      eval {
        make_path $article_path;
        save_file $article_path, $article_header_slug, $article_text;
      };
      say ' ERROR #3' and next if $@;
      say ' OK';
      $docs->{$article_header_slug} = { class => $article_class, subclass => $article_subclass };
      $docs_count += 1;
      if( $docs_count % 100 == 0 ) {
        DumpFile('docs.yaml', $docs);
      }
    }
  }
};

DumpFile('docs.yaml', $docs);
