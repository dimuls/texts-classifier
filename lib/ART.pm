package ART;

use utf8;
use v5.14.2;

use PDL;
use PDL::IO::FastRaw;
use Inline qw( PDLPP );

set_autopthread_targ(4);
set_autopthread_size(1);

sub new(@) {
  my ($class, %opt) = @_;
  return $class if ref $class;

  my $self = {
      beta => $opt{beta}   || die "ART: beta parameter needed",
       rho => $opt{rho}    || die "ART: rho paramter needed",
    lambda => $opt{lambda} || die "ART: lambda paramater needed",
      outs => [],
  };

  bless $self, $class;
  return $self;
}

sub _find_closest_resonanced_prototype_vector($$) {
  my ($self, $x) = @_;
  my $x_sum = $x->sum();
  my $x_measure = $x_sum / ($self->{beta} + $x->dim(0));
  
  ($_->{pv_fx_sum} / $x_sum >= $self->{rho}) and return $_ foreach sort {
    $b->{measure} <=> $a->{measure}
  } grep {
    $_->{measure} >= $x_measure
  } map {
    $_->{pv_sum} = $_->{prototype_vector}->sum;
    $_->{pv_fx_sum} = $_->{prototype_vector}->fuzzy_and($x)->sum();
    $_->{measure} = $_->{pv_fx_sum} / ($self->{beta} + $_->{pv_sum});
    $_;
  } @{ $self->{outs} };

  return undef;
}

sub input($$) {
  my ($self, $X) = @_;
  my ($cols, $rows) = $X->dims;
  for my $i ( 0 .. $rows - 1 ) {
    say $i;
    # Take row[i] for input
    my $x = $X->slice(":,($i)");
    my $v = $self->_find_closest_resonanced_prototype_vector($x);
    if( $v ) {
      $v->{prototype_vector}->adapt($x, $self->{lambda});
      $v->{elements}->append($i);
    } else {
      push @{$self->{outs}}, {
        prototype_vector => $x->copy,
        elements => pdl [ $i ],
      };
    }
  }
}

sub output {
  return [ map { $_->{elements} } @{$_[0]->{outs}} ];
}

sub destroy {
  delete $_[0]->{outs};
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

pp_def('adapt',
  Pars => 'a(n); b(n); c();',
  Code => '
    loop(n) %{
      if( $a() <= $b() ) {
        $a() = $c() * $a() + (1 - $c()) * $a();
      } else {
        $a() = $c() * $b() + (1 - $c()) * $a();
      }
    %}'
);
