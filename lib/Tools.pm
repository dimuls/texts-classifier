package Tools;

use utf8;
use v5.14.2;

use parent qw( Exporter );
our @EXPORT = qw(
  load_processed_docs
  load_data
  make_stem
);

use File::Slurp;

sub load_processed_docs($;$) {
  my ( $path, $limit ) = @_;
  my $pdocs = {};
  opendir(my $dh, $path) || die "Can't open docs path $path";
  my $id = 0;
  while(readdir $dh) {
    last if defined $limit and $id == $limit;
    next if /^\.+/;
    my $words = {};
    my $words_count = 0;
    open FILE, '<:utf8', "$path/$_";
    while(<FILE>) {
      if( /^(\w+):(\d+)/ ) {
        $words->{$1} = $2;
        $words_count++;
      }
    }
    close FILE;
    $pdocs->{$id} = {
                id => $id,
              name => $_,
             words => $words,
       words_count => $words_count,
    } and $id++ if $words_count;
  }
  closedir $dh;
  return $pdocs;
}

sub load_data($;$) {
  my $docs = load_processed_docs($_[0], $_[1]);
  my ($words, $words_ids);
  foreach my $doc ( values %$docs ) {
    while( my ($word_name,  $word_count) = each $doc->{words} ) {
      my $word_id = $words_ids->{$word_name};
      if ( defined $word_id ) {
        $words->{$word_id}->{docs}->{$doc->{id}} = $word_count;
      } else {
        $word_id = scalar keys %$words;
        $words->{$word_id} = {
          id => $word_id,
          name => $word_name,
          docs => {
            $doc->{id} => $word_count,
          }
        };
        $words_ids->{$word_name} = $word_id;
      }
    }
  }
  return ($docs, $words, $words_ids);
}

sub make_stem($) {
  my ( $max_freq, $max_word );
  foreach( split /\|/, `echo $_[0] | mystem -e utf8 -lnf` ) {
    my ($word, $freq) = split ':';
    unless( defined $max_freq or $max_freq >= $freq ) {
      ( $max_freq, $max_word ) = ( $freq, $word );
    }
  }
  return $max_word;
}

1;
