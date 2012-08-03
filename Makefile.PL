use inc::Module::Install;
name 'Data-GoogleSpreadsheet-Dumper';
all_from 'lib/Data/GoogleSpreadsheet/Dumper.pm';

requires 'Any::Moose';
requires 'Net::Google::Spreadsheets';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
