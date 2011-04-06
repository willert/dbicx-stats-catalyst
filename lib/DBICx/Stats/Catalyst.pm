package DBICx::Stats::Catalyst;

=head1 DESCRIPTION

B<DBICx::Stats::Catalyst> delegates L<DBIx:Class>
storage logs to the L<Catalyst::Stats> object given
at object creation time.

=cut

use Moose;
with ( 'DBICx::Stats::Role::PassThrough' );

our $VERSION = '0.00_01';

use Scalar::Util qw/blessed weaken/;

has 'stats' => (
  is       => 'ro',
  isa      => 'Catalyst::Stats',
  required => 1,
  weak_ref => 1,
);

has 'model' => (
  is       => 'ro',
  default  => 'Catalyst::Model::DBIC::Schema'
);

sub svp_begin{
  my $self = shift;
  $self->stats->profile( begin => 'Savepoint' );
}

sub svp_release{
  my $self = shift;
  $self->stats->profile( comment => 'Rolled back!' );
  $self->stats->profile( end => 'Savepoint' );
}

sub svp_rollback{
  my $self = shift;
  $self->stats->profile( end => 'Savepoint' );
}

sub txn_begin {
  my $self = shift;
  $self->stats->profile( begin => 'Transaction' );
}

sub txn_rollback {
  my $self = shift;
  $self->stats->profile( comment => 'Rolled back!' );
  $self->stats->profile( end => 'Transaction' );
}

sub txn_commit {
  my $self = shift;
  $self->stats->profile( end => 'Transaction' );
}

sub query_start {
  my ( $self, $sql, @params ) = @_;
  $self->stats->profile( begin   => $self->model . '->query' );
  $self->stats->profile( comment => $self->_format_sql( $sql ));
}

sub query_end {
  my ( $self, $sql, @params ) = @_;
  $self->stats->profile( end     => $self->model . '->query' );
}

sub _format_sql {
  my $self = shift;
  my $sql = shift;
  ( my $shortend_sql = $sql ) =~ s{ SELECT \s (.*?) \s FROM }
     { 'SELECT ' . ( length $1 > 40 ? '..' : $1 ) . ' FROM' }xe;
  my $depth = @{[ $self->stats->report ]} ?
    [ $self->stats->report ]->[ -1 ][ 0 ] : 0;
  my $prefix = ' ' x ( $depth + 5 );

  if ( length $shortend_sql > 60 ) {
    s{( LEFT \s JOIN | JOIN | WHERE | ORDER \s BY | LIMIT )}{\n$prefix$1}xg
      for $shortend_sql;
  }

  return $shortend_sql;
}

no Moose;

1;

