package Brass::Schema::ResultSet::Issue;
  
use strict;
use warnings;

use DateTime;
use DBIx::Class::Helper::ResultSet::CorrelateRelationship 2.034000;
use Log::Report;

use base qw(DBIx::Class::ResultSet);

__PACKAGE__->load_components(qw(Helper::ResultSet::DateMethods1 Helper::ResultSet::CorrelateRelationship));

sub statistics
{   my $self = shift;
    my $schema = $self->result_source->schema;

    # Work out dates of last quarter
    my $quarter_start = 
       DateTime
       ->now(time_zone => 'local')
       ->set_time_zone('floating')
       ->truncate(to => 'quarter')
       ->subtract(months => 3);

    my $quarter_end =
       $quarter_start 
       ->clone
       ->add(months => 3)
       ->subtract(days => 1);

    my $formatter = $schema->storage->datetime_parser;

    # Number of new security incidents during quarter
    my @all = $self->search({
        'type.is_breach' => 1,
    },{
        join => [qw/type/],
        'select' => ['me.id', 'me.title',
            {
                # Earliest status of new or open
                "" => $schema->resultset('Issue')
                        ->correlate('issue_statuses')
                        ->search({ status => [1, 2]})
                        ->get_column('datetime')
                        ->min_rs->as_query,
                -as => 'opened',
            },
        ],
        having => {
            opened => {
                '>=' => $formatter->format_datetime($quarter_start),
                '<=' => $formatter->format_datetime($quarter_end),
            },
        },
    })->all;

    my @opened = map {
        +{
            title  => $_->get_column('title'),
            opened => $formatter->parse_datetime($_->get_column('opened')),
        }
    } @all;

    # Number of currently open security-related issues
    @all = $self->search([
        'type.is_vulnerability'  => 1,
        'type.is_breach'         => 1,
        'type.is_audit'          => 1,
        'type.is_other_security' => 1,
    ],{
        join => [qw/type/],
        'select' => ['me.id', 'me.title',
            {
                "" => $schema->resultset('IssueStatus')->search({
                    'iss_stat.id' => {'=' => $schema->resultset('Issue')
                        ->correlate('issue_statuses')
                        ->search({
                            datetime => {
                                '<=' => $formatter->format_datetime($quarter_start),
                            }
                        })
                        ->get_column('id')
                        ->max_rs->as_query}
                },{
                    alias    => 'iss_stat', # Prevent conflict with other "me" table
                })->get_column('status')->as_query,
                -as => 'historical_status',
            },
            {
                # Earliest status of new or open
                "" => $schema->resultset('Issue')
                        ->correlate('issue_statuses')
                        ->search({ status => [1, 2]})
                        ->search({
                            datetime => {
                                '>=' => $formatter->format_datetime($quarter_start),
                                '<=' => $formatter->format_datetime($quarter_end),
                            }
                        })
                        ->get_column('datetime')
                        ->min_rs->as_query,
                -as => 'open_in_quarter',
            },
            {
                # Current priority
                "" => $schema->resultset('IssuePriority')->search({
                    'iss_prio.id' => {'=' => $schema->resultset('Issue')
                        ->correlate('issue_priorities')
                        ->get_column('id')
                        ->max_rs->as_query}
                },{
                    alias    => 'iss_prio', # Prevent conflict with other "me" table
                })->get_column('priority')->as_query,
                -as => 'current_priority',
            },
        ],
        having => [
            historical_status => [1,2],
            open_in_quarter   => { '!=' => undef },
        ],
    })->all;

    my %prio_mapping = map {
        $_->id => $_->name,
    } $schema->resultset('Priority')->all;

    my %existing = map { $_ => 0 } values %prio_mapping;
    $existing{$prio_mapping{$_->get_column('current_priority')}}++
        foreach @all;

    {
        from          => $quarter_start,
        to            => $quarter_end,
        new_incidents => \@opened,
        existing      => \%existing,
    }

}

1;
