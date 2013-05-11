package FART;

use utf8;
use v5.14.2;

use Term::ProgressBar;

use PDL;
use PDL::IO::FastRaw;
use Inline qw( PDLPP );

set_autopthread_targ(4);
set_autopthread_size(1);

sub new(@) {
  my ($class, %opt) = @_;
  return $class if ref $class;

  die "FART: beta parameter needed" unless defined $opt{beta};
  die "FART: lambda paramater needed" unless defined $opt{lambda};
  die "FART: rho paramter needed" unless defined $opt{rho};

  my $self = {
      beta => $opt{beta},
    lambda => $opt{lambda},
       rho => $opt{rho},
      outs => [],
    show_progress_bar => $opt{show_progress_bar} || 0,
  };
  bless $self, $class;

  return $self;
}

sub _init_progress_bar($$) {
  my ($self, $count) = @_;
  my $progress_bar = new Term::ProgressBar({
    name => 'Training FuzzyART',
    count => $count,
    ETA   => 'linear',
  });
  $progress_bar->max_update_rate(1);
  return $progress_bar;
}

sub _find_closest_resonanced_prototype_vector($$) {
  my ($self, $x) = @_;
  return undef unless scalar @{$self->{outs}};
  my $beta = $self->{beta};
  my $x_sum = $x->sum();
  my $x_measure = $x_sum / ($beta + $x->dim(0));
  
  ($_->{pv_fx_sum} / $x_sum >= $self->{rho}) and return $_ foreach sort {
    $b->{measure} <=> $a->{measure}
  } grep {
    $_->{measure} >= $x_measure
  } map {
    $_->{pv_fx_sum} = $_->{prototype_vector}->fuzzy_and($x)->sum();
    $_->{measure} = $_->{pv_fx_sum} / ($beta + $_->{pv_sum});
    $_;
  } @{ $self->{outs} };

  return undef;
}

sub input($$) {
  my ($self, $X) = @_;
  my ($cols, $rows) = $X->dims;

  my ($progress, $next_update) = ($self->_init_progress_bar($rows), 0) if $self->{show_progress_bar};

  for my $i ( 0 .. $rows - 1 ) {
    # Take i-th row from input
    my $x = $X->slice(":,($i)");
    my $v = $self->_find_closest_resonanced_prototype_vector($x);
    if( defined $v ) {
      $v->{prototype_vector}->adapt($x, $self->{lambda});
      $v->{pv_sum} = $v->{prototype_vector}->sum;
      push @{$v->{elements}}, $i;
    } else {
      push @{$self->{outs}}, {
        prototype_vector => $x->copy,
        pv_sum => $x->sum,
        elements => [ $i ],
      };
    }
    $next_update = $progress->update($i + 1) if $progress and $i + 1 > $next_update;
  }
  $progress->update($rows) if $progress;

  delete $self->{output} if exists $self->{output};
}

sub _make_output {
  my ($self) = @_;
  my $i = 0;
  $self->{output} = { map { $i++ => $_->{elements} } @{$self->{outs}} };
}

sub output {
  my ($self) = @_;
  $self->_make_output unless exists $self->{output};
  return $self->{output};
}

sub clear {
  my ($self) = @_;
  $self->{outs} = [];
  delete $self->{outputs};
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
