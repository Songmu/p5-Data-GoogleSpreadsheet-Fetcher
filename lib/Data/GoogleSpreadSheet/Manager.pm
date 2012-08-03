package Data::GoogleSpreadSheet::Manager;
use strict;
use warnings;
our $VERSION = '0.01';
$VERSION = eval $VERSION;

use utf8;
use Net::Google::Spreadsheets;

use Any::Moose;

has spreadsheet => (
    is       => 'ro',
    isa      => 'Net::Google::Spreadsheets::Spreadsheet',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Net::Google::Spreadsheets->new(
            username => $self->username,
            password => $self->password,
        )->spreadsheet({
            key => $self->key,
        });
    },
);

has config => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {{}},
);

has username => (
    is  => 'rw',
    isa => 'Str',
);

has password => (
    is  => 'rw',
    isa => 'Str',
);

has key => (
    is  => 'rw',
    isa => 'Str',
);

no Any::Moose;

sub dump_worksheet {
    my ($self, $table) = @_;
    my $table_config = $self->config->{tables}{$table} || {};
    my $sheet     = $table_config->{sheet} || $table;
    my ($worksheet) = grep {$_->title eq $sheet} $self->spreadsheet->worksheets;

    my $cond        = $table_config->{cond} || {sq => 'id > 0'};
    my @rows        = $worksheet->rows($cond);

    my @columns     = @{$table_config->{columns} || []};
    unless (@columns) {
        @columns = grep {/^[a-z]/} map {replace_column4db($_)} keys %{$rows[0]->content};
    }
    my @db_columns = (@columns, @{$table_config->{addtional_columns} || []});
    my @table_rows;

  ROW:
    for my $row (@rows) {
        my $content = $row->content;
        next if $content->{id} && $content->{id} !~ /^\d+$/;

        my %row_data;
        for my $real_column (@db_columns) {
            my $sheet_column = replace_column4spreadsheet($real_column);;
            $row_data{$real_column} = _trim($content->{$sheet_column});
        }

        my $filters = $table_config->{filter} || [];
        my @filters = ref $filters eq 'ARRAY' ? @{$filters} :
                      ref $filters eq 'HASH'  ? %{$filters} : ();

        while (my ($column, $rule) = splice @filters, 0, 2) {
            $column =~ s/_//g;
            $content->{$column} =
                !ref $rule          ? $rule :
                ref $rule eq 'CODE' ? $rule->($content) : '';
        }

        my @validates =
            grep {$_ && ref $_ eq 'CODE'}
            ($self->config->{global}{hooks}{row_validate}, $table_config->{row_validate});

        for my $validate (@validates) {
            next ROW unless $validate->(\%row_data);
        }

        push @table_rows, \%row_data;
    }
    @table_rows;
}

sub _trim {
    my ($string) = @_;

    return '' unless defined $string;

    $string =~ s/^[\s　]+//;
    $string =~ s/[\s　]+$//;

    $string;
}

sub replace_column4spreadsheet {
    my ($column_name) = @_;

    $column_name =~ s/_/-/g;

    $column_name;
}

sub replace_column4db {
    my ($column_name) = @_;

    $column_name =~ s/-/_/g;

    $column_name;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Data::GoogleSpreadSheet::Manager -

=head1 SYNOPSIS

  use Data::GoogleSpreadSheet::Manager;

=head1 DESCRIPTION

Data::GoogleSpreadSheet::Manager is

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
