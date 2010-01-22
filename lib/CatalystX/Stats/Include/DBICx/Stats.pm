package CatalystX::Stats::Include::DBICx::Stats;

use Moose::Role;
with ( 'CatalystX::Dispatcher::DBICx::Stats' );

=head1 DESCRIPTION

B<WuB::Role::Stats::DBIC> enables DBIC query login
within Catalyst stats

=cut

requires 'dispatch';

use DBICx::Stats::Catalyst;

sub create_dbic_storage_debugobj {
  my ( $self, %p ) = @_;
  return DBICx::Stats::Catalyst->new({
    model        => join( '::', $p{app}, 'Model', $p{model_name} ),
    stats        => $p{stats},
    pass_through => $p{pass_through},
  });
}


1;
