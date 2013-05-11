package SOM;

use utf8;
use v5.14.2;

use Term::ProgressBar;

use PDL;
use PDL::IO::FastRaw;
use Inline qw( PDLPP );

use List::Util qw(shuffle);

set_autopthread_targ(4);
set_autopthread_size(1);

sub new(@) {
  my ($class, %opt) = @_;
  return $class if ref $class;

  die "SOM: width parameter needed"  unless defined $opt{width};
  die "SOM: height parameter needed" unless defined $opt{height};
  die "SOM: alpha parameter needed"  unless defined $opt{alpha};
  die "SOM: sigma parameter needed"  unless defined $opt{sigma};
  die "SOM: iter_limit parameter needed"  unless defined $opt{iter_limit};
  die "SOM: error_limit parameter needed"  unless defined $opt{error_limit};

  my $self = {
     width => $opt{width},
    height => $opt{height},
 grid_size => $opt{width} * $opt{height},
     alpha => $opt{alpha},
     sigma => $opt{sigma},
 iter_limit => $opt{iter_limit},
error_limit => $opt{error_limit},
   weights => undef,
      grid => undef,
    show_progress_bar => $opt{show_progress_bar} || 0,
  };
  bless $self, $class;
  $self->_init_grid;
  return $self;
}

sub _init_progress_bar($$) {
  my ($self, $count) = @_;
  my $progress_bar = new Term::ProgressBar({
    name => 'Training SOM',
    count => $count,
    ETA   => 'linear',
  });
  $progress_bar->max_update_rate(1);
  return $progress_bar;
}

sub _init_grid($) {
  my ($self) = @_;
  $self->{grid} = zeros(2, $self->{grid_size});
  my $grid = $self->{grid};
  my $vertex_id = 0;
  for my $i ( 0 .. $self->{width} - 1 ) {
    for my $j ( 0 .. $self->{height} - 1 ) {
      $grid->set(0, $vertex_id, $i);
      $grid->set(1, $vertex_id, $j);
      $vertex_id++;
    }
  }
}

sub _init_weights($$) {
  my ($self, $input_size) = @_;
  $self->{weights} = random $input_size, $self->{grid_size};
}

sub input($$) {
  my ($self, $inputs) = @_;
  my ($inputs_size, $inputs_count) = $inputs->dims;

  $self->_init_weights($inputs_size) unless defined $self->{weights};
  my $grid = $self->{grid};
  my $weights = $self->{weights};
  my $alpha = $self->{alpha};
  my $sigma = $self->{sigma};
  my $iter_limit = $self->{iter_limit};
  my $error_limit = $self->{error_limit};

  my ($progress, $next_update, $counter) = ($self->_init_progress_bar($iter_limit * $inputs_count), 0, 0) if $self->{show_progress_bar};

  for my $i ( 1 .. $iter_limit ) {
    my $inputs_used = 0;
    my $errors_sum = 0;
    for my $input_id ( shuffle(0 .. $inputs_count - 1) ) {
      my $input = $inputs->slice(":,($input_id)");
      my $winner_id = minimum_ind sumover (($weights - $input) ** 2);
      my $winner_vertex = $grid->slice(":,($winner_id)");
      my $winner_weights = $weights->slice(":,($winner_id)");
      my $neighborhood_measures = $alpha->($i) * exp( - sqrt(sumover(($winner_vertex - $grid) ** 2)) / (2 * ($sigma->($i) ** 2)));
      $weights += $neighborhood_measures->dummy(0) * ($input - $weights);
      $next_update = $progress->update($counter) if $progress and $counter++ > $next_update;
      $errors_sum += sqrt(sum(($input - $winner_weights) ** 2));
      last if $errors_sum / ++$inputs_used <= $error_limit;
    }
  }
  $progress->update($iter_limit * $inputs_count) if $progress;

  delete $self->{output} if exists $self->{output};
}

sub _find_neighbors($$$) {
  my ($self, $col, $row) = @_;
  my @neighbors_ids;
  push @neighbors_ids, ($col-1) * $self->{height} + ($row-1) if $col - 1 >= 0 and $row - 1 >= 0;
  push @neighbors_ids, ($col-1) * $self->{height} + ($row+1) if $col - 1 >= 0 and $row + 1 < $self->{height};
  push @neighbors_ids, ($col+1) * $self->{height} + ($row-1) if $col + 1 < $self->{width} and $row - 1 >= 0;
  push @neighbors_ids, ($col+1) * $self->{height} + ($row+1) if $col + 1 < $self->{width} and $row + 1 < $self->{height};
  return @neighbors_ids;
}

sub _make_output($) {
  my ($self) = @_;
  my $weights = $self->{weights};
  my $output = zeros($self->{width}, $self->{height});
  for my $col ( 0 .. $self->{width} - 1 ) {
    for my $row ( 0 .. $self->{height} - 1 ) {
      my $vertex_id = $col * $self->{height} + $row;
      my $vertex_weights = $weights->dice('X', $vertex_id);
      my @neighbors_ids = $self->_find_neighbors($col, $row);
      my $neighbors_weights = $weights->dice('X', [@neighbors_ids]);
      my $neighbors_count = scalar @neighbors_ids;
      $output->set($col, $row, sum( sqrt(sumover(($vertex_weights - $neighbors_weights) ** 2)) / $neighbors_count));
    }
  }
  $output -= $output->min;
  $output /= $output->max;
  $self->{output} = $output;
}

sub output($) {
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
