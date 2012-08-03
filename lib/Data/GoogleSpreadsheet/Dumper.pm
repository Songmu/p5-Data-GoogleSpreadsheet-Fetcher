package Data::GoogleSpreadsheet::Dumper;
use strict;
use warnings;
our $VERSION = '0.01_01';
$VERSION = eval $VERSION; ## no critic

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

has username => (
    is  => 'ro',
    isa => 'Str',
);

has password => (
    is  => 'ro',
    isa => 'Str',
);

has key => (
    is  => 'ro',
    isa => 'Str',
);

has config => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {{}},
);

has ignore_empty_string => (
    is      => 'ro',
    isa     => 'Int',
    default => sub {0},
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
        @columns = grep {/^[a-z]/} map {_replace_column4db($_)} keys %{$rows[0]->content};
    }
    my @db_columns = (@columns, @{$table_config->{addtional_columns} || []});
    my @table_rows;

    my %seen_id;
  ROW:
    for my $row (@rows) {
        my $content = $row->content;
        next if $content->{id} && $content->{id} !~ /^\d+$/;
        !$seen_id{$content->{id}}++ or die "id $content->{id} is duplicated!";

        my %row_data;
        for my $real_column (@db_columns) {
            my $sheet_column = _replace_column4spreadsheet($real_column);

            my $data = _trim($content->{$sheet_column});
            next if $self->ignore_empty_string && $data eq '';
            $row_data{$real_column} = $data;
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

sub _replace_column4spreadsheet {
    my ($column_name) = @_;

    $column_name =~ s/_/-/g;

    $column_name;
}

sub _replace_column4db {
    my ($column_name) = @_;

    $column_name =~ s/-/_/g;

    $column_name;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Data::GoogleSpreadsheet::Dumper -

=head1 SYNOPSIS

  use Data::GoogleSpreadsheet::Dumper;
  my $dumper = Data::GoogleSpreadsheet::Dumper->new(
      username => 'username',
      password => 'your_password_here',
      key      => 'spreadsheet key',
  );
  my @records = $dumper->dump_worksheet('sheet_name');

=head1 DESCRIPTION

Data::GoogleSpreadsheet::Dumper is

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
